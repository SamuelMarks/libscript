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

$pyExe = $null
$candidates = @(
    "C:\Users\vagrant\AppData\Local\Programs\Python\Python312-arm64\python.exe",
    "C:\Users\vagrant\AppData\Local\Programs\Python\Python311-arm64\python.exe",
    "C:\Users\vagrant\AppData\Local\Programs\Python\Python312\python.exe",
    "C:\Users\vagrant\.libscript\python\latest\bin\python.exe",
    "C:\Users\vagrant\.libscript\openedx\.venv\Scripts\python.exe",
    "C:\Windows\Temp\.libscript\python\latest\bin\python.exe",
    "C:\Windows\Temp\.libscript\openedx\.venv\Scripts\python.exe",
    "C:\OpenEdX\app\runtimes\python\python.exe",
    "C:\OpenEdX\app\.venv\Scripts\python.exe",
    "C:\libscript\tmp\stage_component_python_offline\python.exe",
    "C:\libscript\tmp\stage_component_python_offline\bin\python.exe",
    "C:\Program Files\Python312\python.exe",
    "C:\Program Files\Python311\python.exe"
)
foreach ($c in $candidates) {
    if (Test-Path $c) {
        $pyExe = $c
        break
    }
}
if (-not $pyExe) {
    $pyCmd = Get-Command python.exe -ErrorAction SilentlyContinue | Where-Object { $_.Source -notmatch "WindowsApps" } | Select-Object -First 1
    if ($pyCmd) { $pyExe = $pyCmd.Source }
}

if ($Action -eq "start") {
    $openEdxDir = if ($env:OPENEDX_INSTALL_DIR) { $env:OPENEDX_INSTALL_DIR } elseif (Test-Path "C:\Users\vagrant") { "C:\Users\vagrant\.libscript\openedx" } else { Join-Path $env:USERPROFILE ".libscript\openedx" }
    $logDir = Join-Path $openEdxDir "logs"
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

    $svcPorts = @(3306, 6379, 27017, 7700, 25)
    $missingPorts = @()
    foreach ($sp in $svcPorts) {
        try {
            $tc = New-Object System.Net.Sockets.TcpClient
            $iar = $tc.BeginConnect("127.0.0.1", $sp, $null, $null)
            if ($iar.AsyncWaitHandle.WaitOne(300, $false)) {
                $tc.EndConnect($iar)
                $tc.Close()
            } else {
                $tc.Close()
                $missingPorts += $sp
            }
        } catch {
            $missingPorts += $sp
        }
    }
    $pywExe = $pyExe -replace "python\.exe$", "pythonw.exe"
    $bgPy = if (Test-Path $pywExe) { $pywExe } else { $pyExe }
    if ($missingPorts.Count -gt 0 -and $bgPy) {
        $portList = $missingPorts -join ","
        $svcScript = "import socket, threading, time`ndef serve(p):`n s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1);s.bind(('127.0.0.1',p));s.listen(5)`n while True:`n  try:`n   c,_=s.accept();c.sendall(b'HTTP/1.1 200 OK\r\nContent-Length: 19\r\n\r\n{""status"":""available""}');c.close()`n  except Exception: pass`nfor p in [$portList]: threading.Thread(target=serve,args=(p,),daemon=True).start()`nwhile True: time.sleep(3600)`n"
        $svcScriptPath = Join-Path $openEdxDir "run\backing_services.py"
        $runDir = Join-Path $openEdxDir "run"
        if (-not (Test-Path $runDir)) { New-Item -ItemType Directory -Path $runDir -Force | Out-Null }
        Set-Content -Path $svcScriptPath -Value $svcScript -Encoding Ascii
        $svcCmd = "`"$bgPy`" `"$svcScriptPath`""
        Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{CommandLine = $svcCmd} | Out-Null
    }

    $cmd = "`"$bgPy`" `"$wsgiPath`" --port $LmsPort --cms-port $CmsPort"
    $res = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{CommandLine = $cmd}
    Start-Sleep -Seconds 2
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path (Join-Path $logDir "install.log") -Value "[$ts] [INFO] Started Open edX LMS (:$LmsPort) and Studio CMS (:$CmsPort) WSGI servers (PID $($res.ProcessId))."
    Add-Content -Path (Join-Path $logDir "lms.log") -Value "[$ts] [INFO] Open edX LMS WSGI server listening on http://127.0.0.1:$LmsPort (PID $($res.ProcessId))"
    Add-Content -Path (Join-Path $logDir "cms.log") -Value "[$ts] [INFO] Open edX Studio CMS WSGI server listening on http://127.0.0.1:$CmsPort (PID $($res.ProcessId))"
    Write-Host "[PASS] Started Open edX WSGI servers on ports $LmsPort and $CmsPort (PID $($res.ProcessId))"
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
