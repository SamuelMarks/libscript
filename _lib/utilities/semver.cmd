@echo off
:: # semver.cmd
::
:: ## Overview
:: Evaluates Semantic Versioning constraints on Windows.
::
:: ## Usage
:: semver.cmd <version> <constraint>

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "v=%~1"
set "c=%~2"

if "%v%"=="" (
    echo Usage: %~nx0 ^<version^> ^<constraint^> 1>&2
    exit /b 2
)
if "%c%"=="" (
    echo Usage: %~nx0 ^<version^> ^<constraint^> 1>&2
    exit /b 2
)

where jq >nul 2>&1
if %errorlevel% equ 0 (
    jq -e -L "%SCRIPT_DIR%" -n --arg v "%v%" --arg c "%c%" "include \"semver\"; semver_satisfies($v; $c)" >nul 2>&1
    exit /b !errorlevel!
)

powershell -NoProfile -Command "exit 0"
exit /b %errorlevel%
