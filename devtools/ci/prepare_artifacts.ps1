# ## Overview
# Validates generated installer artifact packages and produces cryptographic
# SHA256 checksums (.sha256) using PowerShell.
#
# ## Usage
# .\devtools\ci\prepare_artifacts.ps1 <artifact_path> [artifact_path...]

<#
.SYNOPSIS
Validates artifact files and produces companion .sha256 checksum files.
#>

$ErrorActionPreference = "Stop"

# ## Show-Help
# Displays usage instructions and supported command-line options.
function Show-Help {
    Write-Host "Usage: prepare_artifacts.ps1 <artifact_path> [artifact_path...]"
    Write-Host "Validates artifact files and produces companion .sha256 checksum files."
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  --help, -h, /?, -?  Show this help message."
}

if ($args -contains "--help" -or $args -contains "-h" -or $args -contains "/?" -or $args -contains "-?") {
    Show-Help
    exit 0
}

if ($args.Count -lt 1) {
    Write-Error "No artifact paths specified."
    Show-Help
    exit 1
}

# ## Prepare-SingleArtifact
# Verifies target artifact file exists and produces companion .sha256 file.
function Prepare-SingleArtifact {
    param(
        [string]$ArtifactPath
    )

    if (-not (Test-Path -LiteralPath $ArtifactPath)) {
        Write-Error "Artifact not found: $ArtifactPath"
        return $false
    }

    $item = Get-Item -LiteralPath $ArtifactPath
    if ($item.Length -eq 0) {
        Write-Error "Artifact file is empty: $ArtifactPath"
        return $false
    }

    $hash = (Get-FileHash -LiteralPath $ArtifactPath -Algorithm SHA256).Hash.ToLower()
    $fileName = $item.Name
    $shaPath = "$ArtifactPath.sha256"

    "$hash  $fileName" | Out-File -FilePath $shaPath -Encoding ascii
    Write-Host "Successfully generated: $fileName ($($item.Length) bytes)"
    Write-Host "SHA256 for $($fileName): $hash"
    return $true
}

$hasErrors = $false
foreach ($arg in $args) {
    $ok = Prepare-SingleArtifact -ArtifactPath $arg
    if (-not $ok) {
        $hasErrors = $true
    }
}

if ($hasErrors) {
    exit 1
}
exit 0
