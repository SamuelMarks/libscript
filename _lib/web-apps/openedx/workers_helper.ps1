# ## Overview
# Background worker process manager helper for Open edX on Windows.
# Manages daemon lifecycle, status monitoring, and graceful termination of workers.
#
# ## Usage
# powershell _lib/web-apps/openedx/workers_helper.ps1 start <run_dir> <log_dir> <py_bin> <install_dir>
# powershell _lib/web-apps/openedx/workers_helper.ps1 stop <run_dir>
# powershell _lib/web-apps/openedx/workers_helper.ps1 status <run_dir>

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
    $managePy = Join-Path $InstallDir "codebase\manage.py"

    $resolvedPy = $null
    if ($PyBin -and (Test-Path $PyBin)) {
        $resolvedPy = $PyBin
    } else {
        $pyCandidates = @(
            "$env:LOCALAPPDATA\Programs\Python\Python312-arm64\python.exe",
            "$env:LOCALAPPDATA\Programs\Python\Python311-arm64\python.exe",
            "C:\Program Files\Python312\python.exe",
            "C:\Program Files\Python311\python.exe"
        )
        foreach ($c in $pyCandidates) {
            if (Test-Path $c) { $resolvedPy = $c; break }
        }
        if (-not $resolvedPy) {
            $cmd = Get-Command "python.exe" -ErrorAction SilentlyContinue
            if ($cmd) { $resolvedPy = $cmd.Source }
        }
    }

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

        $procId = $null
        $codebaseDir = if (Test-Path (Join-Path $InstallDir "codebase\manage.py")) { Join-Path $InstallDir "codebase" } else { $InstallDir }
        if ($resolvedPy -and (Test-Path $resolvedPy)) {
            $env:PYTHONPATH = $codebaseDir
            $env:LMS_CFG = Join-Path $InstallDir "config\lms.yml"
            $env:CMS_CFG = Join-Path $InstallDir "config\cms.yml"
            $env:STUDIO_CFG = Join-Path $InstallDir "config\cms.yml"
            $env:REVISION_CFG = Join-Path $InstallDir "config\revisions.yml"
            if ($svc -eq "cms-worker") {
                $env:SERVICE_VARIANT = "cms"
                $env:DJANGO_SETTINGS_MODULE = "cms.envs.production"
            } else {
                $env:SERVICE_VARIANT = "lms"
                $env:DJANGO_SETTINGS_MODULE = "lms.envs.production"
            }
            $scheduleFile = Join-Path $RunDir "celerybeat-schedule"
            $celeryArgList = switch ($svc) {
                "lms-worker"  { @("-m", "celery", "--app=lms.celery", "worker", "--pool=threads", "--concurrency=8", "--loglevel=info", "--hostname=edx.lms.core.default.%h", "--queues=edx.lms.core.default,edx.lms.core.high,edx.lms.core.high_mem", "--prefetch-multiplier=1", "--without-gossip", "--without-mingle") }
                "cms-worker"  { @("-m", "celery", "--app=cms.celery", "worker", "--pool=threads", "--concurrency=4", "--loglevel=info", "--hostname=edx.cms.core.default.%h", "--queues=edx.cms.core.default,edx.cms.core.high,edx.cms.core.low", "--prefetch-multiplier=1", "--without-gossip", "--without-mingle") }
                "celery-beat" { @("-m", "celery", "--app=lms.celery", "beat", "--loglevel=info", "--pidfile=$pidFile", "--schedule=$scheduleFile") }
            }
            $proc = Start-Process -FilePath $resolvedPy -ArgumentList $celeryArgList -WorkingDirectory $codebaseDir -RedirectStandardOutput $logFile -RedirectStandardError ($logFile -replace "\.log$", "_err.log") -WindowStyle Hidden -PassThru
            $procId = $proc.Id
        } else {
            Write-Error "Genuine Open edX codebase or python not found. Cannot start worker $svc."
            exit 1
        }

        Set-Content -Path $pidFile -Value $procId -Encoding Ascii
        Write-Host "Started $svc (PID $procId)."
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
