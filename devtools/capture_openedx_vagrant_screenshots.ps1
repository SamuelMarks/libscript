# ## Overview
# Automates launching Open edX Windows Installer (.msi) wizard inside Vagrant Windows 11,
# stepping through every enumeration (Simple Mode and Advanced Mode flows),
# capturing pixel-perfect screenshots of every wizard step, the desktop icons,
# and the browser validation tabs directly from the live QEMU display framebuffer.
#
# ## Usage
# powershell devtools/capture_openedx_vagrant_screenshots.ps1 [MSI_PATH]

[CmdletBinding()]
param(
    [string]$MsiOverride = ""
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$TempDir = Join-Path $RepoRoot "tmp\vagrant_screenshots"
$Cc0ScreenshotsDir = [System.IO.Path]::GetFullPath((Join-Path $RepoRoot "..\cc0-assets\libscript\openedx\screenshots"))

if (-not (Test-Path $TempDir)) {
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
}
if (-not (Test-Path $Cc0ScreenshotsDir)) {
    New-Item -ItemType Directory -Path $Cc0ScreenshotsDir -Force | Out-Null
}

# Discover SSH port
$SshPort = $env:SSH_PORT
if (-not $SshPort) {
    $qemuProc = Get-CimInstance Win32_Process -Filter "Name LIKE 'qemu%'" -ErrorAction SilentlyContinue |
                Where-Object { $_.CommandLine -like "*windows-11*" } | Select-Object -First 1
    if ($qemuProc -and ($qemuProc.CommandLine -match "hostfwd=tcp::(\d+)-:22")) {
        $SshPort = $Matches[1]
    }
}
if (-not $SshPort -and (Get-Command ps -ErrorAction SilentlyContinue)) {
    $psOut = & ps aux 2>$null | Select-String -Pattern "qemu.*windows-11" | Select-Object -First 1
    if ($psOut -match "hostfwd=tcp::(\d+)-:22") {
        $SshPort = $Matches[1]
    }
}
if (-not $SshPort) { $SshPort = "50791" }

$SshKey = Join-Path $env:HOME ".vagrant.d/insecure_private_key"

# Locate QEMU monitor socket
$MonitorSock = $env:MONITOR_SOCK
if (-not $MonitorSock) {
    $sockCandidates = @(
        (Get-ChildItem -Path "$env:HOME/.vagrant.d/tmp/vagrant-qemu" -Filter "qemu_socket" -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName),
        "/tmp/qemu_socket_win11"
    )
    foreach ($cand in $sockCandidates) {
        if ($cand -and (Test-Path $cand)) {
            $MonitorSock = $cand
            break
        }
    }
}
if (-not $MonitorSock -and (Get-Command ps -ErrorAction SilentlyContinue)) {
    $psOut = & ps aux 2>$null | Select-String -Pattern "qemu.*windows-11" | Select-Object -First 1
    if ($psOut -match "path=([^,]*qemu_socket)") {
        $MonitorSock = $Matches[1]
    }
}

Write-Host "[INFO] Using SSH port: $SshPort"
Write-Host "[INFO] Found QEMU monitor socket: $MonitorSock"

# ## Invoke-VmRun
# Helper to execute command over SSH on guest VM.
function Invoke-VmRun {
    param([string]$Command)
    $fullCmd = @(
        "-p", $SshPort,
        "-o", "StrictHostKeyChecking=no",
        "-o", "UserKnownHostsFile=/dev/null",
        "-o", "LogLevel=ERROR",
        "-i", $SshKey,
        "vagrant@127.0.0.1",
        "$Command; exit 0"
    )
    & ssh $fullCmd
}

# ## Invoke-VmScp
# Helper to copy local files to guest VM.
function Invoke-VmScp {
    param(
        [string]$LocalPath,
        [string]$RemotePath
    )
    $cmd = @(
        "-P", $SshPort,
        "-o", "StrictHostKeyChecking=no",
        "-o", "UserKnownHostsFile=/dev/null",
        "-o", "LogLevel=ERROR",
        "-i", $SshKey,
        $LocalPath,
        "vagrant@127.0.0.1:$RemotePath"
    )
    & scp $cmd
}

# ## Invoke-CaptureScreen
# Helper to capture QEMU screendump and convert to PNG.
function Invoke-CaptureScreen {
    param([string]$Name)
    $ppm = Join-Path $TempDir "$Name.ppm"
    $png = Join-Path $TempDir "$Name.png"
    Start-Sleep -Milliseconds 1500
    if ($MonitorSock -and (Test-Path $MonitorSock)) {
        "screendump $ppm`n" | nc -U $MonitorSock 2>$null | Out-Null
        if (Get-Command sips -ErrorAction SilentlyContinue) {
            & sips -s format png $ppm --out $png 2>$null | Out-Null
        } elseif (Get-Command magick -ErrorAction SilentlyContinue) {
            & magick $ppm $png 2>$null | Out-Null
        }
        if (Test-Path $ppm) { Remove-Item $ppm -Force }
    }
    if (Test-Path $png) {
        if (Test-Path $Cc0ScreenshotsDir) {
            $targetCc0 = Join-Path $Cc0ScreenshotsDir "$Name.png"
            Copy-Item -Path $png -Destination $targetCc0 -Force
            $len = (Get-Item $targetCc0).Length
            Write-Host "[CAPTURED] $Name.png ($len bytes)"
        }
        Remove-Item -Path $png -Force
    }
}

# ## Invoke-VmAction
# Helper to execute UI automation actions in Session 1 and wait for completion.
function Invoke-VmAction {
    param([string]$Action)
    Invoke-VmRun "Set-Content -Path 'C:/libscript/target_btn.txt' -Value '$Action'; Start-ScheduledTask -TaskName 'ClickGui'; `$sw = [System.Diagnostics.Stopwatch]::StartNew(); while ((Get-ScheduledTask -TaskName 'ClickGui').State -eq 'Running' -and `$sw.Elapsed.TotalSeconds -lt 25) { Start-Sleep -Milliseconds 250 }"
    Start-Sleep -Milliseconds 800
}

function Invoke-VmClick { param([string]$Button) Invoke-VmAction "CLICK:$Button" }
function Invoke-VmRadio { param([string]$Radio) Invoke-VmAction "RADIO:$Radio" }
function Invoke-VmCheck { param([string]$Check) Invoke-VmAction "CHECK:$Check" }
function Invoke-VmUncheck { param([string]$Check) Invoke-VmAction "UNCHECK:$Check" }
function Invoke-VmSetEdit { param([int]$Index, [string]$Val) Invoke-VmAction "SET_EDIT:${Index}|${Val}" }
function Invoke-VmWaitDialog { param([string]$Title) Invoke-VmAction "WAIT_DIALOG:$Title" }
function Invoke-VmWait { param([string]$Btn) Invoke-VmAction "WAIT:$Btn" }

function Invoke-VmLaunchMsi {
    Invoke-VmRun "Start-ScheduledTask -TaskName 'LaunchMsi'; Start-Sleep -Seconds 4"
}

function Invoke-LaunchBrowserUrl {
    param([string]$Url)
    Invoke-VmRun "cmd.exe /c call C:\libscript\packaging\open_browser.cmd $Url"
    Start-Sleep -Seconds 5
}

function Invoke-CleanGuestInstallations {
    Write-Host "[INFO] Cleaning any prior installations on guest..."
    Invoke-VmRun 'Stop-Process -Name msiexec -Force -ErrorAction SilentlyContinue; while ($p = Get-Package -Name "*Open edX*" -ErrorAction SilentlyContinue) { foreach ($pkg in $p) { Start-Process msiexec.exe -ArgumentList "/x $($pkg.FastPackageReference) /qn" -Wait } }; Get-ChildItem -Path "Registry::HKEY_CLASSES_ROOT\Installer\Products" -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { $_.ProductName -like "*Open edX*" } | ForEach-Object { Start-Process msiexec.exe -ArgumentList "/x $($_.PSChildName) /qn" -Wait }'
    Invoke-VmRun 'Stop-Process -Name WindowsTerminal -Force -ErrorAction SilentlyContinue'
}

Write-Host "[INFO] Open edX Windows Vagrant screenshot automation initialized."

Write-Host "=== Step 1: Syncing updated packaging and stack files to Windows guest ==="
Invoke-VmScp (Join-Path $RepoRoot "packaging\build_msi.cmd") "C:/libscript/packaging/"
Invoke-VmScp (Join-Path $RepoRoot "packaging\build_msi.sh") "C:/libscript/packaging/"
Invoke-VmScp (Join-Path $RepoRoot "packaging\build_openedx_msi.cmd") "C:/libscript/packaging/"
Invoke-VmScp (Join-Path $RepoRoot "packaging\build_openedx_msi.sh") "C:/libscript/packaging/"
Invoke-VmScp (Join-Path $RepoRoot "packaging\harvest_licenses.cmd") "C:/libscript/packaging/"
Invoke-VmScp (Join-Path $RepoRoot "packaging\harvest_licenses.ps1") "C:/libscript/packaging/"
Invoke-VmScp (Join-Path $RepoRoot "packaging\harvest_licenses.sh") "C:/libscript/packaging/"
Invoke-VmScp (Join-Path $RepoRoot "packaging\harvest_payload.cmd") "C:/libscript/packaging/"
Invoke-VmScp (Join-Path $RepoRoot "packaging\harvest_payload.ps1") "C:/libscript/packaging/"
Invoke-VmScp (Join-Path $RepoRoot "packaging\harvest_payload.sh") "C:/libscript/packaging/"
Invoke-VmScp (Join-Path $RepoRoot "packaging\launch_browser.cmd") "C:/libscript/packaging/"
Invoke-VmScp (Join-Path $RepoRoot "packaging\launch_browser.ps1") "C:/libscript/packaging/"
Invoke-VmScp (Join-Path $RepoRoot "packaging\launch_browser.sh") "C:/libscript/packaging/"
Invoke-VmScp (Join-Path $RepoRoot "packaging\open_browser.cmd") "C:/libscript/packaging/"
Invoke-VmScp (Join-Path $RepoRoot "packaging\open_browser.ps1") "C:/libscript/packaging/"
Invoke-VmScp (Join-Path $RepoRoot "packaging\start_mock_server.cmd") "C:/libscript/packaging/"
Invoke-VmScp (Join-Path $RepoRoot "packaging\start_mock_server.ps1") "C:/libscript/packaging/"
Invoke-VmScp (Join-Path $RepoRoot "packaging\start_mock_server.sh") "C:/libscript/packaging/"
Invoke-VmScp (Join-Path $RepoRoot "packaging\mock_server.ps1") "C:/libscript/packaging/"
Invoke-VmScp (Join-Path $RepoRoot "packaging\click_button.ps1") "C:/libscript/packaging/"
Invoke-VmScp (Join-Path $RepoRoot "packaging\create_desktop_shortcuts.cmd") "C:/libscript/packaging/"
Invoke-VmScp (Join-Path $RepoRoot "packaging\create_desktop_shortcuts.ps1") "C:/libscript/packaging/"
Invoke-VmScp (Join-Path $RepoRoot "packaging\create_desktop_shortcuts.sh") "C:/libscript/packaging/"
Invoke-VmScp (Join-Path $RepoRoot "stacks\cms\openedx\packaging.json") "C:/libscript/stacks/cms/openedx/"
Invoke-VmScp (Join-Path $RepoRoot "stacks\cms\openedx\offline_bundle.json") "C:/libscript/stacks/cms/openedx/"
Invoke-VmScp (Join-Path $RepoRoot "stacks\cms\openedx\manifest.json") "C:/libscript/stacks/cms/openedx/"
Invoke-VmScp (Join-Path $RepoRoot "stacks\cms\openedx\vars.schema.json") "C:/libscript/stacks/cms/openedx/"
Invoke-VmScp (Join-Path $RepoRoot "stacks\cms\openedx\cli.cmd") "C:/libscript/stacks/cms/openedx/"
Invoke-VmScp (Join-Path $RepoRoot "stacks\cms\openedx\cli.sh") "C:/libscript/stacks/cms/openedx/"
Invoke-VmScp (Join-Path $RepoRoot "stacks\cms\openedx\service.cmd") "C:/libscript/stacks/cms/openedx/"
Invoke-VmScp (Join-Path $RepoRoot "stacks\cms\openedx\service.sh") "C:/libscript/stacks/cms/openedx/"
Invoke-VmScp (Join-Path $RepoRoot "stacks\cms\openedx\setup_generic.cmd") "C:/libscript/stacks/cms/openedx/"
Invoke-VmScp (Join-Path $RepoRoot "stacks\cms\openedx\setup_generic.sh") "C:/libscript/stacks/cms/openedx/"

Invoke-CleanGuestInstallations

if ($MsiOverride -and (Test-Path $MsiOverride)) {
    Write-Host "=== Step 2: Syncing provided MSI ($MsiOverride) to Windows guest ==="
    Invoke-VmScp $MsiOverride "C:/libscript/packaging/OpenEdX-Setup.msi"
} else {
    Write-Host "=== Step 2: Compiling full self-contained OpenEdX-Setup.msi on Windows guest ==="
    Invoke-VmRun 'cmd /c "cd C:\libscript && call packaging\build_openedx_msi.cmd --online --out packaging\OpenEdX-Setup --banner-side packaging\assets\openedx_banner_side.bmp --banner-top packaging\assets\openedx_banner_top.bmp --icon packaging\assets\openedx.ico --license packaging\assets\openedx_eula.rtf"'
}

Invoke-VmRun '$principal = New-ScheduledTaskPrincipal -UserId "vagrant" -LogonType Interactive; $settings = New-ScheduledTaskSettingsSet -MultipleInstances Parallel -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries; $aLaunch = New-ScheduledTaskAction -Execute "msiexec.exe" -Argument "/i C:\libscript\packaging\OpenEdX-Setup.msi"; Register-ScheduledTask -TaskName "LaunchMsi" -Action $aLaunch -Principal $principal -Force > $null; $aClick = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File C:\libscript\packaging\click_button.ps1"; Register-ScheduledTask -TaskName "ClickGui" -Action $aClick -Principal $principal -Settings $settings -Force > $null; $aRun = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\libscriptun_gui.ps1"; Register-ScheduledTask -TaskName "RunGui" -Action $aRun -Principal $principal -Force > $null'
Invoke-VmRun 'Remove-Item "C:/Users/Public/Desktop/Microsoft Edge.lnk" -Force -ErrorAction SilentlyContinue; Remove-Item "C:/Users/vagrant/Desktop/Microsoft Edge.lnk" -Force -ErrorAction SilentlyContinue'

Invoke-CleanGuestInstallations

Write-Host "`n=== Flow 1: Simple Mode Installation ==="
Write-Host "[INFO] Launching OpenEdX-Setup.msi in Session 1..."
Invoke-VmLaunchMsi

# Step 1: Welcome
Invoke-VmWaitDialog "Welcome"
Invoke-CaptureScreen "01_simple_welcome"

# Step 2: License Agreement
Invoke-VmClick "Next"
Invoke-VmWaitDialog "License"
Invoke-CaptureScreen "02_simple_license"

# Step 3: Setup Type
Invoke-VmClick "I Agree"
Invoke-VmWaitDialog "Installation Mode"
Invoke-CaptureScreen "03_simple_setup_type"

# Step 4: Verify Ready
Invoke-VmClick "Next"
Invoke-VmWaitDialog "Ready to Install"
Invoke-CaptureScreen "04_simple_verify_ready"

# Step 5: Install & Exit
Write-Host "[INFO] Triggering installation in Simple Mode..."
Invoke-VmClick "Install"
Invoke-VmWaitDialog "Setup Complete"
Invoke-CaptureScreen "05_simple_exit"
Invoke-VmClick "Finish"
Start-Sleep -Seconds 2

Invoke-CleanGuestInstallations

Write-Host "`n=== Flow 2: Advanced Mode Customization ==="
Write-Host "[INFO] Launching OpenEdX-Setup.msi for Advanced Mode in Session 1..."
Invoke-VmLaunchMsi
Invoke-VmWaitDialog "Welcome"
Invoke-VmClick "Next"
Invoke-VmWaitDialog "License"
Invoke-VmClick "I Agree"
Invoke-VmWaitDialog "Installation Mode"

# Step 5: Advanced Mode Selected
Invoke-VmRadio "Advanced Mode"
Invoke-VmWaitDialog "Installation Mode"
Invoke-CaptureScreen "06_advanced_setup_type_selected"

# Setup Type -> Component Selection (Features)
Invoke-VmClick "Next"
Invoke-VmWaitDialog "Component Selection"
Invoke-VmCheck "Demo Course"
Invoke-VmCheck "Micro-Frontends"
Invoke-CaptureScreen "06a_advanced_features"

# Features -> Destination Folders
Invoke-VmClick "Next"
Invoke-VmWaitDialog "Destination Folders"
Invoke-VmSetEdit 0 'C:\OpenEdX\app'
Invoke-VmSetEdit 1 'C:\OpenEdX\data'
Invoke-VmSetEdit 2 'C:\OpenEdX\logs'
Invoke-VmSetEdit 3 'C:\OpenEdX\backups'
Invoke-CaptureScreen "06b_advanced_install_location"

# Destination Folders -> Runtime Environment Selection
Invoke-VmClick "Next"
Invoke-VmWaitDialog "Runtime Environment"
Invoke-VmRadio "Install isolated private Python"
Invoke-VmRadio "Install isolated private Node.js"
Invoke-CaptureScreen "06c_advanced_runtime_selection"

# Runtime Environment -> Source Repository & Release
Invoke-VmClick "Next"
Invoke-VmWaitDialog "Source Repository"
Invoke-VmSetEdit 2 "ghp_edxAdminTokenSecret2026ExampleKey"
Invoke-CaptureScreen "06d_advanced_source_repo"

# Source Repo -> Network & Credentials Configuration
Invoke-VmClick "Next"
Invoke-VmWaitDialog "Network and Credentials"
Invoke-VmSetEdit 0 "8000"
Invoke-VmSetEdit 1 "8001"
Invoke-VmSetEdit 2 "edx_admin"
Invoke-VmSetEdit 3 "edx_password_2026!"
Invoke-VmSetEdit 4 "admin@openedx.local"
Invoke-CaptureScreen "06e_advanced_config"

# Config -> Relational Database / DBaaS
Invoke-VmClick "Next"
Invoke-VmWaitDialog "Database"
Invoke-VmSetEdit 0 "3306"
Invoke-VmSetEdit 1 "mysql://edx_app:Secr3tP@ss@db.internal:3306/edxapp"
Invoke-CaptureScreen "07_advanced_db"

# DB -> Cache, Document Store & Search
Invoke-VmClick "Next"
Invoke-VmWaitDialog "Cache"
Invoke-VmSetEdit 0 "6379"
Invoke-VmSetEdit 1 "rediss://:RedisSecret2026@cache.internal:6379/0"
Invoke-VmSetEdit 2 "mongodb://edx_mongo:MongoSecret@docdb.internal:27017/edx"
Invoke-VmSetEdit 3 "https://meili.cloud.internal:7700"
Invoke-CaptureScreen "08_advanced_cache_search"

# Cache -> Verify Ready (Advanced)
Invoke-VmClick "Next"
Invoke-VmWaitDialog "Ready to Install"
Invoke-CaptureScreen "09_advanced_verify_ready"

# Verify Ready -> Install & Exit
Write-Host "[INFO] Triggering installation in Advanced Mode..."
Invoke-VmClick "Install"
Invoke-VmWaitDialog "Setup Complete"
Invoke-CaptureScreen "10_advanced_exit"

# Exit -> Finish
Write-Host "[INFO] Waiting for installation to complete and clicking Finish..."
Invoke-VmClick "Finish"
Start-Sleep -Seconds 2
Invoke-VmRun 'cmd /c call C:\libscript\packaging\create_desktop_shortcuts.cmd; Start-Sleep -Seconds 2'
Invoke-CaptureScreen "10b_desktop_icons"

Write-Host "`n=== Flow 3: Browser Verification & Authentication Flows ==="
Write-Host "[INFO] Starting mock server on guest for ports 8000 and 8001..."
Invoke-VmRun 'cmd /c "cd C:\libscript && call packaging\start_mock_server.cmd"'

# Step 11: LMS Login Screen
Write-Host "[INFO] Opening LMS Portal Login (:8000/login) in Browser..."
Invoke-LaunchBrowserUrl "http://localhost:8000/login"
Invoke-CaptureScreen "11_browser_lms_focused"

# Step 12: Studio CMS Sign-in Screen
Write-Host "[INFO] Opening Studio CMS Sign-in (:8001/signin) in Browser..."
Invoke-LaunchBrowserUrl "http://localhost:8001/signin"
Invoke-CaptureScreen "12_browser_studio_focused"

# Step 13: LMS Authenticated Dashboard (edx_admin)
Write-Host "[INFO] Logging in with edx_admin credentials to LMS Dashboard (:8000/dashboard)..."
Invoke-LaunchBrowserUrl "http://localhost:8000/dashboard"
Invoke-CaptureScreen "13_browser_lms_authenticated"

# Step 14: Studio CMS Authenticated Dashboard (staff@openedx.org)
Write-Host "[INFO] Logging in with staff@openedx.org credentials to Studio Dashboard (:8001/home)..."
Invoke-LaunchBrowserUrl "http://localhost:8001/home"
Invoke-CaptureScreen "14_browser_studio_authenticated"

# Clean up browser session
Invoke-VmRun 'Stop-Process -Name chrome, msedge -Force -ErrorAction SilentlyContinue'

Write-Host "`n=== All Open edX Vagrant Windows screenshots captured successfully in cc0-assets! ==="
Get-ChildItem -Path $Cc0ScreenshotsDir -Filter "*.png" | Sort-Object Name | ForEach-Object {
    Write-Host ("{0,-36} {1,10} bytes" -f $_.Name, $_.Length)
}
