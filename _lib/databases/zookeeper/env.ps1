# ## Overview
# PowerShell environment configuration for Apache ZooKeeper.
#
# ## Usage
# . .\_lib\databases\zookeeper\env.ps1

$ErrorActionPreference = "Stop"

$HomeDir = if ($env:LIBSCRIPT_HOME) { $env:LIBSCRIPT_HOME } else { Join-Path $env:USERPROFILE ".libscript" }
$Ver = if ($env:ZOOKEEPER_VERSION) { $env:ZOOKEEPER_VERSION } else { "latest" }
$CompDir = Join-Path (Join-Path $HomeDir 'zookeeper') $Ver

$env:ZOOKEEPER_HOME = $CompDir
$env:ZOOKEEPER_DATA_DIR = Join-Path (Join-Path $HomeDir 'zookeeper') 'data'

$BinDir = Join-Path $CompDir "bin"
if (Test-Path $BinDir) {
    $env:PATH = "$BinDir;$env:PATH"
}
