# ## Overview
# Manages persistent background WSGI processes for LMS and CMS via Windows Task Scheduler.
#
# ## Usage
# powershell -File service_worker.ps1 [start|stop|status] [lmsPort] [cmsPort]

param(
    [string]$Action = "status",
    [int]$LmsPort = 8000,
    [int]$CmsPort = 8001
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$wsgiPath = Join-Path $scriptDir "wsgi_server.py"

$pyCmd = Get-Command python.exe -ErrorAction SilentlyContinue
$pyExe = if ($pyCmd) { $pyCmd.Source } else { (Get-Command py.exe -ErrorAction SilentlyContinue).Source }
if (-not $pyExe -or -not (Test-Path $pyExe)) {
    $candidates = @(
        "C:\libscript\tmp\stage_component_python_offline\python.exe",
        "C:\libscript\tmp\stage_component_python_offline\bin\python.exe",
        "C:\Users\vagrant\AppData\Local\Programs\Python\Python312-arm64\python.exe",
        "C:\Users\vagrant\AppData\Local\Programs\Python\Python311-arm64\python.exe",
        "C:\Program Files\Python312\python.exe",
        "C:\Program Files\Python311\python.exe"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) {
            $pyExe = $c
            break
        }
    }
}

if ($Action -eq "start") {
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Days 365)
    $taskAction = New-ScheduledTaskAction -Execute $pyExe -Argument "`"$wsgiPath`" --port $LmsPort --cms-port $CmsPort"
    Register-ScheduledTask -TaskName "OpenEdXWsgi" -Action $taskAction -Settings $settings -Force | Out-Null
    Start-ScheduledTask -TaskName "OpenEdXWsgi"

    Write-Host "[PASS] Started Open edX WSGI servers on ports $LmsPort and $CmsPort"
} elseif ($Action -eq "stop") {
    "OpenEdXWsgi", "LmsWsgi", "CmsWsgi" | ForEach-Object {
        Stop-ScheduledTask -TaskName $_ -ErrorAction SilentlyContinue
        Unregister-ScheduledTask -TaskName $_ -Confirm:$false -ErrorAction SilentlyContinue
    }
    Get-NetTCPConnection -LocalPort $LmsPort, $CmsPort -ErrorAction SilentlyContinue | ForEach-Object {
        Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue
    }
    Write-Host "[PASS] Stopped Open edX WSGI servers"
} elseif ($Action -eq "status") {
    $lmsRunning = (Test-NetConnection -ComputerName 127.0.0.1 -Port $LmsPort -InformationLevel Quiet)
    $cmsRunning = (Test-NetConnection -ComputerName 127.0.0.1 -Port $CmsPort -InformationLevel Quiet)
    Write-Host "  LMS ($LmsPort): $(if ($lmsRunning) { '[RUNNING]' } else { '[STOPPED]' })"
    Write-Host "  CMS ($CmsPort): $(if ($cmsRunning) { '[RUNNING]' } else { '[STOPPED]' })"
}
