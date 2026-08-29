@echo off
:: # deploy_remote.cmd
::
:: ## Overview
:: Backend orchestrator for the deploy-remote command on Windows.
:: 
:: ## Usage
:: Internally invoked via cli\commands\cloud\deploy-remote.cmd.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if "%~1"=="" (
    echo [ERROR] Usage: deploy_remote.cmd ^<user@host^> [--app ^<path^>@^<domain^>]... [--shared-db ^<engine^>]
    exit /b 1
)

set "TARGET_HOST=%~1"
shift

set "APPS_PATHS="
set "APPS_DOMAINS="
set "SHARED_DB="

:parse_args
if "%~1"=="" goto parse_done
if "%~1"=="--app" (
    if "%~2"=="" (
        echo [ERROR] --app requires an argument
        exit /b 1
    )
    for /f "tokens=1,2 delims=@" %%A in ("%~2") do (
        set "APPS_PATHS=!APPS_PATHS!%%A|"
        set "APPS_DOMAINS=!APPS_DOMAINS!%%B|"
    )
    shift
    shift
    goto parse_args
)
if "%~1"=="--shared-db" (
    if "%~2"=="" (
        echo [ERROR] --shared-db requires an argument
        exit /b 1
    )
    set "SHARED_DB=%~2"
    shift
    shift
    goto parse_args
)
echo [ERROR] Unknown argument: %~1
exit /b 1

:parse_done

call :provision_shared_db

:: Iterate over apps
set "REMAINING_PATHS=!APPS_PATHS!"
set "REMAINING_DOMAINS=!APPS_DOMAINS!"
set "HEALTH_APPS="

:loop_apps
if "!REMAINING_PATHS!"=="" goto done

for /f "tokens=1* delims=|" %%A in ("!REMAINING_PATHS!") do (
    set "APP_PATH=%%A"
    set "REMAINING_PATHS=%%B"
)
for /f "tokens=1* delims=|" %%C in ("!REMAINING_DOMAINS!") do (
    set "APP_DOMAIN=%%C"
    set "REMAINING_DOMAINS=%%D"
)

:: Get App Name
for %%F in ("!APP_PATH!") do set "APP_NAME=%%~nxF"

call :calculate_checksum "!APP_PATH!" LOCAL_SUM

:: Fetch remote sum via ssh
set "REMOTE_SUM="
for /f "delims=" %%R in ('ssh "!TARGET_HOST!" "cat $HOME/.libscript/deploy_state_!APP_NAME! 2>nul" 2^>nul') do (
    set "REMOTE_SUM=%%R"
)

if "!LOCAL_SUM!"=="!REMOTE_SUM!" (
    echo [INFO] [SKIPPED] !APP_NAME! -^> https://!APP_DOMAIN! is live and up-to-date.
) else (
    echo [INFO] [SYNCING] !APP_NAME! -^> https://!APP_DOMAIN! ^(local: !LOCAL_SUM!, remote: !REMOTE_SUM!^)
    ssh "!TARGET_HOST!" "mkdir -p $HOME/apps/!APP_NAME!"
    
    :: Basic scp fallback
    scp -r "!APP_PATH!\*" "!TARGET_HOST!:apps/!APP_NAME!/"
    
    ssh "!TARGET_HOST!" "mkdir -p $HOME/.libscript && echo !LOCAL_SUM! > $HOME/.libscript/deploy_state_!APP_NAME!"
    
    set "NEEDS_DB=0"
    if exist "!APP_PATH!\libscript.json" (
        if not "!SHARED_DB!"=="" (
            jq -e ".dependencies[\"!SHARED_DB!\"]" "!APP_PATH!\libscript.json" >nul 2>nul
            if not errorlevel 1 (
                set "NEEDS_DB=1"
            ) else (
                findstr /C:"\"!SHARED_DB!\"" "!APP_PATH!\libscript.json" >nul 2>nul
                if not errorlevel 1 set "NEEDS_DB=1"
            )
        )
    )
    
    call :setup_app_db "!APP_NAME!" "!NEEDS_DB!"
    call :execute_lifecycle_hooks "apps/!APP_NAME!" "!APP_NAME!"
    call :configure_routing "!APP_NAME!" "!APP_DOMAIN!" "apps/!APP_NAME!" "!APP_PATH!"
)

if exist "!APP_PATH!\libscript.json" (
    set "HEALTH_APPS=!HEALTH_APPS! !APP_NAME!"
)
goto loop_apps

:done
if not "!HEALTH_APPS!"=="" (
    echo [INFO] Running health checks for backend services:!HEALTH_APPS!...
    for %%a in (!HEALTH_APPS!) do (
        ssh "!TARGET_HOST!" "cd $HOME/apps/%%a && LIBSCRIPT_ROOT_DIR=$HOME/libscript $HOME/libscript/_lib/init-systems/daemonize.sh status libscript.json"
    )
)
echo [INFO] Deployment remote complete.
exit /b 0

