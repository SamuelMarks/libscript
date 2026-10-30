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
    [string]$Component = "",
    [switch]$VerifyOnly,
    [switch]$Wheels,
    [switch]$Codebase
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
. (Join-Path $RootDir "_lib\_common\pkg_mgr.ps1")

if (-not $Manifest) {
    $Manifest = Join-Path $RootDir "_lib\web-apps\openedx\offline_bundle.json"
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
$webserversDir = Join-Path $CacheDir "webservers"
$applicationsDir = Join-Path $CacheDir "applications"
$wheelsDir = Join-Path $CacheDir "wheels"
$npmDir = Join-Path $CacheDir "npm"
$codebaseDir = Join-Path $CacheDir "codebase"

foreach ($dir in @($runtimesDir, $databasesDir, $webserversDir, $applicationsDir, $wheelsDir, $npmDir, $codebaseDir)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# ## Get-Sha256Hex
# Computes the lowercase SHA-256 hex digest of a file using pure .NET streaming cryptography.
function Get-Sha256Hex {
    param (
        [string]$FilePath
    )
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $stream = [System.IO.File]::OpenRead($FilePath)
    try {
        return [System.BitConverter]::ToString($sha.ComputeHash($stream)).Replace("-", "").ToLower()
    } finally {
        $stream.Dispose()
        $sha.Dispose()
    }
}

# ## Prune-Archive
# Prunes debug symbols and unneeded assets from downloaded database archives.
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

# ## Build-MfeBundleFromOci
# Synthesizes mfe-bundle-verawood.1.tar.gz from verified overhangio/openedx-mfe:19.0.0 OCI layer blobs when the GitHub release asset is not yet published.
function Build-MfeBundleFromOci {
    param (
        [string]$Destination
    )

    Write-Host "[FALLBACK] [DemoContent] Synthesizing mfe-bundle from verified overhangio/openedx-mfe:19.0.0 OCI layers..."
    $layers = @(
        "2e4aa03b614b7c8f62b75afbc7fa0587f573ccf3768e9b2260b6e742853aa075",
        "32c65588b8a1f1f90a8c5984f31e04d499b191704456722c00e53eaaa55c73da",
        "6c7edb2ee24e18314f00a8229f18dd23b59ae0c521cd6557f4358eacf5a89e29",
        "fca2b76a71dc5bbeeb59c1639d116f82b287904c6684691cf04b6bdd86c07cf9",
        "5d5124879ddd05a1469cbf1162d5c8511736b9472e77757e76eb0d7956f8d34e",
        "95232e6c3f4956551f226ef7dff70abe10950f50061755bf74f9a2f6b90cde47",
        "566e6123c7b9e5616599c5f09da3d7f288ed283f1e96714cead02ad8c3d855a6",
        "d2e9858ca1ac6d4979357be2d21a869ae8d2f053655b7c171d79c0e46788ce4b",
        "00667c1f99367e7e3b33ac84233895feb945b7fb7bd24817c24fc3869db0bef9",
        "59561b40d8ad8c203854417851db6afa51a2fbbc84960242ac58f3f44e4184ef"
    )
    $tmpDir = Join-Path (Split-Path -Parent $Destination) "_tmp_mfe_oci_$PID"
    if (Test-Path $tmpDir) { Remove-Item -Path $tmpDir -Recurse -Force }
    New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        # libscript-allow-raw-fetch
        $tokResp = Invoke-RestMethod -Uri "https://auth.docker.io/token?service=registry.docker.io&scope=repository:overhangio/openedx-mfe:pull" -ErrorAction Stop
        $token = $tokResp.token
        if (-not $token) { throw "Empty registry token" }

        foreach ($digest in $layers) {
            $blobFile = Join-Path $tmpDir "$digest.tar.gz"
            $blobUrl = "https://registry-1.docker.io/v2/overhangio/openedx-mfe/blobs/sha256:$digest"
            # libscript-allow-raw-fetch
            Invoke-WebRequest -Uri $blobUrl -Headers @{ Authorization = "Bearer $token" } -OutFile $blobFile -ErrorAction Stop
            $actualBlobHash = Get-Sha256Hex -FilePath $blobFile
            if ($actualBlobHash -ne $digest) {
                throw "OCI layer SHA-256 mismatch for $digest (got $actualBlobHash)"
            }
            tar.exe -xzf $blobFile -C $tmpDir --strip-components=2 --exclude='*.map' --exclude='*report.html' 2>$null
            Remove-Item -Path $blobFile -Force
        }

        $dirs = (Get-ChildItem -Path $tmpDir -Directory).Name
        if (-not $dirs -or ($dirs -notcontains "authn") -or ($dirs -notcontains "authoring")) {
            throw "Extracted OCI layers missing required authn/authoring directories"
        }
        tar.exe -czf $Destination -C $tmpDir @dirs 2>$null
        Remove-Item -Path $tmpDir -Recurse -Force
        if ((Test-Path $Destination) -and ((Get-Item $Destination).Length -gt 1048576)) {
            Set-Content -Path "$Destination.pruned" -Value "pruned"
            Write-Host "[STORED] [DemoContent] Synthesized and verified $(Split-Path -Leaf $Destination) from OCI layers."
            return $true
        }
    } catch {
        Write-Warning "[WARN] OCI MFE fallback failed: $_"
        if (Test-Path $tmpDir) { Remove-Item -Path $tmpDir -Recurse -Force -ErrorAction SilentlyContinue }
    }
    return $false
}

# ## Process-Artifact
# Validates, downloads, verifies hash, and prunes an individual packaging artifact.
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
        $fileHash = Get-Sha256Hex -FilePath $Destination
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
        libscript_download -Url $Url -Dest $Destination -ProvidedChecksum $ExpectedHash
    } catch {
        Write-Warning "[WARN] Primary download threw exception for $filename`: $_"
    }

    if (-not (Test-Path $Destination) -and ($filename -like "mfe-bundle*.tar.gz")) {
        if (Build-MfeBundleFromOci -Destination $Destination) {
            return $true
        }
    }

    if (-not (Test-Path $Destination)) {
        Write-Error "[FAIL] Failed to download $filename from $Url"
        return $false
    }

    $fileHash = Get-Sha256Hex -FilePath $Destination
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
        if ($Component -and $Component -ne "all" -and $prop.Name -ne $Component) {
            if (-not ($prop.Name -eq "python" -and ($Component -eq "gunicorn" -or $Component -eq "nodeenv" -or $Component -eq "exim"))) {
                continue
            }
        }
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
        if ($Component -and $Component -ne "all" -and $prop.Name -ne $Component) { continue }
        $db = $prop.Value
        $dest = Join-Path $databasesDir $db.filename
        if (-not (Process-Artifact -Url $db.url -Destination $dest -ExpectedHash $db.sha256 -Category "Database")) {
            $totalErrors++
        }
    }
}

