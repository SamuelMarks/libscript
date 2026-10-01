# ## Overview
# Launches browser natively in interactive Session 1 with dedicated profile.
#
# ## Usage
# powershell -ExecutionPolicy Bypass -File packaging/open_browser.ps1 -Url <http://...>

param(
    [string]$Url = "http://localhost:8000/login"
)

# 1. Kill any existing browser or terminal window
Get-Process chrome, msedge, WindowsTerminal, OpenConsole -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

# 2. Find browser
$browserExe = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $browserExe)) {
    $browserExe = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
}
if (-not (Test-Path $browserExe)) {
    Write-Host "[INFO] Browser not detected; installing Google Chrome via winget..."
    & winget install --id Google.Chrome --silent --accept-package-agreements --accept-source-agreements > $null 2>&1
    $browserExe = "C:\Program Files\Google\Chrome\Application\chrome.exe"
}

# 3. Create profile dir if needed
$hash = [Math]::Abs($Url.GetHashCode())
$profileDir = "C:\EdgeProfile_$hash"
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

# 4. Launch browser
$browserArgs = "--user-data-dir=`"$profileDir`" --no-first-run --no-default-browser-check --disable-fre --disable-search-engine-choice-screen --disable-features=SearchEngineChoice,msEdgeFirstRunExperience --disable-session-crashed-bubble --hide-crash-restore-bubble --disable-gpu --start-maximized `"$Url`""
$action = New-ScheduledTaskAction -Execute $browserExe -Argument $browserArgs
$principal = New-ScheduledTaskPrincipal -UserId "vagrant" -LogonType Interactive
Register-ScheduledTask -TaskName "ShowBrowser" -Action $action -Principal $principal -Force | Out-Null
Start-ScheduledTask -TaskName "ShowBrowser"
Start-Sleep -Seconds 5
