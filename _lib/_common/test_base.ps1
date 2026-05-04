$ErrorActionPreference = "Stop"

if (-not (Test-Path Variable:global:LIBSCRIPT_ROOT_DIR)) {
    $currentDir = $PSScriptRoot
    while (-not (Test-Path "$currentDir\ROOT")) {
        $currentDir = Split-Path $currentDir -Parent
        if (-not $currentDir) {
            Write-Error "Could not find LIBSCRIPT_ROOT_DIR"
            exit 1
        }
    }
    $global:LIBSCRIPT_ROOT_DIR = $currentDir
}

. "$global:LIBSCRIPT_ROOT_DIR\_lib\_common\log.ps1"
. "$global:LIBSCRIPT_ROOT_DIR\_lib\_common\pkg_mgr.ps1"

$global:LIBSCRIPT_BUILD_DIR = if ($env:LIBSCRIPT_BUILD_DIR) { $env:LIBSCRIPT_BUILD_DIR } else { "$env:TEMP\libscript_build" }
$global:LIBSCRIPT_DATA_DIR = if ($env:LIBSCRIPT_DATA_DIR) { $env:LIBSCRIPT_DATA_DIR } else { "$env:TEMP\libscript_data" }

$env:PATH = "$global:LIBSCRIPT_DATA_DIR\bin;$env:PATH"

if (-not (Test-Path $global:LIBSCRIPT_BUILD_DIR)) { New-Item -ItemType Directory -Force -Path $global:LIBSCRIPT_BUILD_DIR | Out-Null }
if (-not (Test-Path $global:LIBSCRIPT_DATA_DIR)) { New-Item -ItemType Directory -Force -Path $global:LIBSCRIPT_DATA_DIR | Out-Null }

function assert_version {
    param([string]$CmdName, [string]$Expected)
    if (-not (Get-Command $CmdName -ErrorAction SilentlyContinue)) {
        Write-Error "[FAIL] $CmdName command not found"
        exit 1
    }
    $version = & $CmdName --version 2>&1 | Select-Object -First 1
    if ($version -match $Expected) {
        Write-Host "[PASS] $CmdName version check: $version"
    } else {
        Write-Error "[FAIL] $CmdName version check failed. Expected: $Expected, Got: $version"
        exit 1
    }
}

function assert_exists {
    param([string]$FilePath)
    if (Test-Path $FilePath) {
        Write-Host "[PASS] Exists: $FilePath"
    } else {
        Write-Error "[FAIL] MISSING: $FilePath"
        exit 1
    }
}
