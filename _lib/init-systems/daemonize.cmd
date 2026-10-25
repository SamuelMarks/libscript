@echo off
:: # daemonize.cmd
::
:: ## Overview
:: Cross-platform daemonization wrapper for Windows supporting object-map and array service schemas,
:: per-service working directories, isolated environment variables, PID files, uninstallation, and log inspection.
::
:: ## Usage
:: Run `daemonize.cmd <action> <json_file> [--remove] [--verify-ingress] [--public-url=<url>]`
:: where action is `start`, `stop`, `up`, `down`, `status`, `health`, `logs`, or `uninstall`.

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

set "action="
set "json_file="
set "REMOVE_UNITS=0"
set "VERIFY_INGRESS=0"
set "PUBLIC_URL=%LIBSCRIPT_PUBLIC_URL%"

:: ## parse_args_loop
:: Parses positional and flag arguments for daemonize.cmd.
:parse_args_loop
if "%~1"=="" goto :args_done
set "_da=%~1"
if /i "!_da!"=="--remove" (
    set "REMOVE_UNITS=1"
    shift
    goto :parse_args_loop
)
if /i "!_da!"=="--uninstall" (
    set "REMOVE_UNITS=1"
    shift
    goto :parse_args_loop
)
if /i "!_da!"=="--verify-ingress" (
    set "VERIFY_INGRESS=1"
    shift
    goto :parse_args_loop
)
if /i "!_da!"=="--remediate" (
    shift
    goto :parse_args_loop
)
if /i "!_da:~0,13!"=="--public-url=" (
    set "PUBLIC_URL=!_da:~13!"
    set "VERIFY_INGRESS=1"
    shift
    goto :parse_args_loop
)
if /i "!_da!"=="--public-url" (
    set "PUBLIC_URL=%~2"
    set "VERIFY_INGRESS=1"
    shift
    shift
    goto :parse_args_loop
)
if "!action!"=="" (
    set "action=!_da!"
) else if "!json_file!"=="" (
    set "json_file=!_da!"
)
shift
goto :parse_args_loop

:: ## args_done
:: Finalizes action normalization after argument parsing.
:args_done
if /i "!action!"=="remove" set "action=uninstall"
if /i "!action!"=="uninstall-service" set "action=uninstall"
if /i "!action!"=="stop" (
    if "!REMOVE_UNITS!"=="1" set "action=uninstall"
)
if /i "!action!"=="down" (
    if "!REMOVE_UNITS!"=="1" set "action=uninstall"
)

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

if /i "!action!"=="start" call :cleanup_legacy_services
if /i "!action!"=="up" call :cleanup_legacy_services
if /i "!action!"=="uninstall" call :cleanup_legacy_services

set "JQ_FILTER=((.services // .infrastructure.services) | if type == \"object\" then to_entries | map(.value + {name: (.value.name // .key)}) elif type == \"array\" then map(. + {name: (.name // .id)}) else [] end)[]?"

set "HEALTH_FAILED=0"

for /f "delims=" %%i in ('jq -c "!JQ_FILTER!" "!json_file!" 2^>nul') do (
    set "svc=%%i"
    call :process_service
)
if /i "!action!"=="health" (
    if "!VERIFY_INGRESS!"=="1" call :verify_public_ingress
    if "!HEALTH_FAILED!"=="1" exit /b 1
)
exit /b 0

