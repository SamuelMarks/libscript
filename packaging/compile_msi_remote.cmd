@echo off
:: # compile_msi_remote.cmd
::
:: ## Overview
:: Helper to compile MSI remotely using an external or remote service.
::
:: ## Usage
::   call compile_msi_remote.cmd <WXS_FILE>

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

if not defined LIBSCRIPT_ROOT_DIR (
    set "LIBSCRIPT_ROOT_DIR=!SCRIPT_DIR!\.."
    for %%I in ("!LIBSCRIPT_ROOT_DIR!") do set "LIBSCRIPT_ROOT_DIR=%%~fI"
)

set "OUT_FILE=%~nx1"

set "VAGRANT_DIR=!LIBSCRIPT_ROOT_DIR!\vagrant\windows-11"

:: Get SSH port dynamically (defaulting to 50523 if awk isn't available)
set "SSH_PORT=50523"
for /f "tokens=2" %%A in ('cd /d "%VAGRANT_DIR%" ^&^& vagrant ssh-config 2^>nul ^| findstr /c:"Port "') do set "SSH_PORT=%%A"

set "SSH_KEY=%USERPROFILE%\.vagrant.d\insecure_private_key"
set "SSH_CMD=ssh -p %SSH_PORT% -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -i "%SSH_KEY%" vagrant@127.0.0.1"

echo [INFO] Initiating remote compilation for %OUT_FILE%.wxs via Vagrant guest...

echo $env:Path += ';C:\libscript\tools\wix' > %TEMP%\remote_build.ps1
echo candle.exe -nologo -out "C:\Users\vagrant\Desktop\%OUT_FILE%.wixobj" "C:\libscript\packaging\%OUT_FILE%.wxs" >> %TEMP%\remote_build.ps1
echo candle.exe -nologo -out "C:\Users\vagrant\Desktop\%OUT_FILE%_payload.wixobj" "C:\libscript\packaging\%OUT_FILE%_payload.wxs" >> %TEMP%\remote_build.ps1
echo light.exe -nologo -sval -ext WixUIExtension -out "C:\Users\vagrant\Desktop\%OUT_FILE%.msi" "C:\Users\vagrant\Desktop\%OUT_FILE%.wixobj" "C:\Users\vagrant\Desktop\%OUT_FILE%_payload.wixobj" >> %TEMP%\remote_build.ps1

scp -P "%SSH_PORT%" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -i "%SSH_KEY%" "%TEMP%\remote_build.ps1" "vagrant@127.0.0.1:C:/Users/vagrant/Desktop/remote_build.ps1"

%SSH_CMD% "powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:/Users/vagrant/Desktop/remote_build.ps1"

scp -P "%SSH_PORT%" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -i "%SSH_KEY%" "vagrant@127.0.0.1:C:/Users/vagrant/Desktop/%OUT_FILE%.msi" "packaging\%OUT_FILE%.msi"

echo [PASS] Successfully retrieved natively compiled %OUT_FILE%.msi
exit /b 0
