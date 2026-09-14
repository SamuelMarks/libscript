@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for vagrant on Windows.
:: Installs official Vagrant distribution on Windows.
::
:: ## Usage
:: Automatically invoked during libscript vagrant installation on Windows.

set "THIS_FILE=%~f0"

where vagrant >nul 2>&1
if %errorlevel% equ 0 exit /b 0

if exist "C:\Program Files\Vagrant\bin\vagrant.exe" exit /b 0
if exist "C:\HashiCorp\Vagrant\bin\vagrant.exe" exit /b 0

echo Installing Vagrant via winget...
winget install --id Hashicorp.Vagrant --silent --accept-package-agreements --accept-source-agreements
if errorlevel 1 (
    echo Failed to install Vagrant via winget.
    exit /b 1
)

if exist "C:\Program Files\Vagrant\bin\vagrant.exe" (
    set "VAGRANT_BIN=C:\Program Files\Vagrant\bin"
) else if exist "C:\HashiCorp\Vagrant\bin\vagrant.exe" (
    set "VAGRANT_BIN=C:\HashiCorp\Vagrant\bin"
)

if defined VAGRANT_BIN (
    set "DEST_DIR=%USERPROFILE%\.local\bin"
    if not exist "!DEST_DIR!" mkdir "!DEST_DIR!"
    (
        echo @echo off
        echo "!VAGRANT_BIN!\vagrant.exe" %%*
    ) > "!DEST_DIR!\vagrant.cmd"
)

echo Vagrant installed successfully.
exit /b 0
