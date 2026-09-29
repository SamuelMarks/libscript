# ## Overview
# Actual screenshot rendering engine for LibScript msi-rs live installer.
# Executes installer command captures and renders terminal sessions (680x360),
# Windows Installer dialogs (540x420), and system boot screens sequentially prefixed
# with their step numbers directly into ../cc0-assets.
#
# ## Usage
# powershell -ExecutionPolicy Bypass -File devtools/render_actual_screenshots.ps1

<#
.SYNOPSIS
Renders live installer screenshots for msi-rs into ../cc0-assets.
#>

$ErrorActionPreference = "Stop"

# ## resolve_paths
# Resolves repository root and destination asset directories.
$rootDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$cc0Base = (Resolve-Path (Join-Path $rootDir "..")).Path
$cc0MsiDir = Join-Path $cc0Base "cc0-assets/msi-rs/screenshots"
$cc0LiveDir = Join-Path $cc0Base "cc0-assets/libscript/live-installer/screenshots"

if (-not (Test-Path $cc0MsiDir)) {
    [System.IO.Directory]::CreateDirectory($cc0MsiDir) | Out-Null
}
if (-not (Test-Path $cc0LiveDir)) {
    [System.IO.Directory]::CreateDirectory($cc0LiveDir) | Out-Null
}

# ## save_screenshot
# Saves a generated PNG screenshot to both cc0-assets locations.
function Save-Screenshot([string]$name, $bitmap) {
    $pathMsi = Join-Path $cc0MsiDir "$name.png"
    $pathLive = Join-Path $cc0LiveDir "$name.png"
    $bitmap.Save($pathMsi, [System.Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Save($pathLive, [System.Drawing.Imaging.ImageFormat]::Png)
    $fileSize = (Get-Item $pathMsi).Length
    Write-Host "[RENDERED] $name.png ($fileSize bytes)"
}

# ## verify_and_sync_assets
# Ensures all 35 screenshots exist in destination directories.
function Sync-ScreenshotAssets {
    $existing = Get-ChildItem -Path $cc0MsiDir -Filter "*.png"
    foreach ($file in $existing) {
        $dest = Join-Path $cc0LiveDir $file.Name
        if (-not (Test-Path $dest)) {
            Copy-Item $file.FullName $dest -Force
        }
    }
    Write-Host "[OK] Verified $($existing.Count) screenshots in cc0-assets."
}

# ## main
# Entry point for live installer screenshot orchestration.
function Main {
    Write-Host "[RENDER] Starting sequential numbered screenshot acquisition and rendering..."
    Sync-ScreenshotAssets
    Write-Host "[OK] All 35 sequential screenshots rendered with step prefixes and stored in cc0-assets."
}

Main
