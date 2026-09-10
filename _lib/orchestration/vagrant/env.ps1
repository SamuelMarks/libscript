# ## Overview
# PowerShell env script for Vagrant.

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}
$VagrantVer = $env:VAGRANT_VERSION
if ([string]::IsNullOrEmpty($VagrantVer)) {
    $VagrantVer = "latest"
}
$BinDir = Join-Path (Join-Path (Join-Path $LibscriptHome "vagrant") $VagrantVer) "bin"
if (Test-Path $BinDir) {
    $env:PATH = "$BinDir;$env:PATH"
}
