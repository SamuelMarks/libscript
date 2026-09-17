# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    Environment script for MySQL on Windows PowerShell.
#>
if (-not $env:MYSQL_PORT) { $env:MYSQL_PORT = "3306" }
if (-not $env:MYSQL_DATABASE) { $env:MYSQL_DATABASE = "openedx" }
if (-not $env:MYSQL_USER) { $env:MYSQL_USER = "openedx" }
$MyVer = if ($env:MYSQL_VERSION) { $env:MYSQL_VERSION } else { "8.4.11" }
$LibHome = if ($env:LIBSCRIPT_HOME) { $env:LIBSCRIPT_HOME } else { Join-Path $env:USERPROFILE ".libscript" }

$MyBin = Join-Path $LibHome "mysql\$MyVer\bin"
if (Test-Path $MyBin) {
    $env:PATH = "$MyBin;$env:PATH"
}
