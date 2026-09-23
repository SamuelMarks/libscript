# ## Overview
# Audits codebase and staged files for adherence to LibScript engineering standards:
# - POSIX /bin/sh usage and canonical THIS_FILE preamble
# - Windows batch script parity (.cmd / .bat)
# - No evil eval usage
# - Idempotency patterns
# - 100% doc block coverage (## Overview and ## Usage)
#
# ## Usage
# Execute via PowerShell:
#   powershell.exe -File devtools\audit\audit_standards.ps1 [--all | --staged]

<#
.SYNOPSIS
PowerShell standards auditor for LibScript.
#>

$ErrorActionPreference = "Stop"

# ## Show-Help
# Displays help instructions for the audit script.
function Show-Help {
    Write-Host "Usage: audit_standards.ps1 [--all | --staged | <file>...]"
    Write-Host "Audits files for adherence to LibScript engineering standards."
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  --all               Audit all tracked script files in repository."
    Write-Host "  --staged            Audit git-staged files (default if no files given)."
    Write-Host "  --help, -h, /?, -?  Show this help message."
}

if ($args -contains "--help" -or $args -contains "-h" -or $args -contains "/?" -or $args -contains "-?") {
    Show-Help
    exit 0
}

$rootDir = if ($env:ROOT_DIR) { Resolve-Path $env:ROOT_DIR } else { Resolve-Path (Join-Path $PSScriptRoot '..\..') }
Set-Location $rootDir

$errorsCount = 0

# ## Log-Violation
# Logs an engineering standard failure.
function Log-Violation {
    param(
        [string]$File,
        [string]$Rule,
        [string]$Details
    )
    [Console]::Error.WriteLine("[STANDARDS VIOLATION] [$Rule] $File`: $Details")
    $script:errorsCount++
}

# ## Test-ExcludedPath
# Checks whether a path should be omitted from standards checks.
function Test-ExcludedPath {
    param([string]$Path)
    $normalized = $Path.Replace([char]92, [char]47)
    if ($normalized -match '^(\.git|gen|cache|tmp|tests_tmp|node_modules|vagrant)/') {
        return $true
    }
    return $false
}

