<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'psmux' stack.

.DESCRIPTION
Execute this script to install and configure psmux on the local system.
#>

$ErrorActionPreference = "Stop"

$Version = $env:PSMUX_VERSION
if ([string]::IsNullOrEmpty($Version)) {
    $Version = "v3.3.6"
}

# Check if winget is available, maybe they published it?
# We will just download from GitHub releases directly.

$InstallDir = "C:\Program Files\psmux"
$BinPath = "$InstallDir\psmux.exe"

if (Test-Path $BinPath) {
    Write-Host "psmux is already installed at $BinPath"
    exit 0
}

Write-Host "Downloading psmux $Version..."

$Arch = "x64"
if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
    $Arch = "arm64"
} elseif ($env:PROCESSOR_ARCHITECTURE -eq "x86") {
    $Arch = "x86"
}

$Url = "https://github.com/psmux/psmux/releases/download/$Version/psmux-$Version-windows-$Arch.zip"
$TempDir = [System.IO.Path]::GetTempPath()
$ZipFile = Join-Path $TempDir "psmux.zip"

Invoke-WebRequest -Uri $Url -OutFile $ZipFile -UseBasicParsing

if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

Write-Host "Extracting to $InstallDir..."
Expand-Archive -Path $ZipFile -DestinationPath $InstallDir -Force
Remove-Item $ZipFile -Force

# Add to Machine Path
$CurrentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
if ($CurrentPath -notmatch [regex]::Escape($InstallDir)) {
    [Environment]::SetEnvironmentVariable("PATH", "$CurrentPath;$InstallDir", "Machine")
    # Also add to current process so subsequent steps find it
    $env:PATH = "$env:PATH;$InstallDir"
}

Write-Host "psmux installed successfully."
