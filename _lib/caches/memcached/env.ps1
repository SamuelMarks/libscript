# ## Overview
# Internal script for memcached on Windows PowerShell.
#
# ## Usage
# Executes initialization, logic, or testing for memcached.

$CompVersion = $env:MEMCACHED_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$BinPath = Join-Path (Join-Path (Join-Path $LibscriptHome "memcached") $CompVersion) "bin"
if (Test-Path $BinPath) {
    $env:PATH = "$BinPath;$env:PATH"
}
