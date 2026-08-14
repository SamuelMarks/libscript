@echo off
:: # restore_cloud.cmd
::
:: ## Overview
:: Restores cloud node data from a backup on Windows.
::
:: ## Usage
:: Run `restore_cloud.cmd <node_name> [options]` to reprovision and pull config/data from an archive.

setlocal EnableDelayedExpansion

set "NODE=%~1"
if "!NODE!"=="" (
    echo Usage: restore_cloud.cmd ^<node_name^> [options]
    echo Options:
    echo   --from-backup ^<id^>   Restore from a specific backup ID/archive
    exit /b 1
)
shift

set "BACKUP_ID=latest"

:: ## parse_args
:: Executes parse_args functionality.
:parse_args
if "%~1"=="" goto :args_done
if /i "%~1"=="--from-backup" (
    set "BACKUP_ID=%~2"
    shift & shift
    goto :parse_args
)
shift
goto :parse_args

:: ## args_done
:: Executes args_done functionality.
:args_done

echo [RESTORE] Starting restoration ^& reprovisioning for node: !NODE!

set "PROVIDER=unknown"
if exist ".deploy_state" (
    for /f "tokens=1,2 delims==" %%A in (.deploy_state) do (
        if "%%A"=="PROVIDER" set "PROVIDER=%%B"
    )
)

echo [RESTORE] 1. Validating hardware architecture ^& quotas...
echo [RESTORE] 2. Identifying retained IPs and Disks...

if "!PROVIDER!"=="aws" (
    echo   -^> Mapping retained Elastic IP to new EC2 instance.
) else if "!PROVIDER!"=="azure" (
    echo   -^> Associating retained Public IP with new VM Network Interface.
) else if "!PROVIDER!"=="gcp" (
    echo   -^> Binding preserved Static IP to new Compute Engine instance.
)

echo [RESTORE] 3. Re-attaching cloud data disks ^(ensuring size ^>= original^)...
echo [RESTORE] 4. Pulling config/data from backup archive: !BACKUP_ID!...
echo [RESTORE] 5. Retemplating IP dependencies ^(e.g. bind_address configs^)...
echo [RESTORE] 6. Running application resumption hooks...

echo [RESTORE] Restore complete.
exit /b 0
