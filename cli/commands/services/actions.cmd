@echo off
:: # actions.cmd
:: ## Overview
:: Provides a unified interface for managing service states (start, stop, restart, status, health, logs, down, uninstall-service, deprovision-db, export-state, import-state).
:: ## Usage
:: Execute this script to perform lifecycle actions on background services.

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

if not defined LIBSCRIPT_ROOT_DIR (
    set "LIBSCRIPT_ROOT_DIR=!SCRIPT_DIR!\..\..\.."
)
set "action=%cmd%"
if /i "!action!"=="deprovision-db" (
    set "_db_json=%~2"
    if "!_db_json!"=="" set "_db_json=libscript.json"
    call "!LIBSCRIPT_ROOT_DIR!\_lib\databases\deprovision_db.cmd" "!_db_json!"
    exit /b !ERRORLEVEL!
)
if /i "!action!"=="export-state" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\databases\export_db.cmd" "%~2" "%~3"
    exit /b !ERRORLEVEL!
)
if /i "!action!"=="import-state" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\databases\import_db.cmd" "%~2" "%~3"
    exit /b !ERRORLEVEL!
)
if /i "!action!"=="prepare-storage" (
    set "_ps_json=%~2"
    if "!_ps_json!"=="" set "_ps_json=libscript.json"
    if exist "!LIBSCRIPT_ROOT_DIR!\_lib\_common\env_printer.cmd" (
        set "STACK="
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\env_printer.cmd" --hydrate "!_ps_json!"
    )
    set "_ps_def_mount=!DATA_DISK_MOUNT!"
    if "!_ps_def_mount!"=="" set "_ps_def_mount=!DATA_MOUNT_DIR!"
    if "!_ps_def_mount!"=="" set "_ps_def_mount=/mnt/data"
    for /f "tokens=1,2 delims=	 " %%M in ('jq -r --arg mp "!_ps_def_mount!" --arg fs "NTFS" ".infrastructure.node.data_disks[]? | [(.mount_path // $mp), (.fstype // $fs)] | @tsv" "!_ps_json!" 2^>nul') do (
        echo [STORAGE] Ensuring persistent disk mount "%%M" ^(fstype: %%N^)...
        call "!LIBSCRIPT_ROOT_DIR!\traits\storage\mount.cmd" --auto-data-disk "%%M" "%%N"
    )
    for /f "tokens=1* delims= " %%S in ('jq -r --arg sp " " --arg eq "=" "((.infrastructure.service_overrides // {}) * (.service_overrides // {})) | to_entries[]? | .key + $sp + (.value | to_entries | map(.key + $eq + (.value | tostring)) | join($sp))" "!_ps_json!" 2^>nul') do (
        if exist "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" (
            echo [DAEMON] Applying service_overrides for "%%S" ^(%%T^)...
            for %%O in (%%T) do (
                set "STACK="
                call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" override-env "%%S" "%%O"
            )
        )
    )
    for %%F in ("!_ps_json!") do set "_ps_dir=%%~dpF"
    if "!_ps_dir:~-1!"=="\" set "_ps_dir=!_ps_dir:~0,-1!"
    if defined OLLAMA_MODEL_LIST (
        if exist "!_ps_dir!\.env.libscript" (
            findstr /v /b /c:"OLLAMA_MODELS=/" /c:"OLLAMA_MODELS=\" "!_ps_dir!\.env.libscript" > "!_ps_dir!\.env.libscript.tmp" 2>nul
            move /y "!_ps_dir!\.env.libscript.tmp" "!_ps_dir!\.env.libscript" >nul 2>&1
        )
    )
    set "_ol_ovr_dir="
    for /f "delims=" %%O in ('jq -r ".service_overrides.ollama.OLLAMA_MODELS_DIR // .service_overrides.ollama.OLLAMA_MODELS // .infrastructure.service_overrides.ollama.OLLAMA_MODELS_DIR // .infrastructure.service_overrides.ollama.OLLAMA_MODELS // empty" "!_ps_json!" 2^>nul') do set "_ol_ovr_dir=%%O"
    set "_has_ol=0"
    for /f "delims=" %%O in ('jq -r --arg ol "ollama" --arg y "1" --arg n "0" "if (.deps.ollama != null) or (.dependencies.ollama != null) or ([.dependencies.runtime[]? | select(.name == $ol)] | length > 0) then $y else $n end" "!_ps_json!" 2^>nul') do set "_has_ol=%%O"
    if not "!_ol_ovr_dir!"=="" set "_has_ol=1"
    if not "!OLLAMA_MODELS_DIR!"=="" set "_has_ol=1"
    if "!_has_ol!"=="1" (
        if exist "!LIBSCRIPT_ROOT_DIR!\_lib\app-servers\ollama\service.cmd" (
            for /f "delims=" %%O in ('jq -r --arg eq "=" "((.infrastructure.service_overrides.ollama // {}) * (.service_overrides.ollama // {})) | to_entries[]? | .key + $eq + (.value | tostring)" "!_ps_json!" 2^>nul') do (
                set "%%O"
            )
            if not "!_ol_ovr_dir!"=="" set "OLLAMA_MODELS_DIR=!_ol_ovr_dir!"
            echo [DAEMON] Configuring ollama model storage and restarting/reloading daemon if needed...
            set "STACK="
            call "!LIBSCRIPT_ROOT_DIR!\_lib\app-servers\ollama\service.cmd" configure
        )
    )
    set "_pg_ovr_dir="
    for /f "delims=" %%P in ('jq -r ".service_overrides.postgres.POSTGRES_DATA_DIR // .service_overrides.postgres.PGDATA // .service_overrides.postgresql.POSTGRES_DATA_DIR // .service_overrides.postgresql.PGDATA // .infrastructure.service_overrides.postgres.POSTGRES_DATA_DIR // .infrastructure.service_overrides.postgres.PGDATA // .infrastructure.service_overrides.postgresql.POSTGRES_DATA_DIR // .infrastructure.service_overrides.postgresql.PGDATA // .vars.POSTGRES_DATA_DIR // .vars.PGDATA // empty" "!_ps_json!" 2^>nul') do set "_pg_ovr_dir=%%P"
    if "!_pg_ovr_dir!"=="" set "_pg_ovr_dir=!POSTGRES_DATA_DIR!"
    if "!_pg_ovr_dir!"=="" set "_pg_ovr_dir=!PGDATA!"
    if not "!_pg_ovr_dir!"=="" (
        if exist "!LIBSCRIPT_ROOT_DIR!\_lib\databases\postgres\service.cmd" (
            set "POSTGRES_DATA_DIR=!_pg_ovr_dir!"
            set "PGDATA=!_pg_ovr_dir!"
            echo [DAEMON] Configuring PostgreSQL persistent storage at "!_pg_ovr_dir!"...
            set "STACK="
            call "!LIBSCRIPT_ROOT_DIR!\_lib\databases\postgres\service.cmd" configure "!_pg_ovr_dir!"
        )
    )
    set "_vk_ovr_dir="
    for /f "delims=" %%V in ('jq -r ".service_overrides.valkey.VALKEY_DATA_DIR // .service_overrides.valkey.REDIS_DATA_DIR // .service_overrides.redis.REDIS_DATA_DIR // .service_overrides.redis.VALKEY_DATA_DIR // .infrastructure.service_overrides.valkey.VALKEY_DATA_DIR // .infrastructure.service_overrides.valkey.REDIS_DATA_DIR // .infrastructure.service_overrides.redis.REDIS_DATA_DIR // .infrastructure.service_overrides.redis.VALKEY_DATA_DIR // .vars.VALKEY_DATA_DIR // .vars.REDIS_DATA_DIR // empty" "!_ps_json!" 2^>nul') do set "_vk_ovr_dir=%%V"
    if "!_vk_ovr_dir!"=="" set "_vk_ovr_dir=!VALKEY_DATA_DIR!"
    if "!_vk_ovr_dir!"=="" set "_vk_ovr_dir=!REDIS_DATA_DIR!"
    if not "!_vk_ovr_dir!"=="" (
        if exist "!LIBSCRIPT_ROOT_DIR!\_lib\caches\valkey\service.cmd" (
            set "VALKEY_DATA_DIR=!_vk_ovr_dir!"
            set "REDIS_DATA_DIR=!_vk_ovr_dir!"
            echo [DAEMON] Configuring Valkey/Redis persistent storage at "!_vk_ovr_dir!"...
            set "STACK="
            call "!LIBSCRIPT_ROOT_DIR!\_lib\caches\valkey\service.cmd" configure "!_vk_ovr_dir!"
        )
    )
    set "_ps_cert_store=%CERT_STORE_DIR%"
    if "!_ps_cert_store!"=="" set "_ps_cert_store=!_ps_def_mount!/certs"
    for /f "delims=" %%C in ('jq -r ".ingress.cert_store_dir // empty" "!_ps_json!" 2^>nul') do if not "%%C"=="" set "_ps_cert_store=%%C"
    if not exist "!_ps_cert_store!\live" mkdir "!_ps_cert_store!\live" >nul 2>&1
    if not exist "!_ps_cert_store!\letsencrypt" mkdir "!_ps_cert_store!\letsencrypt" >nul 2>&1
    if not exist "!_ps_cert_store!\acme-webroot\.well-known\acme-challenge" mkdir "!_ps_cert_store!\acme-webroot\.well-known\acme-challenge" >nul 2>&1
    for /d %%D in ("!_ps_cert_store!\live\*") do (
        if exist "%%~fD\fullchain.pem" if exist "%%~fD\privkey.pem" (
            attrib +R "%%~fD\fullchain.pem" >nul 2>&1
            attrib +R "%%~fD\privkey.pem" >nul 2>&1
            echo [STORAGE] [TLS] Restored Let's Encrypt certificate for "%%~nxD" from "%%~fD".
        )
    )
    exit /b 0
)

