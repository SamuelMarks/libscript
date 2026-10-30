# ## Overview
# PowerShell host orchestrator for Open edX Vagrant Windows 11 screenshot capture.
# Delegates to POSIX sh (`devtools/capture_openedx_vagrant_screenshots.sh`) via Git for Windows / MSYS2 sh
# or `devtools/capture_openedx_screenshots.ps1` on Windows hosts.
#
# ## Usage
# powershell -NoProfile -ExecutionPolicy Bypass -File devtools/capture_openedx_vagrant_screenshots.ps1 [args...]

$ErrorActionPreference = "Stop"
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$ShScript = Join-Path $ScriptDir "capture_openedx_vagrant_screenshots.sh"

$shCandidates = @(
    "C:\Program Files\Git\bin\sh.exe",
    "C:\Program Files\Git\usr\bin\sh.exe",
    "/bin/sh"
)

foreach ($shExe in $shCandidates) {
    if (Test-Path $shExe) {
        & $shExe $ShScript @args
        exit $LASTEXITCODE
    }
}

$shCmd = Get-Command sh -ErrorAction SilentlyContinue
if ($shCmd) {
    & $shCmd.Source $ShScript @args
    exit $LASTEXITCODE
}

$fallbackPs1 = Join-Path $ScriptDir "capture_openedx_screenshots.ps1"
if (Test-Path $fallbackPs1) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $fallbackPs1 @args
    exit $LASTEXITCODE
}

Write-Error "[ERROR] POSIX sh interpreter not found to execute $ShScript."
exit 1
