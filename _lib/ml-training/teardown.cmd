@echo off
:: # teardown.cmd
::
:: ## Overview
:: Tears down the provisioned Cloud TPU VM instance for the ML training evaluation node on Windows.
::
:: ## Usage
:: teardown.cmd [TPU_NAME]

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

if not "%~1"=="" set "TPU_NAME=%~1"
if "%TPU_NAME%"=="" set "TPU_NAME=ml-eval-node"
echo Tearing down TPU VM !TPU_NAME!...
call "!LIBSCRIPT_ROOT_DIR!\_lib\cloud-providers\gcp-tpu-vm\cli.cmd" delete "!TPU_NAME!"
set "_TD_RC=!ERRORLEVEL!"
if "%TFRC_STRICT%"=="1" set "_ML_TFRC=1"
if "%LIBSCRIPT_TFRC_STRICT%"=="1" set "_ML_TFRC=1"
if not "%TFRC_CONFIG%"=="" set "_ML_TFRC=1"
if not "%LIBSCRIPT_TFRC_CONFIG%"=="" set "_ML_TFRC=1"
if "!_ML_TFRC!"=="1" if not "%TPU_ZONE%"=="" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\ml-training\_common\tfrc_guard.cmd" :libscript_tfrc_postflight_audit "%GCP_PROJECT_ID%" "%TPU_ZONE%" "!TPU_NAME!"
    if errorlevel 1 exit /b !errorlevel!
)
exit /b !_TD_RC!
