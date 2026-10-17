@echo off
:: # test_k8s_marathon_e2e.cmd
::
:: ## Overview
:: End-to-end live integration test for Kubernetes + `k8s-marathon` PaaS controller on Windows.
::
:: ## Usage
:: tests\test_k8s_marathon_e2e.cmd

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

call "%LIBSCRIPT_ROOT_DIR%\_lib\orchestration\k8s-marathon\cli.cmd" install latest >nul
if errorlevel 1 exit /b 1
call "%LIBSCRIPT_ROOT_DIR%\_lib\orchestration\k8s-marathon\cli.cmd" start >nul
if errorlevel 1 exit /b 1
call "%LIBSCRIPT_ROOT_DIR%\topologies\k8s-marathon-paas\cli.cmd" up >nul
if errorlevel 1 exit /b 1

for %%V in (compile submit status logs stop destroy) do (
    call "%LIBSCRIPT_ROOT_DIR%\payloads\schedulers\kubernetes.cmd" %%V "%LIBSCRIPT_ROOT_DIR%\payloads\ai\vllm\payload.json" >nul
    if errorlevel 1 exit /b 1
)
echo [PASS] Kubernetes + k8s-marathon PaaS controller live end-to-end suite verified.
exit /b 0
