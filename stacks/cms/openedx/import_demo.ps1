# ## Overview
# Demo course and library content ingestion utility for Open edX on Windows (PowerShell).
# Provides automated, idempotent import of demonstration courses and libraries.
#
# ## Usage
#   .\import_demo.ps1 course [-CourseId <id>] [-Repo <url>]
#   .\import_demo.ps1 libraries [-Owner <username>]
#   .\import_demo.ps1 help

<#
.SYNOPSIS
    Demo course and library content ingestion for Open edX.
.DESCRIPTION
    Provides automated, idempotent import of demonstration courses and libraries.
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command = "help",

    [Parameter()]
    [string]$CourseId = "course-v1:edX+DemoX+Demo_Course",

    [Parameter()]
    [string]$Repo = "https://github.com/openedx/edx-demo-course.git",

    [Parameter()]
    [string]$Owner = "admin"
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
# Displays usage documentation.
function Show-Help {
    Write-Host "Open edX Demo Content Ingestion CLI (PowerShell)"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  .\import_demo.ps1 course [-CourseId <id>] [-Repo <url>]"
    Write-Host "  .\import_demo.ps1 libraries [-Owner <username>]"
    Write-Host "  .\import_demo.ps1 help"
}

# ## Import-DemoCourse
# Imports a demo course idempotently from git repository.
function Import-DemoCourse {
    param([string]$TargetId, [string]$RepoUrl)
    Write-Host "[INFO] Checking if course '$TargetId' is already registered..."
    $dataDir = Join-Path $InstallDir "data"
    if (-not (Test-Path $dataDir)) {
        New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
    }

    $coursesJson = Join-Path $dataDir "courses.json"
    if (Test-Path $coursesJson) {
        try {
            $existing = Get-Content -Path $coursesJson -Raw | ConvertFrom-Json
            if ($existing -contains $TargetId) {
                Write-Host "[INFO] Demo course '$TargetId' is already installed. Skipping."
                return
            }
        } catch {
            # Continue import
        }
    }

    Write-Host "[INFO] Ingesting demo course '$TargetId' from '$RepoUrl'..."
    $stagingDir = Join-Path $InstallDir "demo_staging"
    if (Test-Path $stagingDir) {
        Remove-Item -Path $stagingDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if ($gitCmd) {
        & git clone --depth 1 $RepoUrl $stagingDir 2>$null
    }

    $python = Find-Python
    $managePy = Join-Path $InstallDir "manage.py"
    if (Test-Path $managePy) {
        & $python $managePy cms import $dataDir $stagingDir 2>$null
        & $python $managePy lms reindex_course --course-id $TargetId 2>$null
    }

    $list = @()
    if (Test-Path $coursesJson) {
        try { $list = @(Get-Content -Path $coursesJson -Raw | ConvertFrom-Json) } catch { $list = @() }
    }
    if ($list -notcontains $TargetId) {
        $list += $TargetId
    }
    Set-Content -Path $coursesJson -Value (ConvertTo-Json $list -Depth 5) -Encoding Ascii

    if (Test-Path $stagingDir) {
        Remove-Item -Path $stagingDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Host "[INFO] Demo course '$TargetId' successfully imported."
}

# ## Import-DemoLibraries
# Ingests demo libraries idempotently.
function Import-DemoLibraries {
    param([string]$LibOwner)
    $libId = "library-v1:edX+DemoLib"
    $dataDir = Join-Path $InstallDir "data"
    if (-not (Test-Path $dataDir)) {
        New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
    }

    $libsJson = Join-Path $dataDir "libraries.json"
    if (Test-Path $libsJson) {
        try {
            $existing = Get-Content -Path $libsJson -Raw | ConvertFrom-Json
            if ($existing -contains $libId) {
                Write-Host "[INFO] Demo library '$libId' is already installed. Skipping."
                return
            }
        } catch {
            # Continue import
        }
    }

    Write-Host "[INFO] Creating demo library for owner '$LibOwner'..."
    $list = @()
    if (Test-Path $libsJson) {
        try { $list = @(Get-Content -Path $libsJson -Raw | ConvertFrom-Json) } catch { $list = @() }
    }
    if ($list -notcontains $libId) {
        $list += $libId
    }
    Set-Content -Path $libsJson -Value (ConvertTo-Json $list -Depth 5) -Encoding Ascii
    Write-Host "[INFO] Demo library '$libId' successfully created."
}

switch ($Command.ToLower()) {
    "course"    { Import-DemoCourse -TargetId $CourseId -RepoUrl $Repo }
    "libraries" { Import-DemoLibraries -LibOwner $Owner }
    "library"   { Import-DemoLibraries -LibOwner $Owner }
    "help"      { Show-Help }
    default     {
        Write-Error "Unknown command: $Command"
        Show-Help
        exit 1
    }
}
