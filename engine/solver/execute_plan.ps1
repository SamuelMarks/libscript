<#
.SYNOPSIS
## Overview
Linear execution plan runner for LibScript builds on Windows PowerShell.
Reads a deterministic execution-plan.json, iterates over stages and tasks,
checks and updates idempotency stage stamp files, and orchestrates task executions.

## Usage
.\execute_plan.ps1 -PlanFile <path_to_execution_plan.json> [-DryRun]
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$PlanFile,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$repoRoot = if ($env:LIBSCRIPT_ROOT_DIR -and (Test-Path $env:LIBSCRIPT_ROOT_DIR)) {
    (Resolve-Path $env:LIBSCRIPT_ROOT_DIR).Path
} else {
    $d = $scriptDir
    while ($d -and -not (Test-Path (Join-Path $d "libscript.cmd"))) {
        $p = Split-Path -Parent $d
        if ($p -eq $d) { break }
        $d = $p
    }
    $d
}

if (-not (Test-Path $PlanFile)) {
    Write-Error "[ERROR] Execution plan file not found: $PlanFile"
    exit 1
}

$plan = Get-Content $PlanFile -Raw | ConvertFrom-Json

$targetSysroot = $env:LIBSCRIPT_TARGET_SYSROOT
if ([string]::IsNullOrWhiteSpace($targetSysroot)) {
    $targetSysroot = Join-Path $repoRoot "build\target-sysroot"
}

$stampsDir = Join-Path $targetSysroot "var\lib\libscript\stamps"
if (-not $DryRun -and -not (Test-Path $stampsDir)) {
    New-Item -ItemType Directory -Path $stampsDir -Force | Out-Null
}

foreach ($stage in $plan.stages) {
    Write-Host ""
    Write-Host "[STAGE] === $($stage.stage) ===" -ForegroundColor Cyan
    if ($stage.description) {
        Write-Host "[INFO]  $($stage.description)" -ForegroundColor DarkGray
    }

    foreach ($task in $stage.tasks) {
        $stampFile = Join-Path $stampsDir $task.stamp
        if (Test-Path $stampFile) {
            Write-Host "[SKIP]  Task `"$($task.name)`" ($($task.action)) already satisfied by $($task.stamp)" -ForegroundColor DarkGreen
        } else {
            Write-Host "[RUN]   Task `"$($task.name)`" ($($task.action)) [$($task.component)]" -ForegroundColor Yellow
            if ($DryRun) {
                Write-Host "[DRYRUN] Would execute $($task.action) on $($task.component) and touch $stampFile" -ForegroundColor Magenta
            } else {
                $execCmd = Join-Path $repoRoot "$($task.component)\setup.cmd"
                $execScript = Join-Path $repoRoot "$($task.component)\setup.ps1"
                if (Test-Path $execCmd) {
                    & cmd.exe /c "`"$execCmd`" $($task.action)"
                } elseif (Test-Path $execScript) {
                    & $execScript $task.action
                } else {
                    Write-Host "[INFO]  No leaf script for $($task.component); registering step completion" -ForegroundColor DarkGray
                }
                Set-Content -Path $stampFile -Value (Get-Date -Format "o")
                Write-Host "[OK]    Completed `"$($task.name)`" -> $($task.stamp)" -ForegroundColor Green
            }
        }
    }
}

Write-Host ""
Write-Host "[SUCCESS] All execution plan stages processed successfully." -ForegroundColor Green
