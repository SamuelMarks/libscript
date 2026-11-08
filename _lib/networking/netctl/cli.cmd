@echo off
:: # netctl.cmd
:: ## Overview
:: Network control utility for managing local services, reverse proxies, SPAs, WebSockets, and declarative ingress.
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

if exist "%USERPROFILE%\.libscript\jq\latest\bin" set "PATH=%USERPROFILE%\.libscript\jq\latest\bin;!PATH!"
if exist "%USERPROFILE%\.local\bin" set "PATH=%USERPROFILE%\.local\bin;!PATH!"
if exist "%LOCALAPPDATA%\Microsoft\WinGet\Links" set "PATH=%LOCALAPPDATA%\Microsoft\WinGet\Links;!PATH!"
if exist "C:\ProgramData\chocolatey\bin" set "PATH=C:\ProgramData\chocolatey\bin;!PATH!"
if exist "%USERPROFILE%\scoop\shims" set "PATH=%USERPROFILE%\scoop\shims;!PATH!"
where jq >nul 2>&1
if !errorlevel! neq 0 (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install jq latest >nul 2>&1
    if exist "%USERPROFILE%\.libscript\jq\latest\bin" set "PATH=%USERPROFILE%\.libscript\jq\latest\bin;!PATH!"
    if exist "%USERPROFILE%\.local\bin" set "PATH=%USERPROFILE%\.local\bin;!PATH!"
)

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
) else if /I "%~1"=="tls" (
    call "%NETCTL_DIR%lib\state.cmd" tls "%~2"
    exit /b %ERRORLEVEL%
) else if /I "%~1"=="cert-store-dir" (
    call "%NETCTL_DIR%lib\state.cmd" cert-store-dir "%~2"
    exit /b %ERRORLEVEL%
) else if /I "%~1"=="cert_store_dir" (
    call "%NETCTL_DIR%lib\state.cmd" cert_store_dir "%~2"
    exit /b %ERRORLEVEL%
) else if /I "%~1"=="acme-webroot" (
    call "%NETCTL_DIR%lib\state.cmd" acme-webroot "%~2"
    exit /b %ERRORLEVEL%
) else if /I "%~1"=="acme_webroot" (
    call "%NETCTL_DIR%lib\state.cmd" acme_webroot "%~2"
    exit /b %ERRORLEVEL%
) else if /I "%~1"=="proxy-connect-timeout" (
    call "%NETCTL_DIR%lib\state.cmd" proxy-connect-timeout "%~2"
    exit /b %ERRORLEVEL%
) else if /I "%~1"=="proxy_connect_timeout" (
    call "%NETCTL_DIR%lib\state.cmd" proxy_connect_timeout "%~2"
    exit /b %ERRORLEVEL%
) else if /I "%~1"=="proxy-send-timeout" (
    call "%NETCTL_DIR%lib\state.cmd" proxy-send-timeout "%~2"
    exit /b %ERRORLEVEL%
) else if /I "%~1"=="proxy_send_timeout" (
    call "%NETCTL_DIR%lib\state.cmd" proxy_send_timeout "%~2"
    exit /b %ERRORLEVEL%
) else if /I "%~1"=="proxy-read-timeout" (
    call "%NETCTL_DIR%lib\state.cmd" proxy-read-timeout "%~2"
    exit /b %ERRORLEVEL%
) else if /I "%~1"=="proxy_read_timeout" (
    call "%NETCTL_DIR%lib\state.cmd" proxy_read_timeout "%~2"
    exit /b %ERRORLEVEL%
) else if /I "%~1"=="proxy-buffering" (
    call "%NETCTL_DIR%lib\state.cmd" proxy-buffering "%~2"
    exit /b %ERRORLEVEL%
) else if /I "%~1"=="proxy_buffering" (
    call "%NETCTL_DIR%lib\state.cmd" proxy_buffering "%~2"
    exit /b %ERRORLEVEL%
) else if /I "%~1"=="ensure-cert" (
    call :netctl_ensure_letsencrypt_cert "%~2" "%~3" "%~4" "%~5"
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
    set "STACK="
    call "%NETCTL_DIR%lib\state.cmd" init
    
:: ## loop
:: Iterates through singular-mode CLI flags to populate temporary netctl state.
    :loop
    if "%~1"=="" goto done_loop
    if /I "%~1"=="--domain" (
        set "STACK="
        call "%NETCTL_DIR%lib\state.cmd" domain "%~2"
        shift
        shift
        goto loop
    )
    if /I "%~1"=="--tls" (
        set "STACK="
        call "%NETCTL_DIR%lib\state.cmd" tls "%~2"
        shift
        shift
        goto loop
    )
    if /I "%~1"=="--cert-store-dir" (
        set "STACK="
        call "%NETCTL_DIR%lib\state.cmd" cert-store-dir "%~2"
        shift
        shift
        goto loop
    )
    if /I "%~1"=="--cert_store_dir" (
        set "STACK="
        call "%NETCTL_DIR%lib\state.cmd" cert_store_dir "%~2"
        shift
        shift
        goto loop
    )
    if /I "%~1"=="--acme-webroot" (
        set "STACK="
        call "%NETCTL_DIR%lib\state.cmd" acme-webroot "%~2"
        shift
        shift
        goto loop
    )
    if /I "%~1"=="--acme_webroot" (
        set "STACK="
        call "%NETCTL_DIR%lib\state.cmd" acme_webroot "%~2"
        shift
        shift
        goto loop
    )
    if /I "%~1"=="--proxy-connect-timeout" (
        set "NETCTL_PROXY_CONNECT_TIMEOUT=%~2"
        set "STACK="
        call "%NETCTL_DIR%lib\state.cmd" proxy-connect-timeout "%~2"
        shift
        shift
        goto loop
    )
    if /I "%~1"=="--proxy_connect_timeout" (
        set "NETCTL_PROXY_CONNECT_TIMEOUT=%~2"
        set "STACK="
        call "%NETCTL_DIR%lib\state.cmd" proxy_connect_timeout "%~2"
        shift
        shift
        goto loop
    )
    if /I "%~1"=="--proxy-send-timeout" (
        set "NETCTL_PROXY_SEND_TIMEOUT=%~2"
        set "STACK="
        call "%NETCTL_DIR%lib\state.cmd" proxy-send-timeout "%~2"
        shift
        shift
        goto loop
    )
    if /I "%~1"=="--proxy_send_timeout" (
        set "NETCTL_PROXY_SEND_TIMEOUT=%~2"
        set "STACK="
        call "%NETCTL_DIR%lib\state.cmd" proxy_send_timeout "%~2"
        shift
        shift
        goto loop
    )
    if /I "%~1"=="--proxy-read-timeout" (
        set "NETCTL_PROXY_READ_TIMEOUT=%~2"
        set "STACK="
        call "%NETCTL_DIR%lib\state.cmd" proxy-read-timeout "%~2"
        shift
        shift
        goto loop
    )
    if /I "%~1"=="--proxy_read_timeout" (
        set "NETCTL_PROXY_READ_TIMEOUT=%~2"
        set "STACK="
        call "%NETCTL_DIR%lib\state.cmd" proxy_read_timeout "%~2"
        shift
        shift
        goto loop
    )
    if /I "%~1"=="--proxy-buffering" (
        set "NETCTL_PROXY_BUFFERING=%~2"
        set "STACK="
        call "%NETCTL_DIR%lib\state.cmd" proxy-buffering "%~2"
        shift
        shift
        goto loop
    )
    if /I "%~1"=="--proxy_buffering" (
        set "NETCTL_PROXY_BUFFERING=%~2"
        set "STACK="
        call "%NETCTL_DIR%lib\state.cmd" proxy_buffering "%~2"
        shift
        shift
        goto loop
    )
    if /I "%~1"=="--listen" (
        set "STACK="
        call "%NETCTL_DIR%lib\state.cmd" listen "%~2"
        shift
        shift
        goto loop
    )
    if /I "%~1"=="--static" (
        set "STACK="
        call "%NETCTL_DIR%lib\state.cmd" static "%~2" "%~3"
        shift
        shift
        shift
        goto loop
    )
    if /I "%~1"=="--spa" (
        set "STACK="
        call "%NETCTL_DIR%lib\state.cmd" spa "%~2" "%~3"
        shift
        shift
        shift
        goto loop
    )
    if /I "%~1"=="--proxy" (
        set "STACK="
        call "%NETCTL_DIR%lib\state.cmd" proxy "%~2" "%~3"
        shift
        shift
        shift
        goto loop
    )
    if /I "%~1"=="--ws" (
        set "STACK="
        call "%NETCTL_DIR%lib\state.cmd" ws "%~2" "%~3"
        shift
        shift
        shift
        goto loop
    )
    if /I "%~1"=="--rewrite" (
        set "STACK="
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
        set "STACK="
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
if /I "%~1"=="--proxy-connect-timeout" (
    set "NETCTL_PROXY_CONNECT_TIMEOUT=%~2"
    shift
    shift
    goto :apply_arg_loop
)
if /I "%~1"=="--proxy-send-timeout" (
    set "NETCTL_PROXY_SEND_TIMEOUT=%~2"
    shift
    shift
    goto :apply_arg_loop
)
if /I "%~1"=="--proxy-read-timeout" (
    set "NETCTL_PROXY_READ_TIMEOUT=%~2"
    shift
    shift
    goto :apply_arg_loop
)
if /I "%~1"=="--proxy-buffering" (
    set "NETCTL_PROXY_BUFFERING=%~2"
    shift
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
    call :enrich_state_tls
    call :log_state_routes
    for %%D in ("!APPLY_OUT!") do if not exist "%%~dpD" mkdir "%%~dpD"
    call "%NETCTL_DIR%lib\!APPLY_FORMAT!.cmd" > "!APPLY_OUT!"
    echo [INFO] [ROUTES] [WRITE] Wrote !APPLY_FORMAT! config -^> !APPLY_OUT! 1>&2
) else if "!APPLY_RELOAD!"=="1" (
    call :enrich_state_tls
    call :log_state_routes
    if /I "!APPLY_TLS!"=="letsencrypt" (
        call :netctl_ensure_letsencrypt_cert "!APPLY_DOM!" "!APPLY_CERT_STORE!" "!APPLY_ACME_WEBROOT!" "!APPLY_EMAIL!"
    )
    set "ING_DIR=%TEMP%\data\ingress"
    if not exist "!ING_DIR!" mkdir "!ING_DIR!"
    call "%NETCTL_DIR%lib\!APPLY_FORMAT!.cmd" > "!ING_DIR!\!APPLY_FORMAT!.conf"
    echo [INFO] [ROUTES] [WRITE] Installed !APPLY_FORMAT! virtual host config -^> !ING_DIR!\!APPLY_FORMAT!.conf 1>&2
    call :reload_proxy "!APPLY_FORMAT!"
) else (
    call :enrich_state_tls
    call "%NETCTL_DIR%lib\!APPLY_FORMAT!.cmd"
)
if exist "!NETCTL_STATE_FILE!" del "!NETCTL_STATE_FILE!"
exit /b 0

:: ## enrich_state_tls
:: Enriches NETCTL_STATE_FILE with .ingress.tls, .ingress.cert_store_dir, and .ingress.acme_webroot fields.
:enrich_state_tls
set "APPLY_DOM=_"
set "APPLY_TLS="
set "APPLY_CERT_STORE=%CERT_STORE_DIR%"
if "!APPLY_CERT_STORE!"=="" (
    set "_NC_DEF_MOUNT=%DATA_DISK_MOUNT%"
    if "!_NC_DEF_MOUNT!"=="" set "_NC_DEF_MOUNT=%DATA_MOUNT_DIR%"
    if "!_NC_DEF_MOUNT!"=="" set "_NC_DEF_MOUNT=/mnt/data"
    set "APPLY_CERT_STORE=!_NC_DEF_MOUNT!/certs"
)
set "APPLY_EMAIL=%LETSENCRYPT_EMAIL%"
for /f "delims=" %%D in ('jq -r ".domain // \"_\"" "!NETCTL_STATE_FILE!" 2^>nul') do set "APPLY_DOM=%%D"
for /f "delims=" %%T in ('jq -r ".ingress.tls // empty" "!APPLY_JSON!" 2^>nul') do set "APPLY_TLS=%%T"
for /f "delims=" %%C in ('jq -r ".ingress.cert_store_dir // empty" "!APPLY_JSON!" 2^>nul') do if not "%%C"=="" set "APPLY_CERT_STORE=%%C"
set "APPLY_ACME_WEBROOT=!APPLY_CERT_STORE!/acme-webroot"
for /f "delims=" %%W in ('jq -r ".ingress.acme_webroot // empty" "!APPLY_JSON!" 2^>nul') do if not "%%W"=="" set "APPLY_ACME_WEBROOT=%%W"
for /f "delims=" %%M in ('jq -r ".ingress.email // empty" "!APPLY_JSON!" 2^>nul') do if not "%%M"=="" set "APPLY_EMAIL=%%M"
set "APPLY_P_CONN=%NETCTL_PROXY_CONNECT_TIMEOUT%"
for /f "delims=" %%P in ('jq -r ".ingress.proxy_connect_timeout // empty" "!APPLY_JSON!" 2^>nul') do if not "%%P"=="" if not "%%P"=="null" set "APPLY_P_CONN=%%P"
set "APPLY_P_SEND=%NETCTL_PROXY_SEND_TIMEOUT%"
for /f "delims=" %%P in ('jq -r ".ingress.proxy_send_timeout // empty" "!APPLY_JSON!" 2^>nul') do if not "%%P"=="" if not "%%P"=="null" set "APPLY_P_SEND=%%P"
set "APPLY_P_READ=%NETCTL_PROXY_READ_TIMEOUT%"
for /f "delims=" %%P in ('jq -r ".ingress.proxy_read_timeout // empty" "!APPLY_JSON!" 2^>nul') do if not "%%P"=="" if not "%%P"=="null" set "APPLY_P_READ=%%P"
set "APPLY_P_BUF=%NETCTL_PROXY_BUFFERING%"
for /f "delims=" %%P in ('jq -r ".ingress.proxy_buffering // empty" "!APPLY_JSON!" 2^>nul') do if not "%%P"=="" if not "%%P"=="null" set "APPLY_P_BUF=%%P"
jq --arg t "!APPLY_TLS!" --arg c "!APPLY_CERT_STORE!" --arg w "!APPLY_ACME_WEBROOT!" --arg pconn "!APPLY_P_CONN!" --arg psend "!APPLY_P_SEND!" --arg pread "!APPLY_P_READ!" --arg pbuf "!APPLY_P_BUF!" ".tls = $t | .cert_store_dir = $c | .acme_webroot = $w | .proxy_connect_timeout = $pconn | .proxy_send_timeout = $psend | .proxy_read_timeout = $pread | .proxy_buffering = $pbuf | if $t == \"letsencrypt\" then .listen = ((.listen + [\"80\", \"443\"]) | unique) else . end" "!NETCTL_STATE_FILE!" > "!NETCTL_STATE_FILE!.tmp"
move /Y "!NETCTL_STATE_FILE!.tmp" "!NETCTL_STATE_FILE!" >nul
if /I "!APPLY_TLS!"=="letsencrypt" (
    call :netctl_restore_persisted_cert "!APPLY_DOM!" "!APPLY_CERT_STORE!"
)
exit /b 0

:: ## netctl_cert_is_valid_letsencrypt
:: Verifies that a certificate and private key exist, are CA-signed, and are not expired.
:netctl_cert_is_valid_letsencrypt
set "_VC_DOM=%~1"
set "_VC_CERT=%~2"
set "_VC_KEY=%~3"
if not exist "!_VC_CERT!" exit /b 1
if not exist "!_VC_KEY!" exit /b 1
where openssl >nul 2>&1
if errorlevel 1 exit /b 0
set "_VC_ISS="
set "_VC_SUB="
for /f "delims=" %%I in ('openssl x509 -noout -issuer -in "!_VC_CERT!" 2^>nul') do set "_VC_ISS=%%I"
for /f "delims=" %%S in ('openssl x509 -noout -subject -in "!_VC_CERT!" 2^>nul') do set "_VC_SUB=%%S"
if "!_VC_ISS!"=="" exit /b 1
if "!_VC_SUB!"=="" exit /b 1
set "_VC_ISS_V=!_VC_ISS:*=!"
set "_VC_SUB_V=!_VC_SUB:*=!"
if "!_VC_ISS_V!"=="!_VC_SUB_V!" exit /b 1
set "_RENEW_SEC=%LETSENCRYPT_RENEW_BEFORE_SECONDS%"
if "!_RENEW_SEC!"=="" set "_RENEW_SEC=0"
openssl x509 -checkend !_RENEW_SEC! -noout -in "!_VC_CERT!" >nul 2>&1
if errorlevel 1 exit /b 1
exit /b 0

:: ## netctl_restore_persisted_cert
:: Restores a valid non-expired Let's Encrypt certificate from the persistent store and enforces read-only attributes.
:netctl_restore_persisted_cert
set "_RPC_DOM=%~1"
set "_RPC_STORE=%~2"
if "!_RPC_STORE!"=="" set "_RPC_STORE=%CERT_STORE_DIR%"
if "!_RPC_STORE!"=="" (
    set "_NC_DEF_MOUNT=%DATA_DISK_MOUNT%"
    if "!_NC_DEF_MOUNT!"=="" set "_NC_DEF_MOUNT=%DATA_MOUNT_DIR%"
    if "!_NC_DEF_MOUNT!"=="" set "_NC_DEF_MOUNT=/mnt/data"
    set "_RPC_STORE=!_NC_DEF_MOUNT!/certs"
)
set "_RPC_LIVE=!_RPC_STORE!\live\!_RPC_DOM!"
call :netctl_cert_is_valid_letsencrypt "!_RPC_DOM!" "!_RPC_LIVE!\fullchain.pem" "!_RPC_LIVE!\privkey.pem"
if errorlevel 1 exit /b 1
attrib +R "!_RPC_LIVE!\fullchain.pem" >nul 2>&1
attrib +R "!_RPC_LIVE!\privkey.pem" >nul 2>&1
echo [INFO] [REUSE] [TLS] Reusing valid non-expired Let's Encrypt certificate for '!_RPC_DOM!' from read-only store '!_RPC_LIVE!'. 1>&2
exit /b 0

:: ## netctl_persist_cert_readonly
:: Copies issued Let's Encrypt certificates into the persistent store and marks them read-only.
:netctl_persist_cert_readonly
set "_PCR_DOM=%~1"
set "_PCR_STORE=%~2"
if "!_PCR_STORE!"=="" set "_PCR_STORE=%CERT_STORE_DIR%"
if "!_PCR_STORE!"=="" (
    set "_NC_DEF_MOUNT=%DATA_DISK_MOUNT%"
    if "!_NC_DEF_MOUNT!"=="" set "_NC_DEF_MOUNT=%DATA_MOUNT_DIR%"
    if "!_NC_DEF_MOUNT!"=="" set "_NC_DEF_MOUNT=/mnt/data"
    set "_PCR_STORE=!_NC_DEF_MOUNT!/certs"
)
set "_PCR_SRC=%~3"
if "!_PCR_SRC!"=="" (
    set "_PCR_LE_ETC=%LETSENCRYPT_ETC_DIR%"
    if "!_PCR_LE_ETC!"=="" (
        set "_PCR_ETC=%LIBSCRIPT_ETC_DIR%"
        if "!_PCR_ETC!"=="" set "_PCR_ETC=/etc"
        set "_PCR_LE_ETC=!_PCR_ETC!/letsencrypt"
    )
    set "_PCR_SRC=!_PCR_LE_ETC!/live/!_PCR_DOM!"
)
set "_PCR_DST=!_PCR_STORE!\live\!_PCR_DOM!"
if not exist "!_PCR_DST!" mkdir "!_PCR_DST!"
for %%F in (fullchain.pem privkey.pem cert.pem chain.pem) do (
    if exist "!_PCR_SRC!\%%F" (
        attrib -R "!_PCR_DST!\%%F" >nul 2>&1
        copy /Y "!_PCR_SRC!\%%F" "!_PCR_DST!\%%F" >nul 2>&1
        attrib +R "!_PCR_DST!\%%F" >nul 2>&1
    )
)
echo [INFO] [PERSIST] [TLS] Stored read-only Let's Encrypt certificate for '!_PCR_DOM!' in '!_PCR_DST!'. 1>&2
exit /b 0

:: ## netctl_ensure_letsencrypt_cert
:: Ensures a valid, non-expired Let's Encrypt certificate exists for the domain on Windows.
:netctl_ensure_letsencrypt_cert
set "_ELC_DOM=%~1"
set "_ELC_STORE=%~2"
if "!_ELC_STORE!"=="" set "_ELC_STORE=%CERT_STORE_DIR%"
if "!_ELC_STORE!"=="" (
    set "_NC_DEF_MOUNT=%DATA_DISK_MOUNT%"
    if "!_NC_DEF_MOUNT!"=="" set "_NC_DEF_MOUNT=%DATA_MOUNT_DIR%"
    if "!_NC_DEF_MOUNT!"=="" set "_NC_DEF_MOUNT=/mnt/data"
    set "_ELC_STORE=!_NC_DEF_MOUNT!/certs"
)
set "_ELC_WEBROOT=%~3"
if "!_ELC_WEBROOT!"=="" set "_ELC_WEBROOT=!_ELC_STORE!/acme-webroot"
set "_ELC_EMAIL=%~4"
if "!_ELC_EMAIL!"=="" set "_ELC_EMAIL=%LETSENCRYPT_EMAIL%"
if "!_ELC_DOM!"=="" exit /b 0
if "!_ELC_DOM!"=="_" exit /b 0
call :netctl_restore_persisted_cert "!_ELC_DOM!" "!_ELC_STORE!"
if not errorlevel 1 exit /b 0
where certbot >nul 2>&1
if errorlevel 1 (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\security\certbot\setup.cmd"
)
if not exist "!_ELC_WEBROOT!\.well-known\acme-challenge" mkdir "!_ELC_WEBROOT!\.well-known\acme-challenge"
set "_ELC_EMAIL_ARG=--register-unsafely-without-email"
if not "!_ELC_EMAIL!"=="" set "_ELC_EMAIL_ARG=--email !_ELC_EMAIL!"
certbot certonly --webroot -w "!_ELC_WEBROOT!" -d "!_ELC_DOM!" --non-interactive --agree-tos !_ELC_EMAIL_ARG! --keep-until-expiring >nul 2>&1
call :netctl_persist_cert_readonly "!_ELC_DOM!" "!_ELC_STORE!"
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
for /f "delims=" %%R in ('jq -r --arg dom "!_LSR_DOM!" --arg lb "[" --arg rb "]" --arg arr " -> " ".routes // {} | to_entries[]? | ($lb + \"INFO\" + $rb + \" \" + $lb + \"ROUTE\" + $rb + \" \" + $lb + ((.value.type // \"static\") | ascii_upcase) + $rb + \" \" + $dom + .key + $arr + (.value.target // .value.pattern // \"\"))" "!NETCTL_STATE_FILE!" 2^>nul') do (
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
echo   --proxy-connect-timeout ^<val^>  Set upstream proxy connect timeout (e.g., 60s)
echo   --proxy-send-timeout ^<val^>     Set upstream proxy send timeout (e.g., 300s)
echo   --proxy-read-timeout ^<val^>     Set upstream proxy read timeout (e.g., 300s)
echo   --proxy-buffering ^<on^|off^>     Set upstream proxy response buffering (on^|off)
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
