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
    [string]$Kernel = "",
    [string]$Board = "",
    [string]$Libc = "",
    [string]$Heap = "",
    [switch]$Mcuboot,
    [string]$Export = "",
    [string]$Validate = ""
)

$rootDir = if ($env:LIBSCRIPT_ROOT_DIR) { $env:LIBSCRIPT_ROOT_DIR } else { (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path }
$schemaFile = Join-Path $rootDir "synthesis/schemas/os-config.schema.json"

if ($Validate) {
    if (-not (Test-Path $Validate)) {
        Write-Error "[ERROR] File to validate not found: $Validate"
        exit 1
    }
    try {
        $content = Get-Content -Path $Validate -Raw | ConvertFrom-Json
        $requiredFields = if ($content.plan_version -and ($content.target.os -eq "zephyr" -or $content.target.os -eq "freertos")) {
            @("plan_version", "profile_name", "execution_mode", "target", "stages")
        } elseif ($content.reactos_version -or ($content.target -and $content.target.os_family -eq "reactos" -and -not $content.kernel)) {
            @("schema_version", "profile_name", "reactos_version", "target", "init_system", "storage")
        } elseif ($content.freebsd_version -or ($content.target -and $content.target.os_family -eq "freebsd" -and -not $content.kernel)) {
            @("schema_version", "profile_name", "freebsd_version", "target", "init_system", "storage")
        } elseif ($content.illumos_version -or ($content.target -and ($content.target.os_family -eq "illumos" -or $content.target.os_family -eq "sunos") -and -not $content.kernel)) {
            @("schema_version", "profile_name", "illumos_version", "target", "init_system", "storage")
        } else {
            @("schema_version", "target", "kernel", "init_system", "storage")
        }
        foreach ($field in $requiredFields) {
            if (-not $content.$field) {
                Write-Error "[VALIDATION ERROR] Missing required field: $field"
                exit 1
            }
        }
        Write-Host "[INFO] Schema validation successful: $Validate conforms to schema"
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
    $defaultProfile = Join-Path $rootDir "synthesis\profiles\linux\linux-standard-server-glibc.json"
    $chosenConfig = Get-Content -Path $defaultProfile -Raw
}

if ($Kernel -or $Board -or $Libc -or $Heap -or $Mcuboot) {
    $obj = $chosenConfig | ConvertFrom-Json
    if ($Kernel) { $obj.target.os_family = $Kernel }
    if ($Libc) { $obj.target.libc = $Libc }
    if (-not $obj.PSObject.Properties["rtos"]) {
        $obj | Add-Member -NotePropertyName "rtos" -NotePropertyValue ([PSCustomObject]@{})
    }
    if ($Board) { $obj.rtos | Add-Member -NotePropertyName "board" -NotePropertyValue $Board -Force }
    if ($Heap) { $obj.rtos | Add-Member -NotePropertyName "heap_implementation" -NotePropertyValue $Heap -Force }
    if ($Mcuboot) { $obj.rtos | Add-Member -NotePropertyName "mcuboot" -NotePropertyValue ([PSCustomObject]@{ enabled = $true }) -Force }
    $chosenConfig = $obj | ConvertTo-Json -Depth 10
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