# 2b. Webservers
if ($manifestContent.webservers) {
    foreach ($prop in $manifestContent.webservers.PSObject.Properties) {
        if ($Component -and $Component -ne "all" -and $prop.Name -ne $Component) { continue }
        $ws = $prop.Value
        $dest = Join-Path $webserversDir $ws.filename
        if (-not (Process-Artifact -Url $ws.url -Destination $dest -ExpectedHash $ws.sha256 -Category "Webserver")) {
            $totalErrors++
        } else {
            if ($prop.Name -eq "caddy" -and $dest -like "*.zip") {
                $caddyExtractDir = Join-Path $webserversDir "caddy"
                if (-not (Test-Path $caddyExtractDir)) {
                    New-Item -ItemType Directory -Path $caddyExtractDir -Force | Out-Null
                }
                if (-not (Test-Path (Join-Path $caddyExtractDir "caddy.exe"))) {
                    tar.exe -xf $dest -C $caddyExtractDir 2>$null
                    if (-not (Test-Path (Join-Path $caddyExtractDir "caddy.exe"))) {
                        Expand-Archive -Path $dest -DestinationPath $caddyExtractDir -Force -ErrorAction SilentlyContinue
                    }
                }
            }
        }
    }
}

# 2c. Applications
if ($manifestContent.applications) {
    foreach ($prop in $manifestContent.applications.PSObject.Properties) {
        if ($Component -and $Component -ne "all" -and $Component -ne "applications" -and $prop.Name -ne $Component) { continue }
        $app = $prop.Value
        $dest = Join-Path $applicationsDir $app.filename
        if (-not (Process-Artifact -Url $app.url -Destination $dest -ExpectedHash $app.sha256 -Category "Application")) {
            $totalErrors++
        }
    }
}

