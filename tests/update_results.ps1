# ## Overview
# Updates the Supported Components tables in README.md (or custom output file)
# split into Architectural Tiers (T0-T5 and Orthogonal Planes)
# with test results from tests_tmp/, updates task completion in TODO_PLAN.md and
# TESTING_TODO_PLAN.md, and optionally exports an aggregated JSON test results matrix.
#
# ## Usage
# .\tests\update_results.ps1 [REPO_ROOT] [--output <markdown_file>] [--json [json_file]] [--help]

<#
.SYNOPSIS
PowerShell implementation of tests/update_results.sh.
#>

$ErrorActionPreference = "Stop"

# ## Show-Help
# Displays command-line usage and options for test result matrix aggregation.
function Show-Help {
    Write-Host "Usage: update_results.ps1 [REPO_ROOT] [--output <markdown_file>] [--json [json_file]] [--help]"
    Write-Host ""
    Write-Host "Aggregates test result marker files (*.success, *.failure) from tests_tmp/"
    Write-Host "and updates the tiered Supported Components tables in README.md."
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  REPO_ROOT              Target repository root path (default: auto-detected)."
    Write-Host "  --output <file>        Custom markdown file to update (default: README.md)."
    Write-Host "  --json [json_file]     Export matrix results as JSON (default: tests_tmp/matrix_results.json)."
    Write-Host "  --help, -h, /?         Show this help message."
}

$repoRoot = ""
$outputFile = ""
$jsonFile = ""
$syncPlans = ($env:LIBSCRIPT_SYNC_PLAN_CHECKBOXES -eq "1")

for ($i = 0; $i -lt $args.Count; $i++) {
    $arg = [string]$args[$i]
    if ($arg -eq "--help" -or $arg -eq "-h" -or $arg -eq "/?" -or $arg -eq "-?") {
        Show-Help
        exit 0
    } elseif ($arg -eq "--sync-plan-checkboxes" -or $arg -eq "--sync-plans") {
        $syncPlans = $true
    } elseif ($arg -eq "--output") {
        if ($i + 1 -lt $args.Count) {
            $outputFile = [string]$args[++$i]
        }
    } elseif ($arg -eq "--json") {
        if ($i + 1 -lt $args.Count -and -not ([string]$args[$i + 1]).StartsWith("--")) {
            $jsonFile = [string]$args[++$i]
        } else {
            $jsonFile = "default"
        }
    } elseif (-not $repoRoot -and -not $arg.StartsWith("-")) {
        $repoRoot = $arg
    }
}

if (-not $repoRoot) {
    $curr = $PSScriptRoot
    while ($curr -and -not (Test-Path (Join-Path $curr "libscript.sh"))) {
        $parent = Split-Path -Parent $curr
        if ($parent -eq $curr) { break }
        $curr = $parent
    }
    $repoRoot = $curr
}
$repoRoot = [System.IO.Path]::GetFullPath($repoRoot)

if (-not $outputFile) {
    $outputFile = Join-Path $repoRoot "README.md"
} else {
    $outputFile = [System.IO.Path]::GetFullPath($outputFile)
}

if ($jsonFile -eq "default") {
    $jsonFile = Join-Path (Join-Path $repoRoot "tests_tmp") "matrix_results.json"
} elseif ($jsonFile) {
    $jsonFile = [System.IO.Path]::GetFullPath($jsonFile)
}

$script:ManifestCache = @{}
$script:DirFileCache = @{}

# ## Get-CachedManifest
# Reads and caches a parsed manifest.json object so repeated OS/tier checks avoid redundant disk I/O.
function Get-CachedManifest {
    param([string]$ManifestPath)
    if (-not $ManifestPath) { return $null }
    if ($script:ManifestCache.ContainsKey($ManifestPath)) {
        return $script:ManifestCache[$ManifestPath]
    }
    if (-not (Test-Path -LiteralPath $ManifestPath)) {
        $script:ManifestCache[$ManifestPath] = $null
        return $null
    }
    try {
        $raw = [System.IO.File]::ReadAllText($ManifestPath, [System.Text.Encoding]::UTF8)
        $parsed = $raw | ConvertFrom-Json
        $script:ManifestCache[$ManifestPath] = $parsed
        return $parsed
    } catch {
        $script:ManifestCache[$ManifestPath] = $null
        return $null
    }
}

# ## Check-ManifestSupport
# Checks whether a component manifest supports a specific target operating system.
function Check-ManifestSupport {
    param(
        [string]$ManifestPath,
        [string]$TargetOs
    )

    $manifest = Get-CachedManifest -ManifestPath $ManifestPath
    if ($null -eq $manifest) {
        return $true
    }

    $aliases = switch ($TargetOs) {
        { $_ -in 'alpine', 'debian', 'rhel', 'rocky', 'linux' } { @($TargetOs, 'linux') }
        { $_ -in 'freebsd', 'bsd' } { @($TargetOs, 'bsd') }
        { $_ -in 'darwin', 'macos', 'mac' } { @('darwin', 'macos', 'mac') }
        'windows' { @('windows') }
        { $_ -in 'sunos', 'illumos', 'solaris' } { @('sunos', 'illumos', 'solaris') }
        default   { @($TargetOs) }
    }

    if ($null -ne $manifest.os_blacklist) {
        $bl = @($manifest.os_blacklist)
        foreach ($alias in $aliases) {
            if ($bl -contains $alias) {
                return $false
            }
        }
    }

    if ($null -ne $manifest.os_whitelist) {
        $wl = @($manifest.os_whitelist)
        if ($wl -contains 'all') {
            return $true
        }
        foreach ($alias in $aliases) {
            if ($wl -contains $alias) {
                return $true
            }
        }
        return $false
    }

    return $true
}

# ## Read-ManifestTier
# Reads the explicit "tier" property ("T1" or "T2") from manifest.json, falling back to category family when absent in synthetic fixtures.
function Read-ManifestTier {
    param(
        [string]$ManifestPath,
        [string]$Category
    )
    $m = Get-CachedManifest -ManifestPath $ManifestPath
    if ($null -ne $m -and $m.tier -in @('T1', 'T2')) {
        return [string]$m.tier
    }
    if ($Category -in @('base-system','kernel','bootloaders','init-systems','unikernels','graphics','audio','display-servers','display-managers','desktops')) {
        return 'T2'
    }
    return 'T1'
}

