@echo off
:: # click_button.cmd
::
:: ## Overview
:: Automates finding and clicking UI controls (buttons, checkboxes, radio buttons) by text in Windows GUI sessions.
::
:: ## Usage
:: call "%~dp0click_button.cmd" [button_text]

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

:: ## setup_target
:: Configures target button text and log location.
:setup_target
set "PS_SCRIPT=%SCRIPT_DIR%\click_button.ps1"
if not exist "%PS_SCRIPT%" set "PS_SCRIPT=C:\libscript\click_button.ps1"

set "LOG_FILE=%TEMP%\libscript_click.log"
if not exist "%TEMP%" set "LOG_FILE=%SCRIPT_DIR%\click.log"

if not "%~1"=="" (
  echo %~1> "%TEMP%\target_btn.txt"
)

:: ## run_click
:: Executes the click automation via PowerShell Win32 API bridge.
:run_click
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%PS_SCRIPT%" > "%LOG_FILE%" 2>&1
exit /b %ERRORLEVEL%
