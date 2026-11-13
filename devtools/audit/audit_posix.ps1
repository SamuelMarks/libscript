# ## Overview
# Audits shell scripts across the repository for strict POSIX compliance:
# ensures #!/bin/sh shebang, set -feu, absence of bashisms, canonical THIS_FILE=
# resolution dance, and matching Windows batch (.cmd / .bat) companion scripts.
#
# ## Usage
# powershell.exe -File devtools\audit\audit_posix.ps1 [--all | --staged | file1.sh ...]

<#
.SYNOPSIS
PowerShell POSIX compliance, bashism prohibition, and companion parity auditor for LibScript.
#>

$ErrorActionPreference = 'Stop'

# ## Show-Help
# Displays command-line usage instructions for the POSIX compliance auditor.
function Show-Help {
    Write-Host 'Usage: audit_posix.ps1 [--all | --staged | <file>...]'
    Write-Host 'Audits shell scripts for strict POSIX /bin/sh compliance and Windows Batch companion parity.'
    Write-Host ''
    Write-Host 'Options:'
    Write-Host '  --all               Audit all tracked .sh and .cmd/.bat scripts (default).'
    Write-Host '  --staged            Audit git-staged POSIX shell scripts.'
    Write-Host '  --help, -h, /?, -?  Show this help message.'
}

if ($args -contains '--help' -or $args -contains '-h' -or $args -contains '/?' -or $args -contains '-?') {
    Show-Help
    exit 0
}