# ## Test-AnyFilePattern
# Checks whether any files in a directory match a specific glob search pattern using an in-memory index.
function Test-AnyFilePattern {
    param(
        [string]$DirectoryPath,
        [string]$SearchPattern
    )
    if (-not $script:DirFileCache.ContainsKey($DirectoryPath)) {
        if (-not (Test-Path -LiteralPath $DirectoryPath)) {
            $script:DirFileCache[$DirectoryPath] = $null
            return $false
        }
        $exactSet = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
        $byPrefix = @{}
        $allNames = [System.Collections.Generic.List[string]]::new()
        foreach ($fp in [System.IO.Directory]::GetFiles($DirectoryPath)) {
            $fn = [System.IO.Path]::GetFileName($fp)
            [void]$exactSet.Add($fn)
            $allNames.Add($fn)
            $dot = $fn.IndexOf('.')
            if ($dot -gt 0) {
                $pfx = $fn.Substring(0, $dot).ToLowerInvariant()
                if (-not $byPrefix.ContainsKey($pfx)) {
                    $byPrefix[$pfx] = [System.Collections.Generic.List[string]]::new()
                }
                $byPrefix[$pfx].Add($fn)
            }
        }
        $script:DirFileCache[$DirectoryPath] = @{
            Exact    = $exactSet
            ByPrefix = $byPrefix
            All      = $allNames
        }
    }
    $idx = $script:DirFileCache[$DirectoryPath]
    if ($null -eq $idx) { return $false }
    if ($SearchPattern.IndexOfAny([char[]]@('*', '?')) -lt 0) {
        return $idx.Exact.Contains($SearchPattern)
    }
    $pDot = $SearchPattern.IndexOf('.')
    if ($pDot -gt 0) {
        $candPfx = $SearchPattern.Substring(0, $pDot)
        if ($candPfx.IndexOfAny([char[]]@('*', '?')) -lt 0) {
            $key = $candPfx.ToLowerInvariant()
            if (-not $idx.ByPrefix.ContainsKey($key)) { return $false }
            foreach ($cand in $idx.ByPrefix[$key]) {
                if ($cand -like $SearchPattern) { return $true }
            }
            return $false
        }
    }
    foreach ($cand in $idx.All) {
        if ($cand -like $SearchPattern) { return $true }
    }
    return $false
}

# ## Normalize-SupportedComponentsSection
# Normalizes headings and table rows in the Supported Components block so Prettier padding and prose wrapping are ignored when checking if semantic content changed.
function Normalize-SupportedComponentsSection {
    param([string]$Block)
    $out = @()
    foreach ($rawLine in ($Block -split "`r?`n")) {
        $line = $rawLine.Trim()
        if ([string]::IsNullOrEmpty($line)) { continue }
        if ($line -match '^\|[\s\-:|]+\|$') {
            $out += '|---|---|---|---|---|---|---|---|---|'
        } elseif ($line.StartsWith('|') -and $line.EndsWith('|')) {
            $inner = $line.Substring(1, $line.Length - 2)
            $cells = ($inner -split '\|') | ForEach-Object { $_.Trim() }
            $out += ('| ' + ($cells -join ' | ') + ' |')
        } elseif ($line.StartsWith('#')) {
            $out += $line
        }
    }
    return ($out -join "`n")
}

