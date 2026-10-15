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

call :install_msirs
exit /b 0

:: ## install_msirs
:: Orchestrates compiling msi-rs on the Vagrant Windows guest.
:install_msirs
cd /d "%LIBSCRIPT_ROOT_DIR%\vagrant\windows-11"
for /f "tokens=2" %%i in ('vagrant ssh-config ^| findstr /C:"Port "') do set PORT=%%i
cd /d "%SCRIPT_DIR%"

set VM_IP=127.0.0.1
set "KEY=%USERPROFILE%\.vagrant.d\insecure_private_key"
set SSH_CMD=ssh -p %PORT% -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "%KEY%" vagrant@%VM_IP%
set SCP_CMD=scp -P %PORT% -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "%KEY%"

echo [INFO] Ensuring VC++ Redistributable, MSVC, and Rust are installed...
%SSH_CMD% "powershell -Command \"$ErrorActionPreference = 'Stop'; Set-Location C:\libscript; & 'C:\libscript\libscript.cmd' install vcredist latest; & 'C:\libscript\libscript.cmd' install msvc latest; & 'C:\libscript\libscript.cmd' install rust latest\""

echo [INFO] Compiling msi-rs from synced folder...
(
echo $ErrorActionPreference = 'Stop'
echo if ^(Test-Path "C:\msi-rs\target\release\candle.exe"^) {
echo   Write-Host "[INFO] msi-rs is already compiled. Skipping."
echo } else {
echo   Set-Location C:\msi-rs
echo   $env:PATH = "C:\Users\vagrant\.cargo\bin;$env:PATH"
echo   $env:USERPROFILE = "C:\Users\vagrant"
echo   ^& rustup toolchain install 1.85.0-x86_64-pc-windows-msvc --force-non-host
echo   ^& rustup default 1.85.0-x86_64-pc-windows-msvc --force-non-host
echo   $vcvars = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
echo   if ^(-not ^(Test-Path $vcvars^)^) {
echo       $vcvars = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat"
echo       $cmd = "`"$vcvars`" x64 ^&^& cargo build --release"
echo   } else {
echo       $cmd = "`"$vcvars`" ^&^& cargo build --release"
echo   }
echo   cmd.exe /c $cmd
echo   if ^($LASTEXITCODE -ne 0^) {
echo     Write-Error "cargo build failed"
echo     exit 1
echo   }
echo }
echo $env:PATH = "C:\msi-rs\target\release;$env:PATH"
echo if ^(-not ^(Get-Command candle.exe -ErrorAction SilentlyContinue^) -or -not ^(Get-Command light.exe -ErrorAction SilentlyContinue^)^) {
echo   Write-Error "msi-rs candle.exe or light.exe not found in PATH"
echo   exit 1
echo } else {
echo   Write-Host "msi-rs successfully compiled and verified."
echo }
) > "%LIBSCRIPT_ROOT_DIR%\tmp\install_msirs.ps1"

%SCP_CMD% "%LIBSCRIPT_ROOT_DIR%\tmp\install_msirs.ps1" vagrant@%VM_IP%:C:/install_msirs.ps1
%SSH_CMD% "powershell -ExecutionPolicy Bypass -File C:\install_msirs.ps1"
exit /b 0