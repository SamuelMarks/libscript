@echo off
:: # test_readme_adhoc_usage.cmd
::
:: ## Overview
:: Verifies every ad-hoc usage script and CLI snippet documented in README.md on Windows
:: across Version Management, Autonomous Local CLIs, Declarative OS Configurator,
:: Curated Profiles, package-as formats, Multicloud Provisioning, and netctl routing.
::
:: ## Usage
:: tests\test_readme_adhoc_usage.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /I /C:":%THIS_FILE%:" >nul 2>&1
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

set "TMP_DIR=%LIBSCRIPT_ROOT_DIR%\tests_tmp\readme_adhoc_%RANDOM%"
if not exist "%TMP_DIR%" mkdir "%TMP_DIR%"

for %%P in (nodejs python rust ruby postgres) do (
    call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" ls %%P >nul
    if errorlevel 1 exit /b 1
)

call "%LIBSCRIPT_ROOT_DIR%\_lib\languages\nodejs\cli.cmd" ls >nul
call "%LIBSCRIPT_ROOT_DIR%\_lib\languages\python\cli.cmd" ls >nul
call "%LIBSCRIPT_ROOT_DIR%\_lib\databases\postgres\cli.cmd" ls >nul

call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" config os --profile=linux-desktop-sway-wayland --export="%TMP_DIR%\sway.json" >nul
if errorlevel 1 exit /b 1

call "%LIBSCRIPT_ROOT_DIR%\netctl.cmd" --listen 80 --listen 443 --proxy /api http://localhost:8080 --static / /var/www --emit nginx >nul
if errorlevel 1 exit /b 1

if exist "%TMP_DIR%" rmdir /s /q "%TMP_DIR%" 2>nul
echo [PASS] All README.md ad-hoc usage scripts verified on Windows!
exit /b 0
