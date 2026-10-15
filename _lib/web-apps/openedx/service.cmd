@echo off
:: # service.cmd
::
:: ## Overview
:: Service lifecycle manager for the Open edX stack on Windows.
:: Controls starting, stopping, restarting, and status monitoring of LMS, Studio CMS,
:: and supporting stack infrastructure.
::
:: ## Usage
:: call service.cmd start
:: call service.cmd stop
:: call service.cmd restart
:: call service.cmd status
:: call service.cmd lms
:: call service.cmd studio
:: call service.cmd help
::
:: ## Exit Codes
:: 0 - Success
:: 1 - Error

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

if "%LIBSCRIPT_ROOT_DIR%"=="" (
    for %%i in ("%~dp0..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

if "%OPENEDX_INSTALL_DIR%"=="" (
    if defined LIBSCRIPT_HOME (
        set "OPENEDX_INSTALL_DIR=%LIBSCRIPT_HOME%\openedx"
    ) else (
        set "OPENEDX_INSTALL_DIR=%USERPROFILE%\.libscript\openedx"
    )
)

set "RUN_DIR=%OPENEDX_INSTALL_DIR%\run"
set "LOG_DIR=%OPENEDX_INSTALL_DIR%\logs"
if not exist "%RUN_DIR%" mkdir "%RUN_DIR%" 2>nul
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" 2>nul

set "LMS_PID_FILE=%RUN_DIR%\lms.pid"
set "CMS_PID_FILE=%RUN_DIR%\cms.pid"
if "%OPENEDX_LMS_PORT%"=="" set "OPENEDX_LMS_PORT=8000"
if "%OPENEDX_CMS_PORT%"=="" set "OPENEDX_CMS_PORT=8001"

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=status"
if "%ACTION%"=="help" goto show_help
if "%ACTION%"=="--help" goto show_help
if "%ACTION%"=="-h" goto show_help
if "%ACTION%"=="/?" goto show_help

if "%ACTION%"=="start" goto do_start
if "%ACTION%"=="stop" goto do_stop
if "%ACTION%"=="restart" goto do_restart
if "%ACTION%"=="status" goto do_status
if "%ACTION%"=="install-service" goto do_install_service
if "%ACTION%"=="uninstall-service" goto do_uninstall_service
if "%ACTION%"=="lms" goto do_lms
if "%ACTION%"=="studio" goto do_studio
if "%ACTION%"=="cms" goto do_studio

echo [ERROR] Unknown subcommand: %ACTION% >&2
goto show_help

:: ## show_help
:: Displays command-line usage instructions and available options.
:show_help
echo Open edX Service Manager (Windows)
echo.
echo Usage: %~nx0 ^<subcommand^>
echo.
echo Subcommands:
echo   start     Start LMS, Studio, and worker background services
echo   stop      Stop all running Open edX services
echo   restart   Restart all Open edX services
echo   status    Display health and listening status of all services
echo   lms       Check LMS status or launch in browser
echo   studio    Check Studio status or launch in browser
echo   help, -h  Show this help text
exit /b 0

:: ## do_start
:: Performs the do_start operation and updates component state.
:do_start
echo [INFO] Starting Open edX platform services...

:: Start LMS
powershell -NoProfile -Command "try { $c = [System.Net.Sockets.TcpClient]::new('127.0.0.1', %OPENEDX_LMS_PORT%); $c.Close(); exit 0 } catch { exit 1 }"
if %ERRORLEVEL%==0 (
    echo [INFO] Open edX LMS is already listening on port %OPENEDX_LMS_PORT%
) else (
    echo [INFO] Launching Open edX LMS on port %OPENEDX_LMS_PORT%...
    if exist "%OPENEDX_INSTALL_DIR%\.venv\Scripts\waitress-serve.exe" if exist "%OPENEDX_INSTALL_DIR%\codebase" (
        cd /D "%OPENEDX_INSTALL_DIR%\codebase"
        powershell -WindowStyle Hidden -Command "Start-Process '%OPENEDX_INSTALL_DIR%\.venv\Scripts\waitress-serve.exe' -ArgumentList '--listen=0.0.0.0:%OPENEDX_LMS_PORT% lms.wsgi:application' -RedirectStandardOutput '%LOG_DIR%\lms.log' -RedirectStandardError '%LOG_DIR%\lms_err.log' -WindowStyle Hidden"
    ) else if exist "%SCRIPT_DIR%\service_worker.ps1" (
        powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\service_worker.ps1" start %OPENEDX_LMS_PORT% %OPENEDX_CMS_PORT%
    ) else (
        echo [ERROR] Genuine Open edX codebase or waitress not found for LMS. >&2
        exit /b 1
    )
)

:: Start CMS
powershell -NoProfile -Command "try { $c = [System.Net.Sockets.TcpClient]::new('127.0.0.1', %OPENEDX_CMS_PORT%); $c.Close(); exit 0 } catch { exit 1 }"
if %ERRORLEVEL%==0 (
    echo [INFO] Open edX Studio CMS is already listening on port %OPENEDX_CMS_PORT%
) else (
    echo [INFO] Launching Open edX Studio CMS on port %OPENEDX_CMS_PORT%...
    if exist "%OPENEDX_INSTALL_DIR%\.venv\Scripts\waitress-serve.exe" if exist "%OPENEDX_INSTALL_DIR%\codebase" (
        cd /D "%OPENEDX_INSTALL_DIR%\codebase"
        powershell -WindowStyle Hidden -Command "Start-Process '%OPENEDX_INSTALL_DIR%\.venv\Scripts\waitress-serve.exe' -ArgumentList '--listen=0.0.0.0:%OPENEDX_CMS_PORT% cms.wsgi:application' -RedirectStandardOutput '%LOG_DIR%\cms.log' -RedirectStandardError '%LOG_DIR%\cms_err.log' -WindowStyle Hidden"
    )
)

:: Start Workers
if exist "%SCRIPT_DIR%\workers.cmd" call "%SCRIPT_DIR%\workers.cmd" start

echo [INFO] Waiting for LMS and CMS to become responsive...
powershell -NoProfile -Command "$ports = @(%OPENEDX_LMS_PORT%, %OPENEDX_CMS_PORT%); $timeout = 30; $sw = [System.Diagnostics.Stopwatch]::StartNew(); while ($sw.Elapsed.TotalSeconds -lt $timeout) { $allUp = $true; foreach ($p in $ports) { try { $c = [System.Net.Sockets.TcpClient]::new('127.0.0.1', $p); $c.Close() } catch { $allUp = $false } }; if ($allUp) { Write-Host '[PASS] Open edX platform services started and listening.'; exit 0 }; Start-Sleep -Seconds 2 }; Write-Error '[ERROR] Timeout waiting for Open edX services to start listening.'; exit 1"
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Services failed to start properly. Check logs. >&2
    exit /b 1
)

exit /b 0

:: ## do_stop
:: Performs the do_stop operation and updates component state.
:do_stop
echo [INFO] Stopping Open edX platform services...

:: Stop workers
if exist "%SCRIPT_DIR%\workers.cmd" call "%SCRIPT_DIR%\workers.cmd" stop

:: Terminate background python waitress WSGI listeners on ports if tracked
if exist "%SCRIPT_DIR%\service_worker.ps1" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\service_worker.ps1" stop %OPENEDX_LMS_PORT% %OPENEDX_CMS_PORT%
)
powershell -NoProfile -Command "Get-NetTCPConnection -LocalPort %OPENEDX_LMS_PORT%, %OPENEDX_CMS_PORT% -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }"

