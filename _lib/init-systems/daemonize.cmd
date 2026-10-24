@echo off
:: # daemonize.cmd
::
:: ## Overview
:: Cross-platform daemonization wrapper for Windows supporting object-map and array service schemas,
:: per-service working directories, isolated environment variables, PID files, and log inspection.
::
:: ## Usage
:: Run `daemonize.cmd <action> <json_file>` where action is `start`, `stop`, `up`, `down`, `status`, `health`, or `logs`.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
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

set "action=%~1"
set "json_file=%~2"

if "!action!"=="" exit /b 0
if "!json_file!"=="" exit /b 0
if not exist "!json_file!" exit /b 0

for %%P in ("!json_file!") do set "MANIFEST_DIR=%%~dpP"
if "!MANIFEST_DIR:~-1!"=="\" set "MANIFEST_DIR=!MANIFEST_DIR:~0,-1!"

if exist "!LIBSCRIPT_ROOT_DIR!\_lib\_common\env_printer.cmd" (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\env_printer.cmd" --hydrate "!json_file!"
)

set "DATA_BASE=%TEMP%\data"
if defined LIBSCRIPT_DATA_DIR set "DATA_BASE=!LIBSCRIPT_DATA_DIR!"
if not exist "!DATA_BASE!" mkdir "!DATA_BASE!"

set "JQ_FILTER=(.services | if type == \"object\" then to_entries | map(.value + {name: (.value.name // .key)}) elif type == \"array\" then map(. + {name: (.name // .id)}) else [] end)[]?"

for /f "delims=" %%i in ('jq -c "!JQ_FILTER!" "!json_file!" 2^>nul') do (
    set "svc=%%i"
    call :process_service
)
exit /b 0

:: ## process_service
:: Processes a single service entry for the requested lifecycle action.
:process_service
set "name="
set "cmd="
set "raw_wd=."
for /f "delims=" %%n in ('echo !svc! ^| jq -r ".name // empty" 2^>nul') do set "name=%%n"
for /f "delims=" %%c in ('echo !svc! ^| jq -r ".command // empty" 2^>nul') do set "cmd=%%c"
for /f "delims=" %%w in ('echo !svc! ^| jq -r ".working_dir // .cwd // \".\"" 2^>nul') do set "raw_wd=%%w"

if "!name!"=="" exit /b 0
if "!cmd!"=="" exit /b 0

set "svc_workdir=!MANIFEST_DIR!"
if not "!raw_wd!"=="." (
    if "!raw_wd:~1,1!"==":" (
        set "svc_workdir=!raw_wd!"
    ) else (
        set "svc_workdir=!MANIFEST_DIR!\!raw_wd:/=\!"
    )
)

set "svc_data=!DATA_BASE!\!name!"
if not exist "!svc_data!" mkdir "!svc_data!"
set "runner_file=!svc_data!\run_!name!.cmd"
set "log_file=!svc_data!\service.log"
set "pid_file=!svc_data!\service.pid"

if /i "!action!"=="start" goto :do_start
if /i "!action!"=="up" goto :do_start
if /i "!action!"=="stop" goto :do_stop
if /i "!action!"=="down" goto :do_stop
if /i "!action!"=="status" goto :do_status
if /i "!action!"=="health" goto :do_status
if /i "!action!"=="logs" goto :do_logs
exit /b 0

:: ## do_start
:: Generates an isolated runner script and starts the service in the background.
:do_start
echo Configuring and starting service '!name!' (workdir: !svc_workdir!)...
(
    echo @echo off
    echo setlocal EnableDelayedExpansion
    echo set "PATH=!PATH!"
    if exist "!MANIFEST_DIR!\.env.libscript" (
        echo for /f "usebackq tokens=* delims=" %%%%L in ^("!MANIFEST_DIR!\.env.libscript"^) do set "%%%%L"
    )
) > "!runner_file!"

for /f "delims=" %%f in ('echo !svc! ^| jq -r ".env_files[]?" 2^>nul') do (
    set "ef=%%f"
    set "ef_win=!ef:/=\!"
    if exist "!svc_workdir!\!ef_win!" (
        echo for /f "usebackq tokens=* delims=" %%%%L in ^("!svc_workdir!\!ef_win!"^) do set "%%%%L" >> "!runner_file!"
    ) else if exist "!MANIFEST_DIR!\!ef_win!" (
        echo for /f "usebackq tokens=* delims=" %%%%L in ^("!MANIFEST_DIR!\!ef_win!"^) do set "%%%%L" >> "!runner_file!"
    ) else if exist "!ef_win!" (
        echo for /f "usebackq tokens=* delims=" %%%%L in ^("!ef_win!"^) do set "%%%%L" >> "!runner_file!"
    )
)

for /f "delims=" %%e in ('echo !svc! ^| jq -r ".env // {} | to_entries[]? | \"set \\\"\(.key)=\(.value)\\\"\"" 2^>nul') do (
    echo %%e >> "!runner_file!"
)

(
    echo pushd "!svc_workdir!"
    echo call !cmd! ^>^> "!log_file!" 2^>^&1
    echo popd
) >> "!runner_file!"

start "!name!" /B cmd.exe /v:on /c "!runner_file!"
echo running > "!pid_file!"
exit /b 0

:: ## do_stop
:: Stops the target background service and removes its PID marker.
:do_stop
echo Stopping service '!name!'...
taskkill /fi "WINDOWTITLE eq !name!" /f >nul 2>&1
if exist "!pid_file!" del /f /q "!pid_file!" >nul 2>&1
exit /b 0

:: ## do_status
:: Checks whether the target service is currently active.
:do_status
if exist "!pid_file!" (
    echo [RUNNING] !name!
) else (
    echo [STOPPED] !name!
)
exit /b 0

:: ## do_logs
:: Outputs the tail of the service log file.
:do_logs
if exist "!log_file!" (
    echo === !name! ^(!log_file!^) ===
    type "!log_file!"
) else (
    echo === !name! ^(no logs found^) ===
)
exit /b 0
