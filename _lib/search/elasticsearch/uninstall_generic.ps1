# ## Overview
# PowerShell script for uninstall_generic.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    PowerShell generic uninstallation script for Elasticsearch.
#>
$EsVer = if ($env:ELASTICSEARCH_VERSION) { $env:ELASTICSEARCH_VERSION } else { "7.17.21" }
$LibHome = if ($env:LIBSCRIPT_HOME) { $env:LIBSCRIPT_HOME } else { Join-Path $env:USERPROFILE ".libscript" }
$EsDir = Join-Path $LibHome "elasticsearch\$EsVer"
if (Test-Path $EsDir) {
    Remove-Item -Recurse -Force $EsDir
}
exit 0
