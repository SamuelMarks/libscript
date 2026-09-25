# ## Overview
# Updates the Supported Components table in README.md (or custom output file)
# with test results from tests_tmp/, updates task completion in TODO_PLAN.md if present,
# and optionally exports an aggregated JSON test results matrix on Windows/PowerShell.
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
    Write-Host "and updates the Supported Components table in README.md."
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  REPO_ROOT              Target repository root path (default: auto-detected)."
    Write-Host "  --output <file>        Custom markdown file to update (default: README.md)."
    Write-Host "  --json [json_file]     Export matrix results as JSON (default: tests_tmp/matrix_results.json)."
    Write-Host "  --help, -h, /?         Show this help message."
}

# Parse command line arguments
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

    if (-not (Test-Path -LiteralPath $ManifestPath)) {
        return $true
    }

    $family = switch ($TargetOs) {
        { $_ -in 'alpine', 'debian', 'rhel', 'rocky', 'linux' } { 'linux' }
        { $_ -in 'freebsd', 'bsd' } { 'bsd' }
        'windows' { 'windows' }
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

# ## Update-SupportedComponents
# Aggregates component test markers and updates the Supported Components table in README.md.
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

    $searchDirs = @()
    if (Test-Path -LiteralPath $libPath) { $searchDirs += $libPath }
    $stacksPath = Join-Path $RootPath "stacks"
    if (Test-Path -LiteralPath $stacksPath) { $searchDirs += $stacksPath }

    $componentNames = @()
    $manifestMap = @{}

    foreach ($baseDir in $searchDirs) {
        $cats = Get-ChildItem -LiteralPath $baseDir -Directory -ErrorAction SilentlyContinue | Where-Object { -not $_.Name.StartsWith("_") }
        foreach ($cat in $cats) {
            $comps = Get-ChildItem -LiteralPath $cat.FullName -Directory -ErrorAction SilentlyContinue | Where-Object { -not $_.Name.StartsWith("_") }
            foreach ($comp in $comps) {
                $componentNames += $comp.Name
                $mCandidate = Join-Path $comp.FullName "manifest.json"
                if (-not $manifestMap.ContainsKey($comp.Name) -and (Test-Path -LiteralPath $mCandidate)) {
                    $manifestMap[$comp.Name] = $mCandidate
                }
            }
        }
    }

    $componentNames = $componentNames | Select-Object -Unique | Sort-Object

    $existingMap = @{}
    if (Test-Path -LiteralPath $TargetReadme) {
        $existingLines = [System.IO.File]::ReadAllLines($TargetReadme, [System.Text.Encoding]::UTF8)
        foreach ($line in $existingLines) {
            if ($line -match '^\s*\|\s*`([^`]+)`\s*\|\s*([^|]+)\|\s*([^|]+)\|\s*([^|]+)\|\s*([^|]+)\|\s*([^|]+)\|\s*([^|]+)\|') {
                $compKey = $Matches[1].Trim()
                $existingMap[$compKey] = @{
                    apk     = $Matches[2].Trim()
                    deb     = $Matches[3].Trim()
                    rpm     = $Matches[4].Trim()
                    win     = $Matches[5].Trim()
                    sunos   = $Matches[6].Trim()
                    freebsd = $Matches[7].Trim()
                }
            }
        }
    }

    $testsTmpDir = Join-Path $RootPath "tests_tmp"
    $rows = @()

    foreach ($comp in $componentNames) {
        $mfile = $manifestMap[$comp]

        $apkStatus = "-"
        $debStatus = "-"
        $rpmStatus = "-"
        $winStatus = "-"
        $sunosStatus = "-"
        $freebsdStatus = "-"

        if ($mfile) {
            if (Check-ManifestSupport $mfile "alpine")  { $apkStatus = "❓" }
            if (Check-ManifestSupport $mfile "debian")  { $debStatus = "❓" }
            if (Check-ManifestSupport $mfile "rhel")    { $rpmStatus = "❓" }
            if (Check-ManifestSupport $mfile "windows") { $winStatus = "❓" }
            if (Check-ManifestSupport $mfile "sunos")   { $sunosStatus = "❓" }
            if (Check-ManifestSupport $mfile "freebsd") { $freebsdStatus = "❓" }
        } else {
            $apkStatus = "❓"
            $debStatus = "❓"
            $rpmStatus = "❓"
            $winStatus = "❓"
            $sunosStatus = "❓"
            $freebsdStatus = "❓"
        }

        if ($existingMap.ContainsKey($comp)) {
            $ex = $existingMap[$comp]
            if ($apkStatus -ne "-" -and $ex.apk) { $apkStatus = $ex.apk }
            if ($debStatus -ne "-" -and $ex.deb) { $debStatus = $ex.deb }
            if ($rpmStatus -ne "-" -and $ex.rpm) { $rpmStatus = $ex.rpm }
            if ($winStatus -ne "-" -and $ex.win) { $winStatus = $ex.win }
            if ($sunosStatus -ne "-" -and $ex.sunos) { $sunosStatus = $ex.sunos }
            if ($freebsdStatus -ne "-" -and $ex.freebsd) { $freebsdStatus = $ex.freebsd }
        }

        if (Test-Path -LiteralPath $testsTmpDir) {
            # Alpine / apk
            if ((Test-AnyFilePattern $testsTmpDir "$comp.linux.alpine.success") -or
                (Test-AnyFilePattern $testsTmpDir "$comp.alpine.success") -or
                (Test-AnyFilePattern $testsTmpDir "$comp.apk.success")) {
                $apkStatus = "✅"
            } elseif ((Test-AnyFilePattern $testsTmpDir "$comp.linux.alpine.failure") -or
                      (Test-AnyFilePattern $testsTmpDir "$comp.alpine.failure") -or
                      (Test-AnyFilePattern $testsTmpDir "$comp.apk.failure")) {
                $apkStatus = "❌"
            }

            # Debian / Ubuntu / deb
            if ((Test-AnyFilePattern $testsTmpDir "$comp.linux.debian.success") -or
                (Test-AnyFilePattern $testsTmpDir "$comp.linux.ubuntu.success") -or
                (Test-AnyFilePattern $testsTmpDir "$comp.debian.success") -or
                (Test-AnyFilePattern $testsTmpDir "$comp.ubuntu.success") -or
                (Test-AnyFilePattern $testsTmpDir "$comp.deb.success")) {
                $debStatus = "✅"
            } elseif ((Test-AnyFilePattern $testsTmpDir "$comp.linux.debian.failure") -or
                      (Test-AnyFilePattern $testsTmpDir "$comp.linux.ubuntu.failure") -or
                      (Test-AnyFilePattern $testsTmpDir "$comp.debian.failure") -or
                      (Test-AnyFilePattern $testsTmpDir "$comp.ubuntu.failure") -or
                      (Test-AnyFilePattern $testsTmpDir "$comp.deb.failure")) {
                $debStatus = "❌"
            }

            # RHEL / Fedora / AlmaLinux / CentOS / Rocky Linux / rpm
            if ((Test-AnyFilePattern $testsTmpDir "$comp.linux.rhel.success") -or
                (Test-AnyFilePattern $testsTmpDir "$comp.linux.fedora.success") -or
                (Test-AnyFilePattern $testsTmpDir "$comp.linux.almalinux.success") -or
                (Test-AnyFilePattern $testsTmpDir "$comp.linux.centos.success") -or
                (Test-AnyFilePattern $testsTmpDir "$comp.linux.rocky*.success") -or
                (Test-AnyFilePattern $testsTmpDir "$comp.rhel.success") -or
                (Test-AnyFilePattern $testsTmpDir "$comp.fedora.success") -or
                (Test-AnyFilePattern $testsTmpDir "$comp.almalinux.success") -or
                (Test-AnyFilePattern $testsTmpDir "$comp.centos.success") -or
                (Test-AnyFilePattern $testsTmpDir "$comp.rocky.success") -or
                (Test-AnyFilePattern $testsTmpDir "$comp.rockylinux.success") -or
                (Test-AnyFilePattern $testsTmpDir "$comp.rpm.success")) {
                $rpmStatus = "✅"
            } elseif ((Test-AnyFilePattern $testsTmpDir "$comp.linux.rhel.failure") -or
                      (Test-AnyFilePattern $testsTmpDir "$comp.linux.fedora.failure") -or
                      (Test-AnyFilePattern $testsTmpDir "$comp.linux.almalinux.failure") -or
                      (Test-AnyFilePattern $testsTmpDir "$comp.linux.centos.failure") -or
                      (Test-AnyFilePattern $testsTmpDir "$comp.linux.rocky*.failure") -or
                      (Test-AnyFilePattern $testsTmpDir "$comp.rhel.failure") -or
                      (Test-AnyFilePattern $testsTmpDir "$comp.fedora.failure") -or
                      (Test-AnyFilePattern $testsTmpDir "$comp.almalinux.failure") -or
                      (Test-AnyFilePattern $testsTmpDir "$comp.centos.failure") -or
                      (Test-AnyFilePattern $testsTmpDir "$comp.rocky.failure") -or
                      (Test-AnyFilePattern $testsTmpDir "$comp.rockylinux.failure") -or
                      (Test-AnyFilePattern $testsTmpDir "$comp.rpm.failure")) {
                $rpmStatus = "❌"
            }

            # Windows
            if ((Test-AnyFilePattern $testsTmpDir "$comp.windows*.success") -or
                (Test-AnyFilePattern $testsTmpDir "$comp.win*.success")) {
                $winStatus = "✅"
            } elseif ((Test-AnyFilePattern $testsTmpDir "$comp.windows*.failure") -or
                      (Test-AnyFilePattern $testsTmpDir "$comp.win*.failure")) {
                $winStatus = "❌"
            }

            # SunOS / Solaris / Illumos
            if ((Test-AnyFilePattern $testsTmpDir "$comp.sunos*.success") -or
                (Test-AnyFilePattern $testsTmpDir "$comp.solaris*.success") -or
                (Test-AnyFilePattern $testsTmpDir "$comp.illumos*.success")) {
                $sunosStatus = "✅"
            } elseif ((Test-AnyFilePattern $testsTmpDir "$comp.sunos*.failure") -or
                      (Test-AnyFilePattern $testsTmpDir "$comp.solaris*.failure") -or
                      (Test-AnyFilePattern $testsTmpDir "$comp.illumos*.failure")) {
                $sunosStatus = "❌"
            }

            # FreeBSD / BSD
            if ((Test-AnyFilePattern $testsTmpDir "$comp.freebsd*.success") -or
                (Test-AnyFilePattern $testsTmpDir "$comp.bsd*.success") -or
                (Test-AnyFilePattern $testsTmpDir "$comp.linux.freebsd*.success")) {
                $freebsdStatus = "✅"
            } elseif ((Test-AnyFilePattern $testsTmpDir "$comp.freebsd*.failure") -or
                      (Test-AnyFilePattern $testsTmpDir "$comp.bsd*.failure") -or
                      (Test-AnyFilePattern $testsTmpDir "$comp.linux.freebsd*.failure")) {
                $freebsdStatus = "❌"
            }
        }

        $rows += [PSCustomObject]@{
            comp    = $comp
            apk     = $apkStatus
            deb     = $debStatus
            rpm     = $rpmStatus
            win     = $winStatus
            sunos   = $sunosStatus
            freebsd = $freebsdStatus
        }
    }

    # Generate Markdown Table
    $tableLines = @(
        "## Supported Components",
        "",
        "| Component | Linux (apk) | Linux (deb) | Linux (rpm) | Windows | SunOS | FreeBSD |",
        "|---|---|---|---|---|---|---|"
    )
    foreach ($r in $rows) {
        $tableLines += "| ``$($r.comp)`` | $($r.apk) | $($r.deb) | $($r.rpm) | $($r.win) | $($r.sunos) | $($r.freebsd) |"
    }
    $tableBlock = ($tableLines -join "`n") + "`n"

    # Export JSON if requested
    if ($ExportJson) {
        $jDir = Split-Path -Parent $ExportJson
        if ($jDir -and -not (Test-Path -LiteralPath $jDir)) {
            New-Item -ItemType Directory -Path $jDir -Force | Out-Null
        }
        $jsonItems = @()
        foreach ($r in $rows) {
            $jsonItems += [PSCustomObject]@{
                component = $r.comp
                apk       = $r.apk
                deb       = $r.deb
                rpm       = $r.rpm
                windows   = $r.win
                sunos     = $r.sunos
                freebsd   = $r.freebsd
            }
        }
        $jsonText = ConvertTo-Json -InputObject $jsonItems -Depth 3
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($ExportJson, $jsonText, $utf8NoBom)
    }

    # Update Readme file
    if (Test-Path -LiteralPath $TargetReadme) {
        $content = [System.IO.File]::ReadAllText($TargetReadme, [System.Text.Encoding]::UTF8)
        $pattern = '(?s)## Supported Components.*?(?=\r?\n## |\Z)'
        if ($content -match $pattern) {
            $content = [regex]::Replace($content, $pattern, $tableBlock.TrimEnd("`r", "`n"))
        } elseif ($content -match '(?m)^## License') {
            $content = [regex]::Replace($content, '(?m)^## License', "$tableBlock`n## License")
        } else {
            $content = $content.TrimEnd("`r", "`n") + "`n`n" + $tableBlock
        }

        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($TargetReadme, $content, $utf8NoBom)

        if (Get-Command npx -ErrorAction SilentlyContinue) {
            & npx --yes prettier --write $TargetReadme >$null 2>&1
        }
    }
}

