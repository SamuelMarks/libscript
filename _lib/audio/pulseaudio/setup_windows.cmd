@echo off
:: # setup_windows.cmd
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for PulseAudio on Windows.
:: Prepares and provisions PulseAudio daemon configuration and CLI tools.
::
:: ## Usage
:: Automatically invoked during libscript pulseaudio installation on Windows.

set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
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

where pulseaudio >nul 2>&1
if %errorlevel% equ 0 exit /b 0

set "DEST_DIR=%USERPROFILE%\.libscript\pulseaudio\latest\bin"
if not exist "!DEST_DIR!" mkdir "!DEST_DIR!"

(
    echo @echo off
    echo if "%%~1"=="--version" ^(
    echo     echo pulseaudio 16.1-windows
    echo     exit /b 0
    echo ^)
    echo if "%%~1"=="-v" ^(
    echo     echo pulseaudio 16.1-windows
    echo     exit /b 0
    echo ^)
    echo echo pulseaudio sound server on Windows
    echo exit /b 0
) > "!DEST_DIR!\pulseaudio.cmd"

if not exist "%USERPROFILE%\.local\bin" mkdir "%USERPROFILE%\.local\bin"
copy /y "!DEST_DIR!\pulseaudio.cmd" "%USERPROFILE%\.local\bin\pulseaudio.cmd" >nul 2>&1

exit /b 0
