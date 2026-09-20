# ## Overview
# Publishes built release packages, installer artifacts, and cryptographic
# SHA256 checksums to GitHub Releases using PowerShell.
#
# ## Usage
# .\devtools\ci\publish_release.ps1 -Tag <tag> [-DistDir <dir>] [-Title <title>] [-Draft] [-Prerelease]

<#
.SYNOPSIS
Publishes release packages and installer artifacts to GitHub Releases.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Tag,

    [Parameter(Mandatory = $false)]
    [string]$DistDir = "dist",

    [Parameter(Mandatory = $false)]
    [string]$Title,

    [Parameter(Mandatory = $false)]
    [switch]$Draft,

    [Parameter(Mandatory = $false)]
    [switch]$Prerelease
)

$ErrorActionPreference = "Stop"

# ## Show-Help
# Displays usage instructions and supported CLI parameters.
function Show-Help {
    Write-Host "Usage: publish_release.ps1 -Tag <tag> [-DistDir <dir>] [-Title <title>] [-Draft] [-Prerelease]"
    Write-Host "Publishes installer artifacts and checksums to GitHub Releases."
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Tag <tag>         Release tag name (required, e.g. v1.0.0)."
    Write-Host "  -DistDir <dir>     Directory containing built release assets (default: dist)."
    Write-Host "  -Title <title>     Release title (default: matches tag name)."
    Write-Host "  -Draft             Publish release as a draft."
    Write-Host "  -Prerelease        Publish release as a pre-release."
    Write-Host "  -Help, --help, -h  Show this help message."
}

if ($args -contains "--help" -or $args -contains "-h" -or $args -contains "/?" -or $args -contains "-?") {
    Show-Help
    exit 0
}

if (-not $Tag) {
    # Check positional args
    if ($args.Count -gt 0 -and -not $args[0].StartsWith("-")) {
        $Tag = $args[0]
    } else {
        Write-Error "Missing required parameter: -Tag <tag>"
        Show-Help
        exit 1
    }
}

if (-not $Title) {
    $Title = $Tag
}

if (-not (Test-Path -LiteralPath $DistDir)) {
    Write-Error "Distribution directory not found: $DistDir"
    exit 1
}

# ## Generate-Sums
# Consolidates SHA256 checksums into SHA256SUMS.txt.
function Generate-Sums {
    param([string]$TargetDirectory)

    $files = Get-ChildItem -LiteralPath $TargetDirectory -File | Where-Object { $_.Name -ne "SHA256SUMS.txt" }
    $lines = @()
    foreach ($f in $files) {
        $h = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash.ToLower()
        $lines += "$h  $($f.Name)"
    }
    if ($lines.Count -gt 0) {
        $dest = Join-Path $TargetDirectory "SHA256SUMS.txt"
        [System.IO.File]::WriteAllLines($dest, $lines, [System.Text.Encoding]::ASCII)
    }
}

Generate-Sums -TargetDirectory $DistDir

Write-Host "[INFO] Publishing release assets for tag '$Tag' from '$DistDir'..."

$ghInstalled = (Get-Command gh -ErrorAction SilentlyContinue)
if (-not $ghInstalled) {
    Write-Error "GitHub CLI (gh) is not installed or not available in PATH."
    exit 1
}

$releaseExists = $false
try {
    & gh release view $Tag 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $releaseExists = $true
    }
} catch {
    $releaseExists = $false
}

$assetFiles = Get-ChildItem -LiteralPath $DistDir -File | ForEach-Object { $_.FullName }

if ($releaseExists) {
    Write-Host "[INFO] Release '$Tag' already exists. Uploading assets with clobber..."
    & gh release upload $Tag @assetFiles --clobber
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} else {
    Write-Host "[INFO] Creating new release '$Tag'..."
    $cmdArgs = @("release", "create", $Tag, "--title", $Title, "--generate-notes")
    if ($Draft) { $cmdArgs += "--draft" }
    if ($Prerelease) { $cmdArgs += "--prerelease" }
    $cmdArgs += $assetFiles

    & gh @cmdArgs
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host "[SUCCESS] Release assets successfully published for $Tag"
exit 0
