#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"

if (Get-Command pkgx -ErrorAction SilentlyContinue) {
    Write-Host "[INFO] pkgx is already installed."
    exit 0
}

Write-Host "[INFO] Bootstrapping pkgx for Windows..."
Write-Host "Fetching latest release from GitHub API..."
$rel = Invoke-RestMethod "https://api.github.com/repos/pkgxdev/pkgx/releases/latest"
$asset = $rel.assets | Where-Object { $_.name -match "windows" -and $_.name -match "x86-64.tar.xz" }

if (-not $asset) {
    Write-Error "Could not find Windows asset in the latest pkgx release."
    exit 1
}

$outFile = "$env:TEMP\pkgx-windows.tar.xz"
Write-Host "Downloading $($asset.name)..."
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $outFile

$binDir = "$env:USERPROFILE\.pkgx\bin"
if (-not (Test-Path $binDir)) {
    New-Item -ItemType Directory -Force -Path $binDir | Out-Null
}

$extractDir = "$env:TEMP\pkgx_extract"
if (Test-Path $extractDir) { Remove-Item -Recurse -Force $extractDir }
New-Item -ItemType Directory -Force -Path $extractDir | Out-Null

Write-Host "Extracting..."
# Windows 10 build 17063+ includes a port of bsdtar simply named `tar`, which supports xz extraction natively.
tar -xf $outFile -C $extractDir

# Search for the extracted binary (it's usually pkgx.exe inside a pkgx-v* folder)
$exeFile = Get-ChildItem -Path $extractDir -Recurse -Filter "pkgx.exe" | Select-Object -First 1
if (-not $exeFile) {
    Write-Error "Could not find pkgx.exe in the extracted archive."
    exit 1
}

Move-Item -Path $exeFile.FullName -Destination "$binDir\pkgx.exe" -Force
Write-Host "[INFO] pkgx successfully installed to $binDir\pkgx.exe."
Write-Host "[INFO] Please ensure $binDir is added to your system PATH."
