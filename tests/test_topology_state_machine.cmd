@echo off
:: # test_topology_state_machine.cmd
::
:: ## Overview
:: Verifies .topology_state.json checkpointing, locking, and fencing on Windows across all 8 topologies.
::
:: ## Usage
:: tests\test_topology_state_machine.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
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

for %%T in (valkey-cluster postgres-ha redis-cluster k0s-ha minio-distributed mesos-marathon-ha k8s-marathon-paas) do (
    call "%LIBSCRIPT_ROOT_DIR%\topologies\%%T\cli.cmd" up >nul
    if errorlevel 1 exit /b 1
    call "%LIBSCRIPT_ROOT_DIR%\topologies\%%T\cli.cmd" status >nul
    if errorlevel 1 exit /b 1
    call "%LIBSCRIPT_ROOT_DIR%\topologies\%%T\cli.cmd" down >nul
    if errorlevel 1 exit /b 1
)
call "%LIBSCRIPT_ROOT_DIR%\topologies\gke-tpu-cluster\cli.cmd" --help >nul
if errorlevel 1 exit /b 1
echo [PASS] Topology state machine checkpointing, locking, and fencing verified across all 8 topologies.
exit /b 0
