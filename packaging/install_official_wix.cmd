@echo off
:: # install_official_wix.cmd
::
:: ## Overview
:: Installs the official WiX Toolset on the Vagrant guest via SSH.
::
:: ## Usage
:: install_official_wix.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
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

cd "%LIBSCRIPT_ROOT_DIR%\vagrant\windows-11"
for /f "tokens=2" %%i in ('vagrant ssh-config ^| findstr /C:"Port "') do set PORT=%%i
cd "%SCRIPT_DIR%"

set VM_IP=127.0.0.1
set "KEY=%USERPROFILE%\.vagrant.d\insecure_private_key"
set SSH_CMD=ssh -p %PORT% -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "%KEY%" vagrant@%VM_IP%
set SCP_CMD=scp -P %PORT% -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "%KEY%"

echo [INFO] Installing official WiX Toolset v3.14 on VM...

(
echo $ErrorActionPreference = 'Stop'
echo if (-not (Test-Path C:\wix^)^) {
echo   New-Item -ItemType Directory -Force -Path C:\wix ^| Out-Null
echo   Write-Host "Downloading WiX Toolset..."
echo   [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
echo   Invoke-WebRequest -Uri 'https://github.com/wixtoolset/wix3/releases/download/wix3141rtm/wix314-binaries.zip' -OutFile C:\wix.zip
echo   Write-Host "Extracting WiX Toolset..."
echo   Expand-Archive -Path C:\wix.zip -DestinationPath C:\wix -Force
echo   Remove-Item C:\wix.zip -Force
echo }
echo if (-not (Test-Path C:\wix\candle.exe^) -or -not (Test-Path C:\wix\light.exe^)^) {
echo   Write-Error "WiX installation failed"
echo   exit 1
echo } else {
echo   Write-Host "WiX successfully installed."
echo }
) > "%LIBSCRIPT_ROOT_DIR%\tmp\install_wix.ps1"

%SCP_CMD% "%LIBSCRIPT_ROOT_DIR%\tmp\install_wix.ps1" vagrant@%VM_IP%:C:/wix_install.ps1
%SSH_CMD% "powershell -ExecutionPolicy Bypass -File C:\wix_install.ps1"
