# ## Overview
# Harvests the LibScript repository into a deployment payload or WiX fragment XML.
#
# ## Usage
#   .\packaging\harvest_payload.ps1 [-OutputDir <dir>] [-ManifestFile <file>] [-WixFragment <file>]

<#
.SYNOPSIS
Harvests the LibScript repository into a deployment payload or WiX fragment XML.

.DESCRIPTION
Gathers files from the LibScript repository while respecting .gitignore rules,
excluding build artifacts, test temporary directories, and nested .git repositories.
Generates directory hierarchies and WiX XML fragments with components and files.
Supports optional offline cache harvesting via -IncludeCache for air-gapped installers.

.PARAMETER OutputDir
Target staging directory for harvested files.

.PARAMETER ManifestFile
Output file path for the list of relative file paths.

.PARAMETER WixFragment
Output file path for the generated WiX XML fragment.

.PARAMETER ComponentGroup
WiX ComponentGroup ID (default: LibscriptHarvestedComponents).

.PARAMETER DirectoryId
WiX Directory ID for the payload root (default: LIBSCRIPT_FOLDER).

.PARAMETER RootDir
Root repository directory (default: parent of packaging).

.PARAMETER IncludeCache
Path to hydrated offline cache directory to embed in payload.
#>

[CmdletBinding()]
param(
    [Alias('output-dir')]
    [string]$OutputDir,

    [Alias('manifest-file')]
    [string]$ManifestFile,

    [Alias('wix-fragment')]
    [string]$WixFragment,

    [Alias('component-group')]
    [string]$ComponentGroup = 'LibscriptHarvestedComponents',

    [Alias('directory-id')]
    [string]$DirectoryId = 'LIBSCRIPT_FOLDER',

    [Alias('root-dir')]
    [string]$RootDir,

    [Alias('include-cache')]
    [string]$IncludeCache
)

$ErrorActionPreference = 'Stop'

if (-not $RootDir) {
    $RootDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
} else {
    $RootDir = (Resolve-Path $RootDir).Path
}