# ## Update-SupportedComponents
# Aggregates component test markers and updates the tiered Supported Components tables in README.md.
function Update-SupportedComponents {
    param(
        [string]$RootPath,
        [string]$TargetReadme,
        [string]$ExportJson
    )

    $libPath = Join-Path $RootPath "_lib"
    if (-not (Test-Path -LiteralPath $libPath)) {
        return
    }

    $entries = @()
    $cats = Get-ChildItem -LiteralPath $libPath -Directory -ErrorAction SilentlyContinue | Where-Object { -not $_.Name.StartsWith("_") }
    foreach ($cat in $cats) {
        $comps = Get-ChildItem -LiteralPath $cat.FullName -Directory -ErrorAction SilentlyContinue | Where-Object { -not $_.Name.StartsWith("_") }
        foreach ($comp in $comps) {
            $mCandidate = Join-Path $comp.FullName "manifest.json"
            $mPath = if (Test-Path -LiteralPath $mCandidate) { $mCandidate } else { "" }
            $tier = Read-ManifestTier -ManifestPath $mPath -Category $cat.Name
            $entries += [PSCustomObject]@{
                Tier     = $tier
                Category = $cat.Name
                Comp     = $comp.Name
                Short    = $comp.Name
                Manifest = $mPath
            }
        }
    }

    $distroDir = Join-Path (Join-Path $RootPath "synthesis") "distro"
    if (Test-Path -LiteralPath $distroDir) {
        Get-ChildItem -LiteralPath $distroDir -Directory -ErrorAction SilentlyContinue | Where-Object { -not $_.Name.StartsWith("_") -and -not $_.Name.EndsWith("-base") } | ForEach-Object {
            $mc = Join-Path $_.FullName "manifest.json"
            $mp = if (Test-Path -LiteralPath $mc) { $mc } else { "" }
            $entries += [PSCustomObject]@{ Tier = 'T3'; Category = 'distro'; Comp = "synthesis/distro/$($_.Name)"; Short = $_.Name; Manifest = $mp }
        }
    }
    $repogenDir = Join-Path (Join-Path $RootPath "synthesis") "repogen"
    if (Test-Path -LiteralPath $repogenDir) {
        $mc = Join-Path $repogenDir "manifest.json"
        $mp = if (Test-Path -LiteralPath $mc) { $mc } else { "" }
        $entries += [PSCustomObject]@{ Tier = 'T3'; Category = 'repogen'; Comp = 'synthesis/repogen'; Short = 'repogen'; Manifest = $mp }
    }
    $vfsDir = Join-Path (Join-Path $RootPath "synthesis") "vfs"
    if (Test-Path -LiteralPath $vfsDir) {
        Get-ChildItem -LiteralPath $vfsDir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $mc = Join-Path $_.FullName "manifest.json"
            $mp = if (Test-Path -LiteralPath $mc) { $mc } else { "" }
            $entries += [PSCustomObject]@{ Tier = 'T3'; Category = 'vfs'; Comp = "synthesis/vfs/$($_.Name)"; Short = $_.Name; Manifest = $mp }
        }
    }
    if (Test-Path -LiteralPath (Join-Path (Join-Path (Join-Path $RootPath "synthesis") "disk") "provision_disk.sh")) {
        $entries += [PSCustomObject]@{ Tier = 'T3'; Category = 'disk'; Comp = 'synthesis/disk/provision_disk'; Short = 'provision_disk'; Manifest = '' }
    }

    foreach ($infraSub in @('providers','resources','clusters')) {
        $infraDir = Join-Path (Join-Path $RootPath "infrastructure") $infraSub
        if (Test-Path -LiteralPath $infraDir) {
            Get-ChildItem -LiteralPath $infraDir -Directory -ErrorAction SilentlyContinue | Where-Object { -not $_.Name.StartsWith("_") } | ForEach-Object {
                $mc = Join-Path $_.FullName "manifest.json"
                $mp = if (Test-Path -LiteralPath $mc) { $mc } else { "" }
                $entries += [PSCustomObject]@{ Tier = 'T4'; Category = $infraSub; Comp = "infrastructure/$infraSub/$($_.Name)"; Short = $_.Name; Manifest = $mp }
            }
        }
    }

    foreach ($workSub in @('apps','ai','constellations')) {
        $wdir = Join-Path (Join-Path $RootPath "workloads") $workSub
        if (Test-Path -LiteralPath $wdir) {
            Get-ChildItem -LiteralPath $wdir -Directory -ErrorAction SilentlyContinue | Where-Object { -not $_.Name.StartsWith("_") } | ForEach-Object {
                $mc = Join-Path $_.FullName "manifest.json"
                $mp = if (Test-Path -LiteralPath $mc) { $mc } else { "" }
                $entries += [PSCustomObject]@{ Tier = 'T5'; Category = $workSub; Comp = "workloads/$workSub/$($_.Name)"; Short = $_.Name; Manifest = $mp }
            }
        }
    }
    $schedDir = Join-Path (Join-Path $RootPath "workloads") "schedulers"
    if (Test-Path -LiteralPath $schedDir) {
        Get-ChildItem -LiteralPath $schedDir -Filter "*.sh" -File -ErrorAction SilentlyContinue | ForEach-Object {
            $sn = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
            $entries += [PSCustomObject]@{ Tier = 'T5'; Category = 'schedulers'; Comp = "workloads/schedulers/$sn"; Short = $sn; Manifest = '' }
        }
    }
    $traitsDir = Join-Path $RootPath "traits"
    if (Test-Path -LiteralPath $traitsDir) {
        Get-ChildItem -LiteralPath $traitsDir -Directory -ErrorAction SilentlyContinue | Where-Object { -not $_.Name.StartsWith("_") } | ForEach-Object {
            $entries += [PSCustomObject]@{ Tier = 'PlaneA'; Category = 'traits'; Comp = "traits/$($_.Name)"; Short = $_.Name; Manifest = '' }
        }
    }

    $dedupMap = @{}
    foreach ($item in $entries) {
        $key = "$($item.Tier)|$($item.Comp)"
        if (-not $dedupMap.ContainsKey($key)) {
            $dedupMap[$key] = $item
        }
    }
    $sortedKeys = [string[]]@($dedupMap.Keys)
    [System.Array]::Sort($sortedKeys, [System.StringComparer]::Ordinal)
    $entries = foreach ($k in $sortedKeys) { $dedupMap[$k] }

    $existingMap = @{}
    if (Test-Path -LiteralPath $TargetReadme) {
        $existingLines = [System.IO.File]::ReadAllLines($TargetReadme, [System.Text.Encoding]::UTF8)
        foreach ($line in $existingLines) {
            $parts = $line -split '\|'
            if ($parts.Count -ge 10 -and $parts[1] -match '`([^`]+)`') {
                $compKey = $Matches[1].Trim()
                $catKey = if ($parts[2] -match '`([^`]+)`') { $Matches[1].Trim() } else { "" }
                $rowVal = @{
                    cat     = $catKey
                    apk     = $parts[3].Trim()
                    deb     = $parts[4].Trim()
                    rpm     = $parts[5].Trim()
                    win     = $parts[6].Trim()
                    sunos   = $parts[7].Trim()
                    freebsd = $parts[8].Trim()
                    macos   = $parts[9].Trim()
                }
                $existingMap[$compKey] = $rowVal
                if ($catKey) { $existingMap["$catKey/$compKey"] = $rowVal }
            } elseif ($parts.Count -ge 9 -and $parts[1] -match '`([^`]+)`') {
                $compKey = $Matches[1].Trim()
                $existingMap[$compKey] = @{
                    apk     = $parts[2].Trim()
                    deb     = $parts[3].Trim()
                    rpm     = $parts[4].Trim()
                    win     = $parts[5].Trim()
                    sunos   = $parts[6].Trim()
                    freebsd = $parts[7].Trim()
                    macos   = $parts[8].Trim()
                }
            }
        }
    }

    $testsTmpDir = Join-Path $RootPath "tests_tmp"
    $rows = @()

    foreach ($e in $entries) {
        $comp = $e.Comp
        $shortComp = $e.Short
        $cat = $e.Category
        $mfile = $e.Manifest
        $symCheck = [string][char]0x2705
        $symCross = [string][char]0x274C
        $symQuest = [string][char]0x2753

        $apkStatus = "-"
        $debStatus = "-"
        $rpmStatus = "-"
        $winStatus = "-"
        $sunosStatus = "-"
        $freebsdStatus = "-"
        $macosStatus = "-"

        if ($mfile) {
            if (Check-ManifestSupport $mfile "alpine")  { $apkStatus = $symQuest }
            if (Check-ManifestSupport $mfile "debian")  { $debStatus = $symQuest }
            if (Check-ManifestSupport $mfile "rhel")    { $rpmStatus = $symQuest }
            if (Check-ManifestSupport $mfile "windows") { $winStatus = $symQuest }
            if (Check-ManifestSupport $mfile "sunos")   { $sunosStatus = $symQuest }
            if (Check-ManifestSupport $mfile "freebsd") { $freebsdStatus = $symQuest }
            if (Check-ManifestSupport $mfile "darwin")  { $macosStatus = $symQuest }
        } elseif ($cat -eq "bootloaders") {
            $apkStatus = $symQuest; $debStatus = $symQuest; $rpmStatus = $symQuest; $freebsdStatus = $symQuest
        } elseif ($cat -in @('storage','runtimes','ml-training','topologies','payloads','traits')) {
            $apkStatus = $symQuest; $debStatus = $symQuest; $rpmStatus = $symQuest; $winStatus = $symQuest; $sunosStatus = $symQuest; $freebsdStatus = $symQuest; $macosStatus = $symQuest
        } else {
            $apkStatus = $symQuest; $debStatus = $symQuest; $rpmStatus = $symQuest; $winStatus = $symQuest; $sunosStatus = $symQuest; $freebsdStatus = $symQuest; $macosStatus = $symQuest
        }

        $lookupKey = if ($existingMap.ContainsKey($comp)) { $comp } elseif (-not $comp.Contains("/") -and $existingMap.ContainsKey($shortComp)) { $shortComp } else { "" }
        if ($lookupKey) {
            $ex = $existingMap[$lookupKey]
            if ($ex.apk -and -not $ex.apk.StartsWith('`') -and $apkStatus -ne "-") { $apkStatus = $ex.apk }
            if ($debStatus -ne "-" -and $ex.deb) { $debStatus = $ex.deb }
            if ($rpmStatus -ne "-" -and $ex.rpm) { $rpmStatus = $ex.rpm }
            if ($winStatus -ne "-" -and $ex.win) { $winStatus = $ex.win }
            if ($sunosStatus -ne "-" -and $ex.sunos) { $sunosStatus = $ex.sunos }
            if ($freebsdStatus -ne "-" -and $ex.freebsd) { $freebsdStatus = $ex.freebsd }
            if ($macosStatus -ne "-" -and $ex.macos) { $macosStatus = $ex.macos }
        }

        $idempotent = $false
        if (Test-Path -LiteralPath $testsTmpDir) {
            $markerComp = $shortComp
            if ($comp -eq "freebsd/distro" -or $comp -eq "synthesis/distro/freebsd") { $markerComp = "freebsd-distro" }
            elseif ($comp -eq "illumos/distro" -or $comp -eq "synthesis/distro/illumos") { $markerComp = "illumos-distro" }
            elseif ($comp -eq "reactos/distro" -or $comp -eq "synthesis/distro/reactos") { $markerComp = "reactos-distro" }
            elseif ($comp -eq "dos/distro" -or $comp -eq "synthesis/distro/dos") { $markerComp = "dos-distro" }
            elseif ($comp.StartsWith("bootloaders/")) { $markerComp = "bootloaders-$shortComp" }
            elseif ($comp.StartsWith("workloads/schedulers/")) { $markerComp = "scheduler-$shortComp" }
            elseif ($comp.StartsWith("traits/")) { $markerComp = "trait-$shortComp" }

            if ((Test-AnyFilePattern $testsTmpDir "$markerComp.idempotent.success") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.idempotent.success")) { $idempotent = $true }

            if ((Test-AnyFilePattern $testsTmpDir "$markerComp.linux.alpine.success") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.linux.alpine.success") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.alpine.success") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.apk.success")) { $apkStatus = $symCheck }
            elseif ((Test-AnyFilePattern $testsTmpDir "$markerComp.linux.alpine.skipped") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.linux.alpine.skipped")) { $apkStatus = "-" }
            elseif ((Test-AnyFilePattern $testsTmpDir "$markerComp.linux.alpine.failure") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.linux.alpine.failure") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.alpine.failure") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.apk.failure")) { $apkStatus = $symCross }

            if ((Test-AnyFilePattern $testsTmpDir "$markerComp.linux.debian.success") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.linux.debian.success") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.debian.success") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.deb.success")) { $debStatus = $symCheck }
            elseif ((Test-AnyFilePattern $testsTmpDir "$markerComp.linux.debian.skipped") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.linux.debian.skipped")) { $debStatus = "-" }
            elseif ((Test-AnyFilePattern $testsTmpDir "$markerComp.linux.debian.failure") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.linux.debian.failure") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.debian.failure") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.deb.failure")) { $debStatus = $symCross }

            if ((Test-AnyFilePattern $testsTmpDir "$markerComp.linux.rocky*.success") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.linux.rocky*.success") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.rocky.success") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.rpm.success")) { $rpmStatus = $symCheck }
            elseif ((Test-AnyFilePattern $testsTmpDir "$markerComp.linux.rocky.skipped") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.linux.rocky.skipped")) { $rpmStatus = "-" }
            elseif ((Test-AnyFilePattern $testsTmpDir "$markerComp.linux.rocky*.failure") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.linux.rocky*.failure") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.rocky.failure") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.rpm.failure")) { $rpmStatus = $symCross }

            if ((Test-AnyFilePattern $testsTmpDir "$markerComp.windows*.success") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.windows*.success") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.win*.success")) { $winStatus = $symCheck }
            elseif ((Test-AnyFilePattern $testsTmpDir "$markerComp.windows*.skipped") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.windows*.skipped")) { $winStatus = "-" }
            elseif ((Test-AnyFilePattern $testsTmpDir "$markerComp.windows*.failure") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.windows*.failure") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.win*.failure")) { $winStatus = $symCross }

            if ((Test-AnyFilePattern $testsTmpDir "$markerComp.sunos*.success") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.sunos*.success") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.illumos*.success")) { $sunosStatus = $symCheck }
            elseif ((Test-AnyFilePattern $testsTmpDir "$markerComp.sunos*.skipped") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.sunos*.skipped")) { $sunosStatus = "-" }
            elseif ((Test-AnyFilePattern $testsTmpDir "$markerComp.sunos*.failure") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.sunos*.failure") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.illumos*.failure")) { $sunosStatus = $symCross }

            if ($markerComp -ne $shortComp) {
                if (Test-AnyFilePattern $testsTmpDir "$markerComp.freebsd*.success") { $freebsdStatus = $symCheck }
                elseif (Test-AnyFilePattern $testsTmpDir "$markerComp.freebsd*.skipped") { $freebsdStatus = "-" }
                elseif (Test-AnyFilePattern $testsTmpDir "$markerComp.freebsd*.failure") { $freebsdStatus = $symCross }
            } else {
                if ((Test-AnyFilePattern $testsTmpDir "$shortComp.freebsd*.success") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.bsd*.success")) { $freebsdStatus = $symCheck }
                elseif (Test-AnyFilePattern $testsTmpDir "$shortComp.freebsd*.skipped") { $freebsdStatus = "-" }
                elseif ((Test-AnyFilePattern $testsTmpDir "$shortComp.freebsd*.failure") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.bsd*.failure")) { $freebsdStatus = $symCross }
            }

            if ($markerComp -ne $shortComp) {
                if ((Test-AnyFilePattern $testsTmpDir "$markerComp.darwin*.success") -or (Test-AnyFilePattern $testsTmpDir "$markerComp.macos*.success")) { $macosStatus = $symCheck }
                elseif ((Test-AnyFilePattern $testsTmpDir "$markerComp.darwin*.skipped") -or (Test-AnyFilePattern $testsTmpDir "$markerComp.darwin*.unsupported") -or (Test-AnyFilePattern $testsTmpDir "$markerComp.macos*.skipped")) { $macosStatus = "-" }
                elseif ((Test-AnyFilePattern $testsTmpDir "$markerComp.darwin*.failure") -or (Test-AnyFilePattern $testsTmpDir "$markerComp.macos*.failure")) { $macosStatus = $symCross }
            } else {
                if ((Test-AnyFilePattern $testsTmpDir "$shortComp.darwin*.success") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.macos*.success")) { $macosStatus = $symCheck }
                elseif ((Test-AnyFilePattern $testsTmpDir "$shortComp.darwin*.skipped") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.darwin*.unsupported") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.macos*.skipped")) { $macosStatus = "-" }
                elseif ((Test-AnyFilePattern $testsTmpDir "$shortComp.darwin*.failure") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.macos*.failure")) { $macosStatus = $symCross }
            }
        }

        $rows += [PSCustomObject]@{
            tier       = $e.Tier
            category   = $cat
            component  = $comp
            idempotent = $idempotent
            apk        = $apkStatus
            deb        = $debStatus
            rpm        = $rpmStatus
            windows    = $winStatus
            sunos      = $sunosStatus
            freebsd    = $freebsdStatus
            macos      = $macosStatus
        }
    }

    $tierMeta = @(
        @{ Key = 'T1';     Title = '### T1: Atomic Userland & Daemon Recipes' },
        @{ Key = 'T2';     Title = '### T2: OS, Kernel & System Plumbing Recipes' },
        @{ Key = 'T3';     Title = '### T3: Image, OS & Artifact Synthesis' },
        @{ Key = 'T4';     Title = '### T4: Infrastructure Providers & Cluster Substrates' },
        @{ Key = 'T5';     Title = '### T5: Declarative Workloads, Application Stacks & Stateful Constellations' },
        @{ Key = 'PlaneA'; Title = '### Plane A (Traits): Unified Cross-Cutting Node Traits' }
    )

    $tableLines = @(
        "## Supported Components",
        "",
        'Components are organized into LibScript''s 6 strict compositional tiers (`T0`–`T5`) and orthogonal cross-cutting planes (see [`ARCHITECTURE.md`](ARCHITECTURE.md)).'
    )
    foreach ($tm in $tierMeta) {
        $tableLines += ""
        $tableLines += $tm.Title
        $tableLines += ""
        $tableLines += "| Component | Category | Linux (apk) | Linux (deb) | Linux (rpm) | Windows | SunOS | FreeBSD | macOS |"
        $tableLines += "|---|---|---|---|---|---|---|---|---|"
        foreach ($r in ($rows | Where-Object { $_.tier -eq $tm.Key })) {
            $tableLines += "| ``$($r.component)`` | ``$($r.category)`` | $($r.apk) | $($r.deb) | $($r.rpm) | $($r.windows) | $($r.sunos) | $($r.freebsd) | $($r.macos) |"
        }
    }
    $tableBlock = ($tableLines -join "`n") + "`n"

    if ($ExportJson) {
        $jDir = Split-Path -Parent $ExportJson
        if ($jDir -and -not (Test-Path -LiteralPath $jDir)) {
            New-Item -ItemType Directory -Path $jDir -Force | Out-Null
        }
        $jsonText = ConvertTo-Json -InputObject $rows -Depth 3
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($ExportJson, $jsonText, $utf8NoBom)
    }

    if (Test-Path -LiteralPath $TargetReadme) {
        $content = [System.IO.File]::ReadAllText($TargetReadme, [System.Text.Encoding]::UTF8)
        $pattern = '(?s)## Supported Components.*?(?=\r?\n## |\Z)'
        $newNorm = Normalize-SupportedComponentsSection -Block $tableBlock
        $needsReadmeWrite = $true

        $existingMatch = [regex]::Match($content, $pattern)
        if ($existingMatch.Success) {
            $existingNorm = Normalize-SupportedComponentsSection -Block $existingMatch.Value
            if ($existingNorm -eq $newNorm) {
                $needsReadmeWrite = $false
            } else {
                $replacementBlock = $tableBlock.TrimEnd("`r", "`n")
                $content = ([regex]$pattern).Replace($content, { param($m) $replacementBlock }, 1)
            }
        } elseif ($content -match '(?m)^## License') {
            $content = ([regex]'(?m)^## License').Replace($content, { param($m) "$tableBlock`n## License" }, 1)
        } else {
            $content = $content.TrimEnd("`r", "`n") + "`n`n" + $tableBlock
        }

        if ($needsReadmeWrite) {
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            $lfContent = $content -replace "`r`n", "`n"
            [System.IO.File]::WriteAllText($TargetReadme, $lfContent, $utf8NoBom)

            $localPrettier = Join-Path $RootPath "node_modules\.bin\prettier.cmd"
            $hasPrettierCmd = $null -ne (Get-Command prettier -ErrorAction SilentlyContinue)
            $hasNpxCmd = $null -ne (Get-Command npx -ErrorAction SilentlyContinue)

            $prevErrPref = $ErrorActionPreference
            $ErrorActionPreference = "Continue"
            try {
                if ($hasPrettierCmd) {
                    & prettier --write $TargetReadme >$null 2>&1
                } elseif (Test-Path -LiteralPath $localPrettier) {
                    & $localPrettier --write $TargetReadme >$null 2>&1
                } elseif ($hasNpxCmd) {
                    & npx --yes prettier --write $TargetReadme >$null 2>&1
                }
            } finally {
                $ErrorActionPreference = $prevErrPref
            }

            if (Test-Path -LiteralPath $TargetReadme) {
                $formatted = [System.IO.File]::ReadAllText($TargetReadme, [System.Text.Encoding]::UTF8) -replace "`r`n", "`n"
                [System.IO.File]::WriteAllText($TargetReadme, $formatted, $utf8NoBom)
            }
        }
    }
}

# ## Update-TodoPlan
# Synchronizes pass/fail test results from README.md and tests_tmp into TODO_PLAN.md and TESTING_TODO_PLAN.md.
function Update-TodoPlan {
    param(
        [string]$RootPath,
        [string]$TargetReadme
    )

    $todoFile = Join-Path $RootPath "TODO_PLAN.md"
    $testsTmpDir = Join-Path $RootPath "tests_tmp"
    $readmeMap = @{}
    if ($TargetReadme -and (Test-Path -LiteralPath $TargetReadme)) {
        foreach ($rl in [System.IO.File]::ReadAllLines($TargetReadme, [System.Text.Encoding]::UTF8)) {
            if ($rl -match '^\|\s*`([^`]+)`\s*\|') {
                $parts = $rl -split '\|'
                if ($parts.Count -ge 10) {
                    $cKey = ($parts[1] -replace '[` ]', '').Trim()
                    $readmeMap[$cKey] = @{
                        apk     = $parts[3].Trim()
                        deb     = $parts[4].Trim()
                        rpm     = $parts[5].Trim()
                        windows = $parts[6].Trim()
                        sunos   = $parts[7].Trim()
                        freebsd = $parts[8].Trim()
                    }
                }
            }
        }
    }

    if (Test-Path -LiteralPath $todoFile) {
        $symCheck = [string][char]0x2705
        $todoLines = [System.IO.File]::ReadAllLines($todoFile, [System.Text.Encoding]::UTF8)
        if ($todoLines.Count -gt 0 -and $todoLines[0] -match 'Native Windows & MS-DOS Execution Plan') {
            return
        }
        $newLines = @()
        $todoChanged = $false
        foreach ($line in $todoLines) {
            if ($line -match '^- \[[ x]\] `([^`]+)`:.*OmniOS') {
                $compRef = $Matches[1].Trim()
                $compShort = (Split-Path -Leaf $compRef) -replace '[` ]', ''
                $mc = $compShort
                if ($compRef -eq "synthesis/distro/dos" -or $compRef -eq "dos/distro") { $mc = "dos-distro" }
                elseif ($compRef -eq "synthesis/distro/freebsd" -or $compRef -eq "freebsd/distro") { $mc = "freebsd-distro" }
                elseif ($compRef -eq "synthesis/distro/illumos" -or $compRef -eq "illumos/distro") { $mc = "illumos-distro" }
                elseif ($compRef -eq "synthesis/distro/reactos" -or $compRef -eq "reactos/distro") { $mc = "reactos-distro" }
                $nl = $line
                if (Test-Path -LiteralPath $testsTmpDir) {
                    if ((Test-AnyFilePattern $testsTmpDir "$mc.linux.alpine.success") -or (Test-AnyFilePattern $testsTmpDir "$compShort.linux.alpine.success")) { $nl = $nl -replace '\[ \] Alpine', '[x] Alpine' }
                    if ((Test-AnyFilePattern $testsTmpDir "$mc.linux.debian.success") -or (Test-AnyFilePattern $testsTmpDir "$compShort.linux.debian.success")) { $nl = $nl -replace '\[ \] Debian', '[x] Debian' }
                    if ((Test-AnyFilePattern $testsTmpDir "$mc.linux.rocky*.success") -or (Test-AnyFilePattern $testsTmpDir "$compShort.linux.rocky*.success")) { $nl = $nl -replace '\[ \] Rocky', '[x] Rocky' }
                    if ((Test-AnyFilePattern $testsTmpDir "$mc.windows*.success") -or (Test-AnyFilePattern $testsTmpDir "$compShort.windows*.success")) { $nl = $nl -replace '\[ \] Windows', '[x] Windows' }
                    if ((Test-AnyFilePattern $testsTmpDir "$mc.sunos*.success") -or (Test-AnyFilePattern $testsTmpDir "$compShort.sunos*.success")) { $nl = $nl -replace '\[ \] OmniOS', '[x] OmniOS' }
                    if ((Test-AnyFilePattern $testsTmpDir "$mc.freebsd*.success") -or (Test-AnyFilePattern $testsTmpDir "$compShort.freebsd*.success")) { $nl = $nl -replace '\[ \] FreeBSD', '[x] FreeBSD' }
                    if ((Test-AnyFilePattern $testsTmpDir "$mc.darwin*.success") -or (Test-AnyFilePattern $testsTmpDir "$compShort.darwin*.success")) { $nl = $nl -replace '\[ \] macOS', '[x] macOS' }
                    if ((Test-AnyFilePattern $testsTmpDir "$mc.idempotent.success") -or (Test-AnyFilePattern $testsTmpDir "$compShort.idempotent.success")) { $nl = $nl -replace '\[ \] 2x Idempotent', '[x] 2x Idempotent' }
                }
                $rhs = ($nl -split ':', 2)[1]
                if ($rhs -notmatch '\[ \]') {
                    $nl = $nl -replace '^- \[ \] ', '- [x] '
                }
                if ($nl -ne $line) { $todoChanged = $true }
                $newLines += $nl
            } elseif ($line.StartsWith("- [ ] `_lib/")) {
                $item = $line.Substring(6)
                $compTarget = (($item -split ':')[0] -split ' \(')[0]
                $compName = (Split-Path -Leaf $compTarget) -replace '[` ]', ''
                $hasRes = $false
                if ($compName -and (Test-Path -LiteralPath $testsTmpDir) -and ((Test-AnyFilePattern $testsTmpDir "$compName*.success") -or (Test-AnyFilePattern $testsTmpDir "$compName*.failure"))) {
                    $hasRes = $true
                } elseif ($compName -and $readmeMap.ContainsKey($compName)) {
                    $m = $readmeMap[$compName]
                    if (($m.apk -eq $symCheck) -or ($m.deb -eq $symCheck) -or ($m.rpm -eq $symCheck) -or ($m.windows -eq $symCheck) -or ($m.sunos -eq $symCheck) -or ($m.freebsd -eq $symCheck)) {
                        $hasRes = $true
                    }
                }
                if ($hasRes) {
                    $newLines += "- [x] $item"
                    $todoChanged = $true
                } else {
                    $newLines += $line
                }
            } elseif ($line -match '^- \[ \] `([^`]+)` \(`') {
                $compKey = $Matches[1].Trim()
                $compShort = (Split-Path -Leaf $compKey) -replace '[` ]', ''
                $markerComp = $compShort
                if ($compKey -eq "freebsd/distro") { $markerComp = "freebsd-distro" }
                elseif ($compKey -eq "illumos/distro") { $markerComp = "illumos-distro" }
                elseif ($compKey.StartsWith("bootloaders/")) { $markerComp = "bootloaders-$compShort" }
                elseif ($compKey.StartsWith("workloads/schedulers/")) { $markerComp = "scheduler-$compShort" }
                elseif ($compKey.StartsWith("traits/")) { $markerComp = "trait-$compShort" }
                $item = $line.Substring(6)
                $symCross = [string][char]0x274C
                $hasRes = $false
                if ($line -match 'macOS|Darwin') {
                    if ($compShort -and (Test-Path -LiteralPath $testsTmpDir) -and ((Test-AnyFilePattern $testsTmpDir "$markerComp.darwin.success") -or (Test-AnyFilePattern $testsTmpDir "$markerComp.darwin.failure") -or (Test-AnyFilePattern $testsTmpDir "$markerComp.darwin.skipped") -or (Test-AnyFilePattern $testsTmpDir "$markerComp.darwin.unsupported") -or (Test-AnyFilePattern $testsTmpDir "$compShort.darwin.success") -or (Test-AnyFilePattern $testsTmpDir "$compShort.darwin.failure") -or (Test-AnyFilePattern $testsTmpDir "$compShort.darwin.skipped") -or (Test-AnyFilePattern $testsTmpDir "$compShort.darwin.unsupported"))) {
                        $hasRes = $true
                    }
                } elseif ($line -match 'FreeBSD') {
                    if ($compShort -and (Test-Path -LiteralPath $testsTmpDir) -and ((Test-AnyFilePattern $testsTmpDir "$markerComp.freebsd.success") -or (Test-AnyFilePattern $testsTmpDir "$markerComp.freebsd.failure") -or (Test-AnyFilePattern $testsTmpDir "$markerComp.freebsd.skipped"))) {
                        $hasRes = $true
                    }
                } elseif ($line -match 'OmniOS|SunOS|Verify `-`') {
                    if ($compShort -and (Test-Path -LiteralPath $testsTmpDir) -and ((Test-AnyFilePattern $testsTmpDir "$markerComp.sunos.success") -or (Test-AnyFilePattern $testsTmpDir "$markerComp.sunos.failure") -or (Test-AnyFilePattern $testsTmpDir "$markerComp.sunos.skipped") -or (Test-AnyFilePattern $testsTmpDir "$compShort.sunos.success") -or (Test-AnyFilePattern $testsTmpDir "$compShort.sunos.failure") -or (Test-AnyFilePattern $testsTmpDir "$compShort.sunos.skipped"))) {
                        $hasRes = $true
                    }
                } elseif ($line -match 'Windows') {
                    if ($compShort -and (Test-Path -LiteralPath $testsTmpDir) -and ((Test-AnyFilePattern $testsTmpDir "$markerComp.windows.success") -or (Test-AnyFilePattern $testsTmpDir "$markerComp.windows.failure") -or (Test-AnyFilePattern $testsTmpDir "$markerComp.windows.skipped") -or (Test-AnyFilePattern $testsTmpDir "$compShort.windows.success") -or (Test-AnyFilePattern $testsTmpDir "$compShort.windows.failure") -or (Test-AnyFilePattern $testsTmpDir "$compShort.windows.skipped"))) {
                        $hasRes = $true
                    }
                } elseif ($line -match 'Rocky') {
                    if ($compShort -and (Test-Path -LiteralPath $testsTmpDir) -and ((Test-AnyFilePattern $testsTmpDir "$markerComp.linux.rocky.success") -or (Test-AnyFilePattern $testsTmpDir "$markerComp.linux.rocky.failure") -or (Test-AnyFilePattern $testsTmpDir "$markerComp.linux.rocky.skipped") -or (Test-AnyFilePattern $testsTmpDir "$compShort.linux.rocky.success") -or (Test-AnyFilePattern $testsTmpDir "$compShort.linux.rocky.failure") -or (Test-AnyFilePattern $testsTmpDir "$compShort.linux.rocky.skipped"))) {
                        $hasRes = $true
                    }
                } elseif ($line -match 'Debian') {
                    if ($compShort -and (Test-Path -LiteralPath $testsTmpDir) -and ((Test-AnyFilePattern $testsTmpDir "$markerComp.linux.debian.success") -or (Test-AnyFilePattern $testsTmpDir "$markerComp.linux.debian.failure") -or (Test-AnyFilePattern $testsTmpDir "$markerComp.linux.debian.skipped") -or (Test-AnyFilePattern $testsTmpDir "$compShort.linux.debian.success") -or (Test-AnyFilePattern $testsTmpDir "$compShort.linux.debian.failure") -or (Test-AnyFilePattern $testsTmpDir "$compShort.linux.debian.skipped"))) {
                        $hasRes = $true
                    }
                } else {
                    if ($compShort -and (Test-Path -LiteralPath $testsTmpDir) -and ((Test-AnyFilePattern $testsTmpDir "$markerComp.linux.alpine.success") -or (Test-AnyFilePattern $testsTmpDir "$markerComp.linux.alpine.failure") -or (Test-AnyFilePattern $testsTmpDir "$markerComp.linux.alpine.skipped") -or (Test-AnyFilePattern $testsTmpDir "$compShort.linux.alpine.success") -or (Test-AnyFilePattern $testsTmpDir "$compShort.linux.alpine.failure") -or (Test-AnyFilePattern $testsTmpDir "$compShort.linux.alpine.skipped"))) {
                        $hasRes = $true
                    } elseif ($compKey -and $readmeMap.ContainsKey($compKey)) {
                        $m = $readmeMap[$compKey]
                        if (($m.apk -eq $symCheck) -or ($m.apk -eq "-") -or ($m.apk -eq $symCross)) {
                            $hasRes = $true
                        }
                    }
                }
                if ($hasRes) {
                    $item = $item -replace '\[ \] macOS 27\.2 Vagrant Retest', '[x] macOS 27.2 Vagrant Retest' -replace '\[ \] macOS Vagrant Retest', '[x] macOS Vagrant Retest' -replace '\[ \] FreeBSD Vagrant Retest', '[x] FreeBSD Vagrant Retest' -replace '\[ \] Windows Retest', '[x] Windows Retest' -replace '\[ \] OmniOS Vagrant Retest', '[x] OmniOS Vagrant Retest' -replace '\[ \] Verify `-`', '[x] Verify `-`' -replace '\[ \] Verify `❓` -> Retest', '[x] Verify `❓` -> Retest' -replace '\[ \] Reset `[^`]*` -> `❓`', '[x] Reset `✅` -> `❓`' -replace '\[ \] Reset `[^`]*` ->', '[x] Reset `✅` ->' -replace '\[ \] 2x Idempotent', '[x] 2x Idempotent' -replace '\[ \] `\.sh`/`\.cmd` Parity', '[x] `.sh`/`.cmd` Parity' -replace '\[ \] `Linux \(rpm\)`', '[x] `Linux (rpm)`' -replace '\[ \] \*\*Double-check', '[x] **Double-check'
                    $newLines += "- [x] $item"
                    $todoChanged = $true
                } else {
                    $newLines += $line
                }
            } else {
                $newLines += $line
            }
        }
        if ($todoChanged) {
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($todoFile, (($newLines -join "`n") + "`n"), $utf8NoBom)
        }
    }

    $testingFile = Join-Path $RootPath "TESTING_TODO_PLAN.md"
    if (Test-Path -LiteralPath $testingFile) {
        $symCheck = [string][char]0x2705
        $testLines = [System.IO.File]::ReadAllLines($testingFile, [System.Text.Encoding]::UTF8)
        $outTestLines = @()
        $testingChanged = $false
        foreach ($line in $testLines) {
            if ($line -match '^- \[[ x]\] `([^`]+)`.*:.*OmniOS') {
                $compRef = $Matches[1]
                $compShort = (Split-Path -Leaf $compRef) -replace '[` ]', ''
                $readmeKey = $compShort
                if ($compRef -like "_lib/bootloaders/*") { $readmeKey = "bootloaders/$compShort" }
                elseif ($compRef -eq "synthesis/distro/freebsd") { $readmeKey = "freebsd/distro" }
                elseif ($compRef -eq "synthesis/distro/illumos") { $readmeKey = "illumos/distro" }
                elseif ($compRef -eq "synthesis/disk") { $readmeKey = "storage/provision_disk" }
                elseif ($compRef -eq "synthesis/vfs/provision_isolated_runtime") { $readmeKey = "runtimes/provision_isolated_runtime" }
                elseif (($compRef -like "workloads/*") -or ($compRef -like "synthesis/*") -or ($compRef -like "infrastructure/*") -or ($compRef -like "traits/*")) { $readmeKey = $compRef }

                $rEntry = $null
                if ($readmeMap.ContainsKey($readmeKey)) { $rEntry = $readmeMap[$readmeKey] }
                elseif ($readmeMap.ContainsKey($compShort)) { $rEntry = $readmeMap[$compShort] }

                $newLine = $line
                if (($rEntry -and (($rEntry.sunos -eq $symCheck) -or ($rEntry.sunos -eq "-"))) -or ((Test-Path -LiteralPath $testsTmpDir) -and ((Test-AnyFilePattern $testsTmpDir "$compShort.sunos*.success") -or (Test-AnyFilePattern $testsTmpDir "$compShort.sunos*.skipped")))) {
                    $newLine = $newLine -replace '\[ \] OmniOS', '[x] OmniOS'
                }
                if (($rEntry -and (($rEntry.apk -eq $symCheck) -or ($rEntry.apk -eq "-"))) -or ((Test-Path -LiteralPath $testsTmpDir) -and ((Test-AnyFilePattern $testsTmpDir "$compShort.linux.alpine.success") -or (Test-AnyFilePattern $testsTmpDir "$compShort.*alpine*.skipped")))) {
                    $newLine = $newLine -replace '\[ \] Alpine', '[x] Alpine'
                }
                if (($rEntry -and (($rEntry.deb -eq $symCheck) -or ($rEntry.deb -eq "-"))) -or ((Test-Path -LiteralPath $testsTmpDir) -and ((Test-AnyFilePattern $testsTmpDir "$compShort.linux.debian.success") -or (Test-AnyFilePattern $testsTmpDir "$compShort.*debian*.skipped")))) {
                    $newLine = $newLine -replace '\[ \] Debian', '[x] Debian'
                }
                if (($rEntry -and (($rEntry.rpm -eq $symCheck) -or ($rEntry.rpm -eq "-"))) -or ((Test-Path -LiteralPath $testsTmpDir) -and ((Test-AnyFilePattern $testsTmpDir "$compShort.linux.rocky*.success") -or (Test-AnyFilePattern $testsTmpDir "$compShort.*rocky*.skipped")))) {
                    $newLine = $newLine -replace '\[ \] Rocky', '[x] Rocky'
                }
                if (($rEntry -and (($rEntry.freebsd -eq $symCheck) -or ($rEntry.freebsd -eq "-"))) -or ((Test-Path -LiteralPath $testsTmpDir) -and ((Test-AnyFilePattern $testsTmpDir "$compShort.freebsd*.success") -or (Test-AnyFilePattern $testsTmpDir "$compShort.freebsd*.skipped")))) {
                    $newLine = $newLine -replace '\[ \] FreeBSD', '[x] FreeBSD'
                }
                if (($rEntry -and (($rEntry.windows -eq $symCheck) -or ($rEntry.windows -eq "-"))) -or ((Test-Path -LiteralPath $testsTmpDir) -and ((Test-AnyFilePattern $testsTmpDir "$compShort.windows*.success") -or (Test-AnyFilePattern $testsTmpDir "$compShort.windows*.skipped")))) {
                    $newLine = $newLine -replace '\[ \] Windows', '[x] Windows'
                }
                if (((Test-Path -LiteralPath $testsTmpDir) -and (Test-AnyFilePattern $testsTmpDir "$compShort.idempotent.success")) -or ($newLine -notmatch '\[ \] (OmniOS|Alpine|Debian|Rocky|FreeBSD|Windows)')) {
                    $newLine = $newLine -replace '\[ \] 2x Idempotent', '[x] 2x Idempotent'
                }
                $afterColon = ($newLine -split ':', 2)[1]
                if ($afterColon -and ($afterColon -notmatch '\[ \]')) {
                    $newLine = $newLine -replace '^- \[ \] ', '- [x] '
                }
                if ($newLine -ne $line) { $testingChanged = $true }
                $outTestLines += $newLine
            } else {
                $outTestLines += $line
            }
        }
        if ($testingChanged) {
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($testingFile, (($outTestLines -join "`n") + "`n"), $utf8NoBom)
        }
    }
}

Update-SupportedComponents -RootPath $repoRoot -TargetReadme $outputFile -ExportJson $jsonFile
if ($syncPlans) {
    Update-TodoPlan -RootPath $repoRoot -TargetReadme $outputFile
}
Write-Host "Done updating Supported Components in README.md."
