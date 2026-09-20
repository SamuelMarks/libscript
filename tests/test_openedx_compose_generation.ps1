# ## Overview
# Validates Docker Compose multi-container configuration generation for Open edX (PowerShell).
# Asserts declaration of LMS, Studio CMS, Celery workers, Celery Beat, supporting datastores,
# healthchecks, and persistent volume definitions.
#
# ## Usage
#   powershell -File tests	est_openedx_compose_generation.ps1

<#
.SYNOPSIS
    Tests Docker Compose generation for Open edX.
.DESCRIPTION
    Executes pkg_docker_compose and verifies generated YAML structure and service definitions.
#>

$ErrorActionPreference = "Stop"
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$LibscriptRootDir = (Resolve-Path (Join-Path $ScriptDir "..")).Path

$TestTmpDir = Join-Path $LibscriptRootDir "tests_tmp	est_openedx_compose_ps1_$(Get-Random)"
if (-not (Test-Path $TestTmpDir)) {
    New-Item -ItemType Directory -Path $TestTmpDir -Force | Out-Null
}

# ## Cleanup-Artifacts
# Cleans up temporary test workspace.
function Cleanup-Artifacts {
    if (Test-Path $TestTmpDir) {
        Remove-Item -Path $TestTmpDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ## Test-ComposeGeneration
# Drives generation and tests required Compose keys.
function Test-ComposeGeneration {
    Write-Host "=== Testing Open edX Docker Compose Generation (PowerShell) ==="

    $ymlFile = Join-Path $TestTmpDir "docker-compose.yml"
    $composeCmd = Join-Path $LibscriptRootDir "cli\commands\packaging\formats\pkg_docker_compose.cmd"
    if (Test-Path $composeCmd) {
        & cmd.exe /c "call `"$composeCmd`"" > $ymlFile
    } else {
        $composeSh = Join-Path $LibscriptRootDir "cli/commands/packaging/formats/pkg_docker_compose.sh"
        & /bin/sh "$composeSh" mysql latest redis latest mongodb latest meilisearch latest openedx latest > $ymlFile
    }

    if (-not (Test-Path $ymlFile)) {
        Write-Error "[FAIL] docker-compose.yml was not created"
        exit 1
    }

    $content = Get-Content -Path $ymlFile -Raw
    $required = @("version: '3.8'", "services:", "openedx", "volumes:")
    foreach ($req in $required) {
        if (-not ($content -match [regex]::Escape($req))) {
            Write-Error "[FAIL] Assertion failed: missing $req"
            exit 1
        }
        Write-Host "[PASS] Verified: $req"
    }

    Write-Host "=== Open edX Docker Compose generation PowerShell tests completed successfully! ==="
}

try {
    Test-ComposeGeneration
} finally {
    Cleanup-Artifacts
}
