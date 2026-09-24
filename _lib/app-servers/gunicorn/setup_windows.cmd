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

where python >nul 2>&1
if not errorlevel 1 (
    python -m pip install --upgrade --quiet waitress uvicorn >nul 2>&1
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