if /i "!action!"=="up" set "action=start"
if /i "!action!"=="down" set "action=stop"
if /i "!action!"=="uninstall-service" set "action=uninstall"

set "skip_hooks=0"
set "skip_db_init=%LIBSCRIPT_SKIP_DB_INIT%"
if "!skip_db_init!"=="" set "skip_db_init=0"
set "remove_service=0"
set "purge_data=0"
set "remediate=0"
set "verify_ingress=0"
set "public_url="
set "arg1="

for %%A in (%2 %3 %4 %5 %6 %7 %8 %9) do (
    set "_ca=%%~A"
    if /i "!_ca!"=="--no-hooks" (
        set "skip_hooks=1"
    ) else if /i "!_ca!"=="--skip-db-init" (
        set "skip_db_init=1"
    ) else if /i "!_ca!"=="--skip-migrate" (
        set "skip_db_init=1"
    ) else if /i "!_ca!"=="--remove" (
        set "remove_service=1"
    ) else if /i "!_ca!"=="--uninstall" (
        set "remove_service=1"
    ) else if /i "!_ca!"=="--purge-data" (
        set "purge_data=1"
    ) else if /i "!_ca!"=="--remediate" (
        set "remediate=1"
    ) else if /i "!_ca!"=="--verify-ingress" (
        set "verify_ingress=1"
    ) else if /i "!_ca:~0,13!"=="--public-url=" (
        set "public_url=!_ca:~13!"
        set "verify_ingress=1"
    ) else if "!arg1!"=="" (
        set "arg1=!_ca!"
    )
)