if exist "%LMS_PID_FILE%" del /f /q "%LMS_PID_FILE%" 2>nul
if exist "%CMS_PID_FILE%" del /f /q "%CMS_PID_FILE%" 2>nul
echo [PASS] Open edX platform services stopped.
exit /b 0

:: ## do_restart
:: Performs the do_restart operation and updates component state.
:do_restart
call :do_stop
call :do_start
exit /b 0

:: ## do_status
:: Performs the do_status operation and updates component state.
:do_status
echo ======================================================
echo              Open edX Platform Status (Windows)
echo ======================================================
powershell -NoProfile -Command "$ports = @{ 'LMS Portal' = %OPENEDX_LMS_PORT%; 'Studio CMS' = %OPENEDX_CMS_PORT%; 'MySQL' = 3306; 'Redis' = 6379; 'MongoDB' = 27017; 'Meilisearch' = 7700 }; foreach ($k in $ports.Keys) { $p = $ports[$k]; try { $c = [System.Net.Sockets.TcpClient]::new('127.0.0.1', $p); $c.Close(); Write-Host ('  ' + $k.PadRight(20) + ' (Port ' + $p + '): [RUNNING]') } catch { Write-Host ('  ' + $k.PadRight(20) + ' (Port ' + $p + '): [STOPPED]') } }"
if exist "%SCRIPT_DIR%\workers.cmd" call "%SCRIPT_DIR%\workers.cmd" status
echo ======================================================
exit /b 0

:: ## do_lms
:: Performs the do_lms operation and updates component state.
:do_lms
call :do_status
start http://localhost:%OPENEDX_LMS_PORT%
exit /b 0

:: ## do_studio
:: Performs the do_studio operation and updates component state.
:do_studio
call :do_status
start http://localhost:%OPENEDX_CMS_PORT%
exit /b 0

:: ## do_install_service
:: Performs the do_install_service operation and updates component state.
:do_install_service
echo [INFO] Installing Open edX native services...

call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" "openedx-lms" "%OPENEDX_INSTALL_DIR%\.venv\Scripts\waitress-serve.exe --listen=0.0.0.0:%OPENEDX_LMS_PORT% lms.wsgi:application" "%OPENEDX_INSTALL_DIR%\codebase" "Open edX LMS Service" ""
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" "openedx-cms" "%OPENEDX_INSTALL_DIR%\.venv\Scripts\waitress-serve.exe --listen=0.0.0.0:%OPENEDX_CMS_PORT% cms.wsgi:application" "%OPENEDX_INSTALL_DIR%\codebase" "Open edX Studio CMS Service" ""

call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" "openedx-lms-worker" "%OPENEDX_INSTALL_DIR%\.venv\Scripts\python.exe -m celery -A lms worker --loglevel=INFO -c 2" "%OPENEDX_INSTALL_DIR%\codebase" "Open edX LMS Celery Worker" ""
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" "openedx-cms-worker" "%OPENEDX_INSTALL_DIR%\.venv\Scripts\python.exe -m celery -A cms worker --loglevel=INFO -c 2" "%OPENEDX_INSTALL_DIR%\codebase" "Open edX CMS Celery Worker" ""
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" "openedx-celery-beat" "%OPENEDX_INSTALL_DIR%\.venv\Scripts\python.exe -m celery -A lms beat --loglevel=INFO" "%OPENEDX_INSTALL_DIR%\codebase" "Open edX Celery Beat Scheduler" ""

echo [PASS] Successfully installed Open edX services.
exit /b 0

:: ## do_uninstall_service
:: Performs the do_uninstall_service operation and updates component state.
:do_uninstall_service
echo [INFO] Uninstalling Open edX native services...
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" --uninstall "openedx-lms"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" --uninstall "openedx-cms"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" --uninstall "openedx-lms-worker"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" --uninstall "openedx-cms-worker"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" --uninstall "openedx-celery-beat"
echo [PASS] Successfully uninstalled Open edX services.
exit /b 0
