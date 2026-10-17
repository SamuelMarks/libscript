# ## Overview
# PowerShell environment configuration for HashiCorp Nomad.
#
# ## Usage
# . .\_lib\orchestration\nomad\env.ps1

$ErrorActionPreference = "Stop"

$HomeDir = if ($env:LIBSCRIPT_HOME) { $env:LIBSCRIPT_HOME } else { Join-Path $env:USERPROFILE ".libscript" }
$Ver = if ($env:NOMAD_VERSION) { $env:NOMAD_VERSION } else { "latest" }
$Port = if ($env:NOMAD_HTTP_PORT) { $env:NOMAD_HTTP_PORT } else { "4646" }
$CompDir = Join-Path (Join-Path $HomeDir 'nomad') $Ver

$env:NOMAD_HOME = $CompDir
$env:NOMAD_HTTP_PORT = $Port
$env:NOMAD_ADDR = "http://127.0.0.1:$Port"

$BinDir = Join-Path $CompDir "bin"
if (Test-Path $BinDir) {
    $env:PATH = "$BinDir;$env:PATH"
}
