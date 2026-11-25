@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Tier 2 Windows sysroot setup for dos-pktdrv (PCNTPKT, NE2000, SHSUCDX, FDAPM, HIMEMX, DOSLFN).
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
if "%DOS_PKTDRV_VERSION%"=="" set "DOS_PKTDRV_VERSION=1.4"
if /I "%ACTION%"=="use" (
    echo [ERROR] dos-pktdrv is a Tier 2 sysroot-only package; use is unsupported. 1>&2
    exit /b 2
)
call :resolve_version
if /I "%ACTION%"=="ls" (
    if exist "%LIBSCRIPT_HOME%\dos-pktdrv" dir /b "%LIBSCRIPT_HOME%\dos-pktdrv"
    exit /b 0
)
if /I "%ACTION%"=="ls-remote" (
    echo 1.4
    exit /b 0
)
if /I "%ACTION%"=="download" exit /b 0
if /I "%ACTION%"=="bootstrap" goto :do_install
if /I "%ACTION%"=="compile" goto :do_install
if /I "%ACTION%"=="install" goto :do_install
if /I "%ACTION%"=="uninstall" (
    if exist "%LIBSCRIPT_HOME%\dos-pktdrv\!EXACT_VERSION!" rmdir /s /q "%LIBSCRIPT_HOME%\dos-pktdrv\!EXACT_VERSION!"
    exit /b 0
)
exit /b 0

:: ## resolve_version
:: Normalizes DOS_PKTDRV_VERSION into EXACT_VERSION.
:resolve_version
set "EXACT_VERSION=%DOS_PKTDRV_VERSION%"
if /I "!EXACT_VERSION!"=="latest" set "EXACT_VERSION=1.4"
if /I "!EXACT_VERSION!"=="stable" set "EXACT_VERSION=1.4"
if /I "!EXACT_VERSION!"=="lts" set "EXACT_VERSION=1.4"
exit /b 0

:: ## do_install
:: Emits DOS drivers idempotently and stages into LIBSCRIPT_TARGET_SYSROOT when active.
:do_install
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_get_version_dir "dos-pktdrv" "!EXACT_VERSION!" >nul
set "TARGET_DIR=!LIBSCRIPT_VERSION_DIR!"
if exist "!TARGET_DIR!\dos\PCNTPKT.COM" if exist "!TARGET_DIR!\dos\FDAPM.COM" (
    if not "%FORCE_REINSTALL%"=="1" (
        call :stage_sysroot
        call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "dos-pktdrv" "%DOS_PKTDRV_VERSION%" "!EXACT_VERSION!"
        call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "dos-pktdrv" "default" "!EXACT_VERSION!"
        exit /b 0
    )
)
if not exist "!TARGET_DIR!\dos" mkdir "!TARGET_DIR!\dos"
set "_EMIT=%TEMP%\pktdrv_emit_!RANDOM!.exe"
set "STACK="
call "%LIBSCRIPT_ROOT_DIR%\engine\common\dos32\compile_host_c89.cmd" "!SCRIPT_DIR!\src\emit_dos_drivers_c89.c" "!_EMIT!"
if errorlevel 1 exit /b 1
goto :run_emit

:: ## run_emit
:: Runs DOS driver emitter and updates aliases.
:run_emit
"!_EMIT!" "!TARGET_DIR!\dos"
if exist "!_EMIT!" del /f /q "!_EMIT!" >nul 2>&1
call :stage_sysroot
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "dos-pktdrv" "%DOS_PKTDRV_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "dos-pktdrv" "default" "!EXACT_VERSION!"
exit /b 0

:: ## stage_sysroot
:: Copies DOS drivers to LIBSCRIPT_TARGET_SYSROOT\DOS during OS image synthesis.
:stage_sysroot
if not "%LIBSCRIPT_IMAGE_BUILD%"=="1" exit /b 0
if "%LIBSCRIPT_TARGET_SYSROOT%"=="" exit /b 0
if /I "%LIBSCRIPT_DOS_STRATUM%"=="dos16-fcb" exit /b 0
if not exist "%LIBSCRIPT_TARGET_SYSROOT%\DOS" mkdir "%LIBSCRIPT_TARGET_SYSROOT%\DOS"
copy /y "!TARGET_DIR!\dos\*.*" "%LIBSCRIPT_TARGET_SYSROOT%\DOS\" >nul
exit /b 0
