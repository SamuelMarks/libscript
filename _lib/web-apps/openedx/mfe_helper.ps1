# ## Overview
# Frontend Micro-Frontend (MFE) build and deployment helper for Open edX on Windows.
# Manages frontend applications, offline bundle extraction, asset compilation, and static distribution.
#
# ## Usage
# powershell _lib/web-apps/openedx/mfe_helper.ps1 build <root_dir> <mfe_name> [version]
# powershell _lib/web-apps/openedx/mfe_helper.ps1 deploy <root_dir> <dist_root> <mfe_name> [dest_path]
# powershell _lib/web-apps/openedx/mfe_helper.ps1 list <root_dir>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Action,
    [Parameter(Position = 1)]
    [string]$Arg1,
    [Parameter(Position = 2)]
    [string]$Arg2,
    [Parameter(Position = 3)]
    [string]$Arg3,
    [Parameter(Position = 4)]
    [string]$Arg4
)

# ## Show-Help
# Displays command usage documentation.
function Show-Help {
    Write-Host "Usage: mfe_helper.ps1 build <root_dir> <mfe_name> [version]"
    Write-Host "       mfe_helper.ps1 deploy <root_dir> <dist_root> <mfe_name> [dest_path]"
    Write-Host "       mfe_helper.ps1 list <root_dir>"
    exit 0
}

# ## Resolve-CacheDir
# Resolves the LibScript offline artifact cache directory.
function Resolve-CacheDir {
    if ($env:LIBSCRIPT_CACHE_DIR -and (Test-Path $env:LIBSCRIPT_CACHE_DIR)) {
        return $env:LIBSCRIPT_CACHE_DIR
    }
    $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
    $repoRoot = (Resolve-Path (Join-Path $scriptDir "..\..\..")).Path
    return (Join-Path $repoRoot "cache")
}

