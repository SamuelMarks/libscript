@echo off
:: # priv.cmd
:: ## Overview
:: Detects and configures privilege escalation tools (sudo, doas, su). It exports the `priv` function to transparently execute commands with root privileges depending on the available system utility and user identity.
:: ## Usage
:: Source this file and prefix commands requiring elevated rights with `priv`.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        if "%LIBSCRIPT_DEBUG%"=="1" echo [STOP] processing "!THIS_FILE!" >&2
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


:: Prevent accidental direct execution
if "%~1"=="" (
    echo This is a LibScript library module and should be called via 'call'.
    exit /b 1
)

:: Dispatch to label
goto %1

:: -----------------------------------------------------------------------------
:: :check_admin
:: -----------------------------------------------------------------------------
:: Returns: errorlevel 0 (Admin or MS-DOS ring 0) or 1 (Non-Admin)
:: ## check_admin
:: Checks whether the current process is running in MS-DOS ring 0 or with Windows Administrator privileges.
:check_admin
if "%IS_MSDOS%"=="1" exit /b 0
if /i "%TARGET_OS%"=="msdos" exit /b 0
if /i "%LIBSCRIPT_TARGET_OS%"=="msdos" exit /b 0
net session >nul 2>&1
if "%errorlevel%" == "0" exit /b 0
fltmc >nul 2>&1
if "%errorlevel%" == "0" exit /b 0
exit /b 1

:: -----------------------------------------------------------------------------
:: :priv <command> [args...]
:: -----------------------------------------------------------------------------
:: Param: %~2 - The command to run
:: Param: %~3-9 - Arguments for the command
:: ## priv
:: Executes a command directly on MS-DOS or when already elevated, otherwise elevates via Win32 ls-elevate.exe.
:priv
if "%LIBSCRIPT_SKIP_SYSTEM_DEPS%"=="1" exit /b 0
set "CMD_TO_RUN=%~2"
if "!CMD_TO_RUN!"=="" (
    echo Error: :priv requires a command.
    exit /b 1
)

call :check_admin
if "%errorlevel%" == "0" (
    shift
    %CMD_TO_RUN% %2 %3 %4 %5 %6 %7 %8 %9
    exit /b !ERRORLEVEL!
)

echo Requesting administrative privileges for: !CMD_TO_RUN!
set "PS_ARGS="
set "all_args=%*"
for /f "tokens=2,*" %%a in ("!all_args!") do set "PS_ARGS=%%b"

set "LS_HELPER_BIN="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\win32\build_helper.cmd" :resolve_helper ls-elevate
if not errorlevel 1 if not "!LS_HELPER_BIN!"=="" (
    "!LS_HELPER_BIN!" "!CMD_TO_RUN!" !PS_ARGS!
    exit /b !errorlevel!
)

where powershell >nul 2>&1
if not errorlevel 1 (
    powershell -NoProfile -Command "Start-Process -FilePath '!CMD_TO_RUN!' -ArgumentList '!PS_ARGS!' -Verb RunAs -Wait"
    exit /b !errorlevel!
)
echo [ERROR] Cannot elevate '!CMD_TO_RUN!': ls-elevate.exe and PowerShell are unavailable. 1>&2
exit /b 1

:: -----------------------------------------------------------------------------
:: :priv_as <user> <command> [args...]
:: -----------------------------------------------------------------------------
:: Param: %~2 - The user to run as (currently ignored, defaults to Admin)
:: Param: %~3 - The command to run
:: ## priv_as
:: Executes a command under the specified target user account.
:priv_as
:: On Windows, 'priv_as' usually implies 'run as admin' for most LibScript tasks.
:: Proper 'runas /user:...' requires a password, which is interactive.
:: For consistency, we fall back to :priv.
shift
goto :priv
