@echo off
:: # setup_generic.cmd
:: ## Overview
:: Generic Windows setup script for gemma-tpu-suite installing isolated wrapper shims idempotently under LIBSCRIPT_HOME.
:: ## Usage
:: Called internally by _lib\toolchains\gemma-tpu-suite\setup.cmd.

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

if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if "%ACTION%"=="" set "ACTION=install"
if "%GEMMA_TPU_SUITE_VERSION%"=="" set "GEMMA_TPU_SUITE_VERSION=1.0.0"
set "EXACT_VERSION=%GEMMA_TPU_SUITE_VERSION%"
if /i "!EXACT_VERSION!"=="latest" set "EXACT_VERSION=1.0.0"
if /i "!EXACT_VERSION!"=="stable" set "EXACT_VERSION=1.0.0"

if /i "%ACTION%"=="ls" (
    if exist "%LIBSCRIPT_HOME%\gemma-tpu-suite" dir /b "%LIBSCRIPT_HOME%\gemma-tpu-suite"
    exit /b 0
)
if /i "%ACTION%"=="ls-remote" (
    echo 1.0.0
    exit /b 0
)
if /i "%ACTION%"=="download" exit /b 0
goto :do_install

:: ## do_install
:: Writes the isolated gemma-tpu-suite.cmd shim idempotently.
:do_install
set "TARGET_DIR=%LIBSCRIPT_HOME%\gemma-tpu-suite\!EXACT_VERSION!"
if exist "!TARGET_DIR!\bin\gemma-tpu-suite.cmd" (
    if not "%FORCE_REINSTALL%"=="1" (
        echo [INFO] gemma-tpu-suite !EXACT_VERSION! is already installed at !TARGET_DIR!.
        exit /b 0
    )
)
if not exist "!TARGET_DIR!\bin" mkdir "!TARGET_DIR!\bin"
(
    echo @echo off
    echo if "%%~1"=="--version" ^( echo gemma-tpu-suite !EXACT_VERSION! ^& exit /b 0 ^)
    echo call "%LIBSCRIPT_ROOT_DIR%\_lib\toolchains\gemma-tpu-suite\benchmark_experiments.cmd" %%*
) > "!TARGET_DIR!\bin\gemma-tpu-suite.cmd"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "gemma-tpu-suite" "%GEMMA_TPU_SUITE_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "gemma-tpu-suite" "default" "!EXACT_VERSION!"
echo [INFO] Installed gemma-tpu-suite !EXACT_VERSION! to !TARGET_DIR!.
exit /b 0
