@echo off
:: # env.cmd
::
:: ## Overview
:: Windows environment configuration and runtime path exports for `libtpu-rs` (`LIBTPU_RS_DIR`, `LIBTPU_RS_SO`, `LIBTPU_RS_SDK_SO`, `LIBTPU_RS_WHEEL`, `LIBTPU_RS_SO_SHA256`).
::
:: ## Usage
:: call _lib\toolchains\libtpu-rs\env.cmd

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

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%LIBTPU_RS_VERSION%"=="" (
    set "LIBTPU_RS_VERSION=0.0.52"
)
set "_LTR_EXACT=%LIBTPU_RS_VERSION%"
if /i "!_LTR_EXACT!"=="latest" set "_LTR_EXACT=0.0.52"
if /i "!_LTR_EXACT!"=="lts" set "_LTR_EXACT=0.0.52"
set "_LTR_BASE=%LIBSCRIPT_HOME%\libtpu-rs\!_LTR_EXACT!"
set "_LTR_SO=%LIBTPU_RS_SO_PATH%"
if "!_LTR_SO!"=="" set "_LTR_SO=!_LTR_BASE!\lib\tpu.dll"
set "_LTR_SDK=%LIBTPU_RS_SDK_SO_PATH%"
if "!_LTR_SDK!"=="" set "_LTR_SDK=!_LTR_BASE!\lib\sdk.dll"
set "_LTR_WHL=%LIBTPU_RS_WHEEL_PATH%"
if "!_LTR_WHL!"=="" (
    if exist "!_LTR_BASE!\wheels\wheel_path.txt" (
        set /p _LTR_WHL=<"!_LTR_BASE!\wheels\wheel_path.txt"
    )
)
set "_LTR_SHA=%LIBTPU_RS_SO_SHA256%"
if "!_LTR_SHA!"=="" (
    if exist "!_LTR_BASE!\lib\libtpu_so_sha256.txt" (
        set /p _LTR_SHA=<"!_LTR_BASE!\lib\libtpu_so_sha256.txt"
    )
)
set "_LTR_TPU_LP=%TPU_LIBRARY_PATH%"
if "%LIBTPU_RS_ACTIVATE_TPU_LIBRARY_PATH%"=="1" set "_LTR_TPU_LP=!_LTR_SO!"

set "_CAND_P=!_LTR_BASE!\bin"
echo ";!PATH!;" | findstr /I /C:";!_CAND_P!;" >nul 2>&1
if errorlevel 1 set "PATH=!_CAND_P!;!PATH!"
set "CALLER_SCRIPT_DIR=%SCRIPT_DIR%"
call "%LIBSCRIPT_ROOT_DIR%\engine\common\env_base.cmd" "libtpu-rs" "!_LTR_EXACT!"

endlocal & (
    set "LIBTPU_RS_VERSION=%LIBTPU_RS_VERSION%"
    set "LIBSCRIPT_HOME=%LIBSCRIPT_HOME%"
    set "LIBTPU_RS_DIR=%_LTR_BASE%"
    set "LIBTPU_RS_SO=%_LTR_SO%"
    set "LIBTPU_RS_SDK_SO=%_LTR_SDK%"
    set "LIBTPU_RS_WHEEL=%_LTR_WHL%"
    set "LIBTPU_RS_SO_SHA256=%_LTR_SHA%"
    set "TPU_LIBRARY_PATH=%_LTR_TPU_LP%"
    set "PATH=%PATH%"
)
exit /b 0
