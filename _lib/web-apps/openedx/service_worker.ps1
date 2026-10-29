# cspell:words wmiclass
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

$openEdxDir = if ($env:OPENEDX_INSTALL_DIR) {
    $env:OPENEDX_INSTALL_DIR.TrimEnd('\')
} elseif (Test-Path "$env:ProgramData\OpenEdX\install_dir.txt") {
    (Get-Content "$env:ProgramData\OpenEdX\install_dir.txt" -Raw).Trim().TrimEnd('\')
} elseif (Test-Path "$env:USERPROFILE\.libscript\openedx") {
    "$env:USERPROFILE\.libscript\openedx"
} else {
    Join-Path $env:USERPROFILE ".libscript\openedx"
}
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
    $cfgDir = Join-Path $openEdxDir "config"
    $lmsCfg = if (Test-Path (Join-Path $cfgDir "lms.yml")) { Join-Path $cfgDir "lms.yml" } else { Join-Path $cfgDir "lms.env.json" }
    $cmsCfg = if (Test-Path (Join-Path $cfgDir "cms.yml")) { Join-Path $cfgDir "cms.yml" } else { Join-Path $cfgDir "cms.env.json" }
    $revCfg = Join-Path $cfgDir "revisions.yml"
    $staticLms = Join-Path $openEdxDir "staticfiles"
    $staticCms = Join-Path $openEdxDir "staticfiles\studio"

    $env:LMS_CFG = $lmsCfg
    $env:CMS_CFG = $cmsCfg
    $env:STUDIO_CFG = $cmsCfg
    $env:REVISION_CFG = $revCfg
    $env:STATIC_ROOT_LMS = $staticLms
    $env:STATIC_ROOT_CMS = $staticCms
    $env:OPENEDX_LMS_PORT = "$LmsPort"
    $env:OPENEDX_CMS_PORT = "$CmsPort"
    $env:PYTHONPATH = $codebaseDir
    $env:OAUTHLIB_INSECURE_TRANSPORT = "1"

    $lmsOut = Join-Path $logDir "lms.log"
    $lmsErr = Join-Path $logDir "lms_err.log"
    $cmsOut = Join-Path $logDir "cms.log"
    $cmsErr = Join-Path $logDir "cms_err.log"

    $hasFullEdxDeps = Test-Path (Join-Path $openEdxDir ".venv\Lib\site-packages\edx_django_utils")
    $lmsSettingsMod = if ($hasFullEdxDeps) { "lms.envs.production" } else { "lms.envs.libscript_win" }
    $cmsSettingsMod = if ($hasFullEdxDeps) { "cms.envs.production" } else { "cms.envs.libscript_win" }

    $lmsBat = Join-Path $runDir "start_lms.cmd"
    $cmsBat = Join-Path $runDir "start_cms.cmd"
    $waitressFlagsLms = "--listen=0.0.0.0:$LmsPort --threads=8 --channel-timeout=300 --max-request-header-size=32768 --max-request-body-size=2147483648 lms.wsgi:application"
    $waitressFlagsCms = "--listen=0.0.0.0:$CmsPort --threads=8 --channel-timeout=300 --max-request-header-size=32768 --max-request-body-size=2147483648 cms.wsgi:application"
    $runnerLms = if (Test-Path $waitressExe) { "`"$waitressExe`" $waitressFlagsLms" } else { "`"$pyExe`" -m waitress $waitressFlagsLms" }
    $runnerCms = if (Test-Path $waitressExe) { "`"$waitressExe`" $waitressFlagsCms" } else { "`"$pyExe`" -m waitress $waitressFlagsCms" }

    Set-Content -Path $lmsBat -Value "@echo off`r`ncd /d `"$codebaseDir`"`r`nset `"PYTHONPATH=$codebaseDir`"`r`nset `"OPENEDX_INSTALL_DIR=$openEdxDir`"`r`nset `"SERVICE_VARIANT=lms`"`r`nset `"DJANGO_SETTINGS_MODULE=$lmsSettingsMod`"`r`nset `"LMS_CFG=$lmsCfg`"`r`nset `"CMS_CFG=$cmsCfg`"`r`nset `"REVISION_CFG=$revCfg`"`r`nset `"STATIC_ROOT_LMS=$staticLms`"`r`nset `"STATIC_ROOT_CMS=$staticCms`"`r`nset `"OAUTHLIB_INSECURE_TRANSPORT=1`"`r`nset `"OPENEDX_LMS_PORT=$LmsPort`"`r`nset `"OPENEDX_CMS_PORT=$CmsPort`"`r`n$runnerLms > `"$lmsOut`" 2> `"$lmsErr`"`r`n" -Encoding Ascii
    Set-Content -Path $cmsBat -Value "@echo off`r`ncd /d `"$codebaseDir`"`r`nset `"PYTHONPATH=$codebaseDir`"`r`nset `"OPENEDX_INSTALL_DIR=$openEdxDir`"`r`nset `"SERVICE_VARIANT=cms`"`r`nset `"DJANGO_SETTINGS_MODULE=$cmsSettingsMod`"`r`nset `"LMS_CFG=$lmsCfg`"`r`nset `"CMS_CFG=$cmsCfg`"`r`nset `"STUDIO_CFG=$cmsCfg`"`r`nset `"REVISION_CFG=$revCfg`"`r`nset `"STATIC_ROOT_LMS=$staticLms`"`r`nset `"STATIC_ROOT_CMS=$staticCms`"`r`nset `"OAUTHLIB_INSECURE_TRANSPORT=1`"`r`nset `"OPENEDX_LMS_PORT=$LmsPort`"`r`nset `"OPENEDX_CMS_PORT=$CmsPort`"`r`n$runnerCms > `"$cmsOut`" 2> `"$cmsErr`"`r`n" -Encoding Ascii

    $si = ([wmiclass]"Win32_ProcessStartup").CreateInstance()
    $si.ShowWindow = 0
    $rLms = ([wmiclass]"Win32_Process").Create("cmd.exe /c `"$lmsBat`"", $codebaseDir, $si)
    $rCms = ([wmiclass]"Win32_Process").Create("cmd.exe /c `"$cmsBat`"", $codebaseDir, $si)

    Set-Content -Path (Join-Path $runDir "lms.pid") -Value $rLms.ProcessId -Encoding Ascii
    Set-Content -Path (Join-Path $runDir "cms.pid") -Value $rCms.ProcessId -Encoding Ascii
    Start-Sleep -Seconds 3
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path (Join-Path $logDir "install.log") -Value "[$ts] [INFO] Started real Open edX LMS (:$LmsPort, PID $($rLms.ProcessId)) and Studio CMS (:$CmsPort, PID $($rCms.ProcessId))."
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
