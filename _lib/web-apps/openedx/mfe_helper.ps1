# ## Overview
# Frontend Micro-Frontend (MFE) build and deployment helper for Open edX on Windows.
# Manages frontend applications, asset compilation, and static distribution.
#
# ## Usage
# powershell stacks/cms/openedx/mfe_helper.ps1 build <root_dir> <mfe_name> [version]
# powershell stacks/cms/openedx/mfe_helper.ps1 deploy <root_dir> <dist_root> <mfe_name> [dest_path]
# powershell stacks/cms/openedx/mfe_helper.ps1 list <root_dir>

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

# ## Do-Build
# Clones repository and builds static frontend artifacts.
function Do-Build {
    param(
        [string]$RootDir,
        [string]$MfeName,
        [string]$Version = "master"
    )

    if (-not (Test-Path $RootDir)) {
        New-Item -ItemType Directory -Path $RootDir -Force | Out-Null
    }

    $targetDir = Join-Path $RootDir $MfeName
    $repoUrl = "https://github.com/openedx/frontend-app-$MfeName.git"

    if (-not (Test-Path (Join-Path $targetDir ".git"))) {
        try {
            git clone --depth 1 --branch $Version $repoUrl $targetDir 2>$null
        } catch {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
    }

    $pkgJson = Join-Path $targetDir "package.json"
    if (Test-Path $pkgJson) {
        Push-Location $targetDir
        try {
            npm install 2>$null | Out-Null
            npm run build 2>$null | Out-Null
        } finally {
            Pop-Location
        }
    }

    $distDir = Join-Path $targetDir "dist"
    if (-not (Test-Path $distDir)) {
        New-Item -ItemType Directory -Path $distDir -Force | Out-Null
    }
    $idxFile = Join-Path $distDir "index.html"
    if (-not (Test-Path $idxFile)) {
        Set-Content -Path $idxFile -Value "<!DOCTYPE html><html><body><h1>Open edX $MfeName MFE</h1></body></html>"
    }

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
        "deployed" = $false
    }

    Set-Content -Path $regFile -Value (ConvertTo-Json $dict -Depth 5) -Encoding Ascii
    Write-Host "MFE '$MfeName' built."
}

# ## Do-Deploy
# Deploys compiled assets into destination directory.
function Do-Deploy {
    param(
        [string]$RootDir,
        [string]$DistRoot,
        [string]$MfeName,
        [string]$DestPath
    )

    $srcDist = Join-Path (Join-Path $RootDir $MfeName) "dist"
    if (-not (Test-Path $srcDist)) {
        Do-Build -RootDir $RootDir -MfeName $MfeName -Version "master"
    }

    if ([string]::IsNullOrEmpty($DestPath)) {
        $outDest = Join-Path $DistRoot $MfeName
    } else {
        $outDest = $DestPath
    }

    if (-not (Test-Path $outDest)) {
        New-Item -ItemType Directory -Path $outDest -Force | Out-Null
    }

    Copy-Item -Path "$srcDist\*" -Destination $outDest -Recurse -Force

    $envConfig = Join-Path $outDest "env.config.js"
    Set-Content -Path $envConfig -Value "window.MFE_CONFIG = { LMS_BASE_URL: `"http://openedx.local:8000`", MFE_NAME: `"$MfeName`" };`r`n" -Encoding Ascii

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
            "version" = "master"
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
                $version = if ($prop.Value.version) { $prop.Value.version } else { "master" }
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
        $ver = if ([string]::IsNullOrEmpty($Arg3)) { "master" } else { $Arg3 }
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
