@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Generic Windows setup module for reactos-distro.
::
:: ## Usage
:: _lib\reactos\distro\setup_generic.cmd

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

if "%ACTION%"=="" set "ACTION=install"
if "%REACTOS_DISTRO_VERSION%"=="" set "REACTOS_DISTRO_VERSION=0.4.16"
if /I "%REACTOS_DISTRO_VERSION%"=="latest" set "REACTOS_DISTRO_VERSION=0.4.16"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"

if /I "%ACTION%"=="ls-remote" (
    echo 0.4.15
    echo 0.4.16
    echo nightly
    exit /b 0
)
if /I "%ACTION%"=="assemble" (
    set "STACK="
    call "!SCRIPT_DIR!\assemble.cmd"
    exit /b !errorlevel!
)
if /I "%ACTION%"=="install" (
    set "_INST=%LIBSCRIPT_HOME%\reactos-distro\%REACTOS_DISTRO_VERSION%"
    if exist "!_INST!\bin\reactos-distro.cmd" (
        echo [SKIP] reactos-distro %REACTOS_DISTRO_VERSION% already installed.
        exit /b 0
    )
    if not exist "!_INST!\bin" mkdir "!_INST!\bin"
    if not exist "%LIBSCRIPT_HOME%\bin" mkdir "%LIBSCRIPT_HOME%\bin"
    (
        echo @echo off
        echo call "%LIBSCRIPT_ROOT_DIR%\_lib\reactos\distro\cli.cmd" %%*
    ) > "!_INST!\bin\reactos-distro.cmd"
    copy /y "!_INST!\bin\reactos-distro.cmd" "%LIBSCRIPT_HOME%\bin\reactos-distro.cmd" >nul 2>&1
    echo [OK] Installed reactos-distro %REACTOS_DISTRO_VERSION%.
    exit /b 0
)

call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_handle_generic_action "reactos-distro" "%ACTION%" "%REACTOS_DISTRO_VERSION%" "libscript_native"
exit /b !errorlevel!
