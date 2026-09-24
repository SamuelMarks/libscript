@echo off
:: # setup.cmd
::
:: ## Overview
:: Orchestrates the setup and installation process for the OpenVPN networking stack on Windows.
:: Installs the official OpenVPN package via winget and provisions executable shims.
:: 
:: ## Usage
:: Execute this script to install and configure openvpn on the local system.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

where openvpn >nul 2>&1
if %errorlevel% equ 0 exit /b 0

if exist "%ProgramFiles%\OpenVPN\bin\openvpn.exe" goto :create_shims
if exist "%ProgramFiles(x86)%\OpenVPN\bin\openvpn.exe" goto :create_shims

echo Installing OpenVPN via winget...
winget install --id OpenVPNTechnologies.OpenVPN --silent --accept-package-agreements --accept-source-agreements

:create_shims
set "OPENVPN_EXE="
if exist "%ProgramFiles%\OpenVPN\bin\openvpn.exe" set "OPENVPN_EXE=%ProgramFiles%\OpenVPN\bin\openvpn.exe"
if exist "%ProgramFiles(x86)%\OpenVPN\bin\openvpn.exe" set "OPENVPN_EXE=%ProgramFiles(x86)%\OpenVPN\bin\openvpn.exe"

if defined OPENVPN_EXE (
    set "DEST_DIR=%USERPROFILE%\.libscript\openvpn\latest\bin"
    if not exist "!DEST_DIR!" mkdir "!DEST_DIR!"
    (
        echo @echo off
        echo "!OPENVPN_EXE!" %%*
    ) > "!DEST_DIR!\openvpn.cmd"

    if not exist "%USERPROFILE%\.local\bin" mkdir "%USERPROFILE%\.local\bin"
    copy /y "!DEST_DIR!\openvpn.cmd" "%USERPROFILE%\.local\bin\openvpn.cmd" >nul 2>&1
    echo OpenVPN installed successfully.
    exit /b 0
)

echo Failed to install OpenVPN.
exit /b 1
