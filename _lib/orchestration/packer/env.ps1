# ## Overview
#
# ## Usage
# Execute via PowerShell.
# PowerShell env script for Packer.

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}
$PackerVer = $env:PACKER_VERSION
if ([string]::IsNullOrEmpty($PackerVer)) {
    $PackerVer = "latest"
}
$BinDir = Join-Path (Join-Path (Join-Path $LibscriptHome "packer") $PackerVer) "bin"
if (Test-Path $BinDir) {
    $env:PATH = "$BinDir;$env:PATH"
}
