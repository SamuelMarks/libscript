# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    Environment script for Elasticsearch on Windows PowerShell.
#>
if (-not $env:ELASTICSEARCH_HTTP_PORT) { $env:ELASTICSEARCH_HTTP_PORT = "9200" }
$EsVer = if ($env:ELASTICSEARCH_VERSION) { $env:ELASTICSEARCH_VERSION } else { "7.17.21" }
$LibHome = if ($env:LIBSCRIPT_HOME) { $env:LIBSCRIPT_HOME } else { Join-Path $env:USERPROFILE ".libscript" }

$EsBin = Join-Path $LibHome "elasticsearch\$EsVer\bin"
if (Test-Path $EsBin) {
    $env:PATH = "$EsBin;$env:PATH"
}