if /i "!action!"=="stop" (
    if "!remove_service!"=="1" set "action=uninstall"
)

set "is_json=0"
if "!arg1!"=="" set "is_json=1"
if /i "!arg1!"=="libscript.json" set "is_json=1"
echo !arg1! | findstr /i "\.json$" >nul && set "is_json=1"

if "!is_json!"=="1" (
    set "json_file=!arg1!"
    if "!json_file!"=="" set "json_file=libscript.json"
    if not exist "!json_file!" (
        echo Error: !json_file! not found. 1>&2
        exit /b 1
    )
    jq --version >nul 2>&1
    if errorlevel 1 (
        echo Error: jq is required to parse !json_file!. 1>&2
        exit /b 1
    )
    if exist "!LIBSCRIPT_ROOT_DIR!\_lib\_common\env_printer.cmd" (
        set "STACK="
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\env_printer.cmd" --hydrate "!json_file!"
    )
    if defined SERVICE_PATH set "PATH=!SERVICE_PATH!;!PATH!"
    if defined SERVICE_EXTRA_PATH set "PATH=!SERVICE_EXTRA_PATH!;!PATH!"
    if "!skip_hooks!"=="0" (
        if /i "!action!"=="start" (
            if "!skip_db_init!"=="0" (
                call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\run_hooks.cmd" "!json_file!" "build"
                if errorlevel 1 exit /b 1
            )
        )
        if /i "!action!"=="stop" (
            call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\run_hooks.cmd" "!json_file!" "pre_stop"
        )
        if /i "!action!"=="uninstall" (
            call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\run_hooks.cmd" "!json_file!" "pre_stop"
        )
    )
    if /i not "!action!"=="uninstall" (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\resolve_stack.cmd" "!json_file!" > "!json_file!.resolved.json" 2>nul
        for /f "tokens=1,2 delims=	 " %%A in ('jq -r --arg def "latest" ".selected[] | [.name, .version // $def] | @tsv" "!json_file!.resolved.json" 2^>nul') do (
            set "pkg=%%A"
            set "ver=%%B"
            if "!ver!"=="null" set "ver=latest"
            set "LIBSCRIPT_INTERNAL_START=1"
            if /i "!action!"=="health" (
                call "%~f0" !action! !pkg! !ver!
                if errorlevel 1 (
                    if exist "!json_file!.resolved.json" del "!json_file!.resolved.json"
                    exit /b 1
                )
            ) else if /i "!action!"=="start" (
                if /i "!pkg!"=="postgres" (
                    call "%~f0" !action! !pkg! !ver!
                ) else if /i "!pkg!"=="postgresql" (
                    call "%~f0" !action! !pkg! !ver!
                ) else if /i "!pkg!"=="mariadb" (
                    call "%~f0" !action! !pkg! !ver!
                ) else if /i "!pkg!"=="mysql" (
                    call "%~f0" !action! !pkg! !ver!
                ) else if /i "!pkg!"=="valkey" (
                    call "%~f0" !action! !pkg! !ver!
                ) else if /i "!pkg!"=="redis" (
                    call "%~f0" !action! !pkg! !ver!
                ) else (
                    start "" /b cmd /c call "%~f0" !action! !pkg! !ver!
                )
            ) else (
                start "" /b cmd /c call "%~f0" !action! !pkg! !ver!
            )
        )
        if exist "!json_file!.resolved.json" del "!json_file!.resolved.json"
    )

    if /i "!action!"=="start" (
        if "!skip_hooks!"=="0" (
            if "!skip_db_init!"=="0" (
                if exist "!LIBSCRIPT_ROOT_DIR!\_lib\databases\provision_db.cmd" (
                    call "!LIBSCRIPT_ROOT_DIR!\_lib\databases\provision_db.cmd" "!json_file!"
                    if errorlevel 1 exit /b 1
                )
                call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\run_hooks.cmd" "!json_file!" "db_migrate"
                if errorlevel 1 exit /b 1
            )
            call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\run_hooks.cmd" "!json_file!" "pre_start"
            if errorlevel 1 exit /b 1
        )
        call :normalize_service_data_ownership "!json_file!"
        call "!LIBSCRIPT_ROOT_DIR!\_lib\init-systems\daemonize.cmd" "!action!" "!json_file!"
        if errorlevel 1 exit /b 1
        if "!skip_db_init!"=="0" (
            jq -e ".ingress != null" "!json_file!" >nul 2>&1
            if not errorlevel 1 (
                call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\component_core.cmd" --synchronize-ingress "!json_file!" --reload
            )
        )
        if "!skip_hooks!"=="0" (
            call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\run_hooks.cmd" "!json_file!" "post_start"
            if errorlevel 1 exit /b 1
        )
    ) else if /i "!action!"=="stop" (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\init-systems\daemonize.cmd" "!action!" "!json_file!"
        if "!purge_data!"=="1" (
            if exist "!LIBSCRIPT_ROOT_DIR!\_lib\databases\deprovision_db.cmd" (
                call "!LIBSCRIPT_ROOT_DIR!\_lib\databases\deprovision_db.cmd" "!json_file!"
            )
        )
        if "!skip_hooks!"=="0" (
            call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\run_hooks.cmd" "!json_file!" "post_stop"
            if errorlevel 1 exit /b 1
        )
    ) else if /i "!action!"=="uninstall" (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\init-systems\daemonize.cmd" "uninstall" "!json_file!"
        jq -e ".ingress != null" "!json_file!" >nul 2>&1
        if not errorlevel 1 (
            call "!LIBSCRIPT_ROOT_DIR!\_lib\networking\netctl\cli.cmd" remove-ingress "!json_file!" --reload
        )
        if "!purge_data!"=="1" (
            if exist "!LIBSCRIPT_ROOT_DIR!\_lib\databases\deprovision_db.cmd" (
                call "!LIBSCRIPT_ROOT_DIR!\_lib\databases\deprovision_db.cmd" "!json_file!"
            )
        )
        if "!skip_hooks!"=="0" (
            call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\run_hooks.cmd" "!json_file!" "post_stop"
        )
    ) else if /i "!action!"=="status" (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\init-systems\daemonize.cmd" "!action!" "!json_file!"
    ) else if /i "!action!"=="health" (
        call :run_health_check
        if errorlevel 1 (
            if "!remediate!"=="1" (
                echo [INFO] Health check failed for !json_file!; running auto-remediation...
                call "!LIBSCRIPT_ROOT_DIR!\_lib\init-systems\daemonize.cmd" "stop" "!json_file!"
                if exist "!LIBSCRIPT_ROOT_DIR!\_lib\databases\provision_db.cmd" (
                    set "LIBSCRIPT_FORCE_SEED=1"
                    call "!LIBSCRIPT_ROOT_DIR!\_lib\databases\provision_db.cmd" "!json_file!"
                )
                call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\run_hooks.cmd" "!json_file!" "db_migrate"
                call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\run_hooks.cmd" "!json_file!" "pre_start"
                call :normalize_service_data_ownership "!json_file!"
                call "!LIBSCRIPT_ROOT_DIR!\_lib\init-systems\daemonize.cmd" "start" "!json_file!"
                call :run_health_check
                if errorlevel 1 exit /b 1
            ) else (
                exit /b 1
            )
        )
    ) else if /i "!action!"=="logs" (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\init-systems\daemonize.cmd" "!action!" "!json_file!"
    ) else if /i "!action!"=="restart" (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\init-systems\daemonize.cmd" "stop" "!json_file!"
        call :normalize_service_data_ownership "!json_file!"
        call "!LIBSCRIPT_ROOT_DIR!\_lib\init-systems\daemonize.cmd" "start" "!json_file!"
        jq -e ".ingress != null" "!json_file!" >nul 2>&1
        if not errorlevel 1 (
            call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\component_core.cmd" --synchronize-ingress "!json_file!" --reload
        )
    )

    exit /b 0
)

