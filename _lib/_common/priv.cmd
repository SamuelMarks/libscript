@echo off
:: # priv.cmd
::
:: ## Overview
:: Detects and configures privilege escalation tools (sudo, doas, su).
:: It exports the `priv` function to transparently execute commands with
:: root privileges depending on the available system utility and user identity.
:: 
:: ## Usage
:: Source this file and prefix commands requiring elevated rights with `priv`.

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

setlocal EnableDelayedExpansion
:: # LibScript Privilege Escalation Module (Windows Batch)
:: :: This module provides a consistent way to handle privilege escalation on Windows,
:: mirroring the functionality of `priv.sh` on POSIX systems.
::
:: ## Usage
:: To use this module, call the desired label within this script.
::
:: Example:
::   call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\priv.cmd" :priv <command> <args...>
::
:: ## Labels
::
:: ### :check_admin
:: Checks if the current process has administrative privileges.
:: Returns errorlevel 0 if admin, 1 otherwise.
::
:: ### :priv <command> [args...]
:: Runs the specified command with administrative privileges.
:: If the current process is already elevated, it runs the command directly.
:: If not elevated, it uses PowerShell to prompt for UAC elevation.
::
:: ### :priv_as <user> <command> [args...]
:: Placeholder for future 'run as specific user' functionality on Windows.
:: Currently falls back to :priv as multi-user escalation is non-standard in Batch.

setlocal EnableDelayedExpansion

:: Prevent accidental direct execution
set "THIS_FILE=%~f0"
if "%~1"=="" (
    echo This is a LibScript library module and should be called via 'call'.
    exit /b 1
)

:: Dispatch to label
goto %1

:: -----------------------------------------------------------------------------
:: :check_admin
:: -----------------------------------------------------------------------------
:: Returns: errorlevel 0 (Admin) or 1 (Non-Admin)
:: ## check_admin
:: Executes check_admin functionality.
:check_admin
net session >nul 2>&1
if %errorlevel% == 0 (
    exit /b 0
) else (
    exit /b 1
)

:: -----------------------------------------------------------------------------
:: :priv <command> [args...]
:: -----------------------------------------------------------------------------
:: Param: %~2 - The command to run
:: Param: %~3-9 - Arguments for the command
:: ## priv
:: Executes priv functionality.
:priv
set "CMD_TO_RUN=%~2"
if "!CMD_TO_RUN!"=="" (
    echo Error: :priv requires a command.
    exit /b 1
)

:: Check if already elevated
call :check_admin
if %errorlevel% == 0 (
    REM Already elevated, run directly
    shift
    %CMD_TO_RUN% %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
) else (
    REM Not elevated, use PowerShell to RunAs Admin
    echo Requesting administrative privileges for: !CMD_TO_RUN!
    
    REM Construct the argument string for PowerShell
    set "PS_ARGS="
    set "all_args=%*"
    REM Skip the label name (%1) and command name (%2)
    for /f "tokens=2,*" %%a in ("!all_args!") do set "PS_ARGS=%%b"
    
    REM Use PowerShell Start-Process with -Verb RunAs
    REM -Wait ensures we get the exit code if possible (though RunAs sometimes hides it)
    powershell -Command "Start-Process -FilePath '!CMD_TO_RUN!' -ArgumentList '!PS_ARGS!' -Verb RunAs -Wait"
    exit /b %errorlevel%
)

:: -----------------------------------------------------------------------------
:: :priv_as <user> <command> [args...]
:: -----------------------------------------------------------------------------
:: Param: %~2 - The user to run as (currently ignored, defaults to Admin)
:: Param: %~3 - The command to run
:: ## priv_as
:: Executes priv_as functionality.
:priv_as
:: On Windows, 'priv_as' usually implies 'run as admin' for most LibScript tasks.
:: Proper 'runas /user:...' requires a password, which is interactive.
:: For consistency, we fall back to :priv.
shift
goto :priv