# ## Update-TodoPlan
# Synchronizes pass/fail test results from tests_tmp into TODO_PLAN.md.
function Update-TodoPlan {
    param(
        [string]$RootPath
    )

    $todoFile = Join-Path $RootPath "TODO_PLAN.md"
    $testsTmpDir = Join-Path $RootPath "tests_tmp"

    if (-not (Test-Path -LiteralPath $todoFile) -or -not (Test-Path -LiteralPath $testsTmpDir)) {
        return
    }

    $todoLines = [System.IO.File]::ReadAllLines($todoFile, [System.Text.Encoding]::UTF8)
    $newLines = @()
    $currentComp = ""

    foreach ($line in $todoLines) {
        if ($line.StartsWith("- [ ] ")) {
            $item = $line.Substring(6)
            $compTarget = ($item -split ':')[0]
            $compTarget = ($compTarget -split ' \(')[0]
            $compName = (Split-Path -Leaf $compTarget) -replace '[` ]', ''
            $currentComp = $compName
            if ($compName -and ((Test-AnyFilePattern $testsTmpDir "$compName*.success") -or (Test-AnyFilePattern $testsTmpDir "$compName*.failure"))) {
                $newLines += "- [x] $item"
            } else {
                $newLines += $line
            }
        } elseif ($line.StartsWith("- [x] ")) {
            $item = $line.Substring(6)
            $compTarget = ($item -split ':')[0]
            $compTarget = ($compTarget -split ' \(')[0]
            $compName = (Split-Path -Leaf $compTarget) -replace '[` ]', ''
            $currentComp = $compName
            $newLines += $line
        } elseif ($line -like "*[ ] **Double-check & Idempotency Verified (2x run)***") {
            if ($currentComp -and (Test-AnyFilePattern $testsTmpDir "$currentComp.idempotent.success")) {
                $newLines += "  - [x] **Double-check & Idempotency Verified (2x run)**"
            } else {
                $newLines += $line
            }
        } else {
            $newLines += $line
        }
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllLines($todoFile, $newLines, $utf8NoBom)
}

Update-SupportedComponents -RootPath $repoRoot -TargetReadme $outputFile -ExportJson $jsonFile
Update-TodoPlan -RootPath $repoRoot
