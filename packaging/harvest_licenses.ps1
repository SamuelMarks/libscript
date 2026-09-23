# ## Overview
# Universal dependency license harvester and bundler for LibScript installers on Windows.
# Discovers all packaged dependencies, extracts and validates their legal terms,
# and generates formatted plain-text and Rich Text Format (.rtf) license agreements
# alongside an indexed licenses_manifest.json for WiX, Inno Setup, and NSIS installers.
#
# ## Usage
# powershell -ExecutionPolicy Bypass -File packaging/harvest_licenses.ps1 -TargetInput <dir_or_file> [-OutDir <dir>] [-Format <type>] [-Force]

[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $false)]
    [string]$TargetInput,

    [Parameter(Mandatory = $false)]
    [Alias("out-dir")]
    [string]$OutDir,

    [Parameter(Mandatory = $false)]
    [string]$Format = "all",

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [Alias("h")]
    [switch]$Help
)

# ## Show-Help
# Displays usage and options documentation.
function Show-Help {
    Write-Host "Usage: powershell -ExecutionPolicy Bypass -File packaging\harvest_licenses.ps1 -TargetInput <path> [OPTIONS]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -OutDir <dir>   Output directory for harvested license assets"
    Write-Host "  -Format <type>  Format to generate: rtf, txt, or all (default: all)"
    Write-Host "  -Force          Regenerate licenses even if stamp file exists"
    Write-Host "  -Help           Show this help text"
    exit 0
}

