# Windows PowerShell env stub for postgres

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:POSTGRES_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "postgres") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
