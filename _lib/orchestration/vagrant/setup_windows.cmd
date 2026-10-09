@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for vagrant on Windows.
:: Installs official Vagrant distribution on Windows.
::
:: ## Usage
:: Automatically invoked during libscript vagrant installation on Windows.

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
