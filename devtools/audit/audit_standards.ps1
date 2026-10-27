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
            if ($headerText -notmatch 'set -feu') {
                Log-Violation -File $FilePath -Rule "SET_FEU_SAFETY" -Details "Missing 'set -feu' in first 40 lines."
            }
            if ($headerText -notmatch 'THIS_FILE=') {
                Log-Violation -File $FilePath -Rule "THIS_FILE_DANCE" -Details "Missing canonical 'THIS_FILE=' resolution in first 40 lines."
            }
            if ($headerText -notmatch 'STACK') {
                Log-Violation -File $FilePath -Rule "RECURSION_GUARD" -Details "Missing 'STACK' recursion guard in first 40 lines."
            }
            if ($headerText -notmatch 'LIBSCRIPT_ROOT_DIR') {
                Log-Violation -File $FilePath -Rule "ROOT_DIR_RESOLUTION" -Details "Missing 'LIBSCRIPT_ROOT_DIR' resolution in header."
            }
            if ($headerText -notmatch '# shellcheck disable=SC2296') {
                Log-Violation -File $FilePath -Rule "ZSH_SHELLCHECK_TAG" -Details "Missing '# shellcheck disable=SC2296' in ZSH_VERSION header block."
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

    if ($ext -eq "ps1") {
        $shFile = [System.IO.Path]::ChangeExtension($FilePath, ".sh")
        $cmdFile = [System.IO.Path]::ChangeExtension($FilePath, ".cmd")
        if (-not (Test-Path $shFile)) {
            Log-Violation -File $FilePath -Rule "POSIX_PARITY" -Details "Missing POSIX shell equivalent file ('$shFile')."
        }
        if (-not (Test-Path $cmdFile)) {
            Log-Violation -File $FilePath -Rule "WINDOWS_PARITY" -Details "Missing Windows batch equivalent file ('$cmdFile')."
        }
    }

    # Batch script header verification and reverse POSIX parity
    if ($ext -eq "cmd" -or $ext -eq "bat") {
        $shFile = [System.IO.Path]::ChangeExtension($FilePath, ".sh")
        if (-not (Test-Path $shFile)) {
            Log-Violation -File $FilePath -Rule "POSIX_PARITY" -Details "Missing POSIX shell equivalent file ('$shFile')."
        }
        if ($lines[0].Trim() -notmatch '^@echo off$') {
            Log-Violation -File $FilePath -Rule "BATCH_ECHO_OFF" -Details "Missing '@echo off' on line 1."
        }
        $top25 = ($lines | Select-Object -First 25) -join "`n"
        if ($top25 -notmatch 'EnableDelayedExpansion') {
            Log-Violation -File $FilePath -Rule "BATCH_DELAYED_EXPANSION" -Details "Missing 'setlocal EnableDelayedExpansion' in first 25 lines."
        }
        if ($top25 -notmatch 'THIS_FILE=%~f0') {
            Log-Violation -File $FilePath -Rule "BATCH_THIS_FILE" -Details "Missing 'set `"THIS_FILE=%~f0`"' in first 25 lines."
        }
    }

    # 3. Idempotency checks
    $allContent = Get-Content -Path $FilePath -Raw -ErrorAction SilentlyContinue
    if ($ext -eq "sh") {
        if ($allContent -match '(?m)^[ \t]*mkdir[ \t]+[^-]' -and $allContent -notmatch '(?m)^[ \t]*mkdir[ \t]+.*lock' -and $allContent -notmatch 'while[ \t]+![ \t]+mkdir') {
            Log-Violation -File $FilePath -Rule "IDEMPOTENCY" -Details "Unguarded 'mkdir' found without '-p'. Use 'mkdir -p' for idempotency."
        }
        if ($allContent -match '(?m)^[ \t]*ln[ \t]+-s[ \t]+[^-]') {
            Log-Violation -File $FilePath -Rule "IDEMPOTENCY" -Details "Unguarded 'ln -s' found without '-f'. Use 'ln -sf' for idempotency."
        }
    } elseif ($ext -eq "cmd" -or $ext -eq "bat") {
        if ($allContent -match '(?mi)^[ \t]*(mkdir|md)[ \t]+' -and $allContent -notmatch '(?mi)if[ \t]+not[ \t]+exist') {
            Log-Violation -File $FilePath -Rule "IDEMPOTENCY" -Details "Unguarded 'mkdir' in batch script. Wrap with 'if not exist <dir> mkdir <dir>'."
        }
        if ($allContent -match 'SCRIPT_DIR[%!][^\\/"\s\)]') {
            Log-Violation -File $FilePath -Rule "BATCH_SCRIPT_DIR_SEPARATOR" -Details "Missing backslash separator after SCRIPT_DIR."
        }
        if ($allContent -match 'SCRIPT_DIR:~-1%"=="\\\\"') {
            Log-Violation -File $FilePath -Rule "BATCH_SCRIPT_DIR_STRIP" -Details "Corrupted SCRIPT_DIR:~-1 double-backslash check."
        }
        if ($allContent -match '(?mi)^[ \t]*exit[ \t]+[0-9]+[ \t]*$') {
            Log-Violation -File $FilePath -Rule "BATCH_HYGIENE" -Details "Bare exit without /b found in batch script."
        }
        $chainedIf = @{}
        $lineIdx = 0
        foreach ($bLine in ($allContent -split "`r?`n")) {
            $lineIdx++
            $ind = ($bLine -replace '^(\s*).*$', '$1').Length
            if ($bLine -match '(?i)^\s*\)\s*else(\s|$)' -and $chainedIf.ContainsKey($ind)) {
                Log-Violation -File $FilePath -Rule "BATCH_CHAINED_IF_ELSE" -Details "Chained 'if ... if ... ( ... ) else ( ... )' at line $($chainedIf[$ind])->$lineIdx skips else when outer if is false."
                $chainedIf.Remove($ind)
            } elseif ($bLine -match '^\s*\)\s*$') {
                $chainedIf.Remove($ind)
            }
            if ($bLine -match '(?i)^\s*(\)\s*else\s+)?if\s+.*\s+if\s+.*\(\s*$' -and $bLine -notmatch '(?i)powershell|python|jq|sqlite3') {
                $chainedIf[$ind] = $lineIdx
            }
        }
    }

    # 4. Ban eval checks
    if ($ext -eq "sh") {
        if ($allContent -match '(?m)^[ \t]*eval([ \t]|$)|;[ \t]*eval([ \t]|$)') {
            Log-Violation -File $FilePath -Rule "BAN_EVAL" -Details "Disallowed use of 'eval' found."
        }
    } elseif ($ext -eq "ps1") {
        if ($allContent -match '(?mi)^[ \t]*(Invoke-Expression|iex)\b|;[ \t]*(Invoke-Expression|iex)\b') {
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
    if ($normPath -match '^_lib/[^/]+/[^/]+/.+\.sh$' -and $normPath -notmatch '^_lib/(orchestration|storage|_common|cloud|cloud-providers|kernel|bootloaders)/') {
        $boundaryMatch = Select-String -Path $FilePath -Pattern '^\s*(sudo\s+)?(mount|umount|losetup|fdisk|sfdisk|parted|mkfs(\.[a-z0-9]+)?|cryptsetup)\s' -Quiet
        if ($boundaryMatch) {
            Log-Violation -File $FilePath -Rule "RECIPE_BOUNDARY" -Details "Tier 1 leaf recipe directly invokes kernel/storage primitive."
        }
    }

    # 8c. Enforce Zero-Dependency Substrate in core orchestration
    if ($normPath -match '^(_lib/(_common|orchestration|init-systems|databases|cloud/core)|cli)/.*\.sh$') {
        $interpMatch = Select-String -Path $FilePath -Pattern '(^\s*|\$\()(python3?\s+-c|node\s+-e|perl\s+-e|ruby\s+-e)\s|libscript-allow-interp' -Quiet
        if ($interpMatch) {
            Log-Violation -File $FilePath -Rule "ZERO_DEP_SUBSTRATE" -Details "Core orchestration script invokes external interpreter inline."
        }
    }

    # 8d. Ban hardcoded user/project paths in core substrate (_lib/ and cli/)
    if ($normPath -match '^(_lib|cli)/') {
        $leakMatch = Select-String -Path $FilePath -Pattern '(pulse_query|pulse-query|hospital-dashboard-platform|hospital_dashboard_platform|t1d_analytics|t1d-analytics|/home/azureuser|C:\\Users\\vagrant|\.volta/bin)' -Quiet
        if ($leakMatch) {
            Log-Violation -File $FilePath -Rule "NO_HARDCODED_USER_PATHS" -Details "Hardcoded user/project path or .volta reference in substrate."
        }
    }

    # 8e. Ban commented-out libscript_depends in recipe setup scripts
    if ($normPath -match '^_lib/[^/]+/[^/]+/setup.*\.sh$') {
        $commentedDepMatch = Select-String -Path $FilePath -Pattern '^\s*#\s*#\s*libscript_depends' -Quiet
        if ($commentedDepMatch) {
            Log-Violation -File $FilePath -Rule "COMMENTED_DEPENDS" -Details "Commented-out '# # libscript_depends' found in recipe setup script."
        }
    }

    # 8f. Ban non-POSIX sort -V and bare sed -i in .sh scripts
    if ($ext -eq "sh" -and $normPath -ne 'devtools/audit/audit_posix.sh' -and $normPath -ne 'devtools/audit/audit_standards.sh') {
        $nonPosixFlagMatch = Select-String -Path $FilePath -Pattern '^\s*[^#]*\b(sort\s+-V|sed\s+-i)' -Quiet
        if ($nonPosixFlagMatch) {
            Log-Violation -File $FilePath -Rule "NON_POSIX_TOOL_FLAG" -Details "Non-POSIX sort -V or sed -i detected."
        }
        $dqMatch = Select-String -Path $FilePath -Pattern '^\s*((export\s+)?[A-Za-z_][A-Za-z0-9_]*="[A-Za-z0-9_./:@+-]+"|(log_(info|warn|error)|printf\s+''%s\\n''|echo)\s+"[^$`\\''"]+"(\s*>&2)?|libscript_depends(\s+"[A-Za-z0-9_.-]+")+)(\s*\|\|\s*true)?\s*$'
        if ($dqMatch) {
            Log-Violation -File $FilePath -Rule "UNNECESSARY_DOUBLE_QUOTES" -Details "Double quotes used where single quotes suffice."
        }
    }

    # 8g. Raw Network Fetch & Raw Package Manager Audit
    if ($normPath -notmatch '^(devtools|tests|docker)/') {
        if ($ext -eq "sh") {
            if ($normPath -notmatch '_lib/(_common/pkg_mgr|_common/fetch_checksum|init-systems/daemonize|utilities/(curl|wget|aria2)/test|web-apps/.*/(test_harness|health|service))\.sh$') {
                $rawFetchSh = Select-String -Path $FilePath -Pattern '^\s*[^#]*(curl\s+-[a-zA-Z0-9#-]*[sSfLOo]|wget\s+-[a-zA-Z0-9-]*[qO]|aria2c\s+-[dox])\b' | Where-Object { $_.Line -notmatch '(127\.0\.0\.1|localhost|--unix-socket|--cacert|--connect-timeout|libscript-allow-raw-(fetch|curl))' }
                if ($rawFetchSh) {
                    Log-Violation -File $FilePath -Rule "RAW_NETWORK_FETCH" -Details "Raw curl/wget/aria2c network call found (delegate to libscript_download or libscript_fetch_stdout)."
                }
            }
            if ($normPath -notmatch '_lib/(_common/(pkg_mgr|service)\.sh|package-managers/|orchestration/(vm_builder|distro/))') {
                $rawPkgSh = Select-String -Path $FilePath -Pattern '^\s*[^#]*\b(apt-get\s+(install|remove|purge|update)|apt\s+(install|remove|purge)|apk\s+(add|del|update)|dnf\s+(install|remove|groupinstall)|yum\s+(install|remove|groupinstall)|pacman\s+(-S|-R|-Rns|-Syu)|zypper\s+(install|in|remove|rm)|brew\s+(install|uninstall|tap|services)|port\s+(install|uninstall)|pkg\s+(install|delete|add)|xbps-install|xbps-remove|emerge\s|swupd\s+bundle-add|winget\s+(install|uninstall|upgrade)|choco\s+(install|uninstall|upgrade)|scoop\s+(install|uninstall|update)|vcpkg\s+(install|remove)|conan\s+install|nix\s+profile\s+install|nix-env\s+-i|guix\s+(install|package)|spack\s+(install|uninstall)|npm\s+install\s+-g|composer\s+global\s+require)\b' | Where-Object { $_.Line -notmatch '(--root|libscript-allow-raw-pkg)' }
                if ($rawPkgSh) {
                    Log-Violation -File $FilePath -Rule "RAW_PACKAGE_MANAGER" -Details "Raw package manager usage found (delegate to pkg_mgr.sh / libscript_depends)."
                }
            }
        } elseif ($ext -eq "cmd" -or $ext -eq "bat") {
            if ($normPath -notmatch '(_lib/(_common/pkg_mgr|init-systems/daemonize|utilities/(curl|wget|aria2)/test)|cli/commands/packaging/formats/pkg_docker_compose)\.cmd$') {
                $rawFetchCmd = Select-String -Path $FilePath -Pattern '^\s*(?!::|rem\s|echo\s).*(Invoke-WebRequest|Invoke-RestMethod|\biwr\b|\birm\b|certutil\s+-urlcache|curl\s+-[a-zA-Z0-9]*[sSfLOo])' | Where-Object { $_.Line -notmatch '(127\.0\.0\.1|localhost|--cacert|libscript-allow-raw-fetch)' }
                if ($rawFetchCmd) {
                    Log-Violation -File $FilePath -Rule "RAW_NETWORK_FETCH" -Details "Raw network call in batch script (delegate to pkg_mgr.cmd)."
                }
            }
            if ($normPath -notmatch '_lib/(_common/pkg_mgr\.cmd|package-managers/|orchestration/vm_builder\.cmd)') {
                $rawPkgCmd = Select-String -Path $FilePath -Pattern '^\s*(?!::|rem\s).*\b(winget\s+(install|uninstall|upgrade)|choco\s+(install|uninstall|upgrade)|scoop\s+(install|uninstall|update))\b' | Where-Object { $_.Line -notmatch 'libscript-allow-raw-pkg' }
                if ($rawPkgCmd) {
                    Log-Violation -File $FilePath -Rule "RAW_PACKAGE_MANAGER" -Details "Raw winget/choco/scoop call in batch script (delegate to pkg_mgr.cmd)."
                }
            }
        } elseif ($ext -eq "ps1") {
            if ($normPath -notmatch '_lib/(_common/pkg_mgr|web-apps/openedx/test_harness)\.ps1$') {
                $rawFetchPs1 = Select-String -Path $FilePath -Pattern '^\s*[^#]*(Invoke-WebRequest|Invoke-RestMethod|\biwr\b|\birm\b|Start-BitsTransfer|Net\.WebClient)' | Where-Object { $_.Line -notmatch 'libscript-allow-raw-fetch' }
                if ($rawFetchPs1) {
                    Log-Violation -File $FilePath -Rule "RAW_NETWORK_FETCH" -Details "Raw Invoke-WebRequest/Invoke-RestMethod found (delegate to pkg_mgr.ps1)."
                }
            }
            if ($normPath -notmatch '_lib/(_common/pkg_mgr\.ps1|package-managers/)') {
                $rawPkgPs1 = Select-String -Path $FilePath -Pattern '^\s*[^#]*\b(winget\s+(install|uninstall|upgrade)|choco\s+(install|uninstall|upgrade)|scoop\s+(install|uninstall|update))\b' | Where-Object { $_.Line -notmatch 'libscript-allow-raw-pkg' }
                if ($rawPkgPs1) {
                    Log-Violation -File $FilePath -Rule "RAW_PACKAGE_MANAGER" -Details "Raw winget/choco/scoop call in PowerShell script (delegate to pkg_mgr.ps1)."
                }
            }
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