$origPwd = (Get-Location).Path
$rootDir = if ($env:LIBSCRIPT_ROOT_DIR) { (Resolve-Path $env:LIBSCRIPT_ROOT_DIR).Path } else { (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path }
Set-Location $rootDir

Write-Host '=== LibScript POSIX Compliance & Bashism Prohibition Audit ==='

$script:errorsCount = 0

# ## Add-AuditError
# Emits a formatted POSIX audit violation message to stderr and increments error count.
function Add-AuditError {
    param(
        [string]$File,
        [string]$Message
    )
    [Console]::Error.WriteLine("[FAIL] [$File] $Message")
    $script:errorsCount++
}

# ## Test-ShellScriptPosix
# Audits a single POSIX shell script for shebang, set -feu, THIS_FILE, bashisms, and non-POSIX constructs.
function Test-ShellScriptPosix {
    param([string]$RelPath)

    $norm = $RelPath.Replace([char]92, [char]47)
    if ($norm -match '(^|/)devtools/audit/audit_posix\.sh$') {
        return
    }
    $fullPath = if ([System.IO.Path]::IsPathRooted($RelPath)) { $RelPath } else { Join-Path $rootDir $RelPath }
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        return
    }

    $rawBytes = [System.IO.File]::ReadAllBytes($fullPath)
    if ([Array]::IndexOf($rawBytes, [byte]13) -ge 0) {
        Add-AuditError -File $norm -Message 'Literal carriage return (CRLF) detected in POSIX shell script; enforce LF line endings.'
    }

    $lines = [System.IO.File]::ReadAllLines($fullPath, [System.Text.Encoding]::UTF8)
    if ($lines.Length -eq 0) {
        Add-AuditError -File $norm -Message 'Empty script file (missing #!/bin/sh).'
        return
    }

    $firstLine = $lines[0]
    if ($firstLine -ne '#!/bin/sh') {
        Add-AuditError -File $norm -Message "Line 1 must be #!/bin/sh (found: $firstLine)"
    }

    $hasFeu = $false
    $hasThis = $false
    $badStackQuote = $false
    $unreachableStack = $false
    $hasDblBracket = $false
    $hasFuncKw = $false
    $hasSourceKw = $false
    $hasEchoE = $false
    $hasSortV = $false
    $hasSedI = $false
    $hasGnuBre = $false
    $dqHit = ''
    $sc2015Hit = ''
    $hasUnguardedHome = $false

    $inHd = $false
    $hdDelim = ''
    $hdTab = $false
    $sawRetLine = -10
    $isEnvSh = ($norm -match '(^|/)_lib/[^/]+/[^/]+/env\.sh$')
    $skipStyleRules = ($norm -match '(audit_posix\.sh|audit_standards\.sh|\.tpl)$')

    for ($idx = 0; $idx -lt $lines.Length; $idx++) {
        $fnr = $idx + 1
        $ln = $lines[$idx]

        if ($fnr -le 30 -and $ln -notmatch '^\s*#') {
            if ($ln -match 'set -feu') { $hasFeu = $true }
            if ($ln -match 'THIS_FILE=') { $hasThis = $true }
        }

        if ($inHd) {
            if ($ln -eq $hdDelim -or ($hdTab -and $ln -match ("^\s*" + [regex]::Escape($hdDelim) + '$'))) {
                $inHd = $false
                $hdDelim = ''
                $hdTab = $false
            }
            continue
        }

        if ($ln -notmatch '^\s*#' -and $ln -match '<<(-?)\s*[\x22\x27]?([A-Za-z0-9_]+)[\x22\x27]?\s*(>|2>|$)') {
            $inHd = $true
            $hdTab = ($matches[1] -eq '-')
            $hdDelim = $matches[2]
            continue
        }

        if ($ln -match '\*\x27:\x22\$\{THIS_FILE\}\x22:\x27\*') { $badStackQuote = $true }
        if ($ln -match 'return 0; else exit 0') { $sawRetLine = $fnr }
        if ($fnr -eq ($sawRetLine + 1) -and $ln -match '^STACK=\x22\$\{STACK%\x22\$\{THIS_FILE\}\x22:\}\x22') { $unreachableStack = $true }
        if ($ln -match '(if\s+\[\[|\s\[\[\s|&&\s*\[\[|\|\|\s*\[\[)') { $hasDblBracket = $true }
        if ($ln -match '^\s*function\s+[a-zA-Z0-9_]+(\s*\(\s*\))?\s*\{?\s*$') { $hasFuncKw = $true }
        if ($ln -match '(^\s*source\s+|[;&|]\s*source\s+)') { $hasSourceKw = $true }
        if ($ln -match '(^\s*echo\s+-e\s+|[;&|]\s*echo\s+-e\s+)') { $hasEchoE = $true }

        if ($ln -notmatch '^\s*#') {
            if ($ln -match '(^|[^A-Za-z0-9_])sort\s+-V([^A-Za-z0-9_]|$)') { $hasSortV = $true }
            if ($ln -match '(^|[^A-Za-z0-9_])sed\s+-i') { $hasSedI = $true }
            if ($ln -match '(^|[\s;|&(])grep\s+' -and $ln -notmatch 'grep\s+-[a-zA-Z]*[EF]' -and $ln -match '\x5c[+|?]') { $hasGnuBre = $true }
            if (-not $skipStyleRules -and $dqHit -eq '') {
                if ($ln -match '^\s*(export\s+)?[A-Za-z_][A-Za-z0-9_]*=\x22[A-Za-z0-9_./:@+-]+\x22\s*$' -or
                    $ln -match '^\s*(log_(info|warn|error)|printf\s+\x27%s\x5cn\x27|echo)\s+\x22[^$`\x5c\x27\x22]+\x22(\s*>&2)?\s*$' -or
                    $ln -match '^\s*libscript_depends(\s+\x22[A-Za-z0-9_.-]+\x22)+(\s*\|\|\s*true)?\s*$') {
                    $dqHit = "${fnr}:${ln}"
                }
            }
            if (-not $skipStyleRules -and $sc2015Hit -eq '') {
                if ($ln -match '^[ \x09]*(\[[^\]]+\]([ \x09]*&&[ \x09]*\[[^\]]+\])*|command[ \x09]+-v[ \x09]+[^|;]+)[ \x09]*&&[ \x09]*[^|;&\[{][^|;&]*(\|[ \x09]*[^|;&]+)*\|\|[ \x09]*(true|:)([ \x09;]|$)' -or
                    $ln -match '\$\([ \x09]*cd[ \x09]+[^|;&]+&&[ \x09]*[^|;&]+(\|[ \x09]*[^|;&]+)*\|\|[ \x09]*(true|:)[ \x09]*\)') {
                    $sc2015Hit = "${fnr}:${ln}"
                }
            }
            if ($isEnvSh -and $ln -match '(\$HOME([^A-Za-z0-9_]|$)|\$\{HOME\})') { $hasUnguardedHome = $true }
        }
    }

    if (-not $hasFeu) { Add-AuditError -File $norm -Message 'Missing `set -feu` declaration in header' }
    if (-not $hasThis) { Add-AuditError -File $norm -Message 'Missing canonical THIS_FILE= resolution dance in first 30 lines' }
    if ($badStackQuote) { Add-AuditError -File $norm -Message 'Single-quoted literal ${THIS_FILE} in STACK recursion guard' }
    if ($unreachableStack) { Add-AuditError -File $norm -Message 'Unreachable STACK pop placed after return/exit' }
    if ($hasDblBracket) { Add-AuditError -File $norm -Message 'Banned bashism: `[[ ... ]]` condition syntax detected' }
    if ($hasFuncKw) { Add-AuditError -File $norm -Message 'Banned bashism: `function foo()` syntax detected' }
    if ($hasSourceKw) { Add-AuditError -File $norm -Message 'Banned bashism: `source` used instead of POSIX `.`' }
    if ($hasEchoE) { Add-AuditError -File $norm -Message 'Banned bashism: `echo -e` used instead of `printf`' }
    if ($hasSortV) { Add-AuditError -File $norm -Message 'Non-POSIX `sort -V` detected; use `libscript_sort_versions`' }
    if ($hasSedI) { Add-AuditError -File $norm -Message 'Non-portable `sed -i` detected; use temp file or `libscript_sed_in_place`' }
    if ($hasGnuBre) { Add-AuditError -File $norm -Message 'Non-POSIX GNU BRE extension (\+, \|, \?) in grep without -E' }
    if ($dqHit -ne '') { Add-AuditError -File $norm -Message "Unnecessary double quotes where single quotes suffice: $dqHit" }
    if ($sc2015Hit -ne '') { Add-AuditError -File $norm -Message "SC2015-prone `A && B || true` chain detected (use explicit `if ...; then ... || true; fi`): $sc2015Hit" }
    if ($hasUnguardedHome) { Add-AuditError -File $norm -Message 'Unguarded $HOME reference in env.sh; use ${HOME:-/root} for set -u daemon safety' }
}

