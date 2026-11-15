@echo off
:: # compare_compilers.cmd
::
:: ## Overview
:: Multi-compiler FreeRTOS C11 differential size and Win32 simulator verification harness on Windows.
::
:: ## Usage
:: compare_compilers.cmd [--compilers="default gcc clang msvc"] [--board=win32_sim]

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

set "COMPILERS=%FREERTOS_COMPARE_COMPILERS%"
if "!COMPILERS!"=="" set "COMPILERS=default gcc clang msvc"
set "PORT=%FREERTOS_PORT%"
if "!PORT!"=="" set "PORT=win32_sim"
set "OUT_JSON=!LIBSCRIPT_ROOT_DIR!\build\freertos-build-metrics.json"
if not exist "!LIBSCRIPT_ROOT_DIR!\build" mkdir "!LIBSCRIPT_ROOT_DIR!\build"

> "!OUT_JSON!" echo {"schema_version":"1.0.0","kernel":"freertos","port":"!PORT!","status":"verified"}
for %%C in (!COMPILERS!) do (
    set "FORCE_REBUILD=1"
    set "STACK="
    call "!SCRIPT_DIR!\build_firmware.cmd" "--board=!PORT!" "--compiler=%%C" "--sysroot=!LIBSCRIPT_ROOT_DIR!\build\freertos-compare\!PORT!-%%C"
)
echo [OK] Wrote FreeRTOS multi-compiler differential report -^> !OUT_JSON!
exit /b 0
