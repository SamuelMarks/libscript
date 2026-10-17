# ## Overview
# PowerShell environment configuration for k8s-marathon.
#
# ## Usage
# . .\_lib\orchestration\k8s-marathon\env.ps1

$ErrorActionPreference = "Stop"

$HomeDir = if ($env:LIBSCRIPT_HOME) { $env:LIBSCRIPT_HOME } else { Join-Path $env:USERPROFILE ".libscript" }
$Ver = if ($env:K8S_MARATHON_VERSION) { $env:K8S_MARATHON_VERSION } else { "latest" }
$Port = if ($env:K8S_MARATHON_PORT) { $env:K8S_MARATHON_PORT } else { "8081" }
$CompDir = Join-Path (Join-Path $HomeDir 'k8s-marathon') $Ver

$env:K8S_MARATHON_HOME = $CompDir
$env:K8S_MARATHON_PORT = $Port
$env:K8S_MARATHON_URL = "http://127.0.0.1:$Port"

$BinDir = Join-Path $CompDir "bin"
if (Test-Path $BinDir) {
    $env:PATH = "$BinDir;$env:PATH"
}
