# Windows PowerShell env stub for kubernetes-k0s

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:KUBERNETES_K0S_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "kubernetes-k0s") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
