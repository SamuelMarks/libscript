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
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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

call :build_msirs
exit /b 0

:: ## build_msirs
:: Orchestrates the building of the nodejs MSI artifact using the compiled msi-rs toolchain.
:build_msirs
set COMPONENT=nodejs
set VERSION=20.17.0
set "STAGE_ROOT=%LIBSCRIPT_ROOT_DIR%\tmp\stage_component_%COMPONENT%_offline"

if not exist "%LIBSCRIPT_ROOT_DIR%\cache\runtimes" mkdir "%LIBSCRIPT_ROOT_DIR%\cache\runtimes"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_download "https://nodejs.org/dist/v%VERSION%/node-v%VERSION%-win-x64.zip" "%LIBSCRIPT_ROOT_DIR%\cache\runtimes\node-v%VERSION%-win-x64.zip"

if exist "%STAGE_ROOT%" rmdir /s /q "%STAGE_ROOT%"
if not exist "%STAGE_ROOT%\bin" mkdir "%STAGE_ROOT%\bin"
tar -xf "%LIBSCRIPT_ROOT_DIR%\cache\runtimes\node-v%VERSION%-win-x64.zip" -C "%STAGE_ROOT%"

for /d %%I in ("%STAGE_ROOT%\node-*") do (
    xcopy /s /e /y "%%I\*" "%STAGE_ROOT%\"
    rmdir /s /q "%%I"
)

if exist "%STAGE_ROOT%\node.exe" if not exist "%STAGE_ROOT%\bin\node.exe" (
    copy /y "%STAGE_ROOT%\node.exe" "%STAGE_ROOT%\bin\node.exe"
)

set "MAIN_WXS=%STAGE_ROOT%\%COMPONENT%_offline_main.wxs"
set "PAYLOAD_WXS=%STAGE_ROOT%\%COMPONENT%_offline_payload.wxs"

call "%LIBSCRIPT_ROOT_DIR%\packaging\template_component_msi.cmd" --component "%COMPONENT%" --version "%VERSION%" --variant offline --out "%MAIN_WXS%"
call "%LIBSCRIPT_ROOT_DIR%\packaging\harvest_payload.cmd" --source-dir "%STAGE_ROOT%" --wix-fragment "%PAYLOAD_WXS%" --component-group PayloadComponents --directory-id INSTALLFOLDER

echo [INFO] Syncing files to guest...
cd /d "%LIBSCRIPT_ROOT_DIR%\vagrant\windows-11"
call vagrant rsync
for /f "tokens=2" %%i in ('vagrant ssh-config ^| findstr /C:"Port "') do set PORT=%%i
cd /d "%SCRIPT_DIR%"

set VM_IP=127.0.0.1
set "KEY=%USERPROFILE%\.vagrant.d\insecure_private_key"
set SSH_CMD=ssh -p %PORT% -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "%KEY%" vagrant@%VM_IP%
set SCP_CMD=scp -P %PORT% -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "%KEY%"

echo [INFO] Building MSI via msi-rs on guest...
(
echo $ErrorActionPreference = 'Stop'
echo Set-Location C:\libscript\tmp\stage_component_nodejs_offline
echo ^& "C:\msi-rs\target\release\candle.exe" -nologo -arch x64 -out nodejs_offline_main.wixobj nodejs_offline_main.wxs
echo ^& "C:\msi-rs\target\release\candle.exe" -nologo -arch x64 -out nodejs_offline_payload.wixobj nodejs_offline_payload.wxs
echo ^& "C:\msi-rs\target\release\light.exe" -nologo -sval -ext WixUIExtension -out nodejs-msirs.msi nodejs_offline_main.wixobj nodejs_offline_payload.wixobj
echo if (-not (Test-Path nodejs-msirs.msi^^)^^) {
echo   Write-Error "Failed to build nodejs-msirs.msi"
echo   exit 1
echo } else {
echo   Write-Host "Successfully built nodejs-msirs.msi"
echo   Copy-Item nodejs-msirs.msi -Destination C:\libscript\tmp\nodejs-msirs.msi -Force
echo }
) > "%LIBSCRIPT_ROOT_DIR%\tmp\build_msirs.ps1"

%SCP_CMD% "%LIBSCRIPT_ROOT_DIR%\tmp\build_msirs.ps1" vagrant@%VM_IP%:C:/build_msirs.ps1
%SSH_CMD% "powershell -ExecutionPolicy Bypass -File C:\build_msirs.ps1"
exit /b 0