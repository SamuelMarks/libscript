@echo off
:: # env.cmd
::
:: ## Overview
:: Windows environment configuration for OpenWatcom v2 (`WATCOM`, `INCLUDE`, and `binnt64`/`binnt` PATH).
::
:: ## Usage
:: call _lib\toolchains\openwatcom\env.cmd

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
if "%OPENWATCOM_VERSION%"=="" set "OPENWATCOM_VERSION=2.0"
set "WATCOM=%OPENWATCOM_ROOT%"
if "!WATCOM!"=="" set "WATCOM=%LIBSCRIPT_HOME%\openwatcom\%OPENWATCOM_VERSION%"
set "INCLUDE=!WATCOM!\h;!WATCOM!\h\nt"
for %%D in ("!WATCOM!\binnt64" "!WATCOM!\binnt" "!WATCOM!\binw" "!WATCOM!\bin") do (
    if exist "%%~fD" set "PATH=%%~fD;!PATH!"
)

endlocal & (
    set "WATCOM=%WATCOM%"
    set "INCLUDE=%INCLUDE%"
    set "PATH=%PATH%"
)
exit /b 0
