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
