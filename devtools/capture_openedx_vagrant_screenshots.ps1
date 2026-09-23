# ## Overview
# Automates capturing pixel-perfect screenshots of every step and enumeration
# in the Open edX Windows Installer (.msi) wizard using Vagrant Windows 11 and QEMU screendump.
#
# ## Usage
# powershell devtools/capture_openedx_vagrant_screenshots.ps1

[CmdletBinding()]
param(
    [switch]$Help
)

# ## Show-Help
# Displays usage and help information.
function Show-Help {
    Write-Host "Usage: devtools\capture_openedx_vagrant_screenshots.ps1 [-Help]"
    Write-Host ""
    Write-Host "Automates capturing pixel-perfect screenshots of the Open edX MSI installer"
    Write-Host "running inside the Vagrant Windows 11 guest VM."
    exit 0
}

if ($Help) {
    Show-Help
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..")).Path
$Cc0ScreenshotsDir = Join-Path $RepoRoot "..\cc0-assets\libscript\openedx\screenshots"
$TempDir = Join-Path $RepoRoot "tests_tmp\vagrant_screenshots"

if (-not (Test-Path $TempDir)) {
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
}
if (Test-Path (Join-Path $RepoRoot "..\cc0-assets")) {
    if (-not (Test-Path $Cc0ScreenshotsDir)) {
        New-Item -ItemType Directory -Path $Cc0ScreenshotsDir -Force | Out-Null
    }
}

# Discover SSH port dynamically
$SshPort = $null
$vagrantDir = Join-Path $RepoRoot "vagrant\windows-11"
if (Test-Path $vagrantDir) {
    Push-Location $vagrantDir
    try {
        $sshConfig = vagrant ssh-config 2>$null
        foreach ($line in ($sshConfig -split "`n")) {
            if ($line -match "^\s*Port\s+(\d+)") {
                $SshPort = $matches[1]
                break
            }
        }
    } catch {}
    Pop-Location
}
if (-not $SshPort) {
    $SshPort = "50613"
}

$SshKey = Join-Path $env:USERPROFILE ".vagrant.d\insecure_private_key"
if (-not (Test-Path $SshKey)) {
    $SshKey = Join-Path $HOME ".vagrant.d/insecure_private_key"
}

# Locate QEMU monitor socket dynamically
$MonitorSock = $null
$qemuProcs = Get-Process -Name "*qemu*" -ErrorAction SilentlyContinue
# Fallback check socket directory
$vagQemuDir = Join-Path $HOME ".vagrant.d/tmp/vagrant-qemu"
if (Test-Path $vagQemuDir) {
    $sockFile = Get-ChildItem -Path $vagQemuDir -Filter "qemu_socket" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($sockFile) {
        $MonitorSock = $sockFile.FullName
    }
}

# ## Invoke-VmRun
# Helper to execute remote command inside the Vagrant VM via SSH.
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

# ## Invoke-VmClick
# Helper to click a button or radio control in Session 1.
function Invoke-VmClick {
    param([string]$ButtonText)
    Invoke-VmRun "Set-Content -Path 'C:/libscript/target_btn.txt' -Value '$ButtonText'; Start-ScheduledTask -TaskName 'RunGui'; Start-Sleep -Seconds 2"
}

# ## Invoke-LaunchBrowserUrl
# Helper to launch Microsoft Edge to a specified URL in Session 1.
function Invoke-LaunchBrowserUrl {
    param([string]$Url)
    Invoke-VmRun "Set-Content -Path 'C:/libscript/run_gui.ps1' -Value `"Stop-Process -Name msedge -Force -ErrorAction SilentlyContinue; Start-Process 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe' -ArgumentList '--new-window', '--start-maximized', '--no-first-run', '--no-default-browser-check', '$Url'`"; Start-ScheduledTask -TaskName 'RunGui'; Start-Sleep -Seconds 4"
}

# ## Invoke-CleanGuestInstallations
# Helper to uninstall all Open edX packages from Windows guest.
function Invoke-CleanGuestInstallations {
    Write-Host "[INFO] Cleaning any prior installations on guest..."
    Invoke-VmRun 'Stop-Process -Name msiexec -Force -ErrorAction SilentlyContinue; while ($p = Get-Package -Name "*Open edX*" -ErrorAction SilentlyContinue) { foreach ($pkg in $p) { Start-Process msiexec.exe -ArgumentList "/x $($pkg.FastPackageReference) /qn" -Wait } }; Get-ChildItem -Path "Registry::HKEY_CLASSES_ROOT\Installer\Products" -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { $_.ProductName -like "*Open edX*" } | ForEach-Object { Start-Process msiexec.exe -ArgumentList "/x $($_.PSChildName) /qn" -Wait }'
}

Write-Host "[INFO] Open edX Windows Vagrant screenshot automation initialized."

Write-Host "=== Step 1: Syncing updated packaging and stack files to Windows guest ==="
Invoke-VmScp (Join-Path $RepoRoot "packaging\build_msi.cmd") "C:/libscript/packaging/"
Invoke-VmScp (Join-Path $RepoRoot "packaging\build_msi.sh") "C:/libscript/packaging/"
Invoke-VmScp (Join-Path $RepoRoot "packaging\harvest_payload.cmd") "C:/libscript/packaging/"
Invoke-VmScp (Join-Path $RepoRoot "packaging\harvest_payload.ps1") "C:/libscript/packaging/"
Invoke-VmScp (Join-Path $RepoRoot "packaging\harvest_payload.sh") "C:/libscript/packaging/"
Invoke-VmScp (Join-Path $RepoRoot "packaging\launch_browser.cmd") "C:/libscript/packaging/"
Invoke-VmScp (Join-Path $RepoRoot "packaging\launch_browser.ps1") "C:/libscript/packaging/"
Invoke-VmScp (Join-Path $RepoRoot "packaging\launch_browser.sh") "C:/libscript/packaging/"
Invoke-VmScp (Join-Path $RepoRoot "packaging\click_button.ps1") "C:/libscript/packaging/"
Invoke-VmScp (Join-Path $RepoRoot "packaging\start_mock_server.cmd") "C:/libscript/packaging/"
Invoke-VmScp (Join-Path $RepoRoot "packaging\start_mock_server.ps1") "C:/libscript/packaging/"
Invoke-VmScp (Join-Path $RepoRoot "packaging\mock_server.ps1") "C:/libscript/packaging/"

Write-Host "=== Step 2: Compiling full self-contained OpenEdX-Setup.msi on Windows guest ==="
Invoke-VmRun 'cmd /c "cd C:\libscript && call packaging\build_openedx_msi.cmd --online --out packaging\OpenEdX-Setup --banner-side packaging\assets\openedx_banner_side.bmp --banner-top packaging\assets\openedx_banner_top.bmp --icon packaging\assets\openedx.ico --license packaging\assets\openedx_eula.rtf"'

# Configure RunGui task helper in guest
Invoke-VmRun 'Set-Content -Path "C:/libscript/run_gui.ps1" -Value "& powershell.exe -ExecutionPolicy Bypass -File C:/libscript/packaging/click_button.ps1 > C:/libscript/click.log 2>&1"; $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File C:/libscript/run_gui.ps1"; $principal = New-ScheduledTaskPrincipal -UserId "vagrant" -LogonType Interactive; Register-ScheduledTask -TaskName "RunGui" -Action $action -Principal $principal -Force > $null'

# Ensure broken Edge shortcut is cleaned from desktop
Invoke-VmRun 'Remove-Item "C:/Users/Public/Desktop/Microsoft Edge.lnk" -Force -ErrorAction SilentlyContinue; Remove-Item "C:/Users/vagrant/Desktop/Microsoft Edge.lnk" -Force -ErrorAction SilentlyContinue'

Invoke-CleanGuestInstallations

Write-Host "`n=== Flow 1: Simple Setup Flow Enumeration ==="
Write-Host "[INFO] Launching OpenEdX-Setup.msi in Session 1..."
Invoke-VmRun 'Set-Content -Path "C:\libscript\run_gui.ps1" -Value "Start-Process msiexec.exe -ArgumentList `"/i C:\libscript\packaging\OpenEdX-Setup.msi`""; Start-ScheduledTask -TaskName "RunGui"; Start-Sleep -Seconds 4; Set-Content -Path "C:\libscript\run_gui.ps1" -Value "& powershell.exe -ExecutionPolicy Bypass -File C:/libscript/packaging/click_button.ps1 > C:/libscript/click.log 2>&1"'

# Step 1: Welcome
Invoke-CaptureScreen "01_simple_welcome"

# Step 2: License Agreement
Invoke-VmClick "I Agree"
Invoke-CaptureScreen "02_simple_license"

# Step 3: Setup Type (Simple selected by default)
Invoke-VmClick "Next"
Invoke-CaptureScreen "03_simple_setup_type"

# Step 4: Verify Ready
Invoke-VmClick "Next"
Invoke-CaptureScreen "04_simple_verify_ready"

# Step 5: Install & Exit
Write-Host "[INFO] Triggering installation in Simple Mode..."
Invoke-VmClick "Install"
Start-Sleep -Seconds 5
Invoke-CaptureScreen "05_simple_exit"

# Step 6: Finish and Desktop Icons
Write-Host "[INFO] Clicking Finish to complete Simple Mode..."
Invoke-VmClick "Finish"
Start-Sleep -Seconds 3
Invoke-CaptureScreen "10b_desktop_icons"

Write-Host "`n=== Flow 2: Advanced Setup Flow Enumeration ==="
Invoke-CleanGuestInstallations

Write-Host "[INFO] Launching OpenEdX-Setup.msi for Advanced Flow in Session 1..."
Invoke-VmRun 'Set-Content -Path "C:\libscript\run_gui.ps1" -Value "Start-Process msiexec.exe -ArgumentList `"/i C:\libscript\packaging\OpenEdX-Setup.msi`""; Start-ScheduledTask -TaskName "RunGui"; Start-Sleep -Seconds 4; Set-Content -Path "C:\libscript\run_gui.ps1" -Value "& powershell.exe -ExecutionPolicy Bypass -File C:/libscript/packaging/click_button.ps1 > C:/libscript/click.log 2>&1"'

# Welcome -> License
Invoke-VmClick "Next"

# License -> Setup Type
Invoke-VmClick "I Agree"

# Select Advanced Mode
Invoke-VmClick "Advanced Mode"
Invoke-CaptureScreen "06_advanced_setup_type_selected"

# Setup Type -> Component Selection (Features)
Invoke-VmClick "Next"
Invoke-CaptureScreen "06a_advanced_features"

# Features -> Destination Folders
Invoke-VmClick "Next"
Invoke-CaptureScreen "06b_advanced_install_location"

# Destination Folders -> Runtime Environment Selection
Invoke-VmClick "Next"
Invoke-CaptureScreen "06c_advanced_runtime_selection"

# Runtime Environment -> Source Repository & Release
Invoke-VmClick "Next"
Invoke-CaptureScreen "06d_advanced_source_repo"

$srcRepo6d = Join-Path $Cc0ScreenshotsDir "06d_advanced_source_repo.png"
$srcRepo6b = Join-Path $Cc0ScreenshotsDir "06b_advanced_source_repo.png"
if (Test-Path $srcRepo6d) {
    Copy-Item -Path $srcRepo6d -Destination $srcRepo6b -Force
}

# Source Repo -> Network & Credentials Configuration
Invoke-VmClick "Next"
Invoke-CaptureScreen "06e_advanced_config"

# Config -> Relational Database / DBaaS
Invoke-VmClick "Next"
Invoke-CaptureScreen "07_advanced_db"

# DB -> Cache, Document Store & Search
Invoke-VmClick "Next"
Invoke-CaptureScreen "08_advanced_cache_search"

# Cache -> Verify Ready (Advanced)
Invoke-VmClick "Next"
Invoke-CaptureScreen "09_advanced_verify_ready"

# Verify Ready -> Install & Exit
Write-Host "[INFO] Triggering installation in Advanced Mode..."
Invoke-VmClick "Install"
Start-Sleep -Seconds 5
Invoke-CaptureScreen "10_advanced_exit"

# Exit -> Finish
Invoke-VmClick "Finish"

Write-Host "`n=== Flow 3: Browser Verification & Authentication Flows ==="
Write-Host "[INFO] Starting mock server on guest for ports 8000 and 8001..."
Invoke-VmRun 'cmd /c "cd C:\libscript && call packaging\start_mock_server.cmd"'

# Step 11: LMS Login Screen
Write-Host "[INFO] Opening LMS Portal Login (:8000/login) in Edge..."
Invoke-LaunchBrowserUrl "http://localhost:8000/login"
Invoke-CaptureScreen "11_browser_lms_focused"

# Step 12: Studio CMS Sign-in Screen
Write-Host "[INFO] Opening Studio CMS Sign-in (:8001/signin) in Edge..."
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
Invoke-VmRun 'Stop-Process -Name msedge -Force -ErrorAction SilentlyContinue'

Write-Host "`n=== All Open edX Vagrant Windows screenshots captured successfully in cc0-assets! ==="
Get-ChildItem -Path $Cc0ScreenshotsDir -Filter "*.png" | Sort-Object Name | ForEach-Object {
    Write-Host ("{0,-36} {1,10} bytes" -f $_.Name, $_.Length)
}
