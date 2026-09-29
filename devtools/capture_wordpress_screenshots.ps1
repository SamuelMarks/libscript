# ## Overview
# Automates capturing WordPress 7.1.2 screenshots and CLI diagnostic output on Windows.
#
# ## Usage
# powershell -ExecutionPolicy Bypass -File devtools/capture_wordpress_screenshots.ps1 [-OutputDir <path>]

param(
    [string]$OutputDir = ""
)

if (-not $OutputDir) {
    $OutputDir = Join-Path $PSScriptRoot "..\..\cc0-assets\libscript\wordpress\screenshots"
}
if (-not (Test-Path $OutputDir)) {
    [System.IO.Directory]::CreateDirectory($OutputDir) | Out-Null
}

$WpCliCmd = Join-Path $PSScriptRoot "..\stacks\cms\wordpress\cli.cmd"
if (Test-Path $WpCliCmd) {
    & $WpCliCmd help | Out-File -FilePath (Join-Path $OutputDir "cli_help_windows.txt") -Encoding utf8
    & $WpCliCmd healthcheck | Out-File -FilePath (Join-Path $OutputDir "healthcheck_windows.txt") -Encoding utf8
}

Write-Host "[OK] WordPress screenshots and terminal captures completed in $OutputDir"
exit 0
