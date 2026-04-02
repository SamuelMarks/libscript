# LibScript Common Package Manager (PowerShell)

# Resolve LIBSCRIPT_ROOT_DIR if not provided
if (-not $env:LIBSCRIPT_ROOT_DIR) {
    $current = $PSScriptRoot
    while ($current -and -not (Test-Path (Join-Path $current "ROOT"))) {
        $current = Split-Path $current -Parent
    }
    $env:LIBSCRIPT_ROOT_DIR = $current
}

# Source logging
. (Join-Path $PSScriptRoot "log.ps1")

function libscript_download {
    param (
        [string]$Url,
        [string]$Dest,
        [string]$ProvidedChecksum
    )

    if ([string]::IsNullOrEmpty($Dest)) {
        $Dest = Split-Path $Url -Leaf
    }

    # 1. Checksum Resolution
    $checksumDb = Join-Path $env:LIBSCRIPT_ROOT_DIR "checksums.txt"
    $expectedChecksum = $ProvidedChecksum
    if ([string]::IsNullOrEmpty($expectedChecksum) -and (Test-Path $checksumDb)) {
        $match = Get-Content $checksumDb | Select-String -SimpleMatch $Url | Select-Object -First 1
        if ($match) {
            $expectedChecksum = ($match.Line -split '\s+')[1]
        }
    }

    # 2. Aria2 Export Mode
    if ($env:LIBSCRIPT_ARIA2_EXPORT_FILE) {
        $Url | Out-File -FilePath $env:LIBSCRIPT_ARIA2_EXPORT_FILE -Append -Encoding utf8
        "  out=$(Split-Path $Dest -Leaf)" | Out-File -FilePath $env:LIBSCRIPT_ARIA2_EXPORT_FILE -Append -Encoding utf8
        if ($expectedChecksum) {
            "  checksum=sha-256=$($expectedChecksum.Replace('sha-256=', ''))" | Out-File -FilePath $env:LIBSCRIPT_ARIA2_EXPORT_FILE -Append -Encoding utf8
        }
        return
    }

    # 3. Cache Path Resolution
    $cacheDir = $env:LIBSCRIPT_CACHE_DIR
    if ([string]::IsNullOrEmpty($cacheDir)) {
        $cacheDir = Join-Path $env:LIBSCRIPT_ROOT_DIR "cache/downloads"
    }

    $dlDir = $env:DOWNLOAD_DIR
    if ([string]::IsNullOrEmpty($dlDir)) {
        $dlDir = Join-Path $cacheDir (if ($env:PACKAGE_NAME) { $env:PACKAGE_NAME } else { "unknown" })
    }

    if (-not (Test-Path $dlDir)) {
        New-Item -ItemType Directory -Force -Path $dlDir | Out-Null
    }

    $filename = Split-Path $Url -Leaf
    $cacheFile = Join-Path $dlDir $filename

    # 4. Cache Check & Download
    if (Test-Path $cacheFile) {
        log_info "[CACHED] $Url"
    } else {
        log_info "[DOWNLOADING] $Url"
        $downloadSuccess = $false

        # Strategy: Invoke-WebRequest (modern PS) or Net.WebClient (legacy)
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $Url -OutFile $cacheFile -ErrorAction Stop
            $downloadSuccess = $true
        } catch {
            log_warn "Invoke-WebRequest failed, trying WebClient: $($_.Exception.Message)"
            try {
                $client = New-Object System.Net.WebClient
                $client.DownloadFile($Url, $cacheFile)
                $downloadSuccess = $true
            } catch {
                log_error "Download failed for $Url: $($_.Exception.Message)"
                return
            }
        }

        if ($downloadSuccess) {
            $file = Get-Item $cacheFile
            if ($file.Length -eq 0) {
                log_error "Downloaded file is empty."
                Remove-Item $cacheFile -Force
                return
            }
        }
    }

    # 5. Checksum Validation
    if ($expectedChecksum -and $expectedChecksum -ne "SKIP") {
        $cleanExpected = $expectedChecksum.Replace("sha-256=", "").ToLower()
        $actualChecksum = (Get-FileHash -Path $cacheFile -Algorithm SHA256).Hash.ToLower()
        
        if ($actualChecksum -ne $cleanExpected) {
            log_error "Checksum mismatch for $Url. Expected: $cleanExpected, Got: $actualChecksum"
            Remove-Item $cacheFile -Force
            return
        }
    } elseif (Test-Path $cacheFile -and $env:LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB -ne "1") {
        $actualChecksum = (Get-FileHash -Path $cacheFile -Algorithm SHA256).Hash.ToLower()
        "$Url $actualChecksum" | Out-File -FilePath $checksumDb -Append -Encoding utf8
    }

    # 6. Final Placement
    if ($Dest -and $Dest -ne $cacheFile) {
        $destDir = Split-Path $Dest -Parent
        if ($destDir -and -not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Force -Path $destDir | Out-Null
        }
        Copy-Item -Path $cacheFile -Destination $Dest -Force
    }
}

function depends {
    param (
        [string[]]$Packages
    )

    $winPkgMgr = $env:LIBSCRIPT_WINDOWS_PKG_MGR
    if ([string]::IsNullOrEmpty($winPkgMgr)) { $winPkgMgr = "winget" }

    foreach ($pkg in $Packages) {
        log_info "Ensuring dependency: $pkg (via $winPkgMgr)"
        if ($winPkgMgr -eq "winget") {
            # Basic check if installed (winget list is slow, but fairly reliable)
            $list = winget list --name $pkg -e 2>$null
            if ($null -eq $list -or $list.Count -lt 3) {
                log_info "Installing $pkg via winget..."
                winget install --silent --force --name $pkg -e --accept-package-agreements --accept-source-agreements
            }
        } elseif ($winPkgMgr -eq "choco") {
            if (-not (choco list -l | Select-String -SimpleMatch $pkg)) {
                log_info "Installing $pkg via choco..."
                choco install -y $pkg
            }
        }
    }
}

function libscript_fetch {
    libscript_download @args
}

# Export functions
Export-ModuleMember -Function libscript_download, libscript_fetch, depends
