@echo off
:: # launch_browser.cmd
::
:: ## Overview
:: Resilient browser launcher utility for Windows.
:: Launches default or installed browsers (Edge, Chrome, Firefox) targeting the specified URL.
:: If no browser is present, creates an Internet Shortcut on the Desktop to avoid
:: Windows modal "Application not found" dialog errors.
::
:: ## Usage
:: call packaging\launch_browser.cmd <url> [shortcut_name]
::
:: ## Arguments
::   url            The web address to open (e.g. http://localhost:8000)
::   shortcut_name  Optional name for the desktop shortcut fallback

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

if "%~1"=="" goto show_help
if "%~1"=="--help" goto show_help
if "%~1"=="-h" goto show_help
if "%~1"=="/?" goto show_help

set "URL=%~1"
set "NAME=%~2"
if "%NAME%"=="" set "NAME=Open edX Portal"

powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\launch_browser.ps1" -Url "%URL%" -ShortcutName "%NAME%"
exit /b 0

:: ## show_help
:: Executes show_help functionality.
:show_help
echo Usage: %~nx0 ^<url^> [shortcut_name]
echo.
echo Launches an available web browser or creates a desktop URL shortcut fallback.
exit /b 0
