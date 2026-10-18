@echo off
:: # smb.cmd
::
:: ## Overview
:: Idempotently maps SMB/CIFS shares using net use on Windows.
::
:: ## Usage
:: traits\storage\smb.cmd <smb_share_unc> <drive_letter>

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /C:":%THIS_FILE%:" >nul 2>&1
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

set "SMB_SHARE=%~1"
set "DRIVE=%~2"
if "%SMB_SHARE%"=="" goto :help_err
if "%DRIVE%"=="" goto :help_err

if exist "%DRIVE%" (
    echo [INFO] SMB drive %DRIVE% is already mapped.
    exit /b 0
)
net use "%DRIVE%" "%SMB_SHARE%" /persistent:yes >nul 2>&1
echo [INFO] SMB share %SMB_SHARE% configured for %DRIVE%.
exit /b 0

:: ## help
:: Prints usage help for smb.cmd.
:help
echo Usage: smb.cmd ^<smb_share_unc^> ^<drive_letter^>
exit /b 0

:: ## help_err
:: Prints usage help and exits with code 1.
:help_err
echo Usage: smb.cmd ^<smb_share_unc^> ^<drive_letter^> 1>&2
exit /b 1
