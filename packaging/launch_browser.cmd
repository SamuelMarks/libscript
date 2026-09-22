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
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if "%~1"=="" goto show_help
if "%~1"=="--help" goto show_help
if "%~1"=="-h" goto show_help
if "%~1"=="/?" goto show_help

set "URL=%~1"
set "NAME=%~2"
if "%NAME%"=="" set "NAME=Open edX Portal"

powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\launch_browser.ps1" -Url "%URL%" -ShortcutName "%NAME%"
exit /b 0

:show_help
echo Usage: %~nx0 ^<url^> [shortcut_name]
echo.
echo Launches an available web browser or creates a desktop URL shortcut fallback.
exit /b 0
