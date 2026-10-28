# ## Overview
# Manages persistent background WSGI processes for Open edX LMS and Studio CMS on Windows.
#
# ## Usage
# powershell -File service_worker.ps1 [start|stop|status] [lmsPort] [cmsPort]

param(
    [string]$Action = "status",
    [int]$LmsPort = 8000,
    [int]$CmsPort = 8001
)

$openEdxDir = if ($env:OPENEDX_INSTALL_DIR) { $env:OPENEDX_INSTALL_DIR } elseif (Test-Path "$env:USERPROFILE\.libscript\openedx") { "$env:USERPROFILE\.libscript\openedx" } else { Join-Path $env:USERPROFILE ".libscript\openedx" }
$codebaseDir = $openEdxDir
if (Test-Path (Join-Path $openEdxDir "codebase\manage.py")) {
    $codebaseDir = Join-Path $openEdxDir "codebase"
} else {
    $nestedManage = Get-ChildItem -Path (Join-Path $openEdxDir "codebase") -Filter "manage.py" -Recurse -Depth 2 -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($nestedManage) {
        $codebaseDir = $nestedManage.DirectoryName
    } else {
        $rootNested = Get-ChildItem -Path $openEdxDir -Filter "manage.py" -Recurse -Depth 2 -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($rootNested) { $codebaseDir = $rootNested.DirectoryName }
    }
}
$logDir = Join-Path $openEdxDir "logs"
$runDir = Join-Path $openEdxDir "run"

if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
if (-not (Test-Path $runDir)) { New-Item -ItemType Directory -Path $runDir -Force | Out-Null }

$pyExe = $null
$candidates = @(
    (Join-Path $openEdxDir ".venv\Scripts\python.exe"),
    "$env:USERPROFILE\.libscript\openedx\.venv\Scripts\python.exe",
    "C:\OpenEdX\app\.venv\Scripts\python.exe",
    "$env:USERPROFILE\.libscript\python\latest\bin\python.exe",
    "$env:LOCALAPPDATA\Programs\Python\Python312-arm64\python.exe",
    "$env:LOCALAPPDATA\Programs\Python\Python311-arm64\python.exe",
    "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
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

# ## Start-OpenEdxServices
# Starts real Open edX LMS and Studio CMS WSGI processes using waitress or Django runserver.
function Start-OpenEdxServices {
    $managePy = Join-Path $codebaseDir "manage.py"
    if (-not (Test-Path $managePy)) {
        Write-Error "[ERROR] Real Open edX codebase (manage.py) not found at $managePy."
        exit 1
    }
    if (-not $pyExe -or -not (Test-Path $pyExe)) {
        Write-Error "[ERROR] Python runtime not found."
        exit 1
    }

    $waitressExe = Join-Path (Split-Path -Parent $pyExe) "waitress-serve.exe"
    $env:LMS_CFG = Join-Path $openEdxDir "config\lms.env.json"
    $env:CMS_CFG = Join-Path $openEdxDir "config\cms.env.json"
    $env:PYTHONPATH = $codebaseDir

    if (Test-Path $waitressExe) {
        $env:DJANGO_SETTINGS_MODULE = "lms.envs.libscript"
        $lmsProc = Start-Process -FilePath $waitressExe -ArgumentList "--listen=0.0.0.0:$LmsPort", "lms.wsgi:application" -WorkingDirectory $codebaseDir -RedirectStandardOutput (Join-Path $logDir "lms.log") -RedirectStandardError (Join-Path $logDir "lms_err.log") -WindowStyle Hidden -PassThru
        $env:DJANGO_SETTINGS_MODULE = "cms.envs.libscript"
        $cmsProc = Start-Process -FilePath $waitressExe -ArgumentList "--listen=0.0.0.0:$CmsPort", "cms.wsgi:application" -WorkingDirectory $codebaseDir -RedirectStandardOutput (Join-Path $logDir "cms.log") -RedirectStandardError (Join-Path $logDir "cms_err.log") -WindowStyle Hidden -PassThru
    } else {
        $env:DJANGO_SETTINGS_MODULE = "lms.envs.libscript"
        $lmsProc = Start-Process -FilePath $pyExe -ArgumentList "-m", "waitress", "--listen=0.0.0.0:$LmsPort", "lms.wsgi:application" -WorkingDirectory $codebaseDir -RedirectStandardOutput (Join-Path $logDir "lms.log") -RedirectStandardError (Join-Path $logDir "lms_err.log") -WindowStyle Hidden -PassThru
        $env:DJANGO_SETTINGS_MODULE = "cms.envs.libscript"
        $cmsProc = Start-Process -FilePath $pyExe -ArgumentList "-m", "waitress", "--listen=0.0.0.0:$CmsPort", "cms.wsgi:application" -WorkingDirectory $codebaseDir -RedirectStandardOutput (Join-Path $logDir "cms.log") -RedirectStandardError (Join-Path $logDir "cms_err.log") -WindowStyle Hidden -PassThru
    }

    Set-Content -Path (Join-Path $runDir "lms.pid") -Value $lmsProc.Id -Encoding Ascii
    Set-Content -Path (Join-Path $runDir "cms.pid") -Value $cmsProc.Id -Encoding Ascii
    Start-Sleep -Seconds 2
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path (Join-Path $logDir "install.log") -Value "[$ts] [INFO] Started real Open edX LMS (:$LmsPort, PID $($lmsProc.Id)) and Studio CMS (:$CmsPort, PID $($cmsProc.Id))."
    Write-Host "[PASS] Started Open edX LMS (:$LmsPort) and Studio CMS (:$CmsPort)"
}

# ## Stop-OpenEdxServices
# Stops running Open edX LMS and Studio CMS processes.
function Stop-OpenEdxServices {
    foreach ($pf in @("lms.pid", "cms.pid")) {
        $pPath = Join-Path $runDir $pf
        if (Test-Path $pPath) {
            $procId = (Get-Content $pPath -Raw).Trim()
            if ($procId -match "^\d+$") {
                Stop-Process -Id ([int]$procId) -Force -ErrorAction SilentlyContinue
            }
            Remove-Item -Path $pPath -Force -ErrorAction SilentlyContinue
        }
    }
    Get-NetTCPConnection -LocalPort $LmsPort, $CmsPort -ErrorAction SilentlyContinue | ForEach-Object {
        Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue
    }
    Write-Host "[PASS] Stopped Open edX WSGI servers"
}

# ## Get-OpenEdxServiceStatus
# Prints the listening status of LMS and Studio CMS ports.
function Get-OpenEdxServiceStatus {
    $lmsRunning = (Test-NetConnection -ComputerName 127.0.0.1 -Port $LmsPort -InformationLevel Quiet)
    $cmsRunning = (Test-NetConnection -ComputerName 127.0.0.1 -Port $CmsPort -InformationLevel Quiet)
    Write-Host "  LMS ($LmsPort): $(if ($lmsRunning) { '[RUNNING]' } else { '[STOPPED]' })"
    Write-Host "  CMS ($CmsPort): $(if ($cmsRunning) { '[RUNNING]' } else { '[STOPPED]' })"
}

if ($Action -eq "start") {
    Start-OpenEdxServices
} elseif ($Action -eq "stop") {
    Stop-OpenEdxServices
} elseif ($Action -eq "status") {
    Get-OpenEdxServiceStatus
} else {
    Write-Error "Usage: service_worker.ps1 [start|stop|status] [lmsPort] [cmsPort]"
    exit 1
}
