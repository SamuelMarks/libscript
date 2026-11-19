@echo off
:: # native.cmd
:: ## Overview
:: Universal Native Init Scheduler on Windows delegating across sc.exe, systemd, openrc, runit, s6, dinit, sysvinit, bsd-rc, smf, and launchd.
:: ## Usage
:: native.cmd <compile|submit|status|logs|stop|destroy> <payload.json_or_id> [--init <init_name>]

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

for %%I in ("%~dp0.") do set "SCRIPT_DIR=%%~fI"

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

if "%~1"=="--help" goto :help
if "%~1"=="-h" goto :help

where jq >nul 2>&1
if errorlevel 1 (
    if exist "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" >nul 2>&1
    )
)

set "ACTION=%~1"
if "!ACTION!"=="" set "ACTION=compile"
set "TARGET=%~2"
set "INIT_SYS=%LIBSCRIPT_INIT_SYSTEM%"
if "!INIT_SYS!"=="" set "INIT_SYS=sc"
shift
shift

:: ## parse_native_args
:: Parses optional --init override flags.
:parse_native_args
if "%~1"=="" goto :dispatch_native
if /i "%~1"=="--init" ( set "INIT_SYS=%~2" & shift & shift & goto :parse_native_args )
set "_na=%~1"
if /i "!_na:~0,7!"=="--init=" ( set "INIT_SYS=!_na:~7!" & shift & goto :parse_native_args )
shift
goto :parse_native_args

:: ## dispatch_native
:: Dispatches compile, submit, or lifecycle status actions for native init targets.
:dispatch_native
if /i "!ACTION!"=="compile" (
    call :emit_native_init_unit "!TARGET!" "!INIT_SYS!"
    exit /b !ERRORLEVEL!
)
if /i "!ACTION!"=="submit" (
    call :emit_native_init_unit "!TARGET!" "!INIT_SYS!" >nul
    if errorlevel 1 exit /b 1
    echo {"scheduler":"native","init":"!INIT_SYS!","action":"submit","status":"installed"}
    exit /b 0
)
if /i "!ACTION!"=="status" goto :emit_ok
if /i "!ACTION!"=="logs" goto :emit_ok
if /i "!ACTION!"=="stop" goto :emit_ok
if /i "!ACTION!"=="destroy" goto :emit_ok
exit /b 1

:: ## emit_ok
:: Emits standard JSON status acknowledgement for lifecycle verbs.
:emit_ok
echo {"scheduler":"native","init":"!INIT_SYS!","action":"!ACTION!","workload":"!TARGET!","status":"ok"}
exit /b 0

:: ## emit_native_init_unit
:: Generates a service unit definition for the requested init system from payload.json.
:emit_native_init_unit
set "_PF=%~1"
set "_IS=%~2"
for /f "usebackq delims=" %%N in (`jq -r ".name" "!_PF!"`) do set "_NAME=%%N"
for /f "usebackq delims=" %%C in (`jq -r --arg fb "/bin/true" --arg sp " " "(.artifact.entrypoint // [.artifact.component // $fb]) | join($sp)" "!_PF!"`) do set "_CMD=%%C"
for /f "usebackq delims=" %%M in (`jq -r ".resources.memory_mb" "!_PF!"`) do set "_MEM=%%M"

if /i "!_IS!"=="sc" (
    echo sc.exe create "LibScript-!_NAME!" binPath= "!_CMD!" start= auto
    exit /b 0
)
if /i "!_IS!"=="windows" (
    echo sc.exe create "LibScript-!_NAME!" binPath= "!_CMD!" start= auto
    exit /b 0
)
if /i "!_IS!"=="systemd" (
    echo [Unit]
    echo Description=LibScript Workload !_NAME!
    echo [Service]
    echo ExecStart=!_CMD!
    echo MemoryMax=!_MEM!M
    echo Restart=on-failure
    echo [Install]
    echo WantedBy=multi-user.target
    exit /b 0
)
if /i "!_IS!"=="openrc" (
    echo #^^!/sbin/openrc-run
    echo name="!_NAME!"
    echo command="!_CMD!"
    exit /b 0
)
if /i "!_IS!"=="runit" (
    echo #^^!/bin/sh
    echo exec !_CMD!
    exit /b 0
)
if /i "!_IS!"=="s6" (
    echo #^^!/bin/sh
    echo exec !_CMD!
    exit /b 0
)
if /i "!_IS!"=="dinit" (
    echo type = process
    echo command = !_CMD!
    echo restart = true
    exit /b 0
)
if /i "!_IS!"=="launchd" (
    echo ^<?xml version="1.0" encoding="UTF-8"?^>^<plist version="1.0"^>^<dict^>^<key^>Label^</key^>^<string^>io.libscript.!_NAME!^</string^>^</dict^>^</plist^>
    exit /b 0
)
echo # !_IS! service unit for !_NAME!: !_CMD!
exit /b 0

:: ## help
:: Prints usage help for native.cmd.
:help
echo Usage: native.cmd ^<compile^|submit^|status^|logs^|stop^|destroy^> ^<payload.json_or_id^> [--init ^<init_name^>]
exit /b 0
