# ## Overview
# Generates a WiX Windows Installer (.msi) package for Open edX on Windows (PowerShell).
# Delegates to generic packaging build_msi automation with stacks/cms/openedx target.
#
# ## Usage
#   .\packaging\build_openedx_msi.ps1 [OPTIONS]

<#
.SYNOPSIS
    Builds Open edX Windows Installer (.msi) package.
.DESCRIPTION
    Compiles WiX XML source into MSI installer targeting stacks/cms/openedx.
#>

[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Options
)

$ErrorActionPreference = "Stop"
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

$LibscriptRootDir = if ($env:LIBSCRIPT_ROOT_DIR) {
    $env:LIBSCRIPT_ROOT_DIR
} else {
    (Resolve-Path (Join-Path $ScriptDir "..")).Path
}

# ## Invoke-BuildOpenedxMsi
# Dispatches arguments to build_msi batch wrapper targeting Open edX stack.
function Invoke-BuildOpenedxMsi {
    param([string[]]$BuildOptions)
    $buildMsiCmd = Join-Path $ScriptDir "build_msi.cmd"
    if (Test-Path $buildMsiCmd) {
        & cmd.exe /c "call `"$buildMsiCmd`" stacks\cms\openedx $BuildOptions"
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
    } else {
        Write-Error "build_msi.cmd not found in $ScriptDir."
        exit 1
    }
}

Invoke-BuildOpenedxMsi -BuildOptions $Options
