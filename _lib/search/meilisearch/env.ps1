# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    Environment script for Meilisearch on Windows PowerShell.
#>
if (-not $env:MEILISEARCH_PORT) { $env:MEILISEARCH_PORT = "7700" }
$MeiliVer = if ($env:MEILISEARCH_VERSION) { $env:MEILISEARCH_VERSION } else { "v1.36.0" }
$LibHome = if ($env:LIBSCRIPT_HOME) { $env:LIBSCRIPT_HOME } else { Join-Path $env:USERPROFILE ".libscript" }

$MeiliBin = Join-Path $LibHome "meilisearch\$MeiliVer\bin"
if (Test-Path $MeiliBin) {
    $env:PATH = "$MeiliBin;$env:PATH"
}