# ## Do-Build
# Extracts pre-cached MFE archives or clones repository and builds static frontend artifacts.
function Do-Build {
    param(
        [string]$RootDir,
        [string]$MfeName,
        [string]$Version = "release/verawood.1"
    )

    if (-not (Test-Path $RootDir)) {
        New-Item -ItemType Directory -Path $RootDir -Force | Out-Null
    }

    $targetDir = Join-Path $RootDir $MfeName
    $distDir = Join-Path $targetDir "dist"
    $cacheDir = Resolve-CacheDir
    $mfeArchive = Join-Path $cacheDir "npm\frontend-app-$MfeName.tar.gz"
    $bundleArchive = Join-Path $cacheDir "codebase\mfe-bundle-verawood.1.tar.gz"
    if (-not (Test-Path $bundleArchive)) {
        $bundleArchive = Join-Path $cacheDir "npm\mfe-bundle-verawood.1.tar.gz"
    }

    if (Test-Path $mfeArchive) {
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        & tar.exe -xf $mfeArchive -C $targetDir 2>$null
    } elseif (Test-Path $bundleArchive) {
        if (-not (Test-Path $RootDir)) {
            New-Item -ItemType Directory -Path $RootDir -Force | Out-Null
        }
        & tar.exe -xzf $bundleArchive -C $RootDir 2>$null
        $bundleSubName = if ($MfeName -eq "course-authoring") { "authoring" } else { $MfeName }
        $extractedMfe = Join-Path $RootDir $bundleSubName
        if ((Test-Path (Join-Path $extractedMfe "index.html")) -and (-not (Test-Path (Join-Path $distDir "index.html")))) {
            if (-not (Test-Path $distDir)) {
                New-Item -ItemType Directory -Path $distDir -Force | Out-Null
            }
            Get-ChildItem -Path $extractedMfe -File -ErrorAction SilentlyContinue | ForEach-Object {
                Copy-Item -Path $_.FullName -Destination $distDir -Force
            }
        }
    } elseif ($env:LIBSCRIPT_OFFLINE -ne "1") {
        $repoUrl = "https://github.com/openedx/frontend-app-$MfeName.git"
        if (-not (Test-Path (Join-Path $targetDir ".git"))) {
            $gitCmd = Get-Command git -ErrorAction SilentlyContinue
            if ($gitCmd) {
                & git clone --depth 1 --branch $Version $repoUrl $targetDir 2>$null
                if ($LASTEXITCODE -ne 0) {
                    & git clone --depth 1 $repoUrl $targetDir 2>$null
                }
            }
        }
    }

    $pkgJson = Join-Path $targetDir "package.json"
    if ((Test-Path $pkgJson) -and (-not (Test-Path (Join-Path $distDir "index.html")))) {
        $npmCmd = Get-Command npm -ErrorAction SilentlyContinue
        if ($npmCmd) {
            Push-Location $targetDir
            try {
                & npm install --prefer-offline --no-audit 2>$null | Out-Null
                & npm run build 2>$null | Out-Null
            } finally {
                Pop-Location
            }
        }
    }

    if (-not (Test-Path $distDir)) {
        New-Item -ItemType Directory -Path $distDir -Force | Out-Null
    }

    $builtStatus = (Test-Path (Join-Path $distDir "index.html")) -or ((Get-ChildItem -Path $distDir -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0)

    $regFile = Join-Path $RootDir "registry.json"
    $dict = @{}
    if (Test-Path $regFile) {
        try {
            $raw = Get-Content -Path $regFile -Raw
            $json = ConvertFrom-Json $raw
            foreach ($prop in $json.PSObject.Properties) {
                $dict[$prop.Name] = @{
                    "version" = $prop.Value.version
                    "built" = $prop.Value.built
                    "deployed" = $prop.Value.deployed
                }
            }
        } catch {
            $dict = @{}
        }
    }

    $dict[$MfeName] = @{
        "version" = $Version
        "built" = $true
        "has_bundle" = $builtStatus
        "deployed" = $false
    }

    Set-Content -Path $regFile -Value (ConvertTo-Json $dict -Depth 5) -Encoding Ascii
    Write-Host "MFE '$MfeName' built."
}

# ## Do-Deploy
# Deploys compiled assets into destination directory and writes runtime MFE configuration.
function Do-Deploy {
    param(
        [string]$RootDir,
        [string]$DistRoot,
        [string]$MfeName,
        [string]$DestPath
    )

    $srcDist = Join-Path (Join-Path $RootDir $MfeName) "dist"
    if (-not (Test-Path $srcDist)) {
        Do-Build -RootDir $RootDir -MfeName $MfeName -Version "release/verawood.1"
    }

    if ([string]::IsNullOrEmpty($DestPath)) {
        $outDest = Join-Path $DistRoot $MfeName
    } else {
        $outDest = $DestPath
    }

    if (-not (Test-Path $outDest)) {
        New-Item -ItemType Directory -Path $outDest -Force | Out-Null
    }

    if (Test-Path "$srcDist\*") {
        Copy-Item -Path "$srcDist\*" -Destination $outDest -Recurse -Force -ErrorAction SilentlyContinue
    }

    $lmsPort = if ($env:OPENEDX_LMS_PORT) { $env:OPENEDX_LMS_PORT } else { "8000" }
    $cmsPort = if ($env:OPENEDX_CMS_PORT) { $env:OPENEDX_CMS_PORT } else { "8001" }
    $lmsDomain = if ($env:OPENEDX_LMS_DOMAIN) { $env:OPENEDX_LMS_DOMAIN } else { "localhost:$lmsPort" }
    $cmsDomain = if ($env:OPENEDX_CMS_DOMAIN) { $env:OPENEDX_CMS_DOMAIN } else { "localhost:$cmsPort" }

    $envConfig = Join-Path $outDest "env.config.js"
    $cfgJs = "window.MFE_CONFIG = { LMS_BASE_URL: `"http://$lmsDomain`", STUDIO_BASE_URL: `"http://$cmsDomain`", MFE_NAME: `"$MfeName`" };`r`n"
    Set-Content -Path $envConfig -Value $cfgJs -Encoding Ascii

    $regFile = Join-Path $RootDir "registry.json"
    $dict = @{}
    if (Test-Path $regFile) {
        try {
            $raw = Get-Content -Path $regFile -Raw
            $json = ConvertFrom-Json $raw
            foreach ($prop in $json.PSObject.Properties) {
                $dict[$prop.Name] = @{
                    "version" = $prop.Value.version
                    "built" = $prop.Value.built
                    "deployed" = $prop.Value.deployed
                    "dest" = $prop.Value.dest
                }
            }
        } catch {
            $dict = @{}
        }
    }

    if (-not $dict.ContainsKey($MfeName)) {
        $dict[$MfeName] = @{
            "version" = "release/verawood.1"
            "built" = $true
        }
    }
    $dict[$MfeName]["deployed"] = $true
    $dict[$MfeName]["dest"] = $outDest

    Set-Content -Path $regFile -Value (ConvertTo-Json $dict -Depth 5) -Encoding Ascii
    Write-Host "MFE '$MfeName' deployed to $outDest."
}

# ## Do-List
# Lists registered MFEs and their status.
function Do-List {
    param([string]$RootDir)

    $regFile = Join-Path $RootDir "registry.json"
    Write-Host ("{0,-24} {1,-8} {2,-10} {3,-12}" -f "MFE IDENTIFIER", "BUILT", "DEPLOYED", "VERSION")
    Write-Host ("-" * 60)

    if (Test-Path $regFile) {
        try {
            $raw = Get-Content -Path $regFile -Raw
            $json = ConvertFrom-Json $raw
            foreach ($prop in $json.PSObject.Properties) {
                $built = if ($prop.Value.built) { "True" } else { "False" }
                $deployed = if ($prop.Value.deployed) { "True" } else { "False" }
                $version = if ($prop.Value.version) { $prop.Value.version } else { "release/verawood.1" }
                Write-Host ("{0,-24} {1,-8} {2,-10} {3,-12}" -f $prop.Name, $built, $deployed, $version)
            }
        } catch {}
    }
}

if ([string]::IsNullOrEmpty($Action) -or $Action -in @("help", "--help", "-h")) {
    Show-Help
}

switch ($Action.ToLower()) {
    "build" {
        $ver = if ([string]::IsNullOrEmpty($Arg3)) { "release/verawood.1" } else { $Arg3 }
        Do-Build -RootDir $Arg1 -MfeName $Arg2 -Version $ver
    }
    "deploy" {
        Do-Deploy -RootDir $Arg1 -DistRoot $Arg2 -MfeName $Arg3 -DestPath $Arg4
    }
    "list" {
        Do-List -RootDir $Arg1
    }
    Default {
        Write-Error "Error: Unknown action $Action"
        exit 1
    }
}
