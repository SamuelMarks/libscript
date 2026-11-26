@echo off
:: # setup_generic.cmd
:: ## Overview
:: Native zero-PowerShell Windows Batch setup for the Actix+Diesel authentication scaffold stack.
:: ## Usage
:: setup_generic.cmd [action]

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

if exist "!SCRIPT_DIR!\env.cmd" call "!SCRIPT_DIR!\env.cmd"
if "!SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST!"=="" set "SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST=%TEMP%\serve-actix-diesel-auth-scaffold"
if "!SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_BUILD_DIR!"=="" set "SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_BUILD_DIR=!SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST!"

if exist "!SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST!\Cargo.toml" (
    echo [INFO] serve-actix-diesel-auth-scaffold is already checked out at !SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST!.
    exit /b 0
)

where git >nul 2>&1
if errorlevel 1 call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install git latest
call "!LIBSCRIPT_ROOT_DIR!\engine\common\git.cmd" :git_get "https://github.com/SamuelMarks/serve-actix-diesel-auth-scaffold" "!SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST!"
for %%P in ("!SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST!") do set "PARENT_DEST=%%~dpP"
if "!PARENT_DEST:~-1!"=="\" set "PARENT_DEST=!PARENT_DEST:~0,-1!"
call "!LIBSCRIPT_ROOT_DIR!\engine\common\git.cmd" :git_get "https://github.com/offscale/rust-actix-diesel-auth-scaffold" "!PARENT_DEST!\rust-actix-diesel-auth-scaffold"

where cargo >nul 2>&1
if errorlevel 1 (
    if not "!LIBSCRIPT_SKIP_SYSTEM_DEPS!"=="1" call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install rust latest
)
where cargo >nul 2>&1
if not errorlevel 1 (
    pushd "!SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST!"
    set "RUSTC_BOOTSTRAP=1"
    cargo check 2>nul
    popd
)

echo [OK] serve-actix-diesel-auth-scaffold setup complete.
exit /b 0
