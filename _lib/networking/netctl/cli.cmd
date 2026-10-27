@echo off
:: # cli.cmd
:: # netctl.cmd
::
:: ## Overview
:: Network control utility for managing local services, reverse proxies, SPAs, WebSockets, and declarative ingress.
::
:: ## Usage
:: Execute this script to manage networking configurations or apply a libscript.json ingress definition.

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

set NETCTL_DIR=%~dp0
set NETCTL_STATE_FILE=.netctl.json

if "%~1"=="" goto usage

set SINGULAR_MODE=0
set EMIT_FORMAT=

if /I "%~1"=="download" goto :noop
if /I "%~1"=="install" goto :noop
if /I "%~1"=="ls" goto :noop
if /I "%~1"=="ls-remote" goto :noop
if /I "%~1"=="use" goto :noop
if /I "%~1"=="start" goto :noop
if /I "%~1"=="stop" goto :noop
if /I "%~1"=="restart" goto :noop
if /I "%~1"=="install-service" goto :noop
if /I "%~1"=="uninstall-service" goto :noop
if /I "%~1"=="env" goto :noop
if /I "%~1"=="logs" goto :noop
if /I "%~1"=="status" goto :noop
if /I "%~1"=="health" goto :noop
if /I "%~1"=="uninstall" (
    call "%NETCTL_DIR%\uninstall.cmd"
    exit /b %ERRORLEVEL%
)
if /I "%~1"=="test" (
    call "%NETCTL_DIR%\test.cmd"
    exit /b %ERRORLEVEL%
)

if /I "%~1"=="init" (
    call "%NETCTL_DIR%lib\state.cmd" init
    exit /b %ERRORLEVEL%
) else if /I "%~1"=="domain" (
    call "%NETCTL_DIR%lib\state.cmd" domain "%~2"
    exit /b %ERRORLEVEL%
) else if /I "%~1"=="listen" (
    call "%NETCTL_DIR%lib\state.cmd" listen "%~2"
    exit /b %ERRORLEVEL%
) else if /I "%~1"=="static" (
    call "%NETCTL_DIR%lib\state.cmd" static "%~2" "%~3"
    exit /b %ERRORLEVEL%
) else if /I "%~1"=="spa" (
    call "%NETCTL_DIR%lib\state.cmd" spa "%~2" "%~3"
    exit /b %ERRORLEVEL%
) else if /I "%~1"=="proxy" (
    call "%NETCTL_DIR%lib\state.cmd" proxy "%~2" "%~3"
    exit /b %ERRORLEVEL%
) else if /I "%~1"=="ws" (
    call "%NETCTL_DIR%lib\state.cmd" ws "%~2" "%~3"
    exit /b %ERRORLEVEL%
) else if /I "%~1"=="rewrite" (
    call "%NETCTL_DIR%lib\state.cmd" rewrite "%~2" "%~3"
    exit /b %ERRORLEVEL%
) else if /I "%~1"=="apply" (
    shift
    goto :apply_manifest
) else if /I "%~1"=="ingress" (
    shift
    set "APPLY_FORCE_RELOAD=1"
    goto :apply_manifest
) else if /I "%~1"=="remove-ingress" (
    shift
    goto :remove_ingress
) else if /I "%~1"=="unroute" (
    shift
    goto :remove_ingress
) else if /I "%~1"=="reload" (
    shift
    goto :reload_proxy
) else if /I "%~1"=="emit" (
    call "%NETCTL_DIR%lib\%~2.cmd"
    exit /b %ERRORLEVEL%
) else if /I "%~1"=="-h" (
    goto usage
) else if /I "%~1"=="--help" (
    goto usage
) else if /I "%~1"=="/?" (
    goto usage
) else if /I "%~1"=="-?" (
    goto usage
) else (
    set SINGULAR_MODE=1
)

