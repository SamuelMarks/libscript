@echo off
:: # daemon_launcher.cmd
:: ## Overview
:: Launches a persistent background TCP/HTTP daemon on Windows by delegating to daemon_launcher.ps1 so the process survives custom action or SSH session termination.
:: ## Usage
:: daemon_launcher.cmd -Port <port> [-Executable <path>] [-DataDir <dir>] [-HttpJson <json>]

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

if "%TARGET_OS%"=="" (
    if exist "!LIBSCRIPT_ROOT_DIR!\engine\common\os_info.cmd" (
        call "!LIBSCRIPT_ROOT_DIR!\engine\common\os_info.cmd"
    )
)

set "_DL_ORIG_ARGS=%*"
set "_DL_PORT=0"
set "_DL_EXE="
set "_DL_DATADIR="
set "_DL_JSON="
goto :parse_dl_args

:: ## parse_dl_args
:: Parses -Port, -Executable, -DataDir, and -HttpJson CLI flags for daemon_launcher.cmd.
:parse_dl_args
if "%~1"=="" goto :dl_args_done
set "_da=%~1"
if /i "!_da!"=="-Port" ( set "_DL_PORT=%~2" & shift & shift & goto :parse_dl_args )
if /i "!_da!"=="--port" ( set "_DL_PORT=%~2" & shift & shift & goto :parse_dl_args )
if /i "!_da!"=="-Executable" ( set "_DL_EXE=%~2" & shift & shift & goto :parse_dl_args )
if /i "!_da!"=="--executable" ( set "_DL_EXE=%~2" & shift & shift & goto :parse_dl_args )
if /i "!_da!"=="-DataDir" ( set "_DL_DATADIR=%~2" & shift & shift & goto :parse_dl_args )
if /i "!_da!"=="--data-dir" ( set "_DL_DATADIR=%~2" & shift & shift & goto :parse_dl_args )
if /i "!_da!"=="-HttpJson" ( set "_DL_JSON=%~2" & shift & shift & goto :parse_dl_args )
if /i "!_da!"=="--http-json" ( set "_DL_JSON=%~2" & shift & shift & goto :parse_dl_args )
shift
goto :parse_dl_args

:: ## dl_args_done
:: Dispatches MS-DOS foreground/no-op fallback or Win32 C89 ls-daemon.exe execution.
:dl_args_done
if "%IS_MSDOS%"=="1" goto :msdos_daemon_fallback
if /i "%TARGET_OS%"=="msdos" goto :msdos_daemon_fallback

set "LS_HELPER_BIN="
call "!LIBSCRIPT_ROOT_DIR!\engine\common\win32\build_helper.cmd" :resolve_helper ls-daemon
if not errorlevel 1 if not "!LS_HELPER_BIN!"=="" (
    "!LS_HELPER_BIN!" !_DL_ORIG_ARGS!
    exit /b !errorlevel!
)

if "!_DL_DATADIR!"=="" set "_DL_DATADIR=%USERPROFILE%\.libscript\run"
if not exist "!_DL_DATADIR!" mkdir "!_DL_DATADIR!"

if not "!_DL_EXE!"=="" if exist "!_DL_EXE!" (
    for %%F in ("!_DL_EXE!") do set "_DL_WORK=%%~dpF"
    start "" /b /d "!_DL_WORK!" "!_DL_EXE!"
    exit /b 0
)

where powershell >nul 2>&1
if not errorlevel 1 (
    powershell -NoProfile -ExecutionPolicy Bypass -File "!SCRIPT_DIR!\daemon_launcher.ps1" !_DL_ORIG_ARGS!
    exit /b !errorlevel!
)
echo [ERROR] ls-daemon.exe ^(C compiler^) or PowerShell fallback required for loopback port responder. 1>&2
exit /b 1

:: ## msdos_daemon_fallback
:: Handles single-tasking MS-DOS execution via optional foreground run or clean no-op exit.
:msdos_daemon_fallback
if "!_DL_DATADIR!"=="" (
    set "_DL_HOME=%LIBSCRIPT_HOME%"
    if "!_DL_HOME!"=="" set "_DL_HOME=C:\LIBSCRIP"
    set "_DL_DATADIR=!_DL_HOME!\RUN"
)
if not exist "!_DL_DATADIR!" mkdir "!_DL_DATADIR!"
if "%LIBSCRIPT_MSDOS_FOREGROUND%"=="1" if not "!_DL_EXE!"=="" if exist "!_DL_EXE!" (
    call "!_DL_EXE!"
    exit /b !errorlevel!
)
echo [INFO] [MS-DOS] Single-tasking mode: skipping detached background daemon launch.
exit /b 0
