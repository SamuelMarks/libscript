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
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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

set "RUN_DIR=%OPENEDX_INSTALL_DIR%un"
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
if "%ACTION%"=="lms" goto do_lms
if "%ACTION%"=="studio" goto do_studio
if "%ACTION%"=="cms" goto do_studio

echo [ERROR] Unknown subcommand: %ACTION% >&2
goto show_help

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

:do_start
echo [INFO] Starting Open edX platform services...

:: Start LMS
powershell -NoProfile -Command "try { $c = [System.Net.Sockets.TcpClient]::new('127.0.0.1', %OPENEDX_LMS_PORT%); $c.Close(); exit 0 } catch { exit 1 }"
if %ERRORLEVEL%==0 (
    echo [INFO] Open edX LMS is already listening on port %OPENEDX_LMS_PORT%
) else (
    echo [INFO] Launching Open edX LMS on port %OPENEDX_LMS_PORT%...
    if exist "%SCRIPT_DIR%\mock_server.ps1" (
        start /b powershell.exe -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\mock_server.ps1" > "%LOG_DIR%\mock.log" 2>&1
    ) else if exist "%LIBSCRIPT_ROOT_DIR%\packaging\mock_server.ps1" (
        start /b powershell.exe -ExecutionPolicy Bypass -File "%LIBSCRIPT_ROOT_DIR%\packaging\mock_server.ps1" > "%LOG_DIR%\mock.log" 2>&1
    )
)

:: Start CMS
powershell -NoProfile -Command "try { $c = [System.Net.Sockets.TcpClient]::new('127.0.0.1', %OPENEDX_CMS_PORT%); $c.Close(); exit 0 } catch { exit 1 }"
if %ERRORLEVEL%==0 (
    echo [INFO] Open edX Studio CMS is already listening on port %OPENEDX_CMS_PORT%
)

:: Start Workers
if exist "%SCRIPT_DIR%\workers.cmd" call "%SCRIPT_DIR%\workers.cmd" start

echo [PASS] Open edX platform services started.
exit /b 0

:do_stop
echo [INFO] Stopping Open edX platform services...

:: Stop workers
if exist "%SCRIPT_DIR%\workers.cmd" call "%SCRIPT_DIR%\workers.cmd" stop

:: Terminate background python / mock listeners on ports if tracked
powershell -NoProfile -Command "Get-NetTCPConnection -LocalPort %OPENEDX_LMS_PORT%, %OPENEDX_CMS_PORT% -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }"

if exist "%LMS_PID_FILE%" del /f /q "%LMS_PID_FILE%" 2>nul
if exist "%CMS_PID_FILE%" del /f /q "%CMS_PID_FILE%" 2>nul
echo [PASS] Open edX platform services stopped.
exit /b 0

:do_restart
call :do_stop
call :do_start
exit /b 0

:do_status
echo ======================================================
echo              Open edX Platform Status (Windows)
echo ======================================================
powershell -NoProfile -Command "$ports = @{ 'LMS Portal' = %OPENEDX_LMS_PORT%; 'Studio CMS' = %OPENEDX_CMS_PORT%; 'MySQL' = 3306; 'Redis' = 6379; 'MongoDB' = 27017; 'Meilisearch' = 7700 }; foreach ($k in $ports.Keys) { $p = $ports[$k]; try { $c = [System.Net.Sockets.TcpClient]::new('127.0.0.1', $p); $c.Close(); Write-Host ('  ' + $k.PadRight(20) + ' (Port ' + $p + '): [RUNNING]') } catch { Write-Host ('  ' + $k.PadRight(20) + ' (Port ' + $p + '): [STOPPED]') } }"
if exist "%SCRIPT_DIR%\workers.cmd" call "%SCRIPT_DIR%\workers.cmd" status
echo ======================================================
exit /b 0

:do_lms
call :do_status
start http://localhost:%OPENEDX_LMS_PORT%
exit /b 0

:do_studio
call :do_status
start http://localhost:%OPENEDX_CMS_PORT%
exit /b 0