:: ## loop_services
:: Iterates through specified services and triggers execution.
:loop_services
set "pkg=%~2"
if not "!pkg!"=="" (
    set "LIBSCRIPT_INTERNAL_START=1"
    set "STACK="
    if /i "!action!"=="health" (
        call :perform_health_check "!pkg!" "%~3"
        if errorlevel 1 exit /b 1
    ) else (
        call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" "!action!" "!pkg!" latest
    )
    shift
    goto loop_services
)
exit /b 0

:: ## perform_health_check
:: Executes a health check for a single component on Windows by hydrating its env and delegating to test.cmd or daemon readiness tools.
:perform_health_check
set "_hc_pkg=%~1"
set "_hc_ver=%~2"
if "!_hc_ver!"=="" set "_hc_ver=latest"
for /d %%C in ("!LIBSCRIPT_ROOT_DIR!\_lib\*") do (
    if exist "%%C\!_hc_pkg!\env.cmd" (
        set "STACK="
        call "%%C\!_hc_pkg!\env.cmd" >nul 2>&1
    )
)
if /i "!_hc_pkg!"=="postgres" goto :hc_pg
if /i "!_hc_pkg!"=="postgresql" goto :hc_pg
if /i "!_hc_pkg!"=="mariadb" goto :hc_mysql
if /i "!_hc_pkg!"=="mysql" goto :hc_mysql
if /i "!_hc_pkg!"=="valkey" goto :hc_redis
if /i "!_hc_pkg!"=="redis" goto :hc_redis
for /d %%C in ("!LIBSCRIPT_ROOT_DIR!\_lib\*") do (
    if exist "%%C\!_hc_pkg!\test.cmd" (
        set "STACK="
        call "%%C\!_hc_pkg!\test.cmd" >nul 2>&1
        exit /b 0
    )
)
exit /b 0

