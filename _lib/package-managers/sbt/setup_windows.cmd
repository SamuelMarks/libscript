@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for sbt on Windows.
:: Downloads and installs the official sbt distribution.
::
:: ## Usage
:: Automatically invoked during libscript sbt installation on Windows.

set "THIS_FILE=%~f0"

where sbt >nul 2>&1
if %errorlevel% equ 0 exit /b 0

set "DEST_DIR=%USERPROFILE%\.local\sbt"
if not "%PREFIX%"=="" set "DEST_DIR=%PREFIX%"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

set "BIN_DIR=%USERPROFILE%\.local\bin"
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"

set "URL=https://github.com/sbt/sbt/releases/download/v1.10.7/sbt-1.10.7.zip"
set "TEMP_ZIP=%TEMP%\sbt.zip"

echo Downloading sbt from %URL%...
curl -sSL "%URL%" -o "%TEMP_ZIP%"
if errorlevel 1 (
    echo Failed to download sbt.
    exit /b 1
)

tar -xf "%TEMP_ZIP%" -C "%DEST_DIR%"
del "%TEMP_ZIP%" >nul 2>&1

if exist "%DEST_DIR%\sbt\bin\sbt.bat" (
    (
        echo @echo off
        echo "%DEST_DIR%\sbt\bin\sbt.bat" %%*
    ) > "%BIN_DIR%\sbt.cmd"
    echo sbt installed successfully.
    exit /b 0
)

exit /b 1
