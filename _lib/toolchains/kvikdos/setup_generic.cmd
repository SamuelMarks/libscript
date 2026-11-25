@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Windows setup for kvikdos (headless 8086 real-mode DOS CLI runner).
:: Compiles kvikdos_c89.c using cl.exe/gcc/clang and delegates to win-cmd-asm vm8086 when requested.
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use, and uninstall capabilities.

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
if "%KVIKDOS_VERSION%"=="" set "KVIKDOS_VERSION=0.1.0"
call :resolve_version

if /I "%ACTION%"=="ls" (
    if exist "%LIBSCRIPT_HOME%\kvikdos" dir /b "%LIBSCRIPT_HOME%\kvikdos"
    exit /b 0
)
if /I "%ACTION%"=="ls-remote" (
    echo 0.1.0
    exit /b 0
)
if /I "%ACTION%"=="download" (
    echo [INFO] kvikdos !EXACT_VERSION! uses bundled C89 source.
    exit /b 0
)
if /I "%ACTION%"=="use" (
    if not exist "%LIBSCRIPT_HOME%\kvikdos\!EXACT_VERSION!\bin\kvikdos.exe" exit /b 1
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "kvikdos" "default" "!EXACT_VERSION!"
    exit /b !errorlevel!
)
if /I "%ACTION%"=="bootstrap" goto :do_install
if /I "%ACTION%"=="install" goto :do_install
if /I "%ACTION%"=="uninstall" (
    if exist "%LIBSCRIPT_HOME%\kvikdos\!EXACT_VERSION!" rmdir /s /q "%LIBSCRIPT_HOME%\kvikdos\!EXACT_VERSION!"
    exit /b 0
)
call "%LIBSCRIPT_ROOT_DIR%\engine\common\setup_base.cmd" :libscript_handle_generic_action "kvikdos" "%ACTION%" "!EXACT_VERSION!" "from-source" "" "" "" "\"%LIBSCRIPT_HOME%\kvikdos\!EXACT_VERSION!\bin\kvikdos.exe\"" "%LIBSCRIPT_HOME%\kvikdos\!EXACT_VERSION!"
exit /b !errorlevel!

:: ## resolve_version
:: Normalizes KVIKDOS_VERSION aliases into EXACT_VERSION.
:resolve_version
set "EXACT_VERSION=%KVIKDOS_VERSION%"
if /I "!EXACT_VERSION!"=="latest" set "EXACT_VERSION=0.1.0"
if /I "!EXACT_VERSION!"=="stable" set "EXACT_VERSION=0.1.0"
if /I "!EXACT_VERSION!"=="lts" set "EXACT_VERSION=0.1.0"
exit /b 0

:: ## do_install
:: Compiles kvikdos.exe idempotently into LIBSCRIPT_HOME.
:do_install
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_get_version_dir "kvikdos" "!EXACT_VERSION!" >nul
set "TARGET_DIR=!LIBSCRIPT_VERSION_DIR!"
if exist "!TARGET_DIR!\bin\kvikdos.exe" (
    if not "%FORCE_REINSTALL%"=="1" (
        echo [INFO] kvikdos !EXACT_VERSION! is already installed at !TARGET_DIR!.
        call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "kvikdos" "%KVIKDOS_VERSION%" "!EXACT_VERSION!"
        call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "kvikdos" "default" "!EXACT_VERSION!"
        exit /b 0
    )
)
if not exist "!TARGET_DIR!\bin" mkdir "!TARGET_DIR!\bin"
set "STACK="
call "%LIBSCRIPT_ROOT_DIR%\engine\common\dos32\compile_host_c89.cmd" "!SCRIPT_DIR!\src\kvikdos_c89.c" "!TARGET_DIR!\bin\kvikdos.exe"
if errorlevel 1 exit /b 1
goto :done_cc

:: ## done_cc
:: Finalizes symlinks after compilation succeeds.
:done_cc
if not exist "!TARGET_DIR!\bin\kvikdos.exe" exit /b 1
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "kvikdos" "%KVIKDOS_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "kvikdos" "default" "!EXACT_VERSION!"
exit /b 0
