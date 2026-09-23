<#
.SYNOPSIS
## Overview
Codifies the standard context contract variables and idempotency stamp
protocols passed between Tier 2 synthesizers and Tier 1 leaf recipes.

## Usage
.\context.ps1
#>

[CmdletBinding()]
param()

$rootDir = if ($env:LIBSCRIPT_ROOT_DIR) { $env:LIBSCRIPT_ROOT_DIR } else { (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path }
$buildDir = if ($env:LIBSCRIPT_BUILD_DIR) { $env:LIBSCRIPT_BUILD_DIR } else { Join-Path $env:TEMP "libscript_build" }
$sysrootDir = if ($env:LIBSCRIPT_TARGET_SYSROOT) { $env:LIBSCRIPT_TARGET_SYSROOT } else { Join-Path $buildDir "sysroot" }
$hostRoot = if ($env:LIBSCRIPT_HOST_ROOT) { $env:LIBSCRIPT_HOST_ROOT } else { "/tools" }
$stage = if ($env:LIBSCRIPT_STAGE) { $env:LIBSCRIPT_STAGE } else { "stage0" }
$targetArch = if ($env:LIBSCRIPT_TARGET_ARCH) { $env:LIBSCRIPT_TARGET_ARCH } else { "x86_64" }
$targetLibc = if ($env:LIBSCRIPT_TARGET_LIBC) { $env:LIBSCRIPT_TARGET_LIBC } else { "glibc" }
$targetOs = if ($env:LIBSCRIPT_TARGET_OS) { $env:LIBSCRIPT_TARGET_OS } else { "linux" }
$offline = if ($env:LIBSCRIPT_OFFLINE) { $env:LIBSCRIPT_OFFLINE } else { "0" }
$cacheDir = if ($env:LIBSCRIPT_CACHE_DIR) { $env:LIBSCRIPT_CACHE_DIR } else { Join-Path $rootDir "cache" }

$env:LIBSCRIPT_ROOT_DIR = $rootDir
$env:LIBSCRIPT_BUILD_DIR = $buildDir
$env:LIBSCRIPT_TARGET_SYSROOT = $sysrootDir
$env:LIBSCRIPT_HOST_ROOT = $hostRoot
$env:LIBSCRIPT_STAGE = $stage
$env:LIBSCRIPT_TARGET_ARCH = $targetArch
$env:LIBSCRIPT_TARGET_LIBC = $targetLibc
$env:LIBSCRIPT_TARGET_OS = $targetOs
$env:LIBSCRIPT_OFFLINE = $offline
$env:LIBSCRIPT_CACHE_DIR = $cacheDir

$stampDir = Join-Path $sysrootDir "var\lib\libscript\stamps"
$env:LIBSCRIPT_STAMP_DIR = $stampDir
if (-not (Test-Path $stampDir)) {
    New-Item -ItemType Directory -Path $stampDir -Force | Out-Null
}

exit 0
