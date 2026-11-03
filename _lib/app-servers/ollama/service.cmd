@echo off
:: # service.cmd
:: ## Overview
:: Manages background service lifecycle operations (start, stop, status, configure) and OLLAMA_MODELS directory configuration for the ollama component on Windows.
:: ## Usage
:: service.cmd [action]

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

set "STACK="
call "!SCRIPT_DIR!\env.cmd"
set "_ACT=%~1"
if "!_ACT!"=="" set "_ACT=%ACTION%"
if "!_ACT!"=="" set "_ACT=status"
set "_SVC=%LIBSCRIPT_SERVICE_NAME%"
if "!_SVC!"=="" set "_SVC=ollama"

if /i "!_ACT!"=="ensure-models" (
    call :ensure_ollama_models "%~2" "%~3" "%~4" "%~5"
    exit /b !ERRORLEVEL!
)
if /i "!_ACT!"=="prune-models" (
    call :prune_ollama_models "%~2" "%~3" "%~4" "%~5"
    exit /b !ERRORLEVEL!
)

if /i "!_ACT!"=="start" call :configure_ollama_env
if /i "!_ACT!"=="restart" call :configure_ollama_env
if /i "!_ACT!"=="up" call :configure_ollama_env
if /i "!_ACT!"=="install-service" call :configure_ollama_env
if /i "!_ACT!"=="override-env" (
    call :configure_ollama_env "%~2"
    exit /b !ERRORLEVEL!
)
if /i "!_ACT!"=="configure" (
    call :configure_ollama_env "%~2"
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service.cmd" status "!_SVC!" >nul 2>&1
    if not errorlevel 1 (
        set "STACK="
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service.cmd" restart "!_SVC!"
        call :wait_for_ollama_ready
    )
    exit /b 0
)

set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service.cmd" "!_ACT!" "!_SVC!"
set "_SVC_RC=!ERRORLEVEL!"
if /i "!_ACT!"=="start" call :wait_for_ollama_ready
if /i "!_ACT!"=="restart" call :wait_for_ollama_ready
if /i "!_ACT!"=="up" call :wait_for_ollama_ready
exit /b !_SVC_RC!

:: ## configure_ollama_env
:: Creates the OLLAMA_MODELS directory and persists the environment override exclusively for the ollama daemon.
:configure_ollama_env
set "_COE_DIR=%~1"
if /i "!_COE_DIR!"=="ollama" set "_COE_DIR="
if /i "!_COE_DIR!"=="libscript_ollama" set "_COE_DIR="
if "!_COE_DIR!"=="" set "_COE_DIR=!OLLAMA_MODELS_DIR!"
if "!_COE_DIR!"=="" set "_COE_DIR=!OLLAMA_MODELS!"
if "!_COE_DIR!"=="" exit /b 0
if not exist "!_COE_DIR!" mkdir "!_COE_DIR!"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" override-env "!_SVC!" "OLLAMA_MODELS=!_COE_DIR!"
exit /b 0

:: ## wait_for_ollama_ready
:: Polls http://127.0.0.1:11434/api/tags for up to 30 seconds until the Ollama daemon is responsive.
:wait_for_ollama_ready
if "%LIBSCRIPT_DRY_RUN%"=="1" exit /b 0
set "_WOR_MAX=%OLLAMA_READY_TIMEOUT%"
if "!_WOR_MAX!"=="" set "_WOR_MAX=30"
for /l %%I in (1,1,!_WOR_MAX!) do (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_fetch_stdout "http://127.0.0.1:11434/api/tags" >nul 2>&1
    if not errorlevel 1 exit /b 0
    where ollama >nul 2>&1
    if not errorlevel 1 (
        ollama list >nul 2>&1
        if not errorlevel 1 exit /b 0
    )
    timeout /t 1 /nobreak >nul 2>&1
)
exit /b 0

:: ## is_ollama_model_installed
:: Checks whether the requested model (or model:latest) is already registered in ollama list.
:is_ollama_model_installed
set "_IOM_MOD=%~1"
if "!_IOM_MOD!"=="" exit /b 1
set "_IOM_ALT=!_IOM_MOD!:latest"
where ollama >nul 2>&1
if errorlevel 1 exit /b 1
for /f "skip=1 tokens=1" %%M in ('ollama list 2^>nul') do (
    if /i "%%M"=="!_IOM_MOD!" exit /b 0
    if /i "%%M"=="!_IOM_ALT!" exit /b 0
)
exit /b 1

:: ## ensure_ollama_models
:: Idempotently ensures each requested model is present, pulling missing models and verifying registration.
:ensure_ollama_models
call :wait_for_ollama_ready
set "_EOM_LIST=%~1 %~2 %~3 %~4"
if /i "%~1"=="ollama" set "_EOM_LIST=%~2 %~3 %~4"
if /i "%~1"=="libscript_ollama" set "_EOM_LIST=%~2 %~3 %~4"
set "_EOM_TRIM=!_EOM_LIST: =!"
if "!_EOM_TRIM!"=="" set "_EOM_LIST=!OLLAMA_MODEL_LIST!"
if "!_EOM_LIST!"=="" set "_EOM_LIST=!OLLAMA_DEFAULT_MODEL!"
set "_EOM_LIST=!_EOM_LIST:,= !"
for %%M in (!_EOM_LIST!) do (
    call :is_ollama_model_installed "%%M"
    if not errorlevel 1 (
        echo [INFO] [OLLAMA] [REUSE] Model '%%M' is already present.
    ) else (
        echo [INFO] [OLLAMA] [PULL] Pulling model '%%M'...
        ollama pull "%%M"
        if errorlevel 1 (
            echo [ERROR] [OLLAMA] Failed to pull model '%%M'. >&2
            exit /b 1
        )
        call :is_ollama_model_installed "%%M"
        if errorlevel 1 (
            echo [ERROR] [OLLAMA] Model '%%M' was not registered in 'ollama list' after pull. >&2
            exit /b 1
        )
    )
)
exit /b 0

:: ## prune_ollama_models
:: Removes any locally installed Ollama models that are not in the allowed model list.
:prune_ollama_models
call :wait_for_ollama_ready
set "_POM_KEEP=%~1 %~2 %~3 %~4"
if /i "%~1"=="ollama" set "_POM_KEEP=%~2 %~3 %~4"
if /i "%~1"=="libscript_ollama" set "_POM_KEEP=%~2 %~3 %~4"
set "_POM_TRIM=!_POM_KEEP: =!"
if "!_POM_TRIM!"=="" set "_POM_KEEP=!OLLAMA_MODEL_LIST!"
if "!_POM_KEEP!"=="" exit /b 0
where ollama >nul 2>&1
if errorlevel 1 exit /b 0
for /f "skip=1 tokens=1" %%I in ('ollama list 2^>nul') do (
    echo !_POM_KEEP! | findstr /i /c:"%%I" >nul 2>&1
    if errorlevel 1 (
        echo [INFO] [OLLAMA] [PRUNE] Removing unconfigured model '%%I'...
        ollama rm "%%I" >nul 2>&1
    )
)
exit /b 0
