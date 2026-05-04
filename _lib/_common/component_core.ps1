$ErrorActionPreference = "Stop"

# Component Core Router for PowerShell

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

$ACTION = $args[0]
$REQ_PKG = $args[1]
$VERSION = $args[2]

if (-not $ACTION -or $ACTION -match "^--help$|^-h$|^/\?$") {
    Write-Host "Usage: cli.ps1 [COMMAND] [PACKAGE_NAME] [VERSION] [OPTIONS]"
    exit 0
}

if ($ACTION -match "^--version$|^-v$") {
    Write-Host $env:LIBSCRIPT_VERSION
    exit 0
}

if (-not $REQ_PKG) {
    log_error "package_name is required for $ACTION"
    exit 1
}

# Routing
$actionMap = @{
    "install" = "setup.ps1"
    "test"    = "test.ps1"
    "remove"  = "uninstall.ps1"
    "uninstall" = "uninstall.ps1"
}

$targetScript = $actionMap[$ACTION]
if ($targetScript) {
    if (Test-Path $targetScript) {
        & .\$targetScript
    } else {
        log_error "$targetScript not found for action $ACTION"
        exit 1
    }
}
