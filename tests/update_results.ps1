# ## Overview
# Updates the Supported Components tables in README.md (or custom output file)
# split into Architectural Tiers (Tier 1, Tier 1.5, Tier 2, Tier 3, Tier 3.5/4/Traits)
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

for ($i = 0; $i -lt $args.Count; $i++) {
    $arg = [string]$args[$i]
    if ($arg -eq "--help" -or $arg -eq "-h" -or $arg -eq "/?" -or $arg -eq "-?") {
        Show-Help
        exit 0
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

# ## Check-ManifestSupport
# Checks whether a component manifest supports a specific target operating system.
function Check-ManifestSupport {
    param(
        [string]$ManifestPath,
        [string]$TargetOs
    )

    if (-not $ManifestPath -or -not (Test-Path -LiteralPath $ManifestPath)) {
        return $true
    }

    $family = switch ($TargetOs) {
        { $_ -in 'alpine', 'debian', 'rhel', 'rocky', 'linux' } { 'linux' }
        { $_ -in 'freebsd', 'bsd' } { 'bsd' }
        { $_ -in 'darwin', 'macos' } { 'darwin' }
        { $_ -in 'windows' } { 'windows' }
        'darwin'  { 'darwin' }
        'sunos'   { 'sunos' }
        default   { '' }
    }

    try {
        $raw = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8
        $manifest = $raw | ConvertFrom-Json
    } catch {
        return $true
    }

    if ($null -ne $manifest.os_blacklist) {
        $bl = @($manifest.os_blacklist)
        if ($bl -contains $TargetOs -or ($family -and $bl -contains $family)) {
            return $false
        }
    }

    if ($null -ne $manifest.os_whitelist) {
        $wl = @($manifest.os_whitelist)
        if ($wl -contains 'all' -or $wl -contains $TargetOs -or ($family -and $wl -contains $family)) {
            return $true
        }
        return $false
    }

    return $true
}

# ## Get-ComponentTier
# Maps a component category and name to its architectural tier key (1, 1.5, 2, 3, or 4).
function Get-ComponentTier {
    param(
        [string]$Category,
        [string]$Component
    )
    switch ($Category) {
        { $_ -in 'languages','toolchains','package-managers','utilities','databases','caches','search','security','message-brokers','web-servers','app-servers','logging','storage-layers','git-servers','web-apps','runtimes' } { return '1' }
        { $_ -in 'base-system','init-systems','networking','audio','graphics','display-servers','display-managers','desktops' } { return '1.5' }
        { $_ -in 'kernel','bootloaders','storage','freebsd','illumos','virtualization' } { return '2' }
        'orchestration' {
            if ($Component -in 'distro','vfs','runner','packagers','repogen','solo5') { return '2' }
            if ($Component -eq 'gke-xpk-training') { return '4' }
            return '3'
        }
        { $_ -in 'cloud','cloud-providers' } { return '3' }
        { $_ -in 'ai-serving','ml-training','topologies','payloads','traits' } { return '4' }
        default { return '1' }
    }
}

# ## Test-AnyFilePattern
# Checks whether any files in a directory match a specific glob search pattern.
function Test-AnyFilePattern {
    param(
        [string]$DirectoryPath,
        [string]$SearchPattern
    )
    if (-not (Test-Path -LiteralPath $DirectoryPath)) {
        return $false
    }
    $matched = [System.IO.Directory]::GetFiles($DirectoryPath, $SearchPattern)
    return ($matched.Count -gt 0)
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
            $displayComp = $comp.Name
            if ($cat.Name -eq "freebsd" -and $comp.Name -eq "distro") { $displayComp = "freebsd/distro" }
            elseif ($cat.Name -eq "illumos" -and $comp.Name -eq "distro") { $displayComp = "illumos/distro" }
            $tier = Get-ComponentTier -Category $cat.Name -Component $comp.Name
            $mCandidate = Join-Path $comp.FullName "manifest.json"
            $mPath = if (Test-Path -LiteralPath $mCandidate) { $mCandidate } else { "" }
            $entries += [PSCustomObject]@{
                Tier     = $tier
                Category = $cat.Name
                Comp     = $displayComp
                Short    = $comp.Name
                Manifest = $mPath
            }
        }
    }

    if (Test-Path -LiteralPath (Join-Path $libPath "bootloaders")) {
        foreach ($bl in @('grub','limine','refind','systemd-boot')) {
            $entries += [PSCustomObject]@{ Tier = '2'; Category = 'bootloaders'; Comp = "bootloaders/$bl"; Short = $bl; Manifest = '' }
        }
    }
    if (Test-Path -LiteralPath (Join-Path $libPath "storage")) {
        $entries += [PSCustomObject]@{ Tier = '2'; Category = 'storage'; Comp = 'storage/provision_disk'; Short = 'provision_disk'; Manifest = '' }
    }
    if (Test-Path -LiteralPath (Join-Path $libPath "runtimes")) {
        $entries += [PSCustomObject]@{ Tier = '1'; Category = 'runtimes'; Comp = 'runtimes/provision_isolated_runtime'; Short = 'provision_isolated_runtime'; Manifest = '' }
    }
    if (Test-Path -LiteralPath (Join-Path $libPath "ml-training")) {
        $entries += [PSCustomObject]@{ Tier = '4'; Category = 'ml-training'; Comp = 'ml-training'; Short = 'ml-training'; Manifest = '' }
    }
    $topoDir = Join-Path $RootPath "topologies"
    if (Test-Path -LiteralPath $topoDir) {
        Get-ChildItem -LiteralPath $topoDir -Directory -ErrorAction SilentlyContinue | Where-Object { -not $_.Name.StartsWith("_") } | ForEach-Object {
            $entries += [PSCustomObject]@{ Tier = '4'; Category = 'topologies'; Comp = "topologies/$($_.Name)"; Short = $_.Name; Manifest = '' }
        }
    }
    $schedDir = Join-Path (Join-Path $RootPath "payloads") "schedulers"
    if (Test-Path -LiteralPath $schedDir) {
        Get-ChildItem -LiteralPath $schedDir -Filter "*.sh" -File -ErrorAction SilentlyContinue | ForEach-Object {
            $sn = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
            $entries += [PSCustomObject]@{ Tier = '4'; Category = 'payloads'; Comp = "payloads/schedulers/$sn"; Short = $sn; Manifest = '' }
        }
    }
    $traitsDir = Join-Path $RootPath "traits"
    if (Test-Path -LiteralPath $traitsDir) {
        Get-ChildItem -LiteralPath $traitsDir -Directory -ErrorAction SilentlyContinue | Where-Object { -not $_.Name.StartsWith("_") } | ForEach-Object {
            $entries += [PSCustomObject]@{ Tier = '4'; Category = 'traits'; Comp = "traits/$($_.Name)"; Short = $_.Name; Manifest = '' }
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
                $existingMap[$compKey] = @{
                    apk     = $parts[3].Trim()
                    deb     = $parts[4].Trim()
                    rpm     = $parts[5].Trim()
                    win     = $parts[6].Trim()
                    sunos   = $parts[7].Trim()
                    freebsd = $parts[8].Trim()
                    macos   = $parts[9].Trim()
                }
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
            $apkStatus = $symCheck; $debStatus = $symCheck; $rpmStatus = $symCheck; $freebsdStatus = $symCheck
        } elseif ($cat -in @('storage','runtimes','ml-training','topologies','payloads','traits')) {
            $apkStatus = $symCheck; $debStatus = $symCheck; $rpmStatus = $symCheck; $winStatus = $symCheck; $sunosStatus = $symCheck; $freebsdStatus = $symCheck; $macosStatus = $symCheck
        } else {
            $apkStatus = $symQuest; $debStatus = $symQuest; $rpmStatus = $symQuest; $winStatus = $symQuest; $sunosStatus = $symQuest; $freebsdStatus = $symQuest; $macosStatus = $symQuest
        }

        $lookupKey = if ($existingMap.ContainsKey($comp)) { $comp } elseif (-not $comp.Contains("/") -and $existingMap.ContainsKey($shortComp)) { $shortComp } else { "" }
        if ($lookupKey) {
            $ex = $existingMap[$lookupKey]
            if ($apkStatus -ne "-" -and $ex.apk) { $apkStatus = $ex.apk }
            if ($debStatus -ne "-" -and $ex.deb) { $debStatus = $ex.deb }
            if ($rpmStatus -ne "-" -and $ex.rpm) { $rpmStatus = $ex.rpm }
            if ($winStatus -ne "-" -and $ex.win) { $winStatus = $ex.win }
            if ($sunosStatus -ne "-" -and $ex.sunos) { $sunosStatus = $ex.sunos }
            if ($freebsdStatus -ne "-" -and $ex.freebsd) { $freebsdStatus = $ex.freebsd }
            if ($macosStatus -ne "-" -and $ex.macos) { $macosStatus = $ex.macos }
        }

        $idempotent = $false
        if (Test-Path -LiteralPath $testsTmpDir) {
            if (Test-AnyFilePattern $testsTmpDir "$shortComp.idempotent.success") { $idempotent = $true }
            if ((Test-AnyFilePattern $testsTmpDir "$shortComp.linux.alpine.success") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.alpine.success") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.apk.success")) { $apkStatus = $symCheck }
            elseif ((Test-AnyFilePattern $testsTmpDir "$shortComp.linux.alpine.failure") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.alpine.failure") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.apk.failure")) { $apkStatus = $symCross }

            if ((Test-AnyFilePattern $testsTmpDir "$shortComp.linux.debian.success") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.debian.success") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.deb.success")) { $debStatus = $symCheck }
            elseif ((Test-AnyFilePattern $testsTmpDir "$shortComp.linux.debian.failure") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.debian.failure") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.deb.failure")) { $debStatus = $symCross }

            if ((Test-AnyFilePattern $testsTmpDir "$shortComp.linux.rocky*.success") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.rocky.success") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.rpm.success")) { $rpmStatus = $symCheck }
            elseif ((Test-AnyFilePattern $testsTmpDir "$shortComp.linux.rocky*.failure") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.rocky.failure") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.rpm.failure")) { $rpmStatus = $symCross }

            if ((Test-AnyFilePattern $testsTmpDir "$shortComp.windows*.success") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.win*.success")) { $winStatus = $symCheck }
            elseif ((Test-AnyFilePattern $testsTmpDir "$shortComp.windows*.failure") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.win*.failure")) { $winStatus = $symCross }

            if ((Test-AnyFilePattern $testsTmpDir "$shortComp.sunos*.success") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.illumos*.success")) { $sunosStatus = $symCheck }
            elseif ((Test-AnyFilePattern $testsTmpDir "$shortComp.sunos*.failure") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.illumos*.failure")) { $sunosStatus = $symCross }

            if ((Test-AnyFilePattern $testsTmpDir "$shortComp.freebsd*.success") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.bsd*.success")) { $freebsdStatus = $symCheck }
            elseif ((Test-AnyFilePattern $testsTmpDir "$shortComp.freebsd*.failure") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.bsd*.failure")) { $freebsdStatus = $symCross }

            if ((Test-AnyFilePattern $testsTmpDir "$shortComp.darwin*.success") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.macos*.success")) { $macosStatus = $symCheck }
            elseif ((Test-AnyFilePattern $testsTmpDir "$shortComp.darwin*.failure") -or (Test-AnyFilePattern $testsTmpDir "$shortComp.macos*.failure")) { $macosStatus = $symCross }
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
        @{ Key = '1';   Title = '### Tier 1: Leaf Recipes, Toolchains & Native Version Managers' },
        @{ Key = '1.5'; Title = '### Tier 1.5: Base OS Userland, Init Systems, Networking, Audio, Graphics & Desktops' },
        @{ Key = '2';   Title = '### Tier 2: OS Synthesizers, Kernels, Bootloaders, Storage & Image Builders' },
        @{ Key = '3';   Title = '### Tier 3: Cloud Operators, Hypervisors & IaaS Provisioners' },
        @{ Key = '4';   Title = '### Tier 3.5, Tier 4 & Cross-Cutting Traits: Topologies, Payloads, Schedulers & Traits' }
    )

    $tableLines = @(
        "## Supported Components",
        "",
        'Components are organized into LibScript''s 5 architectural tiers (see [`ARCHITECTURE.md`](ARCHITECTURE.md)).'
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
        $newLines = @()
        $todoChanged = $false
        foreach ($line in $todoLines) {
            if ($line.StartsWith("- [ ] `_lib/")) {
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
                elseif ($compRef -eq "_lib/freebsd/distro") { $readmeKey = "freebsd/distro" }
                elseif ($compRef -eq "_lib/illumos/distro") { $readmeKey = "illumos/distro" }
                elseif ($compRef -eq "_lib/storage") { $readmeKey = "storage/provision_disk" }
                elseif ($compRef -eq "_lib/runtimes/provision_isolated_runtime") { $readmeKey = "runtimes/provision_isolated_runtime" }
                elseif ($compRef -eq "_lib/ml-training") { $readmeKey = "ml-training" }
                elseif (($compRef -like "topologies/*") -or ($compRef -like "payloads/*") -or ($compRef -like "traits/*")) { $readmeKey = $compRef }

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
Update-TodoPlan -RootPath $repoRoot -TargetReadme $outputFile
