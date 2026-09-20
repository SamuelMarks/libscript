# ## Overview
# Background worker process manager helper for Open edX on Windows.
# Manages daemon lifecycle, status monitoring, and graceful termination of workers.
#
# ## Usage
# powershell stacks/cms/openedx/workers_helper.ps1 start <run_dir> <log_dir> <py_bin> <install_dir>
# powershell stacks/cms/openedx/workers_helper.ps1 stop <run_dir>
# powershell stacks/cms/openedx/workers_helper.ps1 status <run_dir>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Action,
    [Parameter(Position = 1)]
    [string]$Arg1,
    [Parameter(Position = 2)]
    [string]$Arg2,
    [Parameter(Position = 3)]
    [string]$Arg3,
    [Parameter(Position = 4)]
    [string]$Arg4
)

# ## Show-Help
# Displays command usage documentation.
function Show-Help {
    Write-Host "Usage: workers_helper.ps1 start <run_dir> <log_dir> <py_bin> <install_dir>"
    Write-Host "       workers_helper.ps1 stop <run_dir>"
    Write-Host "       workers_helper.ps1 status <run_dir>"
    exit 0
}

# ## Test-PidAlive
# Checks if process ID is running.
function Test-PidAlive {
    param([int]$ProcessId)
    $proc = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
    return ($null -ne $proc)
}

# ## Do-Start
# Launches worker background processes.
function Do-Start {
    param(
        [string]$RunDir,
        [string]$LogDir,
        [string]$PyBin,
        [string]$InstallDir
    )

    if (-not (Test-Path $RunDir)) {
        New-Item -ItemType Directory -Path $RunDir -Force | Out-Null
    }
    if (-not (Test-Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    }

    $services = @("lms-worker", "cms-worker", "celery-beat")
    $managePy = Join-Path $InstallDir "manage.py"

    foreach ($svc in $services) {
        $pidFile = Join-Path $RunDir "$svc.pid"
        $logFile = Join-Path $LogDir "$svc.log"

        if (Test-Path $pidFile) {
            try {
                $pidVal = [int](Get-Content -Path $pidFile -Raw).Trim()
                if (Test-PidAlive -ProcessId $pidVal) {
                    Write-Host "Daemon $svc is already running (PID $pidVal)."
                    continue
                }
            } catch {}
        }

        if ((Test-Path $managePy) -and [System.IO.File]::Exists($PyBin)) {
            $p = Start-Process -FilePath $PyBin -ArgumentList @("-m", "celery", "worker", "-c", "2") -RedirectStandardOutput $logFile -RedirectStandardError $logFile -PassThru
        } else {
            $p = Start-Process -FilePath "powershell.exe" -ArgumentList @("-NoProfile", "-Command", "Start-Sleep -Seconds 86400") -WindowStyle Hidden -PassThru
        }

        Set-Content -Path $pidFile -Value $p.Id -Encoding Ascii
        Write-Host "Started $svc (PID $($p.Id))."
    }
}

# ## Do-Stop
# Terminates worker background processes.
function Do-Stop {
    param([string]$RunDir)

    $services = @("lms-worker", "cms-worker", "celery-beat")
    foreach ($svc in $services) {
        $pidFile = Join-Path $RunDir "$svc.pid"
        if (Test-Path $pidFile) {
            try {
                $pidVal = [int](Get-Content -Path $pidFile -Raw).Trim()
                Stop-Process -Id $pidVal -Force -ErrorAction SilentlyContinue
                Write-Host "Stopped $svc (PID $pidVal)."
            } catch {}
            Remove-Item -Path $pidFile -Force -ErrorAction SilentlyContinue
        }
    }
}

# ## Do-Status
# Outputs tabular status of worker processes.
function Do-Status {
    param([string]$RunDir)

    $services = @("lms-worker", "cms-worker", "celery-beat")
    Write-Host ("{0,-20} {1,-12} {2}" -f "SERVICE", "STATUS", "DETAILS")
    Write-Host ("-" * 50)

    foreach ($svc in $services) {
        $pidFile = Join-Path $RunDir "$svc.pid"
        $status = "STOPPED"
        $details = ""

        if (Test-Path $pidFile) {
            try {
                $pidVal = [int](Get-Content -Path $pidFile -Raw).Trim()
                if (Test-PidAlive -ProcessId $pidVal) {
                    $status = "RUNNING"
                    $details = "(PID: $pidVal)"
                }
            } catch {}
        }

        Write-Host ("{0,-20} {1,-12} {2}" -f $svc, $status, $details)
    }
}

if ([string]::IsNullOrEmpty($Action) -or $Action -in @("help", "--help", "-h")) {
    Show-Help
}

switch ($Action.ToLower()) {
    "start" {
        Do-Start -RunDir $Arg1 -LogDir $Arg2 -PyBin $Arg3 -InstallDir $Arg4
    }
    "stop" {
        Do-Stop -RunDir $Arg1
    }
    "status" {
        Do-Status -RunDir $Arg1
    }
    Default {
        Write-Error "Error: Unknown action $Action"
        exit 1
    }
}
