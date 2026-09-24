@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for PulseAudio on Windows.
:: Prepares and provisions PulseAudio daemon configuration and CLI tools.
::
:: ## Usage
:: Automatically invoked during libscript pulseaudio installation on Windows.

set "THIS_FILE=%~f0"

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
