@echo off
REM ## Overview
REM Runs CI tests for a given LibScript component on Windows.
REM It skips excluded components and handles setup and testing via batch scripts
REM and PowerShell scripts.
REM 
REM ## Usage
REM run_test_component.cmd <component_path> <os_name>

setlocal enabledelayedexpansion

set COMPONENT=%~1
set OS_NAME=%~2

echo ========================================
echo Testing !COMPONENT!
echo ========================================

set EXCLUDED=0
if "!COMPONENT!"=="_lib/package-managers/swupd" ( set EXCLUDED=1 )
if "!COMPONENT!"=="_lib/package-managers/mas" ( set EXCLUDED=1 )
if "!COMPONENT!"=="_lib/package-managers/conda" ( set EXCLUDED=1 )
if "!COMPONENT!"=="_lib/package-managers/guix" ( set EXCLUDED=1 )
if "!COMPONENT!"=="_lib/package-managers/asdf" ( set EXCLUDED=1 )
if "!COMPONENT!"=="_lib/package-managers/pkg" ( set EXCLUDED=1 )
if "!COMPONENT!"=="_lib/package-managers/xbps" ( set EXCLUDED=1 )
if "!COMPONENT!"=="_lib/package-managers/emerge" ( set EXCLUDED=1 )
if "!COMPONENT!"=="_lib/package-managers/apt" ( set EXCLUDED=1 )
if "!COMPONENT!"=="_lib/package-managers/dnf" ( set EXCLUDED=1 )
if "!COMPONENT!"=="_lib/package-managers/pacman" ( set EXCLUDED=1 )
if "!COMPONENT!"=="_lib/package-managers/zypper" ( set EXCLUDED=1 )
if "!COMPONENT!"=="_lib/package-managers/flatpak" ( set EXCLUDED=1 )
if "!COMPONENT!"=="_lib/package-managers/snap" ( set EXCLUDED=1 )
if "!COMPONENT!"=="_lib/package-managers/macports" ( set EXCLUDED=1 )
if "!COMPONENT!"=="_lib/web-servers/caddy" ( set EXCLUDED=1 )
if "!COMPONENT!"=="_lib/package-managers/nix" ( set EXCLUDED=1 )
if "!COMPONENT!"=="_lib/orchestration/kubernetes-k0s" ( set EXCLUDED=1 )
if "!COMPONENT!"=="_lib/orchestration/kubernetes-thw" ( set EXCLUDED=1 )
if "!COMPONENT!"=="_lib/web-servers/nginx" ( set EXCLUDED=1 )
if "!COMPONENT!"=="_lib/databases/postgres" ( set EXCLUDED=1 )
if "!COMPONENT!"=="_lib/message-brokers/rabbitmq" ( set EXCLUDED=1 )
if "!COMPONENT!"=="_lib/databases/etcd" ( set EXCLUDED=1 )
if "!COMPONENT!"=="stacks/data-science/jupyterhub" ( set EXCLUDED=1 )
if "!COMPONENT!"=="stacks/scaffolds/serve-actix-diesel-auth-scaffold" ( set EXCLUDED=1 )
if "!COMPONENT!"=="stacks/crawlers/firecrawl" ( set EXCLUDED=1 )
if "!COMPONENT!"=="stacks/networking/openvpn" ( set EXCLUDED=1 )
if "!COMPONENT!"=="stacks/task-queues/celery" ( set EXCLUDED=1 )
if "!COMPONENT!"=="stacks/cms/wordpress" ( set EXCLUDED=1 )

if "!EXCLUDED!"=="1" (
    echo Skipping !COMPONENT! on !OS_NAME! ^(excluded^)
    exit /b 0
)

REM Compute ROOT directory dynamically
set "SCRIPT_DIR=%~dp0"
:FIND_ROOT
if exist "%SCRIPT_DIR%\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=%SCRIPT_DIR%"
    goto :ROOT_FOUND
)
for %%I in ("%SCRIPT_DIR%\..") do set "SCRIPT_DIR=%%~fI"
goto :FIND_ROOT
:ROOT_FOUND

cd "%LIBSCRIPT_ROOT_DIR%\!COMPONENT!" || exit /b 1

set SETUP_FAILED=0
if exist setup.cmd (
    call setup.cmd || set SETUP_FAILED=1
) else if exist setup.ps1 (
    powershell -ExecutionPolicy Bypass -File setup.ps1 || set SETUP_FAILED=1
)

if "!SETUP_FAILED!"=="1" (
    echo Setup failed for !COMPONENT!
    exit /b 1
)

FOR /F "tokens=*" %%A IN ('powershell -NoProfile -Command "[Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')"') DO ( SET "PATH=%%A;%PATH%" )

if exist test.cmd (
    call test.cmd || (
        echo Test failed for !COMPONENT!
        exit /b 1
    )
) else (
    echo No test.cmd found
)

exit /b 0
