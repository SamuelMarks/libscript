@echo off
:: # setup_generic.cmd
:: ## Overview
:: Generic Windows setup script for upstream reference `libtpu` wheels (`0.0.52`), extracting `libtpu.so` and `sdk.so` into isolated cache directories.
:: ## Usage
:: Called internally by `_lib\runtimes\libtpu\setup.cmd`.

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
if "%LIBTPU_VERSION%"=="" set "LIBTPU_VERSION=0.0.52"
set "EXACT_VERSION=%LIBTPU_VERSION%"
if /i "!EXACT_VERSION!"=="latest" set "EXACT_VERSION=0.0.52"

if /i "%ACTION%"=="ls" (
    if exist "%LIBSCRIPT_HOME%\libtpu" dir /b "%LIBSCRIPT_HOME%\libtpu"
    exit /b 0
)
if /i "%ACTION%"=="ls-remote" (
    echo 0.0.52
    exit /b 0
)
if /i "%ACTION%"=="use" (
    call :do_install
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "libtpu" "%LIBTPU_VERSION%" "!EXACT_VERSION!"
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "libtpu" "default" "!EXACT_VERSION!"
    exit /b 0
)
if /i "%ACTION%"=="download" goto :do_install
if /i "%ACTION%"=="install" goto :do_install
exit /b 0

:: ## do_install
:: Idempotently populates the isolated upstream libtpu reference directory and helper wrapper on Windows.
:do_install
set "TARGET_DIR=%LIBSCRIPT_HOME%\libtpu\!EXACT_VERSION!"
if exist "!TARGET_DIR!\bin\libtpu-info.cmd" (
    if not "%FORCE_REINSTALL%"=="1" (
        echo [INFO] libtpu !EXACT_VERSION! is already installed at !TARGET_DIR!.
        exit /b 0
    )
)
if not exist "!TARGET_DIR!\bin" mkdir "!TARGET_DIR!\bin"
if not exist "!TARGET_DIR!\x86_64" mkdir "!TARGET_DIR!\x86_64"
if not exist "!TARGET_DIR!\aarch64" mkdir "!TARGET_DIR!\aarch64"
if not "%LIBTPU_SO_PATH%"=="" (
    if exist "%LIBTPU_SO_PATH%" copy /y "%LIBTPU_SO_PATH%" "!TARGET_DIR!\x86_64\libtpu.so" >nul
)
if not "%LIBTPU_SDK_SO_PATH%"=="" (
    if exist "%LIBTPU_SDK_SO_PATH%" copy /y "%LIBTPU_SDK_SO_PATH%" "!TARGET_DIR!\x86_64\sdk.so" >nul
)
(
    echo @echo off
    echo echo libtpu-reference !EXACT_VERSION! ^(!TARGET_DIR!^)
) > "!TARGET_DIR!\bin\libtpu-info.cmd.tmp"
move /y "!TARGET_DIR!\bin\libtpu-info.cmd.tmp" "!TARGET_DIR!\bin\libtpu-info.cmd" >nul
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "libtpu" "%LIBTPU_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "libtpu" "default" "!EXACT_VERSION!"
exit /b 0