# 1. Gather all files
Push-Location $RootDir
try {
    $hasGit = $false
    if (Test-Path (Join-Path $RootDir '.git')) {
        $gitCmd = Get-Command git -ErrorAction SilentlyContinue
        if ($gitCmd) { $hasGit = $true }
    }

    if ($hasGit) {
        $allFiles = & git ls-files -c -o --exclude-standard
    } else {
        $raw = Get-ChildItem -Path $RootDir -Recurse -File -Force
        $allFiles = $raw | ForEach-Object { $_.FullName.Substring($RootDir.Length).TrimStart('\', '/').Replace('\', '/') }
    }

    # 2. Filter prohibited patterns and directories (always exclude cache/ from repo)
    $filtered = [System.Collections.Generic.List[string]]::new()
    $excludeRegex = '(^|/)(\.git|\.github|\.githooks|\.vagrant|tests_tmp|dist|build|node_modules|cache|kubernetes-the-hard-way)(/|$)'
    $excludeExtRegex = '\.(tmp|log|ppm|bak|swp|msi|wixobj|pruned)$'

    foreach ($f in $allFiles) {
        if (-not $f) { continue }
        $norm = $f.Replace('\', '/')
        if ($norm -match $excludeRegex) { continue }
        if ($norm -match $excludeExtRegex) { continue }
        if ($norm -like 'packaging/screenshots/release_test/*') { continue }
        if (-not (Test-Path (Join-Path $RootDir $norm) -PathType Leaf)) { continue }
        $filtered.Add($norm)
    }

    # Add offline cache files if -IncludeCache is provided
    $cacheReal = $null
    if ($IncludeCache) {
        if (Test-Path $IncludeCache) {
            $cacheReal = (Resolve-Path $IncludeCache).Path
        } elseif (Test-Path (Join-Path $RootDir $IncludeCache)) {
            $cacheReal = (Resolve-Path (Join-Path $RootDir $IncludeCache)).Path
        }
    }
    if ($cacheReal) {
        $cacheFiles = Get-ChildItem -Path $cacheReal -Recurse -File -Force
        foreach ($cf in $cacheFiles) {
            $relC = $cf.FullName.Substring($cacheReal.Length).TrimStart('\', '/').Replace('\', '/')
            if ($relC) {
                $filtered.Add("cache/$relC")
            }
        }
    }

    # 3. Write manifest
    if ($ManifestFile) {
        $mDir = Split-Path $ManifestFile -Parent
        if ($mDir -and -not (Test-Path $mDir)) { [void](New-Item -ItemType Directory -Path $mDir -Force) }
        Set-Content -Path $ManifestFile -Value $filtered -Encoding ascii
        Write-Host "[INFO] Wrote manifest to: $ManifestFile ($($filtered.Count) files)"
    }

    # 4. Copy payload if requested
    if ($OutputDir) {
        if (-not (Test-Path $OutputDir)) { [void](New-Item -ItemType Directory -Path $OutputDir -Force) }
        foreach ($f in $filtered) {
            if ($f.StartsWith('cache/') -and $cacheReal) {
                $src = Join-Path $cacheReal ($f.Substring(6).Replace('/', '\'))
            } else {
                $src = Join-Path $RootDir ($f.Replace('/', '\'))
            }
            $dst = Join-Path $OutputDir ($f.Replace('/', '\'))
            $dstDir = Split-Path $dst -Parent
            if (-not (Test-Path $dstDir)) { [void](New-Item -ItemType Directory -Path $dstDir -Force) }
            Copy-Item -Path $src -Destination $dst -Force
        }
        Write-Host "[INFO] Harvested files copied to: $OutputDir"
    }

    # 5. Generate WiX fragment if requested
    if ($WixFragment) {
        $wDir = Split-Path $WixFragment -Parent
        if ($wDir -and -not (Test-Path $wDir)) { [void](New-Item -ItemType Directory -Path $wDir -Force) }

        $dirs = [System.Collections.Generic.SortedDictionary[string, hashtable]]::new()
        foreach ($f in $filtered) {
            $d = Split-Path $f -Parent
            if ($d -and $d -ne '.') {
                $parts = $d.Replace('\', '/').Split('/')
                $curr = ''
                foreach ($p in $parts) {
                    $prev = $curr
                    $curr = if ($curr) { "$curr/$p" } else { $p }
                    if (-not $dirs.ContainsKey($curr)) {
                        $dirs[$curr] = @{ Name = $p; Parent = $prev }
                    }
                }
            }
        }

        $sw = [System.IO.StreamWriter]::new($WixFragment, $false, [System.Text.Encoding]::UTF8)
        $sw.WriteLine('<?xml version="1.0" encoding="UTF-8"?>')
        $sw.WriteLine('<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">')
        $sw.WriteLine('  <Fragment>')

        foreach ($k in $dirs.Keys) {
            $entry = $dirs[$k]
            $dId = 'DIR_' + ($k -replace '[/\\.:\- ]', '_')
            $parentDirId = if ($entry.Parent) { 'DIR_' + ($entry.Parent -replace '[/\\.:\- ]', '_') } else { $DirectoryId }
            $sw.WriteLine("    <DirectoryRef Id=""$parentDirId""><Directory Id=""$dId"" Name=""$($entry.Name)"" /></DirectoryRef>")
        }

        foreach ($f in $filtered) {
            $san = $f -replace '[/\\.:\- ]', '_'
            $cId = 'CMP_H_' + $san
            $fId = 'FIL_H_' + $san
            $d = Split-Path $f -Parent
            $targetDir = if ($d -and $d -ne '.') { 'DIR_' + ($d.Replace('\', '/') -replace '[/\\.:\- ]', '_') } else { $DirectoryId }
            
            if ($f.StartsWith('cache/') -and $cacheReal) {
                $srcPath = Join-Path $cacheReal ($f.Substring(6).Replace('/', '\'))
            } else {
                $srcPath = Join-Path $RootDir ($f.Replace('/', '\'))
            }

            $diskId = '1'
            if ($f -like 'cache/runtimes/*') {
                $diskId = '2'
            } elseif ($f -like 'cache/databases/*') {
                $diskId = '3'
            } elseif ($f -like 'cache/codebase/*' -or $f -like 'cache/wheels/*' -or $f -like 'cache/npm/*') {
                $diskId = '4'
            }

            $sw.WriteLine("    <DirectoryRef Id=""$targetDir"">")
            $sw.WriteLine("      <Component Id=""$cId"" Guid=""*"">")
            $sw.WriteLine("        <File Id=""$fId"" Source=""$srcPath"" KeyPath=""yes"" DiskId=""$diskId"" />")
            $sw.WriteLine("      </Component>")
            $sw.WriteLine("    </DirectoryRef>")
        }

        $sw.WriteLine("    <ComponentGroup Id=""$ComponentGroup"">")
        foreach ($f in $filtered) {
            if ($IncludeCache -and $f.StartsWith('cache/')) { continue }
            $san = $f -replace '[/\.:\- ]', '_'
            $cId = 'CMP_H_' + $san
            $sw.WriteLine("      <ComponentRef Id=""$cId"" />")
        }
        $sw.WriteLine('    </ComponentGroup>')

        if ($IncludeCache) {
            $sw.WriteLine('    <ComponentGroup Id="LibscriptOfflineCacheComponents">')
            foreach ($f in $filtered) {
                if ($f.StartsWith('cache/')) {
                    $san = $f -replace '[/\.:\- ]', '_'
                    $cId = 'CMP_H_' + $san
                    $sw.WriteLine("      <ComponentRef Id=""$cId"" />")
                }
            }
            $sw.WriteLine('    </ComponentGroup>')
        }

        $sw.WriteLine('  </Fragment>')
        $sw.WriteLine('</Wix>')
        $sw.Close()
        Write-Host "[INFO] Generated WiX XML fragment: $WixFragment"
    }

    Write-Host "[PASS] Harvesting complete ($($filtered.Count) files identified)."
}
finally {
    Pop-Location
}
exit 0