# ## Audit-File
# Performs standard validation checks on a single file.
function Audit-File {
    param([string]$FilePath)

    if (-not (Test-Path $FilePath -PathType Leaf)) {
        return
    }

    if (Test-ExcludedPath $FilePath) {
        return
    }

    $ext = [System.IO.Path]::GetExtension($FilePath).TrimStart('.').ToLowerInvariant()
    $lines = Get-Content -Path $FilePath -TotalCount 65 -ErrorAction SilentlyContinue

    if (-not $lines) {
        return
    }

    $headerText = $lines -join "`n"

    # 1. POSIX /bin/sh and THIS_FILE dance for shell scripts
    if ($ext -eq "sh") {
        $firstLine = $lines[0]
        if ($firstLine -match "bash|zsh|ksh") {
            Log-Violation -File $FilePath -Rule "POSIX_SHEBANG" -Details "Non-POSIX shebang found: '$firstLine'. LibScript requires '#!/bin/sh'."
        } elseif (-not ($firstLine.StartsWith("#!/bin/sh"))) {
            if ($FilePath -notmatch "(\.tpl|docker|test|docs-web-template)") {
                Log-Violation -File $FilePath -Rule "POSIX_SHEBANG" -Details "Missing '#!/bin/sh' shebang on line 1."
            }
        }

        # Check for multiple shebangs outside of heredocs
        $inHeredoc = $false
        $delim = ""
        $shebangLines = @()
        $lineNum = 1
        foreach ($ln in (Get-Content -Path $FilePath -ErrorAction SilentlyContinue)) {
            $trimmed = $ln.Trim()
            if ($inHeredoc) {
                if ($trimmed -eq $delim) {
                    $inHeredoc = $false
                    $delim = ""
                }
                $lineNum++
                continue
            }
            if ($ln -match '<<-?\s*["'']?([A-Za-z0-9_]+)["'']?') {
                $inHeredoc = $true
                $delim = $matches[1]
            }
            if ($trimmed.StartsWith("#!")) {
                $shebangLines += $lineNum
            }
            $lineNum++
        }
        if ($shebangLines.Count -gt 1) {
            $joinedLines = $shebangLines -join ", "
            Log-Violation -File $FilePath -Rule "DUPLICATE_SHEBANG" -Details "Multiple shebangs detected outside of heredocs at lines: $joinedLines."
        }

        if ($FilePath -notmatch "(Dockerfile|\.tpl|dockerfiles-ssh|docker/)") {
            if ($headerText -notmatch 'THIS_FILE=') {
                Log-Violation -File $FilePath -Rule "THIS_FILE_DANCE" -Details "Missing canonical 'THIS_FILE=' resolution in first 40 lines."
            }
            if ($headerText -notmatch 'STACK') {
                Log-Violation -File $FilePath -Rule "RECURSION_GUARD" -Details "Missing 'STACK' recursion guard in first 40 lines."
            }
        }

        # 2. Windows batch parity (.cmd or .bat)
        if ($FilePath -notmatch "(docker/|dockerfiles-ssh/|\.tpl|Vagrantfile)") {
            $cmdFile = [System.IO.Path]::ChangeExtension($FilePath, ".cmd")
            $batFile = [System.IO.Path]::ChangeExtension($FilePath, ".bat")
            if (-not (Test-Path $cmdFile) -and -not (Test-Path $batFile)) {
                Log-Violation -File $FilePath -Rule "WINDOWS_PARITY" -Details "Missing Windows batch equivalent file ('$cmdFile')."
            }
        }
    }

    # Batch script header verification
    if ($ext -eq "cmd" -or $ext -eq "bat") {
        if ($headerText -notmatch 'THIS_FILE=%~f0') {
            Log-Violation -File $FilePath -Rule "BATCH_THIS_FILE" -Details "Missing 'set `"THIS_FILE=%~f0`"' in first 25 lines."
        }
    }

    # 3. Idempotency checks
    $allContent = Get-Content -Path $FilePath -Raw -ErrorAction SilentlyContinue
    if ($ext -eq "sh") {
        if ($allContent -match '(?m)^[ 	]*mkdir[ 	]+[^-]' -and $allContent -notmatch '(?m)^[ 	]*mkdir[ 	]+.*lock' -and $allContent -notmatch 'while[ 	]+![ 	]+mkdir') {
            Log-Violation -File $FilePath -Rule "IDEMPOTENCY" -Details "Unguarded 'mkdir' found without '-p'. Use 'mkdir -p' for idempotency."
        }
        if ($allContent -match '(?m)^[ 	]*ln[ 	]+-s[ 	]+[^-]') {
            Log-Violation -File $FilePath -Rule "IDEMPOTENCY" -Details "Unguarded 'ln -s' found without '-f'. Use 'ln -sf' for idempotency."
        }
    } elseif ($ext -eq "cmd" -or $ext -eq "bat") {
        if ($allContent -match '(?mi)^[ 	]*(mkdir|md)[ 	]+' -and $allContent -notmatch '(?mi)if[ 	]+not[ 	]+exist') {
            Log-Violation -File $FilePath -Rule "IDEMPOTENCY" -Details "Unguarded 'mkdir' in batch script. Wrap with 'if not exist <dir> mkdir <dir>'."
        }
    }

    # 4. Ban eval checks
    if ($ext -eq "sh") {
        if ($allContent -match '(?m)^[ 	]*eval([ 	]|$)|;[ 	]*eval([ 	]|$)' -and $allContent -notmatch 'libscript-allow-eval') {
            Log-Violation -File $FilePath -Rule "BAN_EVAL" -Details "Disallowed use of 'eval' found."
        }
    } elseif ($ext -eq "ps1") {
        if ($allContent -match '(?mi)^[ 	]*(Invoke-Expression|iex)\b|;[ 	]*(Invoke-Expression|iex)\b' -and $allContent -notmatch 'libscript-allow-eval') {
            Log-Violation -File $FilePath -Rule "BAN_EVAL" -Details "Disallowed use of 'Invoke-Expression' found."
        }
    }

    # 5. 100% Doc coverage (## Overview and ## Usage)
    if ($ext -eq "sh" -or $ext -eq "cmd" -or $ext -eq "bat" -or $ext -eq "ps1") {
        if ($headerText -notmatch '## Overview') {
            Log-Violation -File $FilePath -Rule "DOC_OVERVIEW" -Details "Missing doc block '## Overview' in first 30 lines."
        }
        if ($headerText -notmatch '## Usage') {
            Log-Violation -File $FilePath -Rule "DOC_USAGE" -Details "Missing doc block '## Usage' in first 30 lines."
        }
    }

    # 6. Option A Hard Fail Proforma check (Exit code 86)
    $fileName = [System.IO.Path]::GetFileName($FilePath)
    if ($fileName -match '^(mount_target_vfs|umount_target_vfs|runner|provision_disk|format_fs)\.(cmd|ps1)$') {
        $content = Get-Content -Path $FilePath -Raw
        if ($ext -eq "cmd" -and $content -notmatch 'exit /b 86') {
            Log-Violation -File $FilePath -Rule "OPTION_A_PROFORMA" -Details "Option A proforma script must exit with status 86."
        } elseif ($ext -eq "ps1" -and $content -notmatch 'exit 86') {
            Log-Violation -File $FilePath -Rule "OPTION_A_PROFORMA" -Details "Option A proforma script must exit with status 86."
        }
    }

    # 7. Remote Safety Mandate (NEVER execute git push)
    if ($ext -eq "sh" -or $ext -eq "cmd" -or $ext -eq "bat" -or $ext -eq "ps1") {
        $pushMatch = Select-String -Path $FilePath -Pattern '^\s*(call\s+)?git\s+push\b' -Quiet
        if ($pushMatch) {
            Log-Violation -File $FilePath -Rule "REMOTE_SAFETY" -Details "Strict safety violation: found 'git push' invocation."
        }
    }

    # 8. Recipe Boundary Check for leaf packages (_lib/<category>/<component>/)
    $normPath = $FilePath.Replace([char]92, [char]47)
    if ($normPath -match '^_lib/[^/]+/[^/]+/.+\.sh$' -and $normPath -notmatch '^_lib/(orchestration|storage|_common|cloud|cloud-providers)/') {
        $boundaryMatch = Select-String -Path $FilePath -Pattern '^\s*(sudo\s+)?(mount|umount|losetup|fdisk|sfdisk|parted|mkfs(\.[a-z0-9]+)?|cryptsetup)\s' -Quiet
        if ($boundaryMatch) {
            Log-Violation -File $FilePath -Rule "RECIPE_BOUNDARY" -Details "Tier 1 leaf recipe directly invokes kernel/storage primitive."
        }
    }
}

# Determine target files
$targetFiles = @()
if ($args -contains "--all") {
    $targetFiles = git ls-files "*.sh" "*.cmd" "*.bat" "*.ps1"
} elseif ($args -contains "--staged" -or $args.Count -eq 0) {
    $targetFiles = git diff --no-ext-diff --cached --name-only --diff-filter=ACM
} else {
    $targetFiles = $args
}

if (-not $targetFiles) {
    Write-Host "[AUDIT] No matching files to audit."
    exit 0
}

foreach ($target in $targetFiles) {
    if ($target -and (Test-Path $target)) {
        Audit-File -FilePath $target
    }
}

if ($errorsCount -gt 0) {
    [Console]::Error.WriteLine("[AUDIT] $errorsCount standards violation(s) found.")
    exit 1
}

Write-Host "[AUDIT] All inspected files adhere to LibScript engineering standards."
exit 0