# ## Test-BatchHeaderInvariants
# Audits the first 25 lines of a Windows Batch companion (.cmd/.bat) for EnableDelayedExpansion, THIS_FILE, and STACK guard.
function Test-BatchHeaderInvariants {
    param([string]$RelPath)

    $norm = $RelPath.Replace([char]92, [char]47)
    $fullPath = if ([System.IO.Path]::IsPathRooted($RelPath)) { $RelPath } else { Join-Path $rootDir $RelPath }
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        return
    }

    $hasDel = $false
    $hasThis = $false
    $hasStackGuard = $false
    $lineIdx = 0
    foreach ($ln in [System.IO.File]::ReadLines($fullPath, [System.Text.Encoding]::UTF8)) {
        $lineIdx++
        if ($lineIdx -gt 25) { break }
        if ($ln -notmatch '(?i)^\s*(::|rem(\s|$))') {
            if ($ln -match '(?i)^\s*setlocal\s+enabledelayedexpansion') { $hasDel = $true }
            if ($ln -match '(?i)this_file=') { $hasThis = $true }
            if ($ln -match '(?i)echo \x22!stack!\x22 \| findstr /i /c:\x22:') { $hasStackGuard = $true }
        }
    }
    if (-not $hasDel) { Add-AuditError -File $norm -Message 'Windows companion missing EnableDelayedExpansion' }
    if (-not $hasThis) { Add-AuditError -File $norm -Message 'Windows companion missing THIS_FILE= definition' }
    if (-not $hasStackGuard) { Add-AuditError -File $norm -Message 'Windows companion missing quoted case-insensitive STACK guard (echo "!STACK!" | findstr /I)' }
}

