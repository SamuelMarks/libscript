# Windows PowerShell env stub for curl

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:CURL_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "curl") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
