@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Tier 2 Windows setup for MIT MS-DOS 1.25, 2.0, and 4.00 (_lib/kernel/msdos/).
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
if "%MSDOS_VERSION%"=="" set "MSDOS_VERSION=4.0"
if /I "%ACTION%"=="use" (
    echo [ERROR] msdos is a Tier 2 kernel package; use is unsupported. 1>&2
    exit /b 2
)
call :resolve_version
if errorlevel 1 exit /b 1
if /I "%ACTION%"=="ls" (
    if exist "%LIBSCRIPT_HOME%\msdos" dir /b "%LIBSCRIPT_HOME%\msdos"
    exit /b 0
)
if /I "%ACTION%"=="ls-remote" (
    echo 4.0 ^(MIT^)
    echo 2.0 ^(MIT^)
    echo 1.25 ^(MIT^)
    exit /b 0
)
if /I "%ACTION%"=="download" exit /b 0
if /I "%ACTION%"=="bootstrap" goto :do_install
if /I "%ACTION%"=="compile" goto :do_install
if /I "%ACTION%"=="install" goto :do_install
if /I "%ACTION%"=="uninstall" (
    if exist "%LIBSCRIPT_HOME%\msdos\!EXACT_VERSION!" rmdir /s /q "%LIBSCRIPT_HOME%\msdos\!EXACT_VERSION!"
    exit /b 0
)
exit /b 0

:: ## resolve_version
:: Validates MSDOS_VERSION strictly against MIT-licensed 1.25, 2.0, and 4.0 releases.
:resolve_version
set "EXACT_VERSION=%MSDOS_VERSION%"
if /I "!EXACT_VERSION!"=="latest" set "EXACT_VERSION=4.0"
if /I "!EXACT_VERSION!"=="stable" set "EXACT_VERSION=4.0"
if /I "!EXACT_VERSION!"=="lts" set "EXACT_VERSION=4.0"
if /I "!EXACT_VERSION!"=="4.00" set "EXACT_VERSION=4.0"
if /I "!EXACT_VERSION!"=="2.00" set "EXACT_VERSION=2.0"
if "!EXACT_VERSION!"=="4.0" exit /b 0
if "!EXACT_VERSION!"=="2.0" exit /b 0
if "!EXACT_VERSION!"=="1.25" exit /b 0
echo [ERROR] Unsupported MS-DOS version !MSDOS_VERSION!. Only MIT 1.25, 2.0, and 4.0 are permitted. 1>&2
exit /b 1

:: ## do_install
:: Builds and stages MIT MS-DOS kernel artifacts idempotently.
:do_install
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_get_version_dir "msdos" "!EXACT_VERSION!" >nul
set "TARGET_DIR=!LIBSCRIPT_VERSION_DIR!"
if exist "!TARGET_DIR!\boot\IO.SYS" if exist "!TARGET_DIR!\boot\MSDOS.SYS" if exist "!TARGET_DIR!\boot\COMMAND.COM" (
    if not "%FORCE_REINSTALL%"=="1" (
        call :stage_sysroot
        call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "msdos" "%MSDOS_VERSION%" "!EXACT_VERSION!"
        call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "msdos" "default" "!EXACT_VERSION!"
        exit /b 0
    )
)
if not exist "!TARGET_DIR!\boot" mkdir "!TARGET_DIR!\boot"
set "STACK="
call "!SCRIPT_DIR!\build_msdos.cmd" "!TARGET_DIR!\boot" "!EXACT_VERSION!"
if errorlevel 1 exit /b 1
call :stage_sysroot
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "msdos" "%MSDOS_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "msdos" "default" "!EXACT_VERSION!"
exit /b 0

:: ## stage_sysroot
:: Stages IO.SYS, MSDOS.SYS, and COMMAND.COM into LIBSCRIPT_TARGET_SYSROOT.
:stage_sysroot
if "%LIBSCRIPT_TARGET_SYSROOT%"=="" exit /b 0
if not exist "%LIBSCRIPT_TARGET_SYSROOT%" mkdir "%LIBSCRIPT_TARGET_SYSROOT%"
copy /y "!TARGET_DIR!\boot\IO.SYS" "%LIBSCRIPT_TARGET_SYSROOT%\IO.SYS" >nul
copy /y "!TARGET_DIR!\boot\MSDOS.SYS" "%LIBSCRIPT_TARGET_SYSROOT%\MSDOS.SYS" >nul
copy /y "!TARGET_DIR!\boot\COMMAND.COM" "%LIBSCRIPT_TARGET_SYSROOT%\COMMAND.COM" >nul
if not "!EXACT_VERSION!"=="1.25" (
    if not exist "%LIBSCRIPT_TARGET_SYSROOT%\DOS" mkdir "%LIBSCRIPT_TARGET_SYSROOT%\DOS"
    if not exist "%LIBSCRIPT_TARGET_SYSROOT%\BOOT" mkdir "%LIBSCRIPT_TARGET_SYSROOT%\BOOT"
    copy /y "!TARGET_DIR!\boot\COMMAND.COM" "%LIBSCRIPT_TARGET_SYSROOT%\DOS\COMMAND.COM" >nul
    copy /y "!TARGET_DIR!\boot\*.bin" "%LIBSCRIPT_TARGET_SYSROOT%\BOOT\" >nul
)
exit /b 0
