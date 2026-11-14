@echo off
:: # setup_generic.cmd
:: ## Overview
:: Multi-Unikernel Pod Composer decomposing multi-daemon component sets on Windows.
:: ## Usage
:: setup_generic.cmd [install|assemble|clean] [--framework=<fw>] [--components=<c0,c1,...>]

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

set "FRAMEWORK=unikraft"
if not "%LIBSCRIPT_UNIKERNEL_FRAMEWORK%"=="" set "FRAMEWORK=%LIBSCRIPT_UNIKERNEL_FRAMEWORK%"
set "DAEMONS_CSV=redis"
if not "%LIBSCRIPT_POD_DAEMONS%"=="" set "DAEMONS_CSV=%LIBSCRIPT_POD_DAEMONS%"
set "TARGET_SYSROOT=!LIBSCRIPT_ROOT_DIR!\build\target-sysroot"
if not "%LIBSCRIPT_TARGET_SYSROOT%"=="" set "TARGET_SYSROOT=%LIBSCRIPT_TARGET_SYSROOT%"
set "POD_DIR=!TARGET_SYSROOT!\unikernel-pod"
if not "%UNIKERNEL_POD_OUT_DIR%"=="" set "POD_DIR=%UNIKERNEL_POD_OUT_DIR%"

if not exist "!POD_DIR!\appliances" mkdir "!POD_DIR!\appliances"
echo {"pod_version":"1.0.0","framework":"!FRAMEWORK!","daemons":"!DAEMONS_CSV!"}> "!POD_DIR!\pod-manifest.json"
echo [OK] Synthesized multi-unikernel pod manifest at !POD_DIR!\pod-manifest.json
exit /b 0