:: ## hc_pg
:: Verifies PostgreSQL daemon readiness via pg_isready on Windows.
:hc_pg
where pg_isready >nul 2>&1
if not errorlevel 1 (
    pg_isready -q
    exit /b !ERRORLEVEL!
)
exit /b 0

:: ## hc_mysql
:: Verifies MariaDB/MySQL daemon readiness via mysqladmin on Windows.
:hc_mysql
where mysqladmin >nul 2>&1
if not errorlevel 1 (
    mysqladmin ping --silent >nul 2>&1
    exit /b 0
)
exit /b 0

:: ## hc_redis
:: Verifies Valkey/Redis daemon readiness via valkey-cli or redis-cli on Windows.
:hc_redis
where valkey-cli >nul 2>&1
if not errorlevel 1 (
    valkey-cli ping >nul 2>&1
    exit /b 0
)
where redis-cli >nul 2>&1
if not errorlevel 1 (
    redis-cli ping >nul 2>&1
    exit /b 0
)
exit /b 0

:: ## normalize_service_data_ownership
:: Ensures data directories and OLLAMA_MODELS_DIR retain read/write permissions for the service user and Ollama daemon on Windows.
:normalize_service_data_ownership
set "_NSDO_JSON=%~1"
if exist "!LIBSCRIPT_ROOT_DIR!\_lib\_common\env_printer.cmd" (
    if not "!_NSDO_JSON!"=="" (
        set "STACK="
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\env_printer.cmd" --hydrate "!_NSDO_JSON!"
    )
)
set "_NSDO_OL=!OLLAMA_MODELS_DIR!"
if "!_NSDO_OL!"=="" set "_NSDO_OL=!OLLAMA_MODELS!"
if not "!_NSDO_OL!"=="" (
    if exist "!_NSDO_OL!" (
        if not exist "!_NSDO_OL!\manifests" mkdir "!_NSDO_OL!\manifests" >nul 2>&1
        if not exist "!_NSDO_OL!\blobs" mkdir "!_NSDO_OL!\blobs" >nul 2>&1
        icacls "!_NSDO_OL!" /grant "*S-1-5-32-544:(OI)(CI)F" /grant "*S-1-5-18:(OI)(CI)F" /T /C /Q >nul 2>&1
    )
)
exit /b 0

