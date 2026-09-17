# ## Overview
# PowerShell script for setup_generic.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    PowerShell generic setup script for Meilisearch on Windows.
#>
$Action = if ($env:ACTION) { $env:ACTION } else { "install" }
$Version = if ($env:MEILISEARCH_VERSION) { $env:MEILISEARCH_VERSION } else { "v1.36.0" }
$LibHome = if ($env:LIBSCRIPT_HOME) { $env:LIBSCRIPT_HOME } else { Join-Path $env:USERPROFILE ".libscript" }

if ($Action -eq "install") {
    if (Get-Command "meilisearch" -ErrorAction SilentlyContinue) {
        Write-Host "Meilisearch is already installed on the system."
        exit 0
    }
    $TargetDir = Join-Path $LibHome "meilisearch\$Version\bin"
    $TargetExe = Join-Path $TargetDir "meilisearch.exe"
    if (Test-Path $TargetExe) {
        Write-Host "Meilisearch $Version is already installed in $TargetDir."
        exit 0
    }
    New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
    $Url = "https://github.com/meilisearch/meilisearch/releases/download/$Version/meilisearch-windows-amd64.exe"
    Write-Host "Downloading Meilisearch from $Url..."
    Invoke-WebRequest -Uri $Url -OutFile $TargetExe
    exit 0
} elseif ($Action -eq "uninstall") {
    $TargetDir = Join-Path $LibHome "meilisearch\$Version"
    if (Test-Path $TargetDir) {
        Remove-Item -Recurse -Force $TargetDir
    }
    exit 0
} elseif ($Action -eq "test") {
    & meilisearch --version
    exit $LASTEXITCODE
}
