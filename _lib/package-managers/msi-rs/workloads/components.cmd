@echo off
:: # components.cmd
:: ## Overview
:: Generic msi-rs workload driver staging an arbitrary component list ({c0, c1, ...}) on Windows.
:: ## Usage
:: components.cmd <target_dir> <c0,c1,...>

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

set "TARGET_DIR=%~1"
if "!TARGET_DIR!"=="" set "TARGET_DIR=!LIBSCRIPT_ROOT_DIR!\build\target-sysroot"
set "COMPONENTS_CSV=%~2"
if "!COMPONENTS_CSV!"=="" set "COMPONENTS_CSV=%MSI_RS_COMPONENTS%"

if "!COMPONENTS_CSV!"=="" exit /b 0

for %%C in (!COMPONENTS_CSV!) do (
    set "LIBSCRIPT_TARGET_SYSROOT=!TARGET_DIR!"
    set "LIBSCRIPT_IMAGE_BUILD=1"
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install "%%C" latest || exit /b 1
)
exit /b 0

:: ## show_help
:: Displays usage instructions for components.cmd.
:show_help
echo Usage: %~nx0 ^<target_dir^> ^<c0,c1,...^>
exit /b 0
