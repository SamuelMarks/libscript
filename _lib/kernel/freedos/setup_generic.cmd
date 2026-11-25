@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Tier 2 Windows setup for FreeDOS kernel (_lib/kernel/freedos/).
:: Rejects `use` with exit code 2 per T2 Version Manager Contract.
::
:: ## Usage
:: Managed by libscript.

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
if "%FREEDOS_VERSION%"=="" set "FREEDOS_VERSION=1.4"
if /I "%ACTION%"=="use" (
    echo [ERROR] freedos is a Tier 2 kernel package; use is unsupported. 1>&2
    exit /b 2
)
call :resolve_version
if /I "%ACTION%"=="ls" (
    if exist "%LIBSCRIPT_HOME%\freedos" dir /b "%LIBSCRIPT_HOME%\freedos"
    exit /b 0
)
if /I "%ACTION%"=="ls-remote" (
    echo 1.4
    echo 1.3
    exit /b 0
)
if /I "%ACTION%"=="download" exit /b 0
if /I "%ACTION%"=="bootstrap" goto :do_install
if /I "%ACTION%"=="compile" goto :do_install
if /I "%ACTION%"=="install" goto :do_install
if /I "%ACTION%"=="uninstall" (
    if exist "%LIBSCRIPT_HOME%\freedos\!EXACT_VERSION!" rmdir /s /q "%LIBSCRIPT_HOME%\freedos\!EXACT_VERSION!"
    exit /b 0
)
exit /b 0

:: ## resolve_version
:: Normalizes FREEDOS_VERSION into EXACT_VERSION.
:resolve_version
set "EXACT_VERSION=%FREEDOS_VERSION%"
if /I "!EXACT_VERSION!"=="latest" set "EXACT_VERSION=1.4"
if /I "!EXACT_VERSION!"=="stable" set "EXACT_VERSION=1.4"
if /I "!EXACT_VERSION!"=="lts" set "EXACT_VERSION=1.3"
exit /b 0

:: ## do_install
:: Builds and stages FreeDOS kernel artifacts idempotently.
:do_install
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_get_version_dir "freedos" "!EXACT_VERSION!" >nul
set "TARGET_DIR=!LIBSCRIPT_VERSION_DIR!"
if exist "!TARGET_DIR!\boot\KERNEL.SYS" if exist "!TARGET_DIR!\boot\COMMAND.COM" (
    if not "%FORCE_REINSTALL%"=="1" (
        call :stage_sysroot
        call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "freedos" "%FREEDOS_VERSION%" "!EXACT_VERSION!"
        call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "freedos" "default" "!EXACT_VERSION!"
        exit /b 0
    )
)
if not exist "!TARGET_DIR!\boot" mkdir "!TARGET_DIR!\boot"
set "STACK="
call "!SCRIPT_DIR!\build_kernel.cmd" "!TARGET_DIR!\boot" "!EXACT_VERSION!"
if errorlevel 1 exit /b 1
call :stage_sysroot
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "freedos" "%FREEDOS_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "freedos" "default" "!EXACT_VERSION!"
exit /b 0

:: ## stage_sysroot
:: Copies KERNEL.SYS, COMMAND.COM, and VBRs into LIBSCRIPT_TARGET_SYSROOT.
:stage_sysroot
if "%LIBSCRIPT_TARGET_SYSROOT%"=="" exit /b 0
if not exist "%LIBSCRIPT_TARGET_SYSROOT%\DOS" mkdir "%LIBSCRIPT_TARGET_SYSROOT%\DOS"
if not exist "%LIBSCRIPT_TARGET_SYSROOT%\BOOT" mkdir "%LIBSCRIPT_TARGET_SYSROOT%\BOOT"
copy /y "!TARGET_DIR!\boot\KERNEL.SYS" "%LIBSCRIPT_TARGET_SYSROOT%\KERNEL.SYS" >nul
copy /y "!TARGET_DIR!\boot\COMMAND.COM" "%LIBSCRIPT_TARGET_SYSROOT%\COMMAND.COM" >nul
copy /y "!TARGET_DIR!\boot\COMMAND.COM" "%LIBSCRIPT_TARGET_SYSROOT%\DOS\COMMAND.COM" >nul
copy /y "!TARGET_DIR!\boot\SYS.COM" "%LIBSCRIPT_TARGET_SYSROOT%\DOS\SYS.COM" >nul
copy /y "!TARGET_DIR!\boot\*.bin" "%LIBSCRIPT_TARGET_SYSROOT%\BOOT\" >nul
exit /b 0
