@echo off
:: # env.cmd
::
:: ## Overview
:: Windows environment configuration for Bento Builder stack, exporting BENTO_DIR and RUBYLIB so
:: Bento::VagrantMsdos and Bento::VagrantFreedos load cleanly inside Vagrant on Windows.
::
:: ## Usage
:: Call this script to configure the Bento Builder environment on Windows.

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
set "CALLER_SCRIPT_DIR=%SCRIPT_DIR%"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\env_base.cmd" "bento-builder"

call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\qemu\env.cmd"
call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\virtualbox\env.cmd"
call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\packer\env.cmd"
call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\vagrant\env.cmd"

set "_RESOLVED_BENTO=!BENTO_DIR!"
if "!_RESOLVED_BENTO!"=="" (
    for %%D in ("!LIBSCRIPT_ROOT_DIR!\..\bento" "%USERPROFILE%\bento") do (
        if "!_RESOLVED_BENTO!"=="" if exist "%%~fD\os_pkrvars\" set "_RESOLVED_BENTO=%%~fD"
        if "!_RESOLVED_BENTO!"=="" if exist "%%~fD\bento.gemspec" set "_RESOLVED_BENTO=%%~fD"
    )
) else if exist "!_RESOLVED_BENTO!\" (
    for %%D in ("!_RESOLVED_BENTO!") do set "_RESOLVED_BENTO=%%~fD"
)

set "_RESOLVED_RUBYLIB=!RUBYLIB!"
if not "!_RESOLVED_BENTO!"=="" if exist "!_RESOLVED_BENTO!\lib\" (
    echo ;!_RESOLVED_RUBYLIB!; | findstr /I /C:";!_RESOLVED_BENTO!\lib;" >nul 2>&1
    if errorlevel 1 (
        if "!_RESOLVED_RUBYLIB!"=="" (
            set "_RESOLVED_RUBYLIB=!_RESOLVED_BENTO!\lib"
        ) else (
            set "_RESOLVED_RUBYLIB=!_RESOLVED_BENTO!\lib;!_RESOLVED_RUBYLIB!"
        )
    )
)

endlocal & (
    set "PATH=%PATH%"
    if not "%_RESOLVED_BENTO%"=="" set "BENTO_DIR=%_RESOLVED_BENTO%"
    if not "%_RESOLVED_RUBYLIB%"=="" set "RUBYLIB=%_RESOLVED_RUBYLIB%"
)
exit /b 0
