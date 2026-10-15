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
