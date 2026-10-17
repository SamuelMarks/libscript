# ## Overview
# PowerShell environment configuration for Slurm Workload Manager.
#
# ## Usage
# . .\_lib\orchestration\slurm\env.ps1

$ErrorActionPreference = "Stop"

$HomeDir = if ($env:LIBSCRIPT_HOME) { $env:LIBSCRIPT_HOME } else { Join-Path $env:USERPROFILE ".libscript" }
$Ver = if ($env:SLURM_VERSION) { $env:SLURM_VERSION } else { "latest" }
$CompDir = Join-Path (Join-Path $HomeDir 'slurm') $Ver

$env:SLURM_HOME = $CompDir
$env:SLURM_STATE_DIR = Join-Path (Join-Path $HomeDir 'slurm') 'state'

$BinDir = Join-Path $CompDir "bin"
if (Test-Path $BinDir) {
    $env:PATH = "$BinDir;$env:PATH"
}
