@echo off
:: # setup.cmd
::
:: ## Overview
:: Proxmox VE hypervisor provider on Windows.
:: Configures Proxmox VM specifications and delegates orchestration to vm_builder worker.
::
:: ## Usage
:: setup.cmd [action] [vmid] [qcow2_image] [storage_pool]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

SET "searchVal=;%THIS_FILE%;"
IF NOT DEFINED STACK (
    SET "STACK=;%THIS_FILE%;"
    echo [CONTINUE] processing "%THIS_FILE%"
) ELSE (
    IF NOT "!STACK:%searchVal%=!"=="!STACK!" (
        echo [STOP]     processing "%THIS_FILE%"
        SET ERRORLEVEL=0
        goto :eof
    ) ELSE (
        SET "STACK=!STACK!%THIS_FILE%;"
        echo [CONTINUE] processing "%THIS_FILE%"
    )
)

if "%~1"=="--help" (
    echo Usage: %~nx0 [action] [vmid] [qcow2_image] [storage_pool]
    echo Proxmox VE hypervisor provider.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [action] [vmid] [qcow2_image] [storage_pool]
    echo Proxmox VE hypervisor provider.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%\..\..\..") do set "REPO_ROOT=%%~fI"

call "%REPO_ROOT%\_lib\orchestration\vm_builder.cmd" "%REPO_ROOT%\_lib/cloud-providers\proxmox\setup.sh" %*
exit /b %ERRORLEVEL%
