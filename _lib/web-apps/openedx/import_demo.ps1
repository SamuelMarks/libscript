# ## Overview
# Demo course and library content ingestion utility for Open edX on Windows (PowerShell).
# Provides automated, idempotent import of demonstration courses and content libraries.
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
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..\..\..")).Path

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
# Imports a demo course idempotently from offline cache archive or git repository.
function Import-DemoCourse {
    param([string]$TargetId, [string]$RepoUrl)
    Write-Host "[INFO] Checking if course '$TargetId' is already registered..."
    $dataDir = if ($env:OPENEDX_DATA_DIR) { $env:OPENEDX_DATA_DIR } else { Join-Path $InstallDir "data" }
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

    Write-Host "[INFO] Ingesting demo course '$TargetId'..."
    $stagingDir = Join-Path $InstallDir "demo_staging"
    if (Test-Path $stagingDir) {
        Remove-Item -Path $stagingDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null

    $cacheDir = if ($env:LIBSCRIPT_CACHE_DIR) { $env:LIBSCRIPT_CACHE_DIR } else { Join-Path $RepoRoot "cache" }
    $cachedDemo1 = Join-Path $cacheDir "codebase\openedx-demo-course.tar.gz"
    $cachedDemo2 = Join-Path $cacheDir "codebase\demo-course.tar.gz"
    $extracted = $false

    foreach ($cand in @($cachedDemo1, $cachedDemo2)) {
        if (Test-Path $cand) {
            Write-Host "[INFO] Extracting offline cached demo course from $cand..."
            & tar.exe -xf $cand -C $stagingDir --strip-components=1 2>$null
            if ($LASTEXITCODE -eq 0 -and (Test-Path (Join-Path $stagingDir "course.xml"))) {
                $extracted = $true
                break
            }
            & tar.exe -xf $cand -C $stagingDir 2>$null
            $subDir = Get-ChildItem -Path $stagingDir -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($subDir -and (Test-Path (Join-Path $subDir.FullName "course.xml"))) {
                $stagingDir = $subDir.FullName
                $extracted = $true
                break
            }
        }
    }

    if (-not $extracted) {
        $gitCmd = Get-Command git -ErrorAction SilentlyContinue
        if ($gitCmd -and $env:LIBSCRIPT_OFFLINE -ne "1") {
            Remove-Item -Path $stagingDir -Recurse -Force -ErrorAction SilentlyContinue
            & git clone --depth 1 $RepoUrl $stagingDir 2>$null
        }
    }

    $python = Find-Python
    $codebaseDir = if (Test-Path (Join-Path $InstallDir "codebase\manage.py")) { Join-Path $InstallDir "codebase" } else { $InstallDir }
    $managePy = Join-Path $codebaseDir "manage.py"
    if (Test-Path $managePy) {
        Push-Location $codebaseDir
        try {
            $env:LMS_CFG = Join-Path $InstallDir 'config\lms.yml'
            $env:CMS_CFG = Join-Path $InstallDir 'config\cms.yml'
            $env:REVISION_CFG = Join-Path $InstallDir 'config\revisions.yml'
            & $python $managePy cms import $dataDir $stagingDir --settings=production 2>$null
            & $python $managePy lms reindex_course --course-id $TargetId --settings=production 2>$null
        } finally {
            Pop-Location
        }
    }

    $list = @()
    if (Test-Path $coursesJson) {
        try { $list = @(Get-Content -Path $coursesJson -Raw | ConvertFrom-Json) } catch { $list = @() }
    }
    if ($list -notcontains $TargetId) {
        $list += $TargetId
    }
    Set-Content -Path $coursesJson -Value (ConvertTo-Json $list -Depth 5) -Encoding Ascii

    $stagingRoot = Join-Path $InstallDir "demo_staging"
    if (Test-Path $stagingRoot) {
        Remove-Item -Path $stagingRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Host "[INFO] Demo course '$TargetId' successfully imported."
}

# ## Import-DemoLibraries
# Ingests demo content libraries idempotently into Open edX Modulestore and catalog metadata.
function Import-DemoLibraries {
    param([string]$LibOwner)
    $libId = "library-v1:edX+DemoLib"
    $dataDir = if ($env:OPENEDX_DATA_DIR) { $env:OPENEDX_DATA_DIR } else { Join-Path $InstallDir "data" }
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

    Write-Host "[INFO] Creating demo content library '$libId' for owner '$LibOwner'..."
    $python = Find-Python
    $codebaseDir = if (Test-Path (Join-Path $InstallDir "codebase\manage.py")) { Join-Path $InstallDir "codebase" } else { $InstallDir }
    $managePy = Join-Path $codebaseDir "manage.py"
    if (Test-Path $managePy) {
        Push-Location $codebaseDir
        try {
            $env:LMS_CFG = Join-Path $InstallDir 'config\lms.yml'
            $env:CMS_CFG = Join-Path $InstallDir 'config\cms.yml'
            $env:REVISION_CFG = Join-Path $InstallDir 'config\revisions.yml'
            $pyScript = @"
import os
try:
    from xmodule.modulestore.django import modulestore
    from opaque_keys.edx.locator import LibraryLocator
    from django.contrib.auth import get_user_model
    User = get_user_model()
    user = User.objects.filter(username='$LibOwner').first() or User.objects.filter(is_superuser=True).first()
    uid = user.id if user else 1
    store = modulestore()
    loc = LibraryLocator(org='edX', library='DemoLib')
    if not store.has_item(loc):
        store.create_library('edX', 'DemoLib', uid, runtime_options={'display_name': 'edX Demonstration Content Library'})
except Exception:
    pass
"@
            & $python $managePy cms shell --settings=production -c $pyScript 2>$null
        } finally {
            Pop-Location
        }
    }

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