if "!SINGULAR_MODE!"=="1" (
    set NETCTL_STATE_FILE=%TEMP%\netctl_state_%RANDOM%.json
    call "%NETCTL_DIR%lib\state.cmd" init
    
:: ## loop
:: Iterates through singular-mode CLI flags to populate temporary netctl state.
    :loop
    if "%~1"=="" goto done_loop
    if /I "%~1"=="--domain" (
        call "%NETCTL_DIR%lib\state.cmd" domain "%~2"
        shift
        shift
        goto loop
    )
    if /I "%~1"=="--listen" (
        call "%NETCTL_DIR%lib\state.cmd" listen "%~2"
        shift
        shift
        goto loop
    )
    if /I "%~1"=="--static" (
        call "%NETCTL_DIR%lib\state.cmd" static "%~2" "%~3"
        shift
        shift
        shift
        goto loop
    )
    if /I "%~1"=="--spa" (
        call "%NETCTL_DIR%lib\state.cmd" spa "%~2" "%~3"
        shift
        shift
        shift
        goto loop
    )
    if /I "%~1"=="--proxy" (
        call "%NETCTL_DIR%lib\state.cmd" proxy "%~2" "%~3"
        shift
        shift
        shift
        goto loop
    )
    if /I "%~1"=="--ws" (
        call "%NETCTL_DIR%lib\state.cmd" ws "%~2" "%~3"
        shift
        shift
        shift
        goto loop
    )
    if /I "%~1"=="--rewrite" (
        call "%NETCTL_DIR%lib\state.cmd" rewrite "%~2" "%~3"
        shift
        shift
        shift
        goto loop
    )
    if /I "%~1"=="--emit" (
        set EMIT_FORMAT=%~2
        shift
        shift
        goto loop
    )
    echo Unknown option: %1
    goto usage

:: ## done_loop
:: Emits the requested reverse-proxy configuration and removes temporary state files.
    :done_loop
    if not "!EMIT_FORMAT!"=="" (
        call "%NETCTL_DIR%lib\!EMIT_FORMAT!.cmd"
    )
    if exist "!NETCTL_STATE_FILE!" del "!NETCTL_STATE_FILE!"
)
exit /b 0

:: ## apply_manifest
:: Parses .ingress from libscript.json and emits or reloads the reverse proxy configuration.
:apply_manifest
set "APPLY_JSON=%~1"
if "!APPLY_JSON!"=="" set "APPLY_JSON=libscript.json"
shift
set "APPLY_FORMAT="
set "APPLY_OUT="
set "APPLY_RELOAD=0"
if "!APPLY_FORCE_RELOAD!"=="1" set "APPLY_RELOAD=1"

:: ## apply_arg_loop
:: Parses optional flags for the apply subcommand.
:apply_arg_loop
if "%~1"=="" goto :apply_exec
if /I "%~1"=="--format" (
    set "APPLY_FORMAT=%~2"
    shift
    shift
    goto :apply_arg_loop
)
if /I "%~1"=="--out" (
    set "APPLY_OUT=%~2"
    shift
    shift
    goto :apply_arg_loop
)
if /I "%~1"=="--reload" (
    set "APPLY_RELOAD=1"
    shift
    goto :apply_arg_loop
)
shift
goto :apply_arg_loop

:: ## apply_exec
:: Executes jq extraction of .ingress and invokes the target proxy emitter.
:apply_exec
if not exist "!APPLY_JSON!" (
    echo Error: Manifest file not found: !APPLY_JSON! >&2
    exit /b 1
)
jq -e ".ingress != null" "!APPLY_JSON!" >nul 2>&1
if errorlevel 1 exit /b 0

for %%P in ("!APPLY_JSON!") do set "MANIFEST_DIR=%%~dpP"
if "!MANIFEST_DIR:~-1!"=="\" set "MANIFEST_DIR=!MANIFEST_DIR:~0,-1!"
set "MANIFEST_DIR_FWD=!MANIFEST_DIR:\=/!"

for %%E in ("!MANIFEST_DIR!\.env" "!MANIFEST_DIR!\.env.secrets" "!MANIFEST_DIR!\.env.libscript") do (
    if exist "%%~fE" (
        for /f "usebackq tokens=1* delims==" %%A in ("%%~fE") do (
            if not "%%A"=="" (
                set "_nk=%%A"
                if not "!_nk:~0,1!"=="#" set "%%A=%%~B"
            )
        )
    )
)

if exist "!LIBSCRIPT_ROOT_DIR!\_lib\_common\env_printer.cmd" (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\env_printer.cmd" --hydrate "!APPLY_JSON!"
)

if "!APPLY_FORMAT!"=="" (
    for /f "delims=" %%f in ('jq -r ".ingress.provider // .ingress.engine // \"nginx\"" "!APPLY_JSON!" 2^>nul') do set "APPLY_FORMAT=%%f"
)
if "!APPLY_FORMAT!"=="" set "APPLY_FORMAT=nginx"

