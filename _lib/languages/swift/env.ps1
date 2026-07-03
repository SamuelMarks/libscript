<#
.SYNOPSIS
Defines environment variables and configurations for the environment variables stack.

.DESCRIPTION
Source or call this script to configure the environment for swift.
#>

$SwiftVersion = $env:SWIFT_VERSION
if ([string]::IsNullOrEmpty($SwiftVersion)) {
    $SwiftVersion = "5.10"
}
if ($SwiftVersion -eq "latest") {
    $SwiftVersion = "5.10"
}

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$SwiftDir = Join-Path $LibscriptHome "swift" $SwiftVersion
$env:PATH = (Join-Path $SwiftDir "usr\bin") + [IO.Path]::PathSeparator + $env:PATH
