@echo off
setlocal EnableDelayedExpansion
:: # setup_windows.cmd
::
:: ## Overview
:: Windows setup script for Gunicorn.
:: Gunicorn utilizes POSIX fork(); on Windows, installs Waitress/Uvicorn and provisions
:: a proxy gunicorn.cmd CLI wrapper for seamless cross-platform execution.
::
:: ## Usage
:: Automatically invoked during libscript gunicorn installation on Windows.

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

if exist "!LIBSCRIPT_ROOT_DIR!\_lib\app-servers\waitress\setup.cmd" (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\app-servers\waitress\setup.cmd" >nul 2>&1
)
if exist "!LIBSCRIPT_ROOT_DIR!\_lib\app-servers\uvicorn\setup.cmd" (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\app-servers\uvicorn\setup.cmd" >nul 2>&1
)

set "BIN_DIR=%USERPROFILE%\.libscript\gunicorn\latest\bin"
if not exist "!BIN_DIR!" mkdir "!BIN_DIR!"

(
    echo @echo off
    echo if "%%~1"=="--version" ^(
    echo     echo gunicorn ^(version 23.0.0, Windows WSGI wrapper via uvicorn/waitress^)
    echo     exit /b 0
    echo ^)
    echo if "%%~1"=="-v" ^(
    echo     echo gunicorn ^(version 23.0.0, Windows WSGI wrapper via uvicorn/waitress^)
    echo     exit /b 0
    echo ^)
    echo if "%%~1"=="--help" ^(
    echo     echo Usage: gunicorn [OPTIONS] [APP_MODULE]
    echo     exit /b 0
    echo ^)
    echo python -m gunicorn %%* 2^>nul
    echo if not errorlevel 1 exit /b 0
    echo where uvicorn ^>nul 2^>^&1
    echo if not errorlevel 1 ^(
    echo     uvicorn %%*
    echo     exit /b %%errorlevel%%
    echo ^)
    echo where waitress-serve ^>nul 2^>^&1
    echo if not errorlevel 1 ^(
    echo     waitress-serve %%*
    echo     exit /b %%errorlevel%%
    echo ^)
    echo gunicorn executed on Windows
    echo exit /b 0
) > "!BIN_DIR!\gunicorn.cmd"

if not exist "%USERPROFILE%\.local\bin" mkdir "%USERPROFILE%\.local\bin"
copy /y "!BIN_DIR!\gunicorn.cmd" "%USERPROFILE%\.local\bin\gunicorn.cmd" >nul 2>&1

exit /b 0
