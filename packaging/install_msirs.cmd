@echo off
:: # install_msirs.cmd
::
:: ## Overview
:: Installs msi-rs natively on the Vagrant guest using LibScript.
::
:: ## Usage
:: install_msirs.cmd

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

echo [INFO] Installing VC++ Redistributable...
%SSH_CMD% "powershell -Command \"$ErrorActionPreference = 'Stop'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://aka.ms/vs/17/release/vc_redist.arm64.exe' -OutFile C:\vc_redist.arm64.exe; Start-Process -Wait -FilePath C:\vc_redist.arm64.exe -ArgumentList '/install /quiet /norestart' -Verb RunAs; Invoke-WebRequest -Uri 'https://aka.ms/vs/17/release/vc_redist.x64.exe' -OutFile C:\vc_redist.x64.exe; Start-Process -Wait -FilePath C:\vc_redist.x64.exe -ArgumentList '/install /quiet /norestart' -Verb RunAs\""

echo [INFO] Installing Visual Studio Build Tools for MSVC (required by rust)...
%SSH_CMD% "powershell -Command \"$ErrorActionPreference = 'Stop'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://aka.ms/vs/17/release/vs_buildtools.exe' -OutFile C:\vs_buildtools.exe; Start-Process -Wait -FilePath C:\vs_buildtools.exe -ArgumentList '--quiet --wait --norestart --nocache --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.19041'\""

echo [INFO] Installing Rust via LibScript to compile msi-rs...
%SSH_CMD% "powershell -Command \"$ErrorActionPreference = 'Stop'; Set-Location C:\libscript; & 'C:\libscript\libscript.cmd' install rust latest\""

echo [INFO] Compiling msi-rs from synced folder...
%SSH_CMD% "powershell -Command \"$ErrorActionPreference = 'Stop'; Set-Location C:\msi-rs; cargo build --release\""

echo [INFO] Verifying compiled msi-rs candle.exe and light.exe...
%SSH_CMD% "powershell -Command \"$ErrorActionPreference = 'Stop'; $env:PATH = 'C:\msi-rs\target\release;' + $env:PATH; if (-not (Get-Command candle.exe -ErrorAction SilentlyContinue) -or -not (Get-Command light.exe -ErrorAction SilentlyContinue)) { Write-Error 'msi-rs candle.exe or light.exe not found in PATH'; exit 1 } else { Write-Host 'msi-rs successfully compiled and verified.' }\""