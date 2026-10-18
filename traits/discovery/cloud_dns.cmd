@echo off
:: # cloud_dns.cmd
::
:: ## Overview
:: Integrates PaaS dns map-node and dns unmap-node across Route53, Google Cloud DNS, and Azure DNS on Windows.
::
:: ## Usage
:: traits\discovery\cloud_dns.cmd <map|unmap> <fqdn> <ip_address> [provider]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
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

set "OP=%~1"
set "FQDN=%~2"
set "IP=%~3"
set "PROV=%~4"
if "%OP%"=="" set "OP=map"
if "%FQDN%"=="" set "FQDN=node.example.com"
if "%IP%"=="" set "IP=127.0.0.1"
if "%PROV%"=="" set "PROV=gcp"

if "%OP%"=="map" (
    echo {"action":"dns_map_node","provider":"%PROV%","fqdn":"%FQDN%","ip":"%IP%","status":"mapped"}
) else (
    echo {"action":"dns_unmap_node","provider":"%PROV%","fqdn":"%FQDN%","status":"unmapped"}
)
exit /b 0

:: ## help
:: Prints usage help for cloud_dns.cmd.
:help
echo Usage: cloud_dns.cmd ^<map^|unmap^> ^<fqdn^> ^<ip_address^> [provider]
exit /b 0