:: ## provision_shared_db
:: Executes provision_shared_db functionality.
:provision_shared_db
if not "!SHARED_DB!"=="" (
    echo [INFO] Provisioning shared DB ^(!SHARED_DB!^) on !TARGET_HOST! ^(if missing^)...
    if "!SHARED_DB!"=="postgres" (
        ssh "!TARGET_HOST!" "command -v psql >/dev/null 2>&1 || $HOME/libscript/libscript.sh install !SHARED_DB! latest; pg_isready >/dev/null 2>&1 || $HOME/libscript/libscript.sh start !SHARED_DB!"
    ) else (
        ssh "!TARGET_HOST!" "$HOME/libscript/libscript.sh install !SHARED_DB! latest && $HOME/libscript/libscript.sh start !SHARED_DB!"
    )
)
exit /b 0

:: ## calculate_checksum
:: Executes calculate_checksum functionality.
:calculate_checksum
set "tgt_dir=%~1"
if exist "!tgt_dir!\.git" (
    for /f %%H in ('git -C "!tgt_dir!" rev-parse HEAD 2^>nul') do set "%~2=%%H"
) else (
    set "%~2=!RANDOM!-!RANDOM!"
)
exit /b 0

:: ## setup_app_db
:: Executes setup_app_db functionality.
:setup_app_db
set "aname=%~1"
set "needs_db=%~2"
if "!needs_db!"=="1" (
    if "!SHARED_DB!"=="postgres" (
        set "safe_db_name=!aname:-=_!"
        echo [INFO] Ensuring DB !safe_db_name! exists on !TARGET_HOST!...
        :: Note: ssh execution happens on the REMOTE host. We use grep since remote is likely Linux. 
        :: If remote is Windows, this would need an OS abstraction layer, but sticking to PaaS Linux standard for now.
        ssh "!TARGET_HOST!" "psql -lqt | cut -d \| -f 1 | grep -qw !safe_db_name! || createdb !safe_db_name!"
        ssh "!TARGET_HOST!" "touch $HOME/apps/!aname!/.env && grep -qxF 'DATABASE_URL=postgres://localhost:5432/!safe_db_name!' $HOME/apps/!aname!/.env || echo DATABASE_URL=postgres://localhost:5432/!safe_db_name! >> $HOME/apps/!aname!/.env"
    )
)
exit /b 0

:: ## execute_lifecycle_hooks
:: Executes execute_lifecycle_hooks functionality.
:execute_lifecycle_hooks
set "rdir=%~1"
set "aname=%~2"
echo [INFO] Executing lifecycle hooks for !aname!...
ssh "!TARGET_HOST!" "cd \"!rdir!\" && if [ -f libscript.json ]; then $HOME/libscript/libscript.sh install-deps; fi"
ssh "!TARGET_HOST!" "cd \"!rdir!\" && if [ -f libscript.json ]; then LIBSCRIPT_ROOT_DIR=$HOME/libscript $HOME/libscript/_lib/orchestration/run_hooks.sh libscript.json install; fi"
ssh "!TARGET_HOST!" "cd \"!rdir!\" && if [ -f libscript.json ]; then LIBSCRIPT_ROOT_DIR=$HOME/libscript $HOME/libscript/_lib/init-systems/daemonize.sh stop libscript.json && LIBSCRIPT_ROOT_DIR=$HOME/libscript $HOME/libscript/_lib/init-systems/daemonize.sh start libscript.json; fi"
exit /b 0

:: ## configure_routing
:: Executes configure_routing functionality.
:configure_routing
set "aname=%~1"
set "adomain=%~2"
set "rdir=%~3"
set "apath=%~4"
echo [INFO] Configuring routing for !aname! -^> !adomain!...

set "is_static=0"
if not exist "!apath!\libscript.json" (
    if exist "!apath!\index.html" (
        set "is_static=1"
    ) else (
        echo [INFO] Warning: No libscript.json or index.html found in !apath!. Assuming static routing.
        set "is_static=1"
    )
)

if "!is_static!"=="1" (
    ssh "!TARGET_HOST!" "$HOME/libscript/netctl/netctl.sh route add \"!aname!\" \"!adomain!\" --static \"$HOME/!rdir!\""
) else (
    set "remote_port=3000"
    for /f "delims=" %%P in ('jq -r ".port // empty" "!apath!\libscript.json" 2^>nul') do (
        if not "%%P"=="" if not "%%P"=="null" set "remote_port=%%P"
    )
    ssh "!TARGET_HOST!" "$HOME/libscript/netctl/netctl.sh route add \"!aname!\" \"!adomain!\" --port \"!remote_port!\""
)
exit /b 0
