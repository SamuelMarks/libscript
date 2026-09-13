@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

where bao >nul 2>&1
if %errorlevel% equ 0 exit /b 0

set "ARCH=amd64"
if "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "ARCH=arm64"

set "DEST_DIR=%USERPROFILE%\.local\bin"
if not "%PREFIX%"=="" set "DEST_DIR=%PREFIX%"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

set "URL=https://github.com/openbao/openbao/releases/download/v2.6.2/openbao_2.6.2_windows_%ARCH%.zip"
set "TEMP_ZIP=%TEMP%\openbao.zip"

echo Downloading OpenBao (%ARCH%) from %URL%...
curl -sSL "%URL%" -o "%TEMP_ZIP%"
if errorlevel 1 (
    echo Failed to download OpenBao.
    exit /b 1
)

tar -xf "%TEMP_ZIP%" -C "%DEST_DIR%"
del "%TEMP_ZIP%" >nul 2>&1

if exist "%DEST_DIR%\bao.exe" (
    echo openbao installed successfully to %DEST_DIR%.
    exit /b 0
)

echo Failed to install openbao.
exit /b 1
