@echo off
:: # run_in_session1.cmd
::
:: ## Overview
:: Executes a target command inside Windows interactive desktop Session 1 via Task Scheduler (/IT) or native session runner.
::
:: ## Usage
:: run_in_session1.cmd [-Command <cmd> | <cmd> [args...]]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
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

if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help

set "TARGET_CMD=msiexec.exe /i C:\libscript\packaging\OpenEdX-Setup.msi"
if /I "%~1"=="-Command" (
    if not "%~2"=="" set "TARGET_CMD=%~2"
) else if /I "%~1"=="--command" (
    if not "%~2"=="" set "TARGET_CMD=%~2"
) else if not "%~1"=="" (
    set "TARGET_CMD=%*"
)

goto :dispatch_session1

:: ## show_help
:: Displays command-line usage instructions for Windows Session 1 execution.
:show_help
echo Usage: %~nx0 [-Command ^<cmd^> ^| ^<cmd^> [args...]]
echo Runs a command interactively within Windows Session 1.
exit /b 0

:: ## dispatch_session1
:: Schedules and runs the target command interactively in the logged-on user's desktop session.
:dispatch_session1
schtasks /Create /F /TN "LibScriptSession1Runner" /SC ONCE /ST 00:00 /IT /TR "!TARGET_CMD!" >nul 2>&1
if not errorlevel 1 (
    schtasks /Run /TN "LibScriptSession1Runner" >nul 2>&1
    set "RUN_RC=!ERRORLEVEL!"
    schtasks /Delete /F /TN "LibScriptSession1Runner" >nul 2>&1
    exit /b !RUN_RC!
)

cmd.exe /c "!TARGET_CMD!"
exit /b !ERRORLEVEL!
