@echo off
:: # unikernel_build.cmd
:: ## Overview
:: Builds a standalone single-process Redis unikernel image on Windows.
:: ## Usage
:: unikernel_build.cmd [staging_rootfs] [output_image] [ipv4_addr]

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

set "STAGE_ROOT=%~1"
if "!STAGE_ROOT!"=="" set "STAGE_ROOT=!LIBSCRIPT_ROOT_DIR!\build\redis-unikernel-root"
set "OUT_IMG=%~2"
if "!OUT_IMG!"=="" set "OUT_IMG=!LIBSCRIPT_ROOT_DIR!\build\images\unikernel\redis.unikernel.img"

if not exist "!STAGE_ROOT!\etc" mkdir "!STAGE_ROOT!\etc"
(
    echo bind 0.0.0.0
    echo protected-mode no
    echo daemonize no
    echo save ""
    echo appendonly yes
) > "!STAGE_ROOT!\etc\redis.conf"

call "!LIBSCRIPT_ROOT_DIR!\cli\commands\package_as\unikernel.cmd" "!STAGE_ROOT!" "!OUT_IMG!"
exit /b !ERRORLEVEL!
