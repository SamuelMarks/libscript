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

# Basic uninstallation base template for parity
log_info "Sourced PowerShell uninstall base."