if ($args -contains '--staged') {
    $stagedSh = @(git diff --no-ext-diff --cached --name-only --diff-filter=ACM -- '*.sh' '.githooks/pre-commit')
    foreach ($f in $stagedSh) {
        if ($f) { Test-ShellScriptPosix -RelPath ([string]$f) }
    }
} elseif ($args.Count -gt 0 -and -not ($args -contains '--all')) {
    foreach ($t in $args) {
        $cand = [string]$t
        if (-not (Test-Path -LiteralPath $cand -PathType Leaf)) {
            $fromOrig = Join-Path $origPwd $cand
            if (Test-Path -LiteralPath $fromOrig -PathType Leaf) {
                $cand = $fromOrig
            }
        }
        if (Test-Path -LiteralPath $cand -PathType Leaf) {
            Test-ShellScriptPosix -RelPath $cand
            $base = if ($cand.EndsWith('.sh', [System.StringComparison]::OrdinalIgnoreCase)) { $cand.Substring(0, $cand.Length - 3) } else { $cand }
            $cmdPath = "${base}.cmd"
            $batPath = "${base}.bat"
            if (-not (Test-Path -LiteralPath $cmdPath -PathType Leaf) -and -not (Test-Path -LiteralPath $batPath -PathType Leaf)) {
                Add-AuditError -File $cand -Message "Missing paired Windows batch companion: $cmdPath"
            } elseif (Test-Path -LiteralPath $cmdPath -PathType Leaf) {
                Test-BatchHeaderInvariants -RelPath $cmdPath
            }
        }
    }
} else {
    $allScripts = @(git ls-files --cached --others --exclude-standard '*.sh' '*.cmd' '*.bat' '.githooks/pre-commit')
    $fileSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($s in $allScripts) {
        if ($s) {
            $normS = ([string]$s).Replace([char]92, [char]47)
            [void]$fileSet.Add($normS)
        }
    }

    foreach ($f in $fileSet) {
        if ($f.EndsWith('.sh', [System.StringComparison]::OrdinalIgnoreCase) -or $f -eq '.githooks/pre-commit') {
            Test-ShellScriptPosix -RelPath $f
            if ($f -notmatch '(^|/)audit_posix\.sh$') {
                $base = if ($f.EndsWith('.sh', [System.StringComparison]::OrdinalIgnoreCase)) { $f.Substring(0, $f.Length - 3) } else { $f }
                $cmdCand = "${base}.cmd"
                $batCand = "${base}.bat"
                if (-not $fileSet.Contains($cmdCand) -and -not $fileSet.Contains($batCand)) {
                    Add-AuditError -File $f -Message "Missing paired Windows batch companion: $cmdCand"
                }
            }
        } elseif ($f.EndsWith('.cmd', [System.StringComparison]::OrdinalIgnoreCase) -or $f.EndsWith('.bat', [System.StringComparison]::OrdinalIgnoreCase)) {
            $base = $f.Substring(0, $f.Length - 4)
            $shCand = "${base}.sh"
            if (-not $fileSet.Contains($shCand)) {
                Add-AuditError -File $f -Message "Missing paired POSIX shell companion: $shCand"
            }
            Test-BatchHeaderInvariants -RelPath $f
        }
    }
}

if ($script:errorsCount -gt 0) {
    [Console]::Error.WriteLine("[ERROR] Audit failed with $($script:errorsCount) standards violations!")
    exit 1
}

Write-Host '[PASS] All audited scripts strictly adhere to POSIX /bin/sh and companion requirements.'
exit 0
