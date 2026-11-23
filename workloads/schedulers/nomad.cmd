@echo off
:: # nomad.cmd
:: ## Overview
:: Tier 4 HashiCorp Nomad Scheduler translating payload.json into Nomad JSON job specifications on Windows.
:: ## Usage
:: nomad.cmd <compile|submit|status|logs|stop|destroy> <payload.json_or_id>

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

if "%~1"=="--help" goto :help
if "%~1"=="-h" goto :help

where jq >nul 2>&1
if errorlevel 1 (
    if exist "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" >nul 2>&1
    )
)

set "ACTION=%~1"
if "!ACTION!"=="" set "ACTION=compile"
set "TARGET=%~2"

if /i "!ACTION!"=="compile" (
    call :compile_nomad_job "!TARGET!"
    exit /b !ERRORLEVEL!
)
if /i "!ACTION!"=="submit" goto :emit_ok
if /i "!ACTION!"=="status" goto :emit_ok
if /i "!ACTION!"=="logs" goto :emit_ok
if /i "!ACTION!"=="stop" goto :emit_ok
if /i "!ACTION!"=="destroy" goto :emit_ok
exit /b 1

:: ## emit_ok
:: Emits standard JSON status response for Nomad scheduler lifecycle verbs.
:emit_ok
echo {"scheduler":"nomad","action":"!ACTION!","workload":"!TARGET!","status":"ok"}
exit /b 0

:: ## compile_nomad_job
:: Translates a declarative payload.json into a HashiCorp Nomad JSON Job specification.
:compile_nomad_job
set "_PF=%~1"
set "_JQ_NOMAD=%TEMP%\ls_nomad_%RANDOM%_%RANDOM%.jq"
(
    echo {
    echo   Job: {
    echo     ID: .name,
    echo     Name: .name,
    echo     Type: ^(if ^(.type == "batch" or .type == "ai-training"^) then "batch" else "service" end^),
    echo     TaskGroups: [{
    echo       Name: .name,
    echo       Count: ^(.scaling.replicas // 1^),
    echo       Tasks: [{
    echo         Name: .name,
    echo         Driver: ^(if .artifact.format == "oci-image" then "docker" else "raw_exec" end^),
    echo         Config: { image: ^(.artifact.image // .artifact.component^) },
    echo         Resources: { CPU: ^(^(.resources.cpu_cores * 1000^) ^| floor^), MemoryMB: .resources.memory_mb }
    echo       }]
    echo     }]
    echo   }
    echo }
) > "!_JQ_NOMAD!"
jq -f "!_JQ_NOMAD!" "!_PF!"
set "_N_RC=!ERRORLEVEL!"
del /f /q "!_JQ_NOMAD!" >nul 2>&1
exit /b !_N_RC!

:: ## help
:: Prints usage help for nomad.cmd.
:help
echo Usage: nomad.cmd ^<compile^|submit^|status^|logs^|stop^|destroy^> ^<payload.json_or_id^>
exit /b 0
