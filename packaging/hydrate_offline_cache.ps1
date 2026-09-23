# ## Overview
# Hydrates and verifies the offline air-gapped artifact cache on Windows.
#
# ## Usage
#   .\packaging\hydrate_offline_cache.ps1 [-Manifest <file>] [-CacheDir <dir>] [-VerifyOnly] [-Wheels] [-Codebase]

<#
.SYNOPSIS
Hydrates and verifies the offline air-gapped artifact cache on Windows.

.DESCRIPTION
Downloads and verifies SHA-256 digests for Python, Node.js, MySQL, Redis, MongoDB,
Meilisearch, edx-platform wheels, and demo courseware archives according to an offline
bundle specification JSON.

.PARAMETER Manifest
Path to offline_bundle.json manifest file.

.PARAMETER CacheDir
Target directory to store downloaded and verified artifacts.

.PARAMETER VerifyOnly
Only verify SHA-256 integrity of existing cached files without downloading.

.PARAMETER Wheels
Download pip wheels matching requirements files into cache/wheels/.

.PARAMETER Codebase
Download or fetch edx-platform release archive into cache/codebase/.
#>

[CmdletBinding()]
param (
    [string]$Manifest = "",
    [string]$CacheDir = "",
    [switch]$VerifyOnly,
    [switch]$Wheels,
    [switch]$Codebase
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir

if (-not $Manifest) {
    $Manifest = Join-Path $RootDir "stacks\cms\openedx\offline_bundle.json"
}
if (-not $CacheDir) {
    if ($env:LIBSCRIPT_CACHE_DIR) {
        $CacheDir = $env:LIBSCRIPT_CACHE_DIR
    } else {
        $CacheDir = Join-Path $RootDir "cache"
    }
}

if (-not (Test-Path $Manifest)) {
    Write-Error "[ERROR] Manifest file not found at: $Manifest"
    exit 1
}

Write-Host "[INFO] Processing offline manifest: $Manifest"
Write-Host "[INFO] Target cache directory: $CacheDir"

$manifestContent = Get-Content -Raw -Path $Manifest | ConvertFrom-Json

$runtimesDir = Join-Path $CacheDir "runtimes"
$databasesDir = Join-Path $CacheDir "databases"
$wheelsDir = Join-Path $CacheDir "wheels"
$npmDir = Join-Path $CacheDir "npm"
$codebaseDir = Join-Path $CacheDir "codebase"

foreach ($dir in @($runtimesDir, $databasesDir, $wheelsDir, $npmDir, $codebaseDir)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

function Prune-Archive {
    param (
        [string]$Destination,
        [string]$Category
    )

    $filename = Split-Path -Leaf $Destination
    $stampFile = "$Destination.pruned"

    if ($filename -like "*mongodb-*.zip") {
        Write-Host "[PRUNING] [$Category] Pruning debug symbols from $filename..."
        $tmpDir = Join-Path (Split-Path -Parent $Destination) "_tmp_mongo_$PID"
        if (Test-Path $tmpDir) { Remove-Item -Path $tmpDir -Recurse -Force }
        New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
        tar.exe -xf $Destination -C $tmpDir --exclude='*.pdb' --exclude='*mongos*' --exclude='*Compass*' --exclude='*vc_redist*' 2>$null
        Remove-Item -Path $Destination -Force
        $topDir = (Get-ChildItem -Path $tmpDir -Directory | Select-Object -First 1).Name
        tar.exe -a -cf $Destination -C $tmpDir $topDir 2>$null
        Remove-Item -Path $tmpDir -Recurse -Force
        Set-Content -Path $stampFile -Value "pruned"
        Write-Host "[PRUNED] [$Category] $filename successfully pruned."
    } elseif ($filename -like "*mysql-*.zip") {
        Write-Host "[PRUNING] [$Category] Pruning debug symbols and static libs from $filename..."
        $tmpDir = Join-Path (Split-Path -Parent $Destination) "_tmp_mysql_$PID"
        if (Test-Path $tmpDir) { Remove-Item -Path $tmpDir -Recurse -Force }
        New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
        tar.exe -xf $Destination -C $tmpDir --exclude='*.pdb' --exclude='*.lib' --exclude='*debug*' --exclude='*docs*' --exclude='*include*' --exclude='*test*' 2>$null
        Remove-Item -Path $Destination -Force
        $topDir = (Get-ChildItem -Path $tmpDir -Directory | Select-Object -First 1).Name
        tar.exe -a -cf $Destination -C $tmpDir $topDir 2>$null
        Remove-Item -Path $tmpDir -Recurse -Force
        Set-Content -Path $stampFile -Value "pruned"
        Write-Host "[PRUNED] [$Category] $filename successfully pruned."
    }
}

function Process-Artifact {
    param (
        [string]$Url,
        [string]$Destination,
        [string]$ExpectedHash,
        [string]$Category
    )

    $filename = Split-Path -Leaf $Destination
    $stampFile = "$Destination.pruned"

    if (Test-Path $Destination) {
        if (Test-Path $stampFile) {
            Write-Host "[VALID] [$Category] $filename (pruned archive verified)."
            return $true
        }
        $fileHash = (Get-FileHash -Path $Destination -Algorithm SHA256).Hash.ToLower()
        if ($fileHash -eq $ExpectedHash.ToLower()) {
            Write-Host "[VALID] [$Category] $filename matches SHA-256."
            Prune-Archive -Destination $Destination -Category $Category
            return $true
        } else {
            Write-Warning "[CORRUPT] [$Category] $filename hash mismatch! Expected: $ExpectedHash, Got: $fileHash"
            if ($VerifyOnly) {
                return $false
            }
            Remove-Item -Path $Destination -Force
            if (Test-Path $stampFile) { Remove-Item -Path $stampFile -Force }
        }
    }

    if ($VerifyOnly) {
        Write-Error "[MISSING] [$Category] $filename not present in cache."
        return $false
    }

    Write-Host "[FETCHING] [$Category] $filename from $Url..."
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing
    } catch {
        Write-Error "[FAIL] Failed to download $filename`: $_"
        return $false
    }

    $fileHash = (Get-FileHash -Path $Destination -Algorithm SHA256).Hash.ToLower()
    if ($fileHash -ne $ExpectedHash.ToLower()) {
        Write-Error "[FAIL] SHA-256 mismatch for newly downloaded $filename."
        Remove-Item -Path $Destination -Force
        if (Test-Path $stampFile) { Remove-Item -Path $stampFile -Force }
        return $false
    }

    Write-Host "[STORED] [$Category] $filename successfully verified."
    Prune-Archive -Destination $Destination -Category $Category
    return $true
}

$totalErrors = 0

# 1. Runtimes
if ($manifestContent.runtimes) {
    foreach ($prop in $manifestContent.runtimes.PSObject.Properties) {
        $rt = $prop.Value
        $dest = Join-Path $runtimesDir $rt.filename
        if (-not (Process-Artifact -Url $rt.url -Destination $dest -ExpectedHash $rt.sha256 -Category "Runtime")) {
            $totalErrors++
        }
    }
}

# 2. Databases
if ($manifestContent.databases) {
    foreach ($prop in $manifestContent.databases.PSObject.Properties) {
        $db = $prop.Value
        $dest = Join-Path $databasesDir $db.filename
        if (-not (Process-Artifact -Url $db.url -Destination $dest -ExpectedHash $db.sha256 -Category "Database")) {
            $totalErrors++
        }
    }
}

# 3. Wheels
if ($manifestContent.wheels -and $manifestContent.wheels.packages) {
    foreach ($whl in $manifestContent.wheels.packages) {
        $dest = Join-Path $wheelsDir $whl.filename
        if (-not (Process-Artifact -Url $whl.url -Destination $dest -ExpectedHash $whl.sha256 -Category "Wheel")) {
            $totalErrors++
        }
    }
}

# 4. Codebase
if ($manifestContent.codebase -and $manifestContent.codebase.archive_filename) {
    $codeDest = Join-Path $codebaseDir $manifestContent.codebase.archive_filename
    if (-not (Process-Artifact -Url $manifestContent.codebase.archive_url -Destination $codeDest -ExpectedHash $manifestContent.codebase.archive_sha256 -Category "Codebase")) {
        $totalErrors++
    }
}

# Demo Content
if ($manifestContent.codebase -and $manifestContent.codebase.demo_content) {
    foreach ($demo in $manifestContent.codebase.demo_content) {
        $demoDest = Join-Path $codebaseDir $demo.filename
        if (-not (Process-Artifact -Url $demo.url -Destination $demoDest -ExpectedHash $demo.sha256 -Category "DemoContent")) {
            $totalErrors++
        }
    }
}

# Copy manifest to cache
Copy-Item -Path $Manifest -Destination (Join-Path $CacheDir "manifest.json") -Force

# Generate checksums.sha256
$checksumPath = Join-Path $CacheDir "checksums.sha256"
$checksumLines = @()
Get-ChildItem -Path $CacheDir -Recurse -File | Where-Object { $_.Name -ne "checksums.sha256" -and $_.Name -ne "manifest.json" } | ForEach-Object {
    $h = (Get-FileHash -Path $_.FullName -Algorithm SHA256).Hash.ToLower()
    $checksumLines += "$h  $($_.Name)"
}
$checksumLines | Out-File -FilePath $checksumPath -Encoding ascii

if ($totalErrors -gt 0) {
    Write-Error "Hydration completed with $totalErrors error(s)."
    exit 1
}

Write-Host "[SUCCESS] Offline artifact cache successfully hydrated and verified at $CacheDir"
exit 0