set "NETCTL_STATE_FILE=%TEMP%\netctl_apply_%RANDOM%.json"
jq -n --arg mdir "!MANIFEST_DIR_FWD!" --slurpfile doc "!APPLY_JSON!" "($doc[0].ingress // {}) as $ing | def expand_env(s): if (s | type) != \"string\" then s else reduce range(3) as $_ (s; gsub(\"\\\\$\\\\{(?<k>[A-Za-z_][A-Za-z0-9_]*):-(?<d>[^}]*)\\\\}\"; (env[.k] // \"\") | if . == \"\" then .d else . end) | gsub(\"\\\\$\\\\{(?<k>[A-Za-z_][A-Za-z0-9_]*)\\\\}\"; env[.k] // \"\")) end; def resolve_path(p): (expand_env(p)) as $ep | if $ep == null or $ep == \"\" then \"\" elif ($ep | startswith(\"/\")) then $ep elif ($ep | startswith(\"./\")) then ($mdir + \"/\" + ($ep | ltrimstr(\"./\"))) else ($mdir + \"/\" + $ep) end; { domain: expand_env($ing.domain // $ing.server_name // \"_\"), listen: (if ($ing.listen | type) == \"array\" then [ $ing.listen[] | tostring | expand_env(.) ] elif ($ing.listen != null) then [ ($ing.listen | tostring | expand_env(.)) ] else [\"80\"] end), routes: (($ing.routes // {}) | if type == \"object\" then with_entries(.key as $k | .value as $v | if ($v | type) == \"string\" then (expand_env($v)) as $ev | (if ($ev | startswith(\"http://\") or startswith(\"https://\")) then {key: $k, value: {type: \"proxy\", target: $ev}} elif ($ev | startswith(\"ws://\") or startswith(\"wss://\")) then {key: $k, value: {type: \"ws\", target: $ev}} else {key: $k, value: {type: \"static\", target: resolve_path($ev)}} end) elif ($v | type) == \"object\" then (if $v.ws then {key: $k, value: {type: \"ws\", target: expand_env($v.ws)}} elif $v.proxy then {key: $k, value: {type: \"proxy\", target: expand_env($v.proxy)}} elif $v.spa == true or $v.type == \"spa\" then {key: $k, value: {type: \"spa\", target: resolve_path($v.static // $v.target // \".\")}} elif $v.static then {key: $k, value: {type: \"static\", target: resolve_path($v.static)}} elif $v.type == \"ws\" then {key: $k, value: {type: \"ws\", target: expand_env($v.target)}} elif $v.type == \"proxy\" then {key: $k, value: {type: \"proxy\", target: expand_env($v.target)}} else {key: $k, value: {type: \"static\", target: resolve_path($v.target // \".\")}} end) else empty end) elif type == \"array\" then reduce .[] as $item ({}; ($item.path // \"/\") as $k | if $item.type == \"spa\" or $item.spa == true then . + {($k): {type: \"spa\", target: resolve_path($item.target // $item.static // \".\")}} elif $item.type == \"ws\" or $item.ws != null then . + {($k): {type: \"ws\", target: expand_env($item.target // $item.ws)}} elif $item.type == \"proxy\" or $item.proxy != null then . + {($k): {type: \"proxy\", target: expand_env($item.target // $item.proxy)}} elif $item.type == \"rewrite\" then . + {($k): {type: \"rewrite\", pattern: expand_env($item.pattern)}} else . + {($k): {type: \"static\", target: resolve_path($item.target // $item.static // \".\")}} end) else {} end) }" > "!NETCTL_STATE_FILE!"

if not "!APPLY_OUT!"=="" (
    call :log_state_routes
    for %%D in ("!APPLY_OUT!") do if not exist "%%~dpD" mkdir "%%~dpD"
    call "%NETCTL_DIR%lib\!APPLY_FORMAT!.cmd" > "!APPLY_OUT!"
    echo [INFO] [ROUTES] [WRITE] Wrote !APPLY_FORMAT! config -^> !APPLY_OUT! 1>&2
) else if "!APPLY_RELOAD!"=="1" (
    call :log_state_routes
    set "ING_DIR=%TEMP%\data\ingress"
    if not exist "!ING_DIR!" mkdir "!ING_DIR!"
    call "%NETCTL_DIR%lib\!APPLY_FORMAT!.cmd" > "!ING_DIR!\!APPLY_FORMAT!.conf"
    echo [INFO] [ROUTES] [WRITE] Installed !APPLY_FORMAT! virtual host config -^> !ING_DIR!\!APPLY_FORMAT!.conf 1>&2
    call :reload_proxy "!APPLY_FORMAT!"
) else (
    call "%NETCTL_DIR%lib\!APPLY_FORMAT!.cmd"
)
if exist "!NETCTL_STATE_FILE!" del "!NETCTL_STATE_FILE!"
exit /b 0

