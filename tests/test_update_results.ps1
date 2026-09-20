# ## Overview
# Validates update_results.ps1 execution, verifying component discovery,
# markdown table updating in README.md, and task tracking in TODO_PLAN.md on Windows/PowerShell.
#
# ## Usage
# .\tests\test_update_results.ps1

<#
.SYNOPSIS
PowerShell test suite for update_results.ps1.
#>

$ErrorActionPreference = "Stop"

if ($args -contains "--help" -or $args -contains "-h" -or $args -contains "/?" -or $args -contains "-?") {
    Write-Host "Usage: test_update_results.ps1"
    Write-Host "Validates update_results.ps1 execution."
    exit 0
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$testTmp = Join-Path ([System.IO.Path]::GetTempPath()) ("test_update_results_" + [System.Guid]::NewGuid().ToString("N"))

try {
    # Setup mock directory structure
    New-Item -ItemType Directory -Path (Join-Path $testTmp "_lib/catA/compA") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $testTmp "_lib/catB/compB") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $testTmp "stacks/catS/compS") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $testTmp "_lib/_common/helper") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $testTmp "tests_tmp") -Force | Out-Null

    New-Item -ItemType File -Path (Join-Path $testTmp "libscript.sh") | Out-Null

    $readmeContent = @'
# Mock Project

## Supported Components

| Component | Linux (apk) | Linux (deb) | Linux (rpm) | Windows | SunOS | FreeBSD |
|---|---|---|---|---|---|---|
| `compA` | ❓ | ❓ | ❓ | - | - | - |

## License
MIT
'@
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText((Join-Path $testTmp "README.md"), $readmeContent, $utf8NoBom)

    $todoContent = @'
- [ ] _lib/catA/compA
  - [ ] **Double-check & Idempotency Verified (2x run)**
- [ ] compB
- [ ] compC
- [x] already_done
'@
    [System.IO.File]::WriteAllText((Join-Path $testTmp "TODO_PLAN.md"), $todoContent, $utf8NoBom)

    # Create mock test result files
    New-Item -ItemType File -Path (Join-Path $testTmp "tests_tmp/compA.idempotent.success") | Out-Null
    New-Item -ItemType File -Path (Join-Path $testTmp "tests_tmp/compA.linux.alpine.success") | Out-Null
    New-Item -ItemType File -Path (Join-Path $testTmp "tests_tmp/compA.sunos.success") | Out-Null
    New-Item -ItemType File -Path (Join-Path $testTmp "tests_tmp/compB.windows.failure") | Out-Null
    New-Item -ItemType File -Path (Join-Path $testTmp "tests_tmp/compS.linux.debian.success") | Out-Null

    # Execute update_results.ps1
    & (Join-Path $PSScriptRoot "update_results.ps1") $testTmp

    $updatedReadme = [System.IO.File]::ReadAllText((Join-Path $testTmp "README.md"), [System.Text.Encoding]::UTF8)

    # Verification 1: compA has success checkmark in README
    if ($updatedReadme -notmatch '\|\s*`compA`\s*\|\s*✅\s*\|\s*❓\s*\|\s*❓\s*\|\s*-\s*\|\s*✅\s*\|\s*-\s*\|') {
        throw "Error: compA success status not found in README.md"
    }

    # Verification 2: compB has failure mark for windows in README
    if ($updatedReadme -notmatch '\|\s*`compB`\s*\|\s*❓\s*\|\s*❓\s*\|\s*❓\s*\|\s*❌\s*\|') {
        throw "Error: compB failure status not found in README.md"
    }

    # Verification 2b: compS from stacks directory has debian success mark
    if ($updatedReadme -notmatch '\|\s*`compS`\s*\|\s*❓\s*\|\s*✅\s*\|\s*❓\s*\|') {
        throw "Error: compS stacks component not discovered or deb status not updated in README.md"
    }

    # Verification 3: _common / helper must NOT be in the table
    if ($updatedReadme -match 'helper') {
        throw "Error: helper from _common found in README.md table"
    }

    # Verification 4: TODO_PLAN.md updated completed items
    $updatedTodo = [System.IO.File]::ReadAllText((Join-Path $testTmp "TODO_PLAN.md"), [System.Text.Encoding]::UTF8)
    if ($updatedTodo -notmatch '- \[x\] _lib/catA/compA') {
        throw "Error: _lib/catA/compA not checked in TODO_PLAN.md"
    }
    if ($updatedTodo -notmatch '- \[x\] \*\*Double-check & Idempotency Verified \(2x run\)\*\*') {
        throw "Error: compA idempotency check not checked in TODO_PLAN.md"
    }
    if ($updatedTodo -notmatch '- \[x\] compB') {
        throw "Error: compB not checked in TODO_PLAN.md"
    }
    if ($updatedTodo -notmatch '- \[ \] compC') {
        throw "Error: compC unexpectedly modified in TODO_PLAN.md"
    }

    # Verification 5: FreeBSD success and custom output + JSON export
    New-Item -ItemType File -Path (Join-Path $testTmp "tests_tmp/compA.freebsd.success") | Out-Null
    New-Item -ItemType File -Path (Join-Path $testTmp "tests_tmp/compA.linux.rocky.success") | Out-Null
    Copy-Item (Join-Path $testTmp "README.md") (Join-Path $testTmp "CUSTOM_REPORT.md")

    & (Join-Path $PSScriptRoot "update_results.ps1") $testTmp --output (Join-Path $testTmp "CUSTOM_REPORT.md") --json (Join-Path $testTmp "tests_tmp/matrix_results.json")

    $customReport = [System.IO.File]::ReadAllText((Join-Path $testTmp "CUSTOM_REPORT.md"), [System.Text.Encoding]::UTF8)
    if ($customReport -notmatch '\|\s*`compA`\s*\|.*\|\s*✅\s*\|') {
        throw "Error: compA FreeBSD status not updated in CUSTOM_REPORT.md"
    }
    if ($customReport -notmatch '\|\s*`compA`\s*\|\s*✅\s*\|\s*❓\s*\|\s*✅\s*\|') {
        throw "Error: compA Rocky Linux (rpm) status not updated in CUSTOM_REPORT.md"
    }

    $jsonPath = Join-Path $testTmp "tests_tmp/matrix_results.json"
    if (-not (Test-Path -LiteralPath $jsonPath)) {
        throw "Error: matrix_results.json was not generated"
    }
    $jsonContent = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8)
    if ($jsonContent -notmatch '"component":\s*"compA"') {
        throw "Error: compA not found in matrix_results.json"
    }

    Write-Host "All tests in test_update_results.ps1 passed successfully."
} finally {
    if (Test-Path -LiteralPath $testTmp) {
        Remove-Item -Recurse -Force $testTmp -ErrorAction SilentlyContinue
    }
}
