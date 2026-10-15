@echo off
:: # desktop.cmd
::
:: ## Overview
:: Configures modular desktop environment and window manager staging
:: inside FreeBSD target sysroot on Windows.
::
:: ## Usage
:: desktop.cmd [sysroot_path] [environment] [username]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
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

SET "searchVal=;%THIS_FILE%;"
IF NOT DEFINED STACK (
    SET "STACK=;%THIS_FILE%;"
    echo [CONTINUE] processing "%THIS_FILE%"
) ELSE (
    IF NOT "!STACK:%searchVal%=!"=="!STACK!" (
        echo [STOP]     processing "%THIS_FILE%"
        SET ERRORLEVEL=0
        goto :eof
    ) ELSE (
        SET "STACK=!STACK!%THIS_FILE%;"
        echo [CONTINUE] processing "%THIS_FILE%"
    )
)

if "%~1"=="--help" (
    echo Usage: %~nx0 [sysroot_path] [environment] [username]
    echo Configures FreeBSD desktop environment.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [sysroot_path] [environment] [username]
    echo Configures FreeBSD desktop environment.
    exit /b 0
)

set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "SYSROOT=%~1"
if "%SYSROOT%"=="" set "SYSROOT=%REPO_ROOT%\build\freebsd-sysroot"
set "DESKTOP=%~2"
if "%DESKTOP%"=="" set "DESKTOP=none"
set "PRIMARY_USER=%~3"
if "%PRIMARY_USER%"=="" set "PRIMARY_USER=freebsd"

set "STAMP_DIR=%SYSROOT%\.libscript_stamps"
set "STAMP_FILE=%STAMP_DIR%\desktop_%DESKTOP%.stamp"

if not exist "%STAMP_DIR%" mkdir "%STAMP_DIR%"
set "USER_HOME=%SYSROOT%\home\%PRIMARY_USER%"
if not exist "%USER_HOME%" mkdir "%USER_HOME%"

if exist "%STAMP_FILE%" (
    echo [SKIP]     FreeBSD desktop %DESKTOP% already configured in %SYSROOT%
    exit /b 0
)

echo [DESKTOP]  Configuring desktop environment: %DESKTOP%...

if "%DESKTOP%"=="xfce4" (
    (
        echo #!/bin/sh
        echo exec startxfce4
    ) > "%USER_HOME%\.xinitrc"
)
if "%DESKTOP%"=="sway" (
    if not exist "%USER_HOME%\.config\sway" mkdir "%USER_HOME%\.config\sway"
    (
        echo set $mod Mod4
        echo set $term foot
        echo bindsym $mod+Return exec $term
        echo bindsym $mod+Shift+q kill
        echo bindsym $mod+Shift+e exit
    ) > "%USER_HOME%\.config\sway\config"
)

echo %DATE% %TIME%> "%STAMP_FILE%"
echo [OK]       Desktop %DESKTOP% configured.
exit /b 0
