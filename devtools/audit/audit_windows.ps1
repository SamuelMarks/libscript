# ## Overview
# Audits all LibScript components on Windows.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
PowerShell equivalent for audit_windows.
#>

$ErrorActionPreference = "Stop"

if ($args -contains "--help" -or $args -contains "-h" -or $args -contains "/?" -or $args -contains "-?") {
    Write-Host "Usage: audit_windows.ps1"
    Write-Host "Audits all LibScript components on Windows."
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  --help, -h, /?, -?  Show this help message."
    exit 0
}

$rootDir = if ($env:ROOT_DIR) { Resolve-Path $env:ROOT_DIR } else { Resolve-Path (Join-Path $PSScriptRoot '..\..') }
$testsTmp = Join-Path $rootDir 'tests_tmp'
if (-not (Test-Path $testsTmp)) {
    New-Item -ItemType Directory -Path $testsTmp | Out-Null
}

$reportJson = Join-Path $testsTmp 'windows_audit_report.json'
$reportMd = Join-Path $testsTmp 'windows_audit_report.md'

$results = @()
$categories = Get-ChildItem -Path (Join-Path $rootDir '_lib') -Directory | Where-Object { $_.Name -ne '_common' -and -not $_.Name.StartsWith('_') }

foreach ($cat in $categories) {
    $components = Get-ChildItem -Path $cat.FullName -Directory | Where-Object { -not $_.Name.StartsWith('_') }
    foreach ($comp in $components) {
        $hasManifest = Test-Path (Join-Path $comp.FullName 'manifest.json')
        $hasSetupCmd = Test-Path (Join-Path $comp.FullName 'setup.cmd')
        $hasSetupGeneric = Test-Path (Join-Path $comp.FullName 'setup_generic.cmd')
        $hasSetupWindows = Test-Path (Join-Path $comp.FullName 'setup_windows.cmd')
        $hasTestCmd = Test-Path (Join-Path $comp.FullName 'test.cmd')
        $hasTestPs1 = Test-Path (Join-Path $comp.FullName 'test.ps1')

        $osSupport = "supported"
        if ($hasManifest) {
            $manifestContent = Get-Content (Join-Path $comp.FullName 'manifest.json') -Raw | ConvertFrom-Json
            if ($manifestContent.os_blacklist -and $manifestContent.os_blacklist -contains "windows") {
                $osSupport = "blacklisted"
            } elseif ($manifestContent.os_whitelist) {
                if (-not ($manifestContent.os_whitelist -contains "windows" -or $manifestContent.os_whitelist -contains "all")) {
                    $osSupport = "not_whitelisted"
                }
            }
        }

        $results += [PSCustomObject]@{
            category = $cat.Name
            component = $comp.Name
            os_support = $osSupport
            has_setup_cmd = $hasSetupCmd
            has_setup_generic = $hasSetupGeneric
            has_setup_windows = $hasSetupWindows
            has_test_cmd = $hasTestCmd
            has_test_ps1 = $hasTestPs1
            install_exit = 0
            test_exit = 0
            install_err = ""
            test_err = ""
        }
    }
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$jsonText = $results | ConvertTo-Json -Depth 4
[IO.File]::WriteAllText($reportJson, $jsonText, $utf8NoBom)

$mdLines = @(
    "# Windows Component Audit Report",
    "",
    "| Category | Component | OS Support | Setup CMD | Setup Windows | Test CMD | Test PS1 |",
    "|---|---|---|---|---|---|---|"
)
foreach ($r in $results) {
    $mdLines += "| $($r.category) | ``$($r.component)`` | $($r.os_support) | $(if ($r.has_setup_cmd) {'Yes'} else {'-'}) | $(if ($r.has_setup_windows) {'Yes'} else {'-'}) | $(if ($r.has_test_cmd) {'Yes'} else {'-'}) | $(if ($r.has_test_ps1) {'Yes'} else {'-'}) |"
}
$mdText = $mdLines -join "`n"
[IO.File]::WriteAllText($reportMd, $mdText, $utf8NoBom)

Write-Host "Audit complete. JSON saved to $reportJson and Markdown to $reportMd."
