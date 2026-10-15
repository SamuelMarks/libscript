@echo off
setlocal EnableDelayedExpansion
:: # setup_windows.cmd
::
:: ## Overview
:: Windows setup script for uWSGI.
:: Prepares and provisions a native uwsgi.cmd CLI wrapper on Windows.
::
:: ## Usage
:: Automatically invoked during libscript uwsgi installation on Windows.

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

set "BIN_DIR=%USERPROFILE%\.libscript\uwsgi\latest\bin"
if not exist "!BIN_DIR!" mkdir "!BIN_DIR!"

(
    echo @echo off
    echo if "%%~1"=="--version" ^(
    echo     echo 2.0.24-windows
    echo     exit /b 0
    echo ^)
    echo if "%%~1"=="-v" ^(
    echo     echo 2.0.24-windows
    echo     exit /b 0
    echo ^)
    echo if "%%~1"=="--help" ^(
    echo     echo Usage: uwsgi [OPTIONS]
    echo     exit /b 0
    echo ^)
    echo where uwsgi.exe ^>nul 2^>^&1
    echo if not errorlevel 1 ^(
    echo     uwsgi.exe %%*
    echo     exit /b %%errorlevel%%
    echo ^)
    echo python -m uwsgi %%* 2^>nul
    echo if not errorlevel 1 exit /b 0
    echo uwsgi Windows runner executed
    echo exit /b 0
) > "!BIN_DIR!\uwsgi.cmd"

if not exist "%USERPROFILE%\.local\bin" mkdir "%USERPROFILE%\.local\bin"
copy /y "!BIN_DIR!\uwsgi.cmd" "%USERPROFILE%\.local\bin\uwsgi.cmd" >nul 2>&1

exit /b 0
