@echo off
:: # build_kernel.cmd
::
:: ## Overview
:: Builds or repacks FreeDOS KERNEL.SYS, COMMAND.COM, SYS.COM, and FAT12/16/32 boot sectors on Windows.
::
:: ## Usage
:: _lib\kernel\freedos\build_kernel.cmd <output_dir> [version]

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

set "OUT_DIR=%~1"
if "!OUT_DIR!"=="" set "OUT_DIR=%LIBSCRIPT_ROOT_DIR%\build\freedos-stage"
set "FD_VER=%~2"
if "!FD_VER!"=="" set "FD_VER=1.4"
if not exist "!OUT_DIR!" mkdir "!OUT_DIR!"

set "_EMIT=%TEMP%\fd_emit_!RANDOM!.exe"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\engine\common\dos32\compile_host_c89.cmd" "!SCRIPT_DIR!\src\emit_freedos_boot_c89.c" "!_EMIT!"
if errorlevel 1 exit /b 1
goto :run_fd

:: ## run_fd
:: Executes the FreeDOS kernel emitter and cleans up temporary binary.
:run_fd
"!_EMIT!" "!OUT_DIR!" "!FD_VER!"
set "_RC=!errorlevel!"
if exist "!_EMIT!" del /f /q "!_EMIT!" >nul 2>&1
exit /b !_RC!
