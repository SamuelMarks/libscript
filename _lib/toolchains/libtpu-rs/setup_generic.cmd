@echo off
:: # setup_generic.cmd
:: ## Overview
:: Generic Windows setup script for `libtpu-rs` enforcing SIGPLAN `RULE-6` pinned Cargo release profiles (full and slim DLL builds) and provisioning an isolated `jax`/`jaxlib` virtual environment via `python_env.cmd`.
:: ## Usage
:: Called internally by `_lib\toolchains\libtpu-rs\setup.cmd`.

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
if "%LIBTPU_RS_VERSION%"=="" set "LIBTPU_RS_VERSION=0.0.52"
if "%LIBTPU_RS_CARGO_PROFILE%"=="" set "LIBTPU_RS_CARGO_PROFILE=opt3-lto-thin-cgu1"
if "%LIBTPU_RS_SLIM_FEATURES%"=="" set "LIBTPU_RS_SLIM_FEATURES=--no-default-features"
if "%LIBTPU_RS_JAX_VERSION%"=="" set "LIBTPU_RS_JAX_VERSION=0.4.38"
set "EXACT_VERSION=%LIBTPU_RS_VERSION%"
if /i "!EXACT_VERSION!"=="latest" set "EXACT_VERSION=0.0.52"

if /i "%ACTION%"=="ls" (
    if exist "%LIBSCRIPT_HOME%\libtpu-rs" dir /b "%LIBSCRIPT_HOME%\libtpu-rs"
    exit /b 0
)
if /i "%ACTION%"=="ls-remote" (
    echo 0.0.52
    exit /b 0
)
if /i "%ACTION%"=="use" (
    call :do_install
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "libtpu-rs" "%LIBTPU_RS_VERSION%" "!EXACT_VERSION!"
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "libtpu-rs" "default" "!EXACT_VERSION!"
    exit /b 0
)
if /i "%ACTION%"=="download" exit /b 0
if /i "%ACTION%"=="install" goto :do_install
exit /b 0

:: ## do_install
:: Builds pinned full and slim release `libtpu_c_api.dll` artifacts and initializes the isolated Python venv on Windows.
:do_install
set "TARGET_DIR=%LIBSCRIPT_HOME%\libtpu-rs\!EXACT_VERSION!"
if exist "!TARGET_DIR!\bin\libtpu-rs-env.cmd" (
    if not "%FORCE_REINSTALL%"=="1" (
        echo [INFO] libtpu-rs !EXACT_VERSION! is already installed at !TARGET_DIR!.
        exit /b 0
    )
)
if not exist "!TARGET_DIR!\bin" mkdir "!TARGET_DIR!\bin"
if not exist "!TARGET_DIR!\lib" mkdir "!TARGET_DIR!\lib"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\experiment_harness.cmd" :libscript_exp_pin_cargo_release "%LIBTPU_RS_CARGO_PROFILE%" "!TARGET_DIR!\cargo_profile.json"

set "_SRC_REPO=%LIBTPU_RS_REPO_DIR%"
if "!_SRC_REPO!"=="" (
    if exist "%LIBSCRIPT_ROOT_DIR%\..\libtpu-rs" set "_SRC_REPO=%LIBSCRIPT_ROOT_DIR%\..\libtpu-rs"
)
if not "!_SRC_REPO!"=="" (
    if exist "!_SRC_REPO!\Cargo.toml" (
        where cargo >nul 2>&1
        if errorlevel 1 call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install rust latest
        pushd "!_SRC_REPO!"
        cargo build --release -p libtpu-c-api
        popd
        if exist "!_SRC_REPO!\target\release\libtpu_c_api.dll" (
            copy /y "!_SRC_REPO!\target\release\libtpu_c_api.dll" "!TARGET_DIR!\lib\libtpu_c_api.unstripped.dll" >nul
            call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\experiment_harness.cmd" :libscript_exp_strip_shared_lib "!_SRC_REPO!\target\release\libtpu_c_api.dll" "!TARGET_DIR!\lib\libtpu_c_api.dll"
        )
        pushd "!_SRC_REPO!"
        cargo build --release -p libtpu-c-api --target-dir "!_SRC_REPO!\target\release-slim" %LIBTPU_RS_SLIM_FEATURES%
        popd
        if exist "!_SRC_REPO!\target\release-slim\release\libtpu_c_api.dll" (
            copy /y "!_SRC_REPO!\target\release-slim\release\libtpu_c_api.dll" "!TARGET_DIR!\lib\libtpu_c_api_slim.unstripped.dll" >nul
            call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\experiment_harness.cmd" :libscript_exp_strip_shared_lib "!_SRC_REPO!\target\release-slim\release\libtpu_c_api.dll" "!TARGET_DIR!\lib\libtpu_c_api_slim.dll"
        )
    )
)

set "_REQ_F=!TARGET_DIR!\jax_requirements.txt"
(
    echo jax==%LIBTPU_RS_JAX_VERSION%
    echo jaxlib==%LIBTPU_RS_JAX_VERSION%
) > "!_REQ_F!"
if not "%LIBSCRIPT_OFFLINE%"=="1" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\python_env.cmd" libscript_python_venv "!TARGET_DIR!\venv" "" "!_REQ_F!"
)
(
    echo @echo off
    echo echo libtpu-rs !EXACT_VERSION! ^(!TARGET_DIR!^)
) > "!TARGET_DIR!\bin\libtpu-rs-env.cmd.tmp"
move /y "!TARGET_DIR!\bin\libtpu-rs-env.cmd.tmp" "!TARGET_DIR!\bin\libtpu-rs-env.cmd" >nul
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "libtpu-rs" "%LIBTPU_RS_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "libtpu-rs" "default" "!EXACT_VERSION!"
exit /b 0
