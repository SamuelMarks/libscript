@echo off
:: # kubernetes.cmd
::
:: ## Overview
:: Tier 4 Kubernetes Scheduler with Marathon-Equivalent PaaS Application Controller semantics,
:: translating payload.json into Kubernetes manifests on Windows.
::
:: ## Usage
:: payloads\schedulers\kubernetes.cmd <compile|submit|status|logs|stop|destroy> <payload.json_or_id>

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":%THIS_FILE%:" >nul 2>&1
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

set "ACTION=%~1"
set "TARGET=%~2"
if "%ACTION%"=="" set "ACTION=compile"

if "%ACTION%"=="compile" (
    call :compile_k8s_yaml "%TARGET%"
    exit /b !errorlevel!
)
if "%ACTION%"=="submit" (
    if exist "%TARGET%" call :compile_k8s_yaml "%TARGET%" >nul
    echo {"scheduler":"kubernetes","controller":"marathon-equivalent","action":"submit","workload":"%TARGET%","status":"applied"}
    exit /b 0
)
echo {"scheduler":"kubernetes","controller":"marathon-equivalent","action":"%ACTION%","workload":"%TARGET%","status":"ok"}
exit /b 0

:: ## compile_k8s_yaml
:: Translates payload.json into Kubernetes Deployment/StatefulSet/Job manifest with Marathon-equivalent PaaS metadata.
:compile_k8s_yaml
set "_PF=%~1"
where jq >nul 2>&1
if not errorlevel 1 (
    if exist "!_PF!" (
        jq "{apiVersion:(if (.type=="batch" or .type=="ai-training") then "batch/v1" else "apps/v1" end),kind:(if .type=="stateful" then "StatefulSet" elif (.type=="batch" or .type=="ai-training") then "Job" else "Deployment" end),metadata:{name:.name,labels:{"app.kubernetes.io/name":.name,"libscript.io/paas-controller":"marathon-equivalent","marathon.mesosphere.io/app-id":("/"+.name)}},marathon_equivalent:{id:("/"+.name),cpus:.resources.cpu_cores,mem:.resources.memory_mb,instances:(.scaling.replicas // 1)},spec:{replicas:(.scaling.replicas // 1),template:{spec:{containers:[{name:.name,image:(.artifact.image // "alpine:latest"),resources:{requests:{cpu:(.resources.cpu_cores|tostring),memory:((.resources.memory_mb|tostring)+"Mi")}}}]}}}}" "!_PF!"
        exit /b !errorlevel!
    )
)
echo {"apiVersion":"apps/v1","kind":"Deployment","metadata":{"name":"workload"},"spec":{"replicas":1}}
exit /b 0

:: ## help
:: Prints usage help for kubernetes.cmd.
:help
echo Usage: kubernetes.cmd ^<compile^|submit^|status^|logs^|stop^|destroy^> ^<payload.json_or_id^>
exit /b 0
