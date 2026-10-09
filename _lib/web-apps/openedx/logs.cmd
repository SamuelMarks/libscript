@echo off
:: # logs.cmd
::
:: ## Overview
:: Command-line interface to tail log files for the Open edX stack on Windows.
:: Supports tailing install logs, web server logs, or worker logs.
::
:: ## Usage
::   call logs.cmd [target] [-n NUM]

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
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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

set "TARGET=install"
set "LINES=50"
set "FOLLOW=0"

:parse_args
if "%~1"=="" goto run_logs
if /i "%~1"=="-n" (
    set "LINES=%~2"
    shift
    shift
    goto parse_args
)
if /i "%~1"=="--lines" (
    set "LINES=%~2"
    shift
    shift
    goto parse_args
)
if /i "%~1"=="--tail" (
    set "LINES=%~2"
    shift
    shift
    goto parse_args
)
if /i "%~1"=="-f" (
    set "FOLLOW=1"
    shift
    goto parse_args
)
if /i "%~1"=="--follow" (
    set "FOLLOW=1"
    shift
    goto parse_args
)
if /i "%~1"=="help" goto show_help
if /i "%~1"=="--help" goto show_help
if /i "%~1"=="-h" goto show_help

set "TARGET=%~1"
shift
goto parse_args

:show_help
echo Usage: logs.cmd [install^|lms^|cms^|worker] [-n NUM^|--tail NUM] [-f^|--follow]
exit /b 0

:run_logs
if "%OPENEDX_INSTALL_DIR%"=="" (
    if defined LIBSCRIPT_HOME (
        set "OPENEDX_INSTALL_DIR=%LIBSCRIPT_HOME%\openedx"
    ) else (
        set "OPENEDX_INSTALL_DIR=%USERPROFILE%\.libscript\openedx"
    )
)
set "OPENEDX_LOG_DIR=%OPENEDX_INSTALL_DIR%\logs"

if "%TARGET%"=="install" (
    set "LOG_FILE=%OPENEDX_LOG_DIR%\install.log"
) else if "%TARGET%"=="lms" (
    set "LOG_FILE=%OPENEDX_LOG_DIR%\lms.log"
) else if "%TARGET%"=="cms" (
    set "LOG_FILE=%OPENEDX_LOG_DIR%\cms.log"
) else if "%TARGET%"=="worker" (
    set "LOG_FILE=%OPENEDX_LOG_DIR%\worker.log"
) else (
    echo Unknown log target: %TARGET% >&2
    exit /b 1
)

if not exist "%LOG_FILE%" (
    echo Log file not found: %LOG_FILE% >&2
    exit /b 0
)

where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    if "%FOLLOW%"=="1" (
        powershell -NoProfile -Command "Get-Content -Path '%LOG_FILE%' -Tail %LINES% -Wait"
    ) else (
        powershell -NoProfile -Command "Get-Content -Path '%LOG_FILE%' -Tail %LINES%"
    )
    exit /b %ERRORLEVEL%
)

echo [ERROR] PowerShell interpreter not found. >&2
exit /b 1
