@echo off
:: # compile.cmd
::
:: ## Overview
:: Compiles Windows Firewall rules via netsh advfirewall with Anti-Lockout Safeguards for SSH, WinRM, and RDP.
::
:: ## Usage
:: traits\firewall\compile.cmd [component...]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":%THIS_FILE%:" >nul 2>&1
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

if "%~1"=="--help" goto :help
if "%~1"=="-h" goto :help

echo [INFO] Applying Anti-Lockout rules for SSH (22), WinRM (5985, 5986), RDP (3389), REST API (8080)...
netsh advfirewall firewall show rule name="LibScript-Anti-Lockout" >nul 2>&1
if errorlevel 1 (
    netsh advfirewall firewall add rule name="LibScript-Anti-Lockout" dir=in action=allow protocol=TCP localport=22,5985,5986,3389,8080 >nul 2>&1
)
exit /b 0

:: ## help
:: Prints usage help for compile.cmd.
:help
echo Usage: compile.cmd [component...]
exit /b 0
