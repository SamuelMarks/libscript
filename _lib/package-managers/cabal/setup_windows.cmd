@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

where cabal >nul 2>&1
if %errorlevel% equ 0 exit /b 0

set "DEST_DIR=%USERPROFILE%\.local\bin"
if not "%PREFIX%"=="" set "DEST_DIR=%PREFIX%"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

set "URL=https://downloads.haskell.org/~cabal/cabal-install-3.12.1.0/cabal-install-3.12.1.0-x86_64-windows.zip"
set "TEMP_ZIP=%TEMP%\cabal.zip"

echo Downloading cabal from %URL%...
curl -sSL "%URL%" -o "%TEMP_ZIP%"
if errorlevel 1 (
    echo Failed to download cabal.
    exit /b 1
)

tar -xf "%TEMP_ZIP%" -C "%DEST_DIR%"
del "%TEMP_ZIP%" >nul 2>&1

if exist "%DEST_DIR%\cabal.exe" (
    echo cabal installed successfully.
    exit /b 0
)

exit /b 1
