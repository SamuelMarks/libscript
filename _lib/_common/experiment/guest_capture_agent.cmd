@echo off
:: # guest_capture_agent.cmd
:: ## Overview
:: Guest-side native screen, desktop icon, and browser CDP authentication capture wrapper on Windows (`Steps 3-5`).
:: ## Usage
:: guest_capture_agent.cmd <screen|desktop|browser> [args...]

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
if exist "!d!\libscript.cmd" ( set "LIBSCRIPT_ROOT_DIR=!d!" & exit /b 0 )
if exist "!d!\ROOT" ( set "LIBSCRIPT_ROOT_DIR=!d!" & exit /b 0 )
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    set "LIBSCRIPT_ROOT_DIR=!SCRIPT_DIR!"
    exit /b 0
)
goto :find_root

:: ## root_found
:: Delegates execution to the companion Session 1 PowerShell guest_capture_agent.ps1 script.
:root_found
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "!SCRIPT_DIR!\guest_capture_agent.ps1" %*
exit /b !errorlevel!
