# ## Overview
# Performs a system-wide installation of MongoDB, Memcached, and HTTPD.
#
# ## Usage
# .\system_install.ps1

$ErrorActionPreference = "Continue"
$LibscriptRoot = if ($env:LIBSCRIPT_ROOT_DIR -and (Test-Path (Join-Path $env:LIBSCRIPT_ROOT_DIR "libscript.cmd"))) {
    $env:LIBSCRIPT_ROOT_DIR
} elseif (Test-Path "C:\libscript\libscript.cmd") {
    "C:\libscript"
} else {
    (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}
$LibscriptCmd = Join-Path $LibscriptRoot "libscript.cmd"
$env:LIBSCRIPT_DEFAULT_INSTALL_METHOD="system"
& $LibscriptCmd install mongodb
& $LibscriptCmd install memcached
& $LibscriptCmd install httpd