:: ## cleanup_legacy_services
:: Stops and removes any legacy service names declared in the manifest.
:cleanup_legacy_services
for /f "delims=" %%L in ('jq -r "((.legacy_service_names // []) + (.infrastructure.legacy_service_names // [])) | unique | .[]?" "!json_file!" 2^>nul') do (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" uninstall "%%L" >nul 2>&1
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
for /f "delims=" %%w in ('echo !svc! ^| jq -r ".working_dir // .working_directory // .cwd // \".\"" 2^>nul') do set "raw_wd=%%w"

if "!name!"=="" exit /b 0

set "svc_data=!DATA_BASE!\!name!"
if not exist "!svc_data!" mkdir "!svc_data!"
set "runner_file=!svc_data!\run_!name!.cmd"
set "log_file=!svc_data!\service.log"
set "pid_file=!svc_data!\service.pid"

if /i "!action!"=="uninstall" goto :do_uninstall
if "!cmd!"=="" exit /b 0

set "svc_workdir=!MANIFEST_DIR!"
if not "!raw_wd!"=="." (
    if "!raw_wd:~1,1!"==":" (
        set "svc_workdir=!raw_wd!"
    ) else (
        set "svc_workdir=!MANIFEST_DIR!\!raw_wd:/=\!"
    )
)

if /i "!action!"=="start" goto :do_start
if /i "!action!"=="up" goto :do_start
if /i "!action!"=="stop" goto :do_stop
if /i "!action!"=="down" goto :do_stop
if /i "!action!"=="status" goto :do_status
if /i "!action!"=="health" goto :do_health
if /i "!action!"=="logs" goto :do_logs
exit /b 0

:: ## do_uninstall
:: Stops and uninstalls the target service and removes its runner and PID files.
:do_uninstall
echo Uninstalling service '!name!'...
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" uninstall "!name!" >nul 2>&1
if exist "!pid_file!" del /f /q "!pid_file!" >nul 2>&1
if exist "!runner_file!" del /f /q "!runner_file!" >nul 2>&1
exit /b 0

:: ## do_start
:: Generates an isolated runner script and starts the service in the background.
:do_start
echo Configuring and starting service '!name!' (workdir: !svc_workdir!)...
(
    echo @echo off
    echo setlocal EnableDelayedExpansion
    echo set "PATH=!PATH!"
    if exist "!svc_data!\.env.service" (
        echo for /f "usebackq tokens=* delims=" %%%%L in ^("!svc_data!\.env.service"^) do set "%%%%L"
    )
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
        echo for /f "usebackq tokens=* delims=" %%%%L in ^("!MANIFEST_DIR!\.env.libscript"^) do set "%%%%L" >> "!runner_file!"
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

:: ## do_health
:: Performs deep health checks on the target service (PID, command, URL, expect_json, port).
:do_health
if not exist "!pid_file!" (
    echo [STOPPED] !name!
    set "HEALTH_FAILED=1"
    exit /b 0
)
echo [RUNNING] !name!
set "hc_cmd="
set "hc_url="
set "hc_expect_status="
set "hc_expect_json="
set "hc_retries=15"
set "hc_interval=2"
set "hc_timeout=5"
set "svc_port="

for /f "delims=" %%c in ('echo !svc! ^| jq -r "(.health_check // .healthcheck) as $hc | if ($hc | type) == \"string\" then $hc elif ($hc | type) == \"object\" then ($hc.command // empty) else empty end" 2^>nul') do set "hc_cmd=%%c"
for /f "delims=" %%u in ('echo !svc! ^| jq -r "(.health_check // .healthcheck) as $hc | if ($hc | type) == \"object\" then ($hc.url // empty) else empty end" 2^>nul') do set "hc_url=%%u"
for /f "delims=" %%s in ('echo !svc! ^| jq -r "(.health_check // .healthcheck) as $hc | if ($hc | type) == \"object\" then ($hc.expect_status // empty) else empty end" 2^>nul') do set "hc_expect_status=%%s"
for /f "delims=" %%j in ('echo !svc! ^| jq -r "(.health_check // .healthcheck) as $hc | if ($hc | type) == \"object\" then ($hc.expect_json // empty) else empty end" 2^>nul') do set "hc_expect_json=%%j"
for /f "delims=" %%r in ('echo !svc! ^| jq -r "(.health_check // .healthcheck) as $hc | if ($hc | type) == \"object\" then ($hc.retries // 15) else 15 end" 2^>nul') do set "hc_retries=%%r"
for /f "delims=" %%t in ('echo !svc! ^| jq -r "(.health_check // .healthcheck) as $hc | if ($hc | type) == \"object\" then ($hc.interval // 2) else 2 end" 2^>nul') do set "hc_interval=%%t"
for /f "delims=" %%o in ('echo !svc! ^| jq -r "(.health_check // .healthcheck) as $hc | if ($hc | type) == \"object\" then ($hc.timeout // 5) else 5 end" 2^>nul') do set "hc_timeout=%%o"
for /f "delims=" %%p in ('echo !svc! ^| jq -r ".port // empty" 2^>nul') do set "svc_port=%%p"

if not "!hc_cmd!"=="" (
    if exist "!MANIFEST_DIR!\.env.libscript" (
        for /f "usebackq tokens=1* delims==" %%A in ("!MANIFEST_DIR!\.env.libscript") do (
            if not "%%A"=="" (
                set "_k=%%A"
                if not "!_k:~0,1!"=="#" set "%%A=%%B"
            )
        )
    )
    for /f "delims=" %%e in ('echo !svc! ^| jq -r "(.env // .environment // {}) | to_entries[]? | \"\(.key)=\(.value)\"" 2^>nul') do (
        set "%%e"
    )
    pushd "!svc_workdir!"
    cmd.exe /c "!hc_cmd!"
    if errorlevel 1 (
        echo [ERROR] Health check command failed for service '!name!': !hc_cmd! >&2
        set "HEALTH_FAILED=1"
    )
    popd
)

if not "!hc_url!"=="" (
    call :poll_hc_url
    goto :after_hc_net
)
if "!hc_cmd!"=="" (
    if not "!svc_port!"=="" (
        call :poll_svc_port
    )
)
:: ## after_hc_net
:: Continues health check completion after URL or port validation.
:after_hc_net
exit /b 0

:: ## poll_svc_port
:: Polls the service TCP/HTTP port with retries and interval backoff.
:poll_svc_port
where curl >nul 2>&1
if errorlevel 1 exit /b 0
set "port_attempt=1"
:: ## poll_port_loop
:: Performs a single TCP/HTTP port readiness poll iteration.
:poll_port_loop
curl -s -m !hc_timeout! -o nul "http://127.0.0.1:!svc_port!" 2>nul
if not errorlevel 1 exit /b 0
if !port_attempt! lss !hc_retries! (
    timeout /t !hc_interval! /nobreak >nul 2>&1
    set /a port_attempt+=1
    goto :poll_port_loop
)
echo [ERROR] Port check failed for service '!name!' on 127.0.0.1:!svc_port! >&2
set "HEALTH_FAILED=1"
exit /b 0

:: ## poll_hc_url
:: Polls the configured health check URL and validates status and JSON payload assertions.
:poll_hc_url
set "hc_attempt=1"
set "hc_url_ok=0"
set "hc_body_file=!svc_data!\hc_body.json"
:: ## poll_hc_loop
:: Performs a single HTTP poll iteration against the service health URL.
:poll_hc_loop
if exist "!hc_body_file!" del /f /q "!hc_body_file!" >nul 2>&1
if not "!hc_expect_status!"=="" (
    set "hc_code=000"
    for /f "delims=" %%k in ('curl -s -m !hc_timeout! -o "!hc_body_file!" -w "%%{http_code}" "!hc_url!" 2^>nul') do set "hc_code=%%k"
    if "!hc_code!"=="!hc_expect_status!" (
        set "hc_url_ok=1"
        goto :poll_hc_done
    )
) else (
    curl -sf -m !hc_timeout! -o "!hc_body_file!" "!hc_url!" 2>nul
    if not errorlevel 1 (
        set "hc_url_ok=1"
        goto :poll_hc_done
    )
)
if !hc_attempt! lss !hc_retries! (
    timeout /t !hc_interval! /nobreak >nul 2>&1
    set /a hc_attempt+=1
    goto :poll_hc_loop
)
:: ## poll_hc_done
:: Evaluates final poll results and optional jq JSON assertions.
:poll_hc_done
if "!hc_url_ok!"=="0" (
    echo [ERROR] Health check URL failed for service '!name!': !hc_url! >&2
    set "HEALTH_FAILED=1"
    if exist "!hc_body_file!" del /f /q "!hc_body_file!" >nul 2>&1
    exit /b 0
)
if not "!hc_expect_json!"=="" (
    jq -e "!hc_expect_json!" "!hc_body_file!" >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] Health check expect_json failed for service '!name!': !hc_expect_json! >&2
        set "HEALTH_FAILED=1"
    )
)
if exist "!hc_body_file!" del /f /q "!hc_body_file!" >nul 2>&1
exit /b 0