:: ## log_state_routes
:: Logs the domain, listen ports, and each route in NETCTL_STATE_FILE to stderr on Windows.
:log_state_routes
if not exist "!NETCTL_STATE_FILE!" exit /b 0
set "_LSR_DOM=_"
set "_LSR_PORTS=80"
for /f "delims=" %%D in ('jq -r ".domain // \"_\"" "!NETCTL_STATE_FILE!" 2^>nul') do set "_LSR_DOM=%%D"
for /f "delims=" %%P in ('jq -r "(.listen // [\"80\"]) | join(\", \")" "!NETCTL_STATE_FILE!" 2^>nul') do set "_LSR_PORTS=%%P"
echo [INFO] [ROUTES] Configuring !APPLY_FORMAT! ingress for domain '!_LSR_DOM!' ^(listen: !_LSR_PORTS!^)... 1>&2
for /f "delims=" %%R in ('jq -r --arg dom "!_LSR_DOM!" ".routes // {} | to_entries[]? | \"[INFO] [ROUTE] [\((.value.type // \"static\") | ascii_upcase)] \($dom)\(.key) -> \(.value.target // .value.pattern // \"\")\"" "!NETCTL_STATE_FILE!" 2^>nul') do (
    echo %%R 1>&2
)
exit /b 0

:: ## usage
:: Displays command-line usage instructions for netctl on Windows.
:usage
echo netctl - Singular and Additive network config generator
echo.
echo Usage:
echo   netctl [COMMAND] [ARGS...]
echo   netctl [OPTIONS...]
echo.
echo Commands:
echo   init                           Initialize .netctl.json
echo   domain ^<server_name^>           Set domain / server_name
echo   listen ^<port^>                  Add a listening port
echo   static ^<path^> ^<target^>         Add a static file route
echo   spa ^<path^> ^<target^>            Add a Single-Page Application static route
echo   proxy ^<path^> ^<target^>          Add a reverse proxy route
echo   ws ^<path^> ^<target^>             Add a WebSocket reverse proxy route
echo   rewrite ^<path^> ^<pattern^>       Add a rewrite rule
echo   apply ^<libscript.json^>         Generate config from .ingress block
echo   emit ^<format^>                  Emit the configuration for a given format
echo                                  Formats: nginx, caddy, apache, iis
echo.
echo Options (Singular mode):
echo   --domain ^<server_name^>         Set domain / server_name
echo   --listen ^<port^>                Add a listening port
echo   --static ^<path^> ^<target^>       Add a static route
echo   --spa ^<path^> ^<target^>          Add a SPA static route
echo   --proxy ^<path^> ^<target^>        Add a proxy route
echo   --ws ^<path^> ^<target^>           Add a WebSocket proxy route
echo   --rewrite ^<path^> ^<pattern^>     Add a rewrite rule
echo   --emit ^<format^>                Emit to specified format and exit
exit /b 1

:: ## noop
:: Handles standard Version Manager Contract lifecycle verbs that are no-ops for netctl.
:noop
echo netctl is a native shell module. No installation or daemon management required.
exit /b 0

:: ## reload_proxy
:: Reloads the specified reverse proxy service (nginx, caddy, apache, httpd, or iis) on Windows.
:reload_proxy
set "_RP_FMT=%~1"
if "!_RP_FMT!"=="" set "_RP_FMT=nginx"
echo [INFO] [DAEMON] [RELOAD] Reloading !_RP_FMT! reverse proxy daemon... 1>&2
if /I "!_RP_FMT!"=="iis" (
    where iisreset >nul 2>&1
    if not errorlevel 1 iisreset /noforce >nul 2>&1
    echo [INFO] [DAEMON] [ACTIVE] !_RP_FMT! reverse proxy reloaded successfully. 1>&2
    exit /b 0
)
if exist "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service.cmd" (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service.cmd" restart "!_RP_FMT!" >nul 2>&1
)
echo [INFO] [DAEMON] [ACTIVE] !_RP_FMT! reverse proxy reloaded successfully. 1>&2
exit /b 0

:: ## remove_ingress
:: Removes reverse proxy ingress configuration for the specified manifest or domain on Windows.
:remove_ingress
set "_RMI_ARG=%~1"
if "!_RMI_ARG!"=="" set "_RMI_ARG=libscript.json"
set "_RMI_FMT=nginx"
if exist "!_RMI_ARG!" (
    for /f "delims=" %%f in ('jq -r ".ingress.provider // .ingress.engine // \"nginx\"" "!_RMI_ARG!" 2^>nul') do set "_RMI_FMT=%%f"
)
if exist "%TEMP%\data\ingress\!_RMI_FMT!.conf" del /f /q "%TEMP%\data\ingress\!_RMI_FMT!.conf" >nul 2>&1
if exist "%TEMP%\data\ingress\nginx.conf" del /f /q "%TEMP%\data\ingress\nginx.conf" >nul 2>&1
call :reload_proxy "!_RMI_FMT!"
exit /b 0
