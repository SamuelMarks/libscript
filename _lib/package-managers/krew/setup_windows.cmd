@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

where kubectl-krew >nul 2>&1
if %errorlevel% equ 0 exit /b 0

set "DEST_DIR=%USERPROFILE%\.local\bin"
if not "%PREFIX%"=="" set "DEST_DIR=%PREFIX%"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

set "URL=https://github.com/kubernetes-sigs/krew/releases/download/v0.5.0/krew-windows_amd64.tar.gz"
set "TEMP_TAR=%TEMP%\krew.tar.gz"

echo Downloading krew from %URL%...
curl -sSL "%URL%" -o "%TEMP_TAR%"
if errorlevel 1 (
    echo Failed to download krew.
    exit /b 1
)

tar -xzf "%TEMP_TAR%" -C "%DEST_DIR%"
del "%TEMP_TAR%" >nul 2>&1

if exist "%DEST_DIR%\krew-windows_amd64.exe" (
    copy /y "%DEST_DIR%\krew-windows_amd64.exe" "%DEST_DIR%\kubectl-krew.exe" >nul
    copy /y "%DEST_DIR%\krew-windows_amd64.exe" "%DEST_DIR%\krew.exe" >nul
    echo krew installed successfully.
    exit /b 0
)

exit /b 1
