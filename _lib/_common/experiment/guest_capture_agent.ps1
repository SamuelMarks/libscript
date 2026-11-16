# ## Overview
# Guest-side Windows Session 1 screen, desktop shortcut, and CDP WebSocket browser login screenshot agent.
#
# ## Usage
# powershell -NoProfile -ExecutionPolicy Bypass -File guest_capture_agent.ps1 -Action <screen|desktop|browser> [options]

param(
    [string]$Action = 'screen',
    [string]$OutFile = 'C:/libscript_exp/screenshots/capture.png',
    [string]$CropMode = 'FULL',
    [string]$DesktopPolicy = 'if-applicable',
    [string]$CaptureType = 'browser_unauthenticated',
    [int]$ServicePort = 8000,
    [string]$HealthPath = '/',
    [string]$Url = 'http://localhost:8000/',
    [int]$TimeoutSec = 300,
    [string]$LoginUrl = '',
    [string]$UsernameSelector = '',
    [string]$PasswordSelector = '',
    [string]$SubmitSelector = '',
    [string]$UsernameValue = '',
    [string]$PasswordValue = '',
    [string]$ReadySelector = ''
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

# ## Save-GuestScreenshot
# Captures the active Windows Session 1 desktop or foreground window bounds directly to a PNG file.
function Save-GuestScreenshot {
    param(
        [string]$TargetPng,
        [string]$Mode
    )
    $parentDir = Split-Path -Parent $TargetPng
    if (($parentDir) -and (-not (Test-Path $parentDir))) {
        New-Item -ItemType Directory -Force -Path $parentDir | Out-Null
    }
    $bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $bmp = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
    $gfx = [System.Drawing.Graphics]::FromImage($bmp)
    $gfx.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
    $gfx.Dispose()

    if ($Mode -eq 'INSTALLER') {
        $w = [Math]::Min(520, $bmp.Width)
        $h = [Math]::Min(420, $bmp.Height)
        $x = [Math]::Max(0, [int](($bmp.Width - $w) / 2))
        $y = [Math]::Max(0, [int](($bmp.Height - $h) / 2))
        $rect = New-Object System.Drawing.Rectangle $x, $y, $w, $h
        $cropped = $bmp.Clone($rect, $bmp.PixelFormat)
        $bmp.Dispose()
        $cropped.Save($TargetPng, [System.Drawing.Imaging.ImageFormat]::Png)
        $cropped.Dispose()
        return
    }
    $bmp.Save($TargetPng, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

# ## Invoke-DesktopCapture
# Minimizes open windows so desktop shortcuts are visible and captures `10b_desktop_icons.png`.
function Invoke-DesktopCapture {
    param(
        [string]$TargetPng,
        [string]$Policy
    )
    if ($Policy -eq 'never') {
        Write-Output 'SKIPPED_NOT_APPLICABLE'
        return
    }
    try {
        $shellApp = New-Object -ComObject Shell.Application
        $shellApp.MinimizeAll()
        Start-Sleep -Seconds 2
    } catch {
    }
    Save-GuestScreenshot -TargetPng $TargetPng -Mode 'FULL'
    Write-Output 'CAPTURED'
}

# ## Wait-LocalHttpService
# Polls `http://127.0.0.1:<port><path>` inside the Windows guest until HTTP 2xx/3xx readiness.
function Wait-LocalHttpService {
    param(
        [int]$Port,
        [string]$Path,
        [int]$MaxSec
    )
    $deadline = (Get-Date).AddSeconds($MaxSec)
    $probeUrl = "http://127.0.0.1:$Port$Path"
    while ((Get-Date) -lt $deadline) {
        try {
            $req = [System.Net.HttpWebRequest]::Create($probeUrl)
            $req.Timeout = 3000
            $req.AllowAutoRedirect = $false
            $resp = [System.Net.HttpWebResponse]$req.GetResponse()
            $code = [int]$resp.StatusCode
            $resp.Close()
            if (($code -ge 200) -and ($code -lt 400)) {
                return
            }
        } catch [System.Net.WebException] {
            if ($_.Exception.Response) {
                $code = [int]$_.Exception.Response.StatusCode
                $_.Exception.Response.Close()
                if (($code -ge 200) -and ($code -lt 400)) {
                    return
                }
            }
        } catch {
        }
        Start-Sleep -Seconds 3
    }
    throw "Timed out waiting for local guest HTTP endpoint $probeUrl"
}

# ## Send-CdpCommand
# Sends a single JSON-RPC message over a local Chrome DevTools Protocol WebSocket.
function Send-CdpCommand {
    param(
        [string]$WsUrl,
        [string]$PayloadJson
    )
    $ws = New-Object System.Net.WebSockets.ClientWebSocket
    $ct = [System.Threading.CancellationToken]::None
    $ws.ConnectAsync([Uri]$WsUrl, $ct).GetAwaiter().GetResult() | Out-Null
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($PayloadJson)
    $seg = New-Object System.ArraySegment[byte] -ArgumentList @(,$bytes)
    $ws.SendAsync($seg, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $ct).GetAwaiter().GetResult() | Out-Null
    $buf = New-Object byte[] 262144
    $recvSeg = New-Object System.ArraySegment[byte] -ArgumentList @(,$buf)
    $res = $ws.ReceiveAsync($recvSeg, $ct).GetAwaiter().GetResult()
    $outStr = [System.Text.Encoding]::UTF8.GetString($buf, 0, $res.Count)
    $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, '', $ct).GetAwaiter().GetResult() | Out-Null
    $ws.Dispose()
    return $outStr
}

# ## Resolve-GuestBrowserExe
# Locates Microsoft Edge or Google Chrome inside the Windows guest.
function Resolve-GuestBrowserExe {
    $candidates = @(
        'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
        'C:\Program Files\Microsoft\Edge\Application\msedge.exe',
        'C:\Program Files\Google\Chrome\Application\chrome.exe'
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) {
            return $c
        }
    }
    throw 'No supported Chromium browser (Edge or Chrome) found inside Windows guest.'
}

# ## Invoke-BrowserVerification
# Opens the target web endpoint, optionally authenticates via CDP DOM selectors, and saves a browser PNG.
function Invoke-BrowserVerification {
    Wait-LocalHttpService -Port $ServicePort -Path $HealthPath -MaxSec $TimeoutSec
    $browserExe = Resolve-GuestBrowserExe
    $profDir = Join-Path ($env:TEMP) ("ls_cdp_" + [System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Force -Path $profDir | Out-Null

    $openTarget = $Url
    if (($CaptureType -eq 'browser_authenticated') -and ($LoginUrl -ne '')) {
        $openTarget = $LoginUrl
    }

    $bArgs = @(
        "--user-data-dir=$profDir",
        '--remote-debugging-port=9222',
        '--no-first-run',
        '--no-default-browser-check',
        '--window-position=40,30',
        '--window-size=1280,800',
        $openTarget
    )
    $proc = Start-Process -FilePath $browserExe -ArgumentList $bArgs -PassThru
    Start-Sleep -Seconds 5

    try {
        $tabsJson = (New-Object System.Net.WebClient).DownloadString('http://127.0.0.1:9222/json')
        $tabs = $tabsJson | ConvertFrom-Json
        $wsUrl = $null
        foreach ($t in $tabs) {
            if (($t.type -eq 'page') -and ($t.webSocketDebuggerUrl)) {
                $wsUrl = $t.webSocketDebuggerUrl
                break
            }
        }

        if (($CaptureType -eq 'browser_authenticated') -and ($wsUrl)) {
            $uSel = $UsernameSelector.Replace("'", "`'")
            $pSel = $PasswordSelector.Replace("'", "`'")
            $sSel = $SubmitSelector.Replace("'", "`'")
            $uVal = $UsernameValue.Replace("'", "`'")
            $pVal = $PasswordValue.Replace("'", "`'")
            $js = "(() => { const sv = (s, v) => { const e = document.querySelector(s); if (!e) return; const d = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value'); if (d && d.set) d.set.call(e, v); else e.value = v; e.dispatchEvent(new Event('input', {bubbles:true})); e.dispatchEvent(new Event('change', {bubbles:true})); }; sv('$uSel', '$uVal'); sv('$pSel', '$pVal'); const b = document.querySelector('$sSel'); if (b) b.click(); })()"
            $rpc = @{ id = 1; method = 'Runtime.evaluate'; params = @{ expression = $js } } | ConvertTo-Json -Compress
            Send-CdpCommand -WsUrl $wsUrl -PayloadJson $rpc | Out-Null
            Start-Sleep -Seconds 6

            if ($ReadySelector -ne '') {
                $rSel = $ReadySelector.Replace("'", "`'")
                $deadline = (Get-Date).AddSeconds(45)
                while ((Get-Date) -lt $deadline) {
                    $chkRpc = @{ id = 2; method = 'Runtime.evaluate'; params = @{ expression = "Boolean(document.querySelector('$rSel'))" } } | ConvertTo-Json -Compress
                    $chkOut = Send-CdpCommand -WsUrl $wsUrl -PayloadJson $chkRpc
                    if ($chkOut -match 'true') { break }
                    Start-Sleep -Seconds 2
                }
            }
            if (($Url -ne '') -and ($Url -ne $LoginUrl)) {
                $navRpc = @{ id = 3; method = 'Page.navigate'; params = @{ url = $Url } } | ConvertTo-Json -Compress
                Send-CdpCommand -WsUrl $wsUrl -PayloadJson $navRpc | Out-Null
                Start-Sleep -Seconds 4
            }
        }

        Save-GuestScreenshot -TargetPng $OutFile -Mode 'BROWSER'
    } finally {
        if ($proc -and (-not $proc.HasExited)) {
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        }
        Remove-Item -Path $profDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if ($Action -eq 'screen') {
    Save-GuestScreenshot -TargetPng $OutFile -Mode $CropMode
} elseif ($Action -eq 'desktop') {
    Invoke-DesktopCapture -TargetPng $OutFile -Policy $DesktopPolicy
} elseif ($Action -eq 'browser') {
    Invoke-BrowserVerification
} else {
    throw "Unsupported guest_capture_agent action: $Action"
}
