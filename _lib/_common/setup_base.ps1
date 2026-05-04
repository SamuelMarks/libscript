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

function libscript_install_binary {
    param (
        [string]$SrcPath,
        [string]$BinName
    )
    $DestDir = if ($env:PREFIX) { $env:PREFIX } else { "$env:USERPROFILE\.local\bin" }
    if (-not (Test-Path $DestDir)) {
        New-Item -ItemType Directory -Force -Path $DestDir | Out-Null
    }

    try {
        Copy-Item -Path $SrcPath -Destination "$env:SystemRoot\$BinName" -Force -ErrorAction Stop
        log_info "$BinName installed to $env:SystemRoot"
        return
    } catch {
        Copy-Item -Path $SrcPath -Destination "$DestDir\$BinName" -Force
        log_info "$BinName installed to $DestDir"
        if (($env:PATH -split ';') -notcontains $DestDir) {
            log_warn "$DestDir is not in your PATH."
        }
    }
}
