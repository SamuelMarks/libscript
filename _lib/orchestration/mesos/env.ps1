# ## Overview
# PowerShell environment configuration for Apache Mesos.
#
# ## Usage
# . .\_lib\orchestration\mesos\env.ps1

$ErrorActionPreference = "Stop"

$HomeDir = if ($env:LIBSCRIPT_HOME) { $env:LIBSCRIPT_HOME } else { Join-Path $env:USERPROFILE ".libscript" }
$Ver = if ($env:MESOS_VERSION) { $env:MESOS_VERSION } else { "latest" }
$CompDir = Join-Path (Join-Path $HomeDir 'mesos') $Ver

$env:MESOS_HOME = $CompDir
$env:MESOS_WORK_DIR = Join-Path (Join-Path $HomeDir 'mesos') 'work'
$env:MESOS_MASTER = "127.0.0.1:5050"

$BinDir = Join-Path $CompDir "bin"
if (Test-Path $BinDir) {
    $env:PATH = "$BinDir;$env:PATH"
}
