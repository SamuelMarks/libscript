# ## Overview
# PowerShell environment configuration for _noop.
#
# ## Usage
# Sourced in PowerShell sessions.

$ErrorActionPreference = "Stop"

$HomeDir = if ($env:LIBSCRIPT_HOME) { $env:LIBSCRIPT_HOME } else { Join-Path $env:USERPROFILE ".libscript" }
$CompDir = Join-Path $HomeDir '_noop'

if (Test-Path $CompDir) {
    $BinDir = Join-Path $CompDir "bin"
    if (Test-Path $BinDir) {
        $env:PATH = "$BinDir;$env:PATH"
    }
}
