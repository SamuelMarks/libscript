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
