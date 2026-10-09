# ## Overview
# XBlock and stack plugin management utility for Open edX on Windows (PowerShell).
# Installs, uninstalls, and enumerates XBlocks and Python extension plugins.
#
# ## Usage
#   .\xblock.ps1 install <package_spec_or_git_url>
#   .\xblock.ps1 uninstall <package_name>
#   .\xblock.ps1 list
#   .\xblock.ps1 help

<#
.SYNOPSIS
    XBlock and plugin management CLI for Open edX.
.DESCRIPTION
    Installs, uninstalls, and lists XBlocks and plugins for Open edX.
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command = "help",

    [Parameter(Position = 1)]
    [string]$Package
)

$ErrorActionPreference = "Stop"
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

$InstallDir = if ($env:OPENEDX_INSTALL_DIR) {
    $env:OPENEDX_INSTALL_DIR
} elseif ($env:LIBSCRIPT_HOME) {
    Join-Path $env:LIBSCRIPT_HOME "openedx"
} else {
    Join-Path $env:USERPROFILE ".libscript\openedx"
}

$DataDir = Join-Path $InstallDir "data"
$XblockRegistry = Join-Path $DataDir "xblocks.json"
if (-not (Test-Path $DataDir)) {
    New-Item -ItemType Directory -Path $DataDir -Force | Out-Null
}

# ## Find-Python
# Discovers Python interpreter in virtual environment or PATH.
function Find-Python {
    $venvPy = Join-Path $InstallDir ".venv\Scripts\python.exe"
    if (Test-Path $venvPy) {
        return $venvPy
    }
    $pyCmd = Get-Command python -ErrorAction SilentlyContinue
    if ($pyCmd) {
        return "python"
    }
    throw "Python interpreter not found in virtualenv or PATH."
}

# ## Show-Help
# Displays XBlock CLI command usage.
function Show-Help {
    Write-Host "Open edX XBlock & Plugin Management CLI (PowerShell)"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  .\xblock.ps1 install <package_spec_or_git_url>"
    Write-Host "  .\xblock.ps1 uninstall <package_name>"
    Write-Host "  .\xblock.ps1 list"
    Write-Host "  .\xblock.ps1 help"
}

# ## Get-Registry
# Returns list of registered XBlock packages.
function Get-Registry {
    if (Test-Path $XblockRegistry) {
        try {
            return @(Get-Content -Path $XblockRegistry -Raw | ConvertFrom-Json)
        } catch {
            return @()
        }
    }
    return @()
}

# ## Save-Registry
# Writes list of registered XBlock packages to disk.
function Save-Registry {
    param([string[]]$List)
    $jsonStr = ConvertTo-Json $List -Depth 5
    Set-Content -Path $XblockRegistry -Value $jsonStr -Encoding Ascii
}

# ## Install-XBlock
# Installs a python package and runs static migrations.
function Install-XBlock {
    param([string]$Pkg)
    if ([string]::IsNullOrEmpty($Pkg)) {
        Write-Error "Package specification required."
        exit 1
    }
    Write-Host "[INFO] Installing XBlock '$Pkg'..."
    $python = Find-Python
    & $python -m pip install $Pkg 2>$null | Out-Null

    $managePy = Join-Path $InstallDir "manage.py"
    if (Test-Path $managePy) {
        & $python $managePy lms migrate --noinput 2>$null | Out-Null
        & $python $managePy cms migrate --noinput 2>$null | Out-Null
        & $python $managePy lms collectstatic --noinput 2>$null | Out-Null
    }

    $list = Get-Registry
    if ($list -notcontains $Pkg) {
        $list += $Pkg
        Save-Registry $list
    }
    Write-Host "[INFO] XBlock '$Pkg' installed."
}

# ## Uninstall-XBlock
# Uninstalls a python package and removes from registry.
function Uninstall-XBlock {
    param([string]$Pkg)
    if ([string]::IsNullOrEmpty($Pkg)) {
        Write-Error "Package name required."
        exit 1
    }
    Write-Host "[INFO] Uninstalling XBlock '$Pkg'..."
    $python = Find-Python
    & $python -m pip uninstall -y $Pkg 2>$null | Out-Null

    $list = @(Get-Registry | Where-Object { $_ -ne $Pkg })
    Save-Registry $list
    Write-Host "[INFO] XBlock '$Pkg' uninstalled."
}

# ## List-XBlocks
# Lists discovered and registered XBlocks.
function List-XBlocks {
    Write-Host "=========================================================================="
    Write-Host ("{0,-32} {1,-40}" -f "XBLOCK IDENTIFIER", "ENTRY POINT / PACKAGE")
    Write-Host ("-" * 74)
    $list = Get-Registry
    if ($list.Length -gt 0) {
        foreach ($item in $list) {
            Write-Host ("{0,-32} {1,-40}" -f $item, "(registered)")
        }
    } else {
        Write-Host "(No XBlocks currently discovered)"
    }
    Write-Host "=========================================================================="
}

switch ($Command.ToLower()) {
    "install"   { Install-XBlock -Pkg $Package }
    "uninstall" { Uninstall-XBlock -Pkg $Package }
    "remove"    { Uninstall-XBlock -Pkg $Package }
    "list"      { List-XBlocks }
    "help"      { Show-Help }
    default     {
        Write-Error "Unknown xblock command: $Command"
        Show-Help
        exit 1
    }
}