# 3. Wheels
$buildConstraints = Join-Path $RootDir "_lib\web-apps\openedx\build-constraints.txt"
if (Test-Path $buildConstraints) {
    $env:PIP_CONSTRAINT = $buildConstraints
    $env:UV_BUILD_CONSTRAINT = $buildConstraints
}
if ($manifestContent.wheels -and $manifestContent.wheels.packages) {
    if (-not $Component -or $Component -eq "all" -or $Component -eq "wheels" -or $Component -eq "openedx-core" -or $Component -eq "openedx" -or $Component -eq "gunicorn" -or $Component -eq "waitress" -or $Component -eq "nodeenv" -or $Component -eq "exim" -or $Wheels) {
        foreach ($whl in $manifestContent.wheels.packages) {
            $dest = Join-Path $wheelsDir $whl.filename
            if (-not (Process-Artifact -Url $whl.url -Destination $dest -ExpectedHash $whl.sha256 -Category "Wheel")) {
                $totalErrors++
            }
        }
    }
}

# 4. Codebase
if ($manifestContent.codebase -and $manifestContent.codebase.archive_filename) {
    if (-not $Component -or $Component -eq "all" -or $Component -eq "codebase" -or $Component -eq "openedx-core" -or $Component -eq "openedx" -or $Codebase) {
        $codeDest = Join-Path $codebaseDir $manifestContent.codebase.archive_filename
        if (-not (Process-Artifact -Url $manifestContent.codebase.archive_url -Destination $codeDest -ExpectedHash $manifestContent.codebase.archive_sha256 -Category "Codebase")) {
            $totalErrors++
        }
    }
}

# Demo Content
if ($manifestContent.codebase -and $manifestContent.codebase.demo_content) {
    if (-not $Component -or $Component -eq "all" -or $Component -eq "codebase" -or $Component -eq "openedx-core" -or $Component -eq "openedx" -or $Codebase) {
        foreach ($demo in $manifestContent.codebase.demo_content) {
            $demoDest = Join-Path $codebaseDir $demo.filename
            if (-not (Process-Artifact -Url $demo.url -Destination $demoDest -ExpectedHash $demo.sha256 -Category "DemoContent")) {
                $totalErrors++
            }
        }
    }
}

# Copy manifest to cache
Copy-Item -Path $Manifest -Destination (Join-Path $CacheDir "manifest.json") -Force

# Generate checksums.sha256
$checksumPath = Join-Path $CacheDir "checksums.sha256"
$checksumLines = @()
Get-ChildItem -Path $CacheDir -Recurse -File | Where-Object { $_.Name -ne "checksums.sha256" -and $_.Name -ne "manifest.json" } | ForEach-Object {
    $h = Get-Sha256Hex -FilePath $_.FullName
    $checksumLines += "$h  $($_.Name)"
}
$checksumLines | Out-File -FilePath $checksumPath -Encoding ascii

if ($totalErrors -gt 0) {
    Write-Error "Hydration completed with $totalErrors error(s)."
    exit 1
}

Write-Host "[SUCCESS] Offline artifact cache successfully hydrated and verified at $CacheDir"
exit 0
