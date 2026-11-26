# ## Overview
# PowerShell CLI entrypoint for memcached.
#
# ## Usage
# Execute via PowerShell: .\cli.ps1 <action> [args...]

$env:PACKAGE_NAME = "memcached"
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$rootDir = if ($env:LIBSCRIPT_ROOT_DIR -and (Test-Path $env:LIBSCRIPT_ROOT_DIR)) {
    (Resolve-Path $env:LIBSCRIPT_ROOT_DIR).Path
} else {
    $d = $scriptDir
    while ($d -and -not (Test-Path (Join-Path $d "libscript.cmd")) -and -not (Test-Path (Join-Path $d "ROOT"))) {
        $p = Split-Path -Parent $d
        if ($p -eq $d) { break }
        $d = $p
    }
    $d
}
$CoreScript = Join-Path $rootDir "engine\common\component_core.ps1"
if (Test-Path $CoreScript) {
    & $CoreScript @args
} else {
    & (Join-Path $scriptDir "cli.cmd") @args
    exit $LASTEXITCODE
}
