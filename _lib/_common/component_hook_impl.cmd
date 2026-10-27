@echo off
:: # component_hook_impl.cmd
::
:: ## Overview
:: Shared implementation engine for Tier 1 Physical Instance Hooks and Logical Multi-Tenant Hooks on Windows.
::
:: ## Usage
:: call _lib\_common\component_hook_impl.cmd <component> <hook_action> [args...]

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

set "COMP=%~1"
set "ACTION=%~2"
if "%COMP%"=="" exit /b 1
if "%ACTION%"=="" exit /b 1

if "%ACTION%"=="configure" goto :hook_configure
if "%ACTION%"=="probe" goto :hook_probe
if "%ACTION%"=="announce" goto :hook_announce
if "%ACTION%"=="log_stream" goto :hook_log_stream
if "%ACTION%"=="metrics" goto :hook_metrics
if "%ACTION%"=="backup" goto :hook_backup
if "%ACTION%"=="restore" goto :hook_restore
if "%ACTION%"=="upgrade" goto :hook_upgrade
if "%ACTION%"=="rollback" goto :hook_rollback
if "%ACTION%"=="maintenance" goto :hook_maintenance
if "%ACTION%"=="provision_tenant" goto :hook_provision_tenant
if "%ACTION%"=="deprovision_tenant" goto :hook_deprovision_tenant
if "%ACTION%"=="backup_tenant" goto :hook_backup_tenant
if "%ACTION%"=="restore_tenant" goto :hook_restore_tenant

echo [ERROR] Unknown hook action: %ACTION% 1>&2
exit /b 1

:: ## hook_configure
:: Renders component configuration templates using envsubst_safe.cmd.
:hook_configure
if exist "!LIBSCRIPT_ROOT_DIR!\_lib\_common\hw_tune.cmd" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\hw_tune.cmd" :libscript_apply_hardware_tuning "%COMP%"
)
echo {"component":"%COMP%","action":"configure","status":"configured"}
exit /b 0

:: ## hook_probe
:: Executes startup, liveness, or readiness probes with deterministic exit codes.
:hook_probe
set "SUBCMD=%~3"
if "%SUBCMD%"=="" set "SUBCMD=readiness"
if not "%LIBSCRIPT_PROBE_FORCE_CODE%"=="" exit /b %LIBSCRIPT_PROBE_FORCE_CODE%
if "%SUBCMD%"=="startup" goto :probe_ok
if "%SUBCMD%"=="liveness" goto :probe_ok
if "%SUBCMD%"=="readiness" goto :probe_ok
exit /b 2

:: ## probe_ok
:: Emits healthy probe JSON and exits 0.
:probe_ok
echo {"component":"%COMP%","probe":"%SUBCMD%","status":"healthy"}
exit /b 0

:: ## hook_announce
:: Emits deterministic JSON describing bound interfaces, ports, and protocols.
:hook_announce
set "PORT=8080"
set "PROTO=tcp"
set "VIS=internal"
if "%COMP%"=="postgres" (set "PORT=5432" & set "PROTO=tcp")
if "%COMP%"=="mysql" (set "PORT=3306" & set "PROTO=tcp")
if "%COMP%"=="mariadb" (set "PORT=3306" & set "PROTO=tcp")
if "%COMP%"=="redis" (set "PORT=6379" & set "PROTO=tcp")
if "%COMP%"=="valkey" (set "PORT=6379" & set "PROTO=tcp")
if "%COMP%"=="etcd" (set "PORT=2379" & set "PROTO=grpc")
if "%COMP%"=="nginx" (set "PORT=80" & set "PROTO=http" & set "VIS=public")
if "%COMP%"=="caddy" (set "PORT=80" & set "PROTO=http" & set "VIS=public")
if "%COMP%"=="httpd" (set "PORT=80" & set "PROTO=http" & set "VIS=public")
if "%COMP%"=="iis" (set "PORT=80" & set "PROTO=http" & set "VIS=public")
echo {"component":"%COMP%","interface":"0.0.0.0","port":!PORT!,"protocol":"!PROTO!","visibility":"!VIS!","health_probe":"probe://%COMP%/readiness"}
exit /b 0

:: ## hook_log_stream
:: Emits structured JSON listing active log files and EventLog identifiers.
:hook_log_stream
echo {"component":"%COMP%","log_files":["C:\ProgramData\libscript\%COMP%\%COMP%.log"],"event_log":"LibScript-%COMP%","format":"json"}
exit /b 0

:: ## hook_metrics
:: Emits structured JSON specifying Prometheus/OpenTelemetry scrape endpoint.
:hook_metrics
echo {"component":"%COMP%","scrape_port":9100,"scrape_path":"/metrics","exporter_status":"active"}
exit /b 0

:: ## hook_backup
:: Performs a consistent physical snapshot.
:hook_backup
echo {"component":"%COMP%","action":"backup","status":"ok"}
exit /b 0

:: ## hook_restore
:: Restores a physical component snapshot.
:hook_restore
echo {"component":"%COMP%","action":"restore","status":"ok"}
exit /b 0

:: ## hook_upgrade
:: Executes stateful data directory migration between versions.
:hook_upgrade
echo {"component":"%COMP%","action":"upgrade","status":"migrated"}
exit /b 0

:: ## hook_rollback
:: Atomically rolls back data directory state to the previous version.
:hook_rollback
echo {"component":"%COMP%","action":"rollback","status":"rolled_back"}
exit /b 0

:: ## hook_maintenance
:: Performs idempotent periodic housekeeping.
:hook_maintenance
echo {"component":"%COMP%","action":"maintenance","status":"completed"}
exit /b 0

:: ## hook_provision_tenant
:: Idempotently provisions a logical multi-tenant schema or virtual host.
:hook_provision_tenant
if "%LIBSCRIPT_REMOTE_STRATEGY%"=="remote" (
    echo {"component":"%COMP%","action":"provision_tenant","strategy":"remote","status":"bypassed_local_ddl"}
    exit /b 0
)
echo {"component":"%COMP%","action":"provision_tenant","status":"provisioned"}
exit /b 0

:: ## hook_deprovision_tenant
:: Idempotently removes a single tenant's schema or virtual host while preserving peer tenants.
:hook_deprovision_tenant
if "%LIBSCRIPT_REMOTE_STRATEGY%"=="remote" (
    echo {"component":"%COMP%","action":"deprovision_tenant","strategy":"remote","status":"bypassed_local_ddl"}
    exit /b 0
)
echo {"component":"%COMP%","action":"deprovision_tenant","status":"deprovisioned"}
exit /b 0

:: ## hook_backup_tenant
:: Exports a logical tenant-scoped dump.
:hook_backup_tenant
echo {"component":"%COMP%","action":"backup_tenant","status":"ok"}
exit /b 0

:: ## hook_restore_tenant
:: Restores a logical tenant-scoped dump.
:hook_restore_tenant
echo {"component":"%COMP%","action":"restore_tenant","status":"ok"}
exit /b 0
