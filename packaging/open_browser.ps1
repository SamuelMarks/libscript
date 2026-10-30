# ## Overview
# Launches browser natively in interactive Session 1 with dedicated profile and optional CDP login automation.
#
# ## Usage
# powershell -ExecutionPolicy Bypass -File packaging/open_browser.ps1 -Url <http://...> [-Url2 <http://...>] [-Username <user>] [-Password <pass>] [-SubmitLogin]

param(
    [string]$Url = "http://localhost:8000/login",
    [string]$Url2 = "",
    [string]$Username = "",
    [string]$Password = "",
    [switch]$SubmitLogin
)

# 1. Kill any existing browser or terminal window and dismiss any system error dialogs
Get-Process chrome, msedge, WindowsTerminal, OpenConsole, WerFault -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
if (Test-Path "C:\libscript\packaging\click_button.ps1") {
    Set-Content -Path "C:\libscript\target_btn.txt" -Value "CLICK:OK" -ErrorAction SilentlyContinue
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\libscript\packaging\click_button.ps1" 2>$null | Out-Null
}
Start-Sleep -Milliseconds 500

# 2. Find browser (Chrome if preinstalled or built-in Microsoft Edge on Windows 11)
$browserExe = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $browserExe)) {
    $browserExe = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
}
if (-not (Test-Path $browserExe)) {
    $browserExe = "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
}

# 3. Create profile dir if needed
$hash = [Math]::Abs(($Url + $Url2 + $Username + $SubmitLogin.IsPresent).GetHashCode())
$profileDir = "C:\EdgeProfile_$hash"
if (Test-Path $profileDir) {
    Remove-Item -Path $profileDir -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path (Join-Path $profileDir "Default") -Force | Out-Null
$preferencesJson = '{"credentials_enable_service":false,"profile":{"password_manager_enabled":false,"password_manager_leak_detection":false}}'
Set-Content -Path (Join-Path $profileDir "Default\Preferences") -Value $preferencesJson -Encoding Ascii

# 4. Launch browser with remote debugging port
$dbgPort = 9222
$urlArgs = "`"$Url`""
if ($Url2) {
    $urlArgs = "`"$Url`" `"$Url2`""
}
$browserArgs = "--user-data-dir=`"$profileDir`" --remote-debugging-port=$dbgPort --remote-allow-origins=* --no-first-run --no-default-browser-check --disable-fre --disable-search-engine-choice-screen --disable-save-password-bubble --password-store=basic --disable-features=SearchEngineChoice,msEdgeFirstRunExperience,PasswordManager,PasswordManagerOnboarding --disable-session-crashed-bubble --hide-crash-restore-bubble --disable-gpu --window-position=10,10 --window-size=780,535 $urlArgs"
$action = New-ScheduledTaskAction -Execute $browserExe -Argument $browserArgs
$principal = New-ScheduledTaskPrincipal -UserId "vagrant" -LogonType Interactive
Register-ScheduledTask -TaskName "ShowBrowser" -Action $action -Principal $principal -Force | Out-Null
Start-ScheduledTask -TaskName "ShowBrowser"
Start-Sleep -Seconds 5

# 5. Optional CDP prefill or login automation
if ($Username -or $SubmitLogin) {
    # ## Invoke-CdpEval
    # Sends a Runtime.evaluate command over WebSocket to a Chrome/Edge target page.
    function Invoke-CdpEval {
        param([string]$WsUrl, [string]$JsExpr)
        try {
            $ws = New-Object System.Net.WebSockets.ClientWebSocket
            $ct = New-Object System.Threading.CancellationToken
            $ws.ConnectAsync([Uri]$WsUrl, $ct).Wait(3000) | Out-Null
            if ($ws.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
                $payload = (@{ id = 1; method = "Runtime.evaluate"; params = @{ expression = $JsExpr; awaitPromise = $true } } | ConvertTo-Json -Compress -Depth 5)
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
                $seg = New-Object System.ArraySegment[byte] -ArgumentList @(,$bytes)
                $ws.SendAsync($seg, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $ct).Wait(3000) | Out-Null
                $buf = New-Object byte[] 16384
                $recvSeg = New-Object System.ArraySegment[byte] -ArgumentList @(,$buf)
                $ws.ReceiveAsync($recvSeg, $ct).Wait(3000) | Out-Null
                $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "", $ct).Wait(1000) | Out-Null
            }
        } catch {
        }
    }

    try {
        $targets = Invoke-RestMethod -Uri "http://127.0.0.1:$dbgPort/json" -TimeoutSec 3 -ErrorAction Stop
        foreach ($t in $targets) {
            if ($t.type -eq "page" -and $t.webSocketDebuggerUrl) {
                $uEsc = $Username.Replace("'", "\'")
                $pEsc = $Password.Replace("'", "\'")
                $doSubmit = if ($SubmitLogin) { "true" } else { "false" }
                $js = @"
new Promise(function(resolve) {
    var attempts = 0;
    function setReactVal(el, val) {
        if (!el) return;
        el.focus();
        var setter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value').set;
        if (setter) {
            setter.call(el, val);
        } else {
            el.value = val;
        }
        el.dispatchEvent(new Event('input', { bubbles: true }));
        el.dispatchEvent(new Event('change', { bubbles: true }));
        el.blur();
    }
    function tryFill() {
        var u = document.querySelector('input[name="emailOrUsername"], #login-email, input[name="email"], input[name="email_or_username"], #user_login, input[type="email"], input[type="text"]');
        var p = document.querySelector('input[name="password"], #login-password, #user_pass, input[type="password"]');
        if ((!u || !p) && attempts < 20) {
            attempts++;
            setTimeout(tryFill, 300);
            return;
        }
        if (u && '$uEsc') {
            setReactVal(u, '$uEsc');
        }
        if (p && '$pEsc') {
            setReactVal(p, '$pEsc');
        }
        if ($doSubmit) {
            setTimeout(function() {
                var btn = document.querySelector('#sign-in, button[name="sign-in"], button[type="submit"], input[type="submit"], .login-button, .action-primary');
                if (btn) { btn.click(); }
                else if (u && u.form) { u.form.submit(); }
                resolve(true);
            }, 250);
        } else {
            resolve(true);
        }
    }
    tryFill();
});
"@
                Invoke-CdpEval -WsUrl $t.webSocketDebuggerUrl -JsExpr $js
            }
        }
        if ($SubmitLogin) {
            Start-Sleep -Seconds 8
        } else {
            Start-Sleep -Seconds 3
        }
    } catch {
    }
}