:: ## verify_public_ingress
:: Polls the public HTTPS ingress URL and verifies HTML content when --verify-ingress is set.
:verify_public_ingress
set "_ing_domain=!PUBLIC_URL!"
if "!_ing_domain!"=="" (
    for /f "delims=" %%D in ('jq -r ".ingress.domain // .domain // empty" "!json_file!" 2^>nul') do set "_ing_domain=%%D"
)
if "!_ing_domain!"=="" exit /b 0
set "_ing_base=https://!_ing_domain!"
if /i "!_ing_domain:~0,7!"=="http://" set "_ing_base=!_ing_domain!"
if /i "!_ing_domain:~0,8!"=="https://" set "_ing_base=!_ing_domain!"
set "_expect_html="
for /f "delims=" %%H in ('jq -r ".ingress.expect_html // empty" "!json_file!" 2^>nul') do set "_expect_html=%%H"
set "_ing_html_file=!DATA_BASE!\ingress_check.html"
curl -sfL -m 10 -o "!_ing_html_file!" "!_ing_base!" 2>nul
if errorlevel 1 (
    echo [ERROR] Public ingress unreachable at !_ing_base! >&2
    set "HEALTH_FAILED=1"
    exit /b 0
)
if not "!_expect_html!"=="" (
    findstr /C:"!_expect_html!" "!_ing_html_file!" >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] Public ingress at !_ing_base! did not match expect_html '!_expect_html!' >&2
        set "HEALTH_FAILED=1"
    )
)
if exist "!_ing_html_file!" del /f /q "!_ing_html_file!" >nul 2>&1
exit /b 0

:: ## do_logs
:: Outputs the tail of the service log file or Windows Service logs.
:do_logs
if exist "!log_file!" (
    echo === !name! ^(!log_file!^) ===
    type "!log_file!"
) else (
    echo === !name! ^(service logs^) ===
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service.cmd" logs "!name!"
)
exit /b 0
