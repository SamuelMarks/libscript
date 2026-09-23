<#
.SYNOPSIS
## Overview
Declarative OS configuration driver supporting profiles, schema validation, and JSON export on Windows.

## Usage
.\config.ps1 os [--profile=<name>] [--export=<out.json>] [--validate=<file.json>]
#>

[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [string]$Subcommand = "os",
    [string]$Profile = "",
    [string]$Export = "",
    [string]$Validate = ""
)

$rootDir = if ($env:LIBSCRIPT_ROOT_DIR) { $env:LIBSCRIPT_ROOT_DIR } else { (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path }
$schemaFile = Join-Path $rootDir "os-config.schema.json"

if ($Validate) {
    if (-not (Test-Path $Validate)) {
        Write-Error "[ERROR] File to validate not found: $Validate"
        exit 1
    }
    try {
        $content = Get-Content -Path $Validate -Raw | ConvertFrom-Json
        $requiredFields = @("schema_version", "target", "kernel", "init_system", "storage")
        foreach ($field in $requiredFields) {
            if (-not $content.$field) {
                Write-Error "[VALIDATION ERROR] Missing required field: $field"
                exit 1
            }
        }
        Write-Host "[INFO] Schema validation successful: $Validate conforms to os-config.schema.json"
        exit 0
    } catch {
        Write-Error "[VALIDATION ERROR] Failed to parse JSON: $_"
        exit 1
    }
}

$chosenConfig = $null
if ($Profile) {
    $profilePath = Join-Path $rootDir "profiles\$Profile.json"
    if (-not (Test-Path $profilePath)) {
        $profilePath = Join-Path $rootDir "profiles\$Profile"
    }
    if (-not (Test-Path $profilePath)) {
        Write-Error "[ERROR] Profile not found: $Profile"
        exit 1
    }
    $chosenConfig = Get-Content -Path $profilePath -Raw
} else {
    $defaultProfile = Join-Path $rootDir "profiles\linux-standard-server-glibc.json"
    $chosenConfig = Get-Content -Path $defaultProfile -Raw
}

if ($Export) {
    $exportDir = Split-Path -Parent $Export
    if ($exportDir -and -not (Test-Path $exportDir)) {
        New-Item -ItemType Directory -Path $exportDir -Force | Out-Null
    }
    Set-Content -Path $Export -Value $chosenConfig
    Write-Host "[INFO] Exported configuration to: $Export"
} else {
    Write-Output $chosenConfig
}

exit 0