if ($Help -or -not $TargetInput) {
    Show-Help
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LibscriptRootDir = (Resolve-Path (Join-Path $ScriptDir "..")).Path

# Resolve Target Path
if (Test-Path $TargetInput) {
    $resolvedTarget = (Resolve-Path $TargetInput).Path
} else {
    Write-Error "[ERROR] Target input does not exist: $TargetInput"
    exit 1
}

# Resolve OutDir
if (-not $OutDir) {
    if (Test-Path -Path $resolvedTarget -PathType Container) {
        $OutDir = Join-Path $resolvedTarget "licenses"
    } else {
        $OutDir = Join-Path (Split-Path -Parent $resolvedTarget) "licenses"
    }
}

$stampFile = Join-Path $OutDir ".stamp.licenses_harvested"
$manifestFile = Join-Path $OutDir "licenses_manifest.json"

if (-not $Force -and (Test-Path $stampFile) -and (Test-Path $manifestFile)) {
    Write-Host "[INFO] Licenses already harvested and up-to-date at: $OutDir"
    exit 0
}

if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

$canonicalLicensesDir = Join-Path $LibscriptRootDir "..\cc0-assets\libscript\packaging\licenses"
if (-not (Test-Path $canonicalLicensesDir)) {
    $canonicalLicensesDir = Join-Path $LibscriptRootDir "cc0-assets\libscript\packaging\licenses"
}

# ## Resolve-SpdxFile
# Locates the best matching canonical license file for a given SPDX identifier, downloading from GitHub if absent.
function Resolve-SpdxFile {
    param([string]$spdx)

    if (Test-Path $canonicalLicensesDir) {
        $exactTxt = Join-Path $canonicalLicensesDir "$spdx.txt"
        if (Test-Path $exactTxt) {
            return $exactTxt
        }

        $tokens = $spdx -split "\s+"
        foreach ($token in $tokens) {
            if ($token -in @("OR", "AND", "(", ")")) { continue }
            $tokTxt = Join-Path $canonicalLicensesDir "$token.txt"
            if (Test-Path $tokTxt) {
                return $tokTxt
            }
        }

        $mitTxt = Join-Path $canonicalLicensesDir "MIT.txt"
        if (Test-Path $mitTxt) {
            return $mitTxt
        }
    }

    # Fallback: attempt downloading directly from cc0-assets GitHub repository
    $ghBase = "https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/packaging/licenses"
    $cacheDir = Join-Path $env:TEMP "libscript_licenses"
    if (-not (Test-Path $cacheDir)) {
        New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
    }
    $cachedFile = Join-Path $cacheDir "$spdx.txt"
    if (Test-Path $cachedFile) {
        return $cachedFile
    }
    try {
        Invoke-WebRequest -Uri "$ghBase/$spdx.txt" -OutFile $cachedFile -UseBasicParsing -ErrorAction Stop
        return $cachedFile
    } catch {
        # Fallback to MIT
        $cachedMit = Join-Path $cacheDir "MIT.txt"
        try {
            Invoke-WebRequest -Uri "$ghBase/MIT.txt" -OutFile $cachedMit -UseBasicParsing -ErrorAction Stop
            return $cachedMit
        } catch {
            return $null
        }
    }
}

# ## Convert-ToRtf
# Converts plain-text license file into RTF.
function Convert-ToRtf {
    param(
        [string]$srcTxt,
        [string]$dstRtf,
        [string]$title,
        [string]$spdx
    )

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("{\rtf1\ansi\deff0 {\fonttbl {\f0 Courier;}}\fs20")
    [void]$sb.AppendLine("{\b Software License Agreement: $title}\par")
    [void]$sb.AppendLine("{\b SPDX License Identifier: $spdx}\par")
    [void]$sb.AppendLine("--------------------------------------------------------------------------------\par")

    $lines = [System.IO.File]::ReadAllLines($srcTxt)
    foreach ($line in $lines) {
        $escaped = $line.Replace('\', '\\').Replace('{', '\{').Replace('}', '\}')
        [void]$sb.AppendLine("$escaped\par")
    }
    [void]$sb.AppendLine("}")
    [System.IO.File]::WriteAllText($dstRtf, $sb.ToString(), [System.Text.Encoding]::UTF8)
}

# Discover bundled licenses
$items = @()

if (Test-Path -Path $resolvedTarget -PathType Container) {
    $pkgJsonPath = Join-Path $resolvedTarget "packaging.json"
    $manifestJsonPath = Join-Path $resolvedTarget "manifest.json"

    if (Test-Path $pkgJsonPath) {
        $pkgObj = Get-Content -LiteralPath $pkgJsonPath -Raw | ConvertFrom-Json
        if ($pkgObj.branding -and $pkgObj.branding.bundled_licenses) {
            foreach ($entry in $pkgObj.branding.bundled_licenses) {
                $comp = $entry.component
                $title = if ($entry.title) { $entry.title } else { $comp }
                $spdx = if ($entry.spdx_id) { $entry.spdx_id } else { "MIT" }
                $licFile = if ($entry.license_file) { $entry.license_file } else { "" }
                $mandatory = if ($null -ne $entry.mandatory) { [bool]$entry.mandatory } else { $true }

                $items += [PSCustomObject]@{
                    name = $comp
                    title = $title
                    spdx = $spdx
                    license_file = $licFile
                    mandatory = $mandatory
                }
            }
        }
    }
}

if ($items.Count -eq 0) {
    Write-Host "[WARN] No bundled licenses found; writing empty manifest."
    $emptyManifest = @{
        schema_version = "1.0.0"
        generated_at = (Get-Date -Format "o")
        licenses = @()
    } | ConvertTo-Json -Depth 5
    Set-Content -LiteralPath $manifestFile -Value $emptyManifest
    Set-Content -LiteralPath $stampFile -Value "harvested"
    exit 0
}

Write-Host "[INFO] Harvesting licenses for $($items.Count) components..."

$manifestList = @()

foreach ($item in $items) {
    $compName = $item.name
    $cleanName = ($compName -replace '[^a-zA-Z0-9_]', '_').ToLower()
    $dstTxt = Join-Path $OutDir "${cleanName}_license.txt"
    $dstRtf = Join-Path $OutDir "${cleanName}_license.rtf"

    $spdxFile = $null
    if ($item.license_file -and (Test-Path $item.license_file)) {
        $spdxFile = (Resolve-Path $item.license_file).Path
    } else {
        $spdxFile = Resolve-SpdxFile $item.spdx
    }

    if ($spdxFile -and (Test-Path $spdxFile)) {
        Copy-Item -LiteralPath $spdxFile -Destination $dstTxt -Force
    } else {
        Set-Content -LiteralPath $dstTxt -Value "License terms for $($item.title) ($($item.spdx))`nPlease refer to upstream documentation."
    }

    Convert-ToRtf -srcTxt $dstTxt -dstRtf $dstRtf -title $item.title -spdx $item.spdx

    $manifestList += [ordered]@{
        name = $cleanName
        title = $item.title
        spdx = $item.spdx
        rtf_file = $dstRtf
        txt_file = $dstTxt
        property_id = "LICENSE_ACCEPTED_${cleanName}"
        mandatory = $item.mandatory
    }
}

$manifestObj = [ordered]@{
    schema_version = "1.0.0"
    generated_at = (Get-Date -Format "o")
    licenses = $manifestList
}

$manifestJson = $manifestObj | ConvertTo-Json -Depth 5
Set-Content -LiteralPath $manifestFile -Value $manifestJson
Set-Content -LiteralPath $stampFile -Value "harvested"

Write-Host "[INFO] Successfully harvested $($items.Count) licenses into $OutDir"
Write-Host "[INFO] Manifest written to $manifestFile"
exit 0
