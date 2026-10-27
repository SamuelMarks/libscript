@echo off
:: # build_on_vagrant.cmd
::
:: ## Overview
:: Builds the Open edX MSIs on the Windows 11 Vagrant guest.
::
:: ## Usage
::   call build_on_vagrant.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
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

echo [INFO] Creating directories on VM...
cd /d "!LIBSCRIPT_ROOT_DIR!\vagrant\windows-11"
vagrant ssh -c "powershell -Command \"New-Item -ItemType Directory -Force -Path C:\libscript\packaging\""

echo [INFO] Uploading WXS files...
vagrant upload "!LIBSCRIPT_ROOT_DIR!\packaging\OpenEdX-Setup.wxs" "C:\libscript\packaging\OpenEdX-Setup.wxs"
vagrant upload "!LIBSCRIPT_ROOT_DIR!\packaging\OpenEdX-Setup_payload.wxs" "C:\libscript\packaging\OpenEdX-Setup_payload.wxs"
vagrant upload "!LIBSCRIPT_ROOT_DIR!\packaging\OpenEdX-Setup-Offline.wxs" "C:\libscript\packaging\OpenEdX-Setup-Offline.wxs"
vagrant upload "!LIBSCRIPT_ROOT_DIR!\packaging\OpenEdX-Setup-Offline_payload.wxs" "C:\libscript\packaging\OpenEdX-Setup-Offline_payload.wxs"

echo [INFO] Generating build script...
(
echo $env:Path += ';' + $env:USERPROFILE + '\.libscript\wix\3.14\bin'
echo Set-Location C:\libscript\packaging
echo Write-Host "[INFO] Building Online MSI..."
echo candle.exe -nologo -out OpenEdX-Setup.wixobj OpenEdX-Setup.wxs
echo candle.exe -nologo -out OpenEdX-Setup_payload.wixobj OpenEdX-Setup_payload.wxs
echo light.exe -nologo -sval -ext WixUIExtension -out OpenEdX-Setup.msi OpenEdX-Setup.wixobj OpenEdX-Setup_payload.wixobj
echo Write-Host "[INFO] Building Offline MSI..."
echo candle.exe -nologo -out OpenEdX-Setup-Offline.wixobj OpenEdX-Setup-Offline.wxs
echo candle.exe -nologo -out OpenEdX-Setup-Offline_payload.wixobj OpenEdX-Setup-Offline_payload.wxs
echo light.exe -nologo -sval -ext WixUIExtension -out OpenEdX-Setup-Offline.msi OpenEdX-Setup-Offline.wixobj OpenEdX-Setup-Offline_payload.wixobj
) > "!LIBSCRIPT_ROOT_DIR!\packaging\build.ps1"

vagrant upload "!LIBSCRIPT_ROOT_DIR!\packaging\build.ps1" "C:\libscript\packaging\build.ps1"

echo [INFO] Running build script...
vagrant ssh -c "powershell -ExecutionPolicy Bypass -File C:\libscript\packaging\build.ps1"

echo [INFO] Downloading MSIs...
cd /d "!LIBSCRIPT_ROOT_DIR!\packaging"
:: Need to download the artifacts. vagrant download wasn't a standard command in older versions but works in vagrant 2.4+.
:: Assuming SCP can be avoided by copying to synced folder.
cd /d "!LIBSCRIPT_ROOT_DIR!\vagrant\windows-11"
vagrant ssh -c "powershell -Command \"Copy-Item C:\libscript\packaging\*.msi C:\vagrant\ -Force\""
copy /y "!LIBSCRIPT_ROOT_DIR!\vagrant\windows-11\OpenEdX-Setup.msi" "!LIBSCRIPT_ROOT_DIR!\packaging\"
copy /y "!LIBSCRIPT_ROOT_DIR!\vagrant\windows-11\OpenEdX-Setup-Offline.msi" "!LIBSCRIPT_ROOT_DIR!\packaging\"

echo [PASS] Done!
exit /b 0
