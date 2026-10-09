@echo off
:: # build_msirs.cmd
::
:: ## Overview
:: Orchestrates building the nodejs .msi via msi-rs on the guest.
::
:: ## Usage
:: build_msirs.cmd

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
call vagrant rsync
for /f "tokens=2" %%i in ('vagrant ssh-config ^| findstr /C:"Port "') do set PORT=%%i
cd "%SCRIPT_DIR%"

set VM_IP=127.0.0.1
set "KEY=%USERPROFILE%\.vagrant.d\insecure_private_key"
set SSH_CMD=ssh -p %PORT% -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "%KEY%" vagrant@%VM_IP%
set SCP_CMD=scp -P %PORT% -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "%KEY%"

echo [INFO] Building MSI via msi-rs on guest...
(
echo $ErrorActionPreference = 'Stop'
echo $env:PATH = "C:\msi-rs\target\release;" + $env:PATH
echo Set-Location C:\libscript\tmp\stage_component_nodejs_offline
echo C:\msi-rs\target\release\candle.exe -nologo -arch x64 -out nodejs_offline_main.wixobj nodejs_offline_main.wxs
echo C:\msi-rs\target\release\candle.exe -nologo -arch x64 -out nodejs_offline_payload.wixobj nodejs_offline_payload.wxs
echo C:\msi-rs\target\release\light.exe -nologo -sval -ext WixUIExtension -out nodejs-msi-rs.msi nodejs_offline_main.wixobj nodejs_offline_payload.wixobj
echo if (-not (Test-Path nodejs-msi-rs.msi^)^) {
echo   Write-Error "Failed to build nodejs-msi-rs.msi"
echo   exit 1
echo } else {
echo   Write-Host "Successfully built nodejs-msi-rs.msi"
echo   Copy-Item nodejs-msi-rs.msi -Destination C:\libscript\tmp\nodejs-msi-rs.msi -Force
echo }
) > "%LIBSCRIPT_ROOT_DIR%\tmp\build_msirs.ps1"

%SCP_CMD% "%LIBSCRIPT_ROOT_DIR%\tmp\build_msirs.ps1" vagrant@%VM_IP%:C:/build_msirs.ps1
%SSH_CMD% "powershell -ExecutionPolicy Bypass -File C:\build_msirs.ps1"