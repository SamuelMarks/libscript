# ## Overview
# PowerShell environment configuration for Marathon.
#
# ## Usage
# . .\_lib\orchestration\marathon\env.ps1

$ErrorActionPreference = "Stop"

$HomeDir = if ($env:LIBSCRIPT_HOME) { $env:LIBSCRIPT_HOME } else { Join-Path $env:USERPROFILE ".libscript" }
$Ver = if ($env:MARATHON_VERSION) { $env:MARATHON_VERSION } else { "latest" }
$Port = if ($env:MARATHON_HTTP_PORT) { $env:MARATHON_HTTP_PORT } else { "8080" }
$CompDir = Join-Path (Join-Path $HomeDir 'marathon') $Ver

$env:MARATHON_HOME = $CompDir
$env:MARATHON_HTTP_PORT = $Port
$env:MARATHON_URL = "http://127.0.0.1:$Port"

$BinDir = Join-Path $CompDir "bin"
if (Test-Path $BinDir) {
    $env:PATH = "$BinDir;$env:PATH"
}