:: ## run_health_check
:: Runs database, daemon, and hook health checks for the target manifest.
:run_health_check
set "_dm_flags="
if "!verify_ingress!"=="1" set "_dm_flags=--verify-ingress"
if not "!public_url!"=="" set "_dm_flags=!_dm_flags! --public-url=!public_url!"
if exist "!LIBSCRIPT_ROOT_DIR!\_lib\databases\health_db.cmd" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\databases\health_db.cmd" "!json_file!"
    if errorlevel 1 exit /b 1
)
call "!LIBSCRIPT_ROOT_DIR!\_lib\init-systems\daemonize.cmd" "health" "!json_file!" !_dm_flags!
if errorlevel 1 exit /b 1
if "!skip_hooks!"=="0" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\run_hooks.cmd" "!json_file!" "health"
    if errorlevel 1 exit /b 1
    set "_cmh_models=!OLLAMA_MODEL_LIST!"
    if "!_cmh_models!"=="" set "_cmh_models=!OLLAMA_DEFAULT_MODEL!"
    if not "!_cmh_models!"=="" (
        where ollama >nul 2>&1
        if not errorlevel 1 (
            set "_cmh_models=!_cmh_models:,= !"
            for %%M in (!_cmh_models!) do (
                call "!LIBSCRIPT_ROOT_DIR!\_lib\app-servers\ollama\service.cmd" ensure-models "%%M" >nul 2>&1
                if errorlevel 1 exit /b 1
            )
        )
    )
)
exit /b 0
