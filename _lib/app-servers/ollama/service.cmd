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

:: ## resolve_ollama_models_dir
:: Resolves a valid filesystem path for OLLAMA_MODELS_DIR and OLLAMA_MODELS on Windows, rejecting non-path model catalog strings.
:resolve_ollama_models_dir
if not "!OLLAMA_MODELS_DIR!"=="" (
    if not "!OLLAMA_MODELS_DIR:~0,1!"=="/" if not "!OLLAMA_MODELS_DIR:~0,1!"=="\" if not "!OLLAMA_MODELS_DIR:~1,1!"==":" set "OLLAMA_MODELS_DIR="
)
if not "!OLLAMA_MODELS!"=="" (
    if not "!OLLAMA_MODELS:~0,1!"=="/" if not "!OLLAMA_MODELS:~0,1!"=="\" if not "!OLLAMA_MODELS:~1,1!"==":" set "OLLAMA_MODELS="
)
set "_ROM_DEF_MOUNT=!DATA_DISK_MOUNT!"
if "!_ROM_DEF_MOUNT!"=="" set "_ROM_DEF_MOUNT=!DATA_MOUNT_DIR!"
if "!_ROM_DEF_MOUNT!"=="" set "_ROM_DEF_MOUNT=/mnt/data"
if "!OLLAMA_MODELS!"=="" (
    if not "!OLLAMA_MODELS_DIR!"=="" (
        set "OLLAMA_MODELS=!OLLAMA_MODELS_DIR!"
    ) else (
        set "OLLAMA_MODELS=!_ROM_DEF_MOUNT!/ollama_models"
    )
)
set "OLLAMA_MODELS_DIR=!OLLAMA_MODELS!"
exit /b 0

:: ## sanitize_ollama_host
:: Strips http://, https://, and any /v1 or /v1/ suffix from OLLAMA_HOST.
:sanitize_ollama_host
set "_SOH_RAW=!OLLAMA_HOST!"
if "!_SOH_RAW!"=="" set "_SOH_RAW=127.0.0.1:11434"
set "_SOH_RAW=!_SOH_RAW:http://=!"
set "_SOH_RAW=!_SOH_RAW:https://=!"
if "!_SOH_RAW:~-1!"=="/" set "_SOH_RAW=!_SOH_RAW:~0,-1!"
if /i "!_SOH_RAW:~-3!"=="/v1" set "_SOH_RAW=!_SOH_RAW:~0,-3!"
if "!_SOH_RAW:~-1!"=="/" set "_SOH_RAW=!_SOH_RAW:~0,-1!"
if "!_SOH_RAW!"=="" set "_SOH_RAW=127.0.0.1:11434"
set "OLLAMA_HOST_BIND=!_SOH_RAW!"
set "OLLAMA_HOST=http://!_SOH_RAW!"
exit /b 0

:: ## configure_ollama_env
:: Creates the OLLAMA_MODELS directory and persists the environment overrides (including CPU-safe llama-server settings) exclusively for the ollama daemon.
:configure_ollama_env
set "_COE_DIR=%~1"
if /i "!_COE_DIR!"=="ollama" set "_COE_DIR="
if /i "!_COE_DIR!"=="libscript_ollama" set "_COE_DIR="
if not "!_COE_DIR!"=="" (
    if not "!_COE_DIR:~0,1!"=="/" if not "!_COE_DIR:~0,1!"=="\" if not "!_COE_DIR:~1,1!"==":" set "_COE_DIR="
)
call :resolve_ollama_models_dir
if not "!_COE_DIR!"=="" (
    set "OLLAMA_MODELS=!_COE_DIR!"
    set "OLLAMA_MODELS_DIR=!_COE_DIR!"
)
if "!OLLAMA_MODELS!"=="" exit /b 0
if not exist "!OLLAMA_MODELS!" mkdir "!OLLAMA_MODELS!"
if not exist "!OLLAMA_MODELS!\manifests" mkdir "!OLLAMA_MODELS!\manifests" >nul 2>&1
if not exist "!OLLAMA_MODELS!\blobs" mkdir "!OLLAMA_MODELS!\blobs" >nul 2>&1
icacls "!OLLAMA_MODELS!" /grant "*S-1-5-32-544:(OI)(CI)F" /grant "*S-1-5-18:(OI)(CI)F" /T /C /Q >nul 2>&1
call :sanitize_ollama_host
set "_COE_HOST=!OLLAMA_HOST_BIND!"
set "_COE_PAR=!OLLAMA_NUM_PARALLEL!"
if "!_COE_PAR!"=="" set "_COE_PAR=1"
set "_COE_MAX=!OLLAMA_MAX_LOADED_MODELS!"
if "!_COE_MAX!"=="" set "_COE_MAX=1"
set "_COE_FA=!OLLAMA_FLASH_ATTENTION!"
if "!_COE_FA!"=="" set "_COE_FA=0"
set "_COE_KV=!OLLAMA_KV_CACHE_TYPE!"
if "!_COE_KV!"=="" set "_COE_KV=f16"
set "_COE_CTX=!OLLAMA_CONTEXT_LENGTH!"
if "!_COE_CTX!"=="" set "_COE_CTX=2048"
set "_COE_Q=!OLLAMA_MAX_QUEUE!"
if "!_COE_Q!"=="" set "_COE_Q=16"
set "_COE_KA=!OLLAMA_KEEP_ALIVE!"
if "!_COE_KA!"=="" set "_COE_KA=10m"
set "_COE_AMX=!GGML_BACKEND_AMX!"
if "!_COE_AMX!"=="" set "_COE_AMX=0"
set "_COE_LLM=!OLLAMA_LLM_LIBRARY!"
set "_COE_GPU=!OLLAMA_NUM_GPU!"
where nvidia-smi >nul 2>&1
if errorlevel 1 (
    if "!_COE_LLM!"=="" set "_COE_LLM=cpu_avx2"
    if "!_COE_GPU!"=="" set "_COE_GPU=0"
)
set "_COE_EXTRA="
if not "!_COE_LLM!"=="" set "_COE_EXTRA=!_COE_EXTRA! \"OLLAMA_LLM_LIBRARY=!_COE_LLM!\""
if not "!_COE_GPU!"=="" set "_COE_EXTRA=!_COE_EXTRA! \"OLLAMA_NUM_GPU=!_COE_GPU!\""
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" override-env "!_SVC!" "OLLAMA_MODELS=!OLLAMA_MODELS!" "OLLAMA_HOST=!_COE_HOST!" "OLLAMA_NUM_PARALLEL=!_COE_PAR!" "OLLAMA_MAX_LOADED_MODELS=!_COE_MAX!" "OLLAMA_FLASH_ATTENTION=!_COE_FA!" "OLLAMA_KV_CACHE_TYPE=!_COE_KV!" "OLLAMA_CONTEXT_LENGTH=!_COE_CTX!" "OLLAMA_MAX_QUEUE=!_COE_Q!" "OLLAMA_KEEP_ALIVE=!_COE_KA!" "GGML_BACKEND_AMX=!_COE_AMX!" !_COE_EXTRA!
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service.cmd" status "!_SVC!" >nul 2>&1
if not errorlevel 1 (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service.cmd" restart "!_SVC!"
    call :wait_for_ollama_ready
)
exit /b 0

:: ## verify_authentic_gemma_model
:: Verifies that gemma:2b has its genuine Google Gemma digest/family and was not aliased to llama3.2:1b; if aliased, removes and re-pulls authentic gemma:2b.
:verify_authentic_gemma_model
if "%LIBSCRIPT_DRY_RUN%"=="1" exit /b 0
where ollama >nul 2>&1
if errorlevel 1 exit /b 0
call :resolve_ollama_models_dir
call :sanitize_ollama_host
set "_VAG_GEMMA_ID="
set "_VAG_LLAMA_ID="
for /f "skip=1 tokens=1,2" %%A in ('ollama list 2^>nul') do (
    if /i "%%A"=="gemma:2b" set "_VAG_GEMMA_ID=%%B"
    if /i "%%A"=="llama3.2:1b" set "_VAG_LLAMA_ID=%%B"
)
if not "!_VAG_GEMMA_ID!"=="" if not "!_VAG_LLAMA_ID!"=="" (
    if /i "!_VAG_GEMMA_ID!"=="!_VAG_LLAMA_ID!" (
        echo [WARN] [OLLAMA] [AUTHENTICITY] Detected non-genuine 'gemma:2b' alias ^(digest matches llama3.2:1b^); restoring authentic Google Gemma 2B weights... >&2
        ollama rm "gemma:2b" >nul 2>&1
        ollama pull "gemma:2b"
        if errorlevel 1 exit /b 1
    )
)
exit /b 0

:: ## verify_ollama_model_inference
:: Sends a 1-token /api/generate smoke request for a model and re-pulls the authentic model once if llama-server crashes.
:verify_ollama_model_inference
set "_VOMI_MOD=%~1"
if "!_VOMI_MOD!"=="" exit /b 0
if "%LIBSCRIPT_DRY_RUN%"=="1" exit /b 0
call :resolve_ollama_models_dir
call :sanitize_ollama_host
if /i "!_VOMI_MOD!"=="gemma:2b" (
    call :verify_authentic_gemma_model
    if errorlevel 1 exit /b 1
)
where curl.exe >nul 2>&1
if errorlevel 1 exit /b 0
set "_VOMI_URL=!OLLAMA_HOST!"
set "_VOMI_TMP=%TEMP%\ollama_vomi_!RANDOM!.json"
curl.exe -sS --connect-timeout 5 --max-time 60 -H "Content-Type: application/json" -H "X-Local-Default: 127.0.0.1" -d "{\"model\":\"!_VOMI_MOD!\",\"prompt\":\"SELECT 1;\",\"stream\":false,\"keep_alive\":\"30m\",\"options\":{\"num_predict\":1,\"num_ctx\":512,\"num_gpu\":0,\"num_thread\":4,\"use_mmap\":false}}" "!_VOMI_URL!/api/generate" > "!_VOMI_TMP!" 2>nul
if exist "!_VOMI_TMP!" (
    findstr /I /C:"llama-server process has terminated" /C:"segmentation fault" /C:"core dumped" /C:"signal: " "!_VOMI_TMP!" >nul 2>&1
    if not errorlevel 1 (
        echo [WARN] [OLLAMA] [HEAL] Model '!_VOMI_MOD!' crashed during 1-token smoke test; applying GGML_BACKEND_AMX=0 / cpu_avx2 overrides, repairing permissions, and re-pulling authentic model... >&2
        del /q "!_VOMI_TMP!" >nul 2>&1
        if defined OLLAMA_MODELS (
            if exist "!OLLAMA_MODELS!" icacls "!OLLAMA_MODELS!" /grant "*S-1-5-32-544:(OI)(CI)F" /grant "*S-1-5-18:(OI)(CI)F" /T /C /Q >nul 2>&1
        )
        call :configure_ollama_env
        where ollama >nul 2>&1
        if not errorlevel 1 (
            ollama rm "!_VOMI_MOD!" >nul 2>&1
            ollama pull "!_VOMI_MOD!"
        )
        curl.exe -sS --connect-timeout 5 --max-time 60 -H "Content-Type: application/json" -H "X-Local-Default: 127.0.0.1" -d "{\"model\":\"!_VOMI_MOD!\",\"prompt\":\"SELECT 1;\",\"stream\":false,\"keep_alive\":\"30m\",\"options\":{\"num_predict\":1,\"num_ctx\":512,\"num_gpu\":0,\"num_thread\":4,\"use_mmap\":false}}" "!_VOMI_URL!/api/generate" > "!_VOMI_TMP!" 2>nul
        if exist "!_VOMI_TMP!" (
            findstr /I /C:"llama-server process has terminated" /C:"segmentation fault" /C:"core dumped" /C:"signal: " "!_VOMI_TMP!" >nul 2>&1
            if not errorlevel 1 (
                del /q "!_VOMI_TMP!" >nul 2>&1
                echo [ERROR] [OLLAMA] Model '!_VOMI_MOD!' still failed 1-token smoke test after re-pull. >&2
                exit /b 1
            )
            del /q "!_VOMI_TMP!" >nul 2>&1
        )
    ) else (
        del /q "!_VOMI_TMP!" >nul 2>&1
    )
)
exit /b 0

:: ## wait_for_ollama_ready
:: Polls http://127.0.0.1:11434/api/tags for up to 30 seconds until the Ollama daemon is responsive.
:wait_for_ollama_ready
if "%LIBSCRIPT_DRY_RUN%"=="1" exit /b 0
call :resolve_ollama_models_dir
call :sanitize_ollama_host
set "_WOR_MAX=%OLLAMA_READY_TIMEOUT%"
if "!_WOR_MAX!"=="" set "_WOR_MAX=30"
for /l %%I in (1,1,!_WOR_MAX!) do (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_fetch_stdout "!OLLAMA_HOST!/api/tags" >nul 2>&1
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
call :configure_ollama_env
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
        if "!OLLAMA_VERIFY_INFERENCE!"=="1" (
            call :verify_ollama_model_inference "%%M"
            if errorlevel 1 exit /b 1
        ) else if /i "%%M"=="gemma:2b" (
            call :verify_ollama_model_inference "%%M"
            if errorlevel 1 exit /b 1
        )
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
        if "!OLLAMA_VERIFY_INFERENCE!"=="1" (
            call :verify_ollama_model_inference "%%M"
            if errorlevel 1 exit /b 1
        ) else if /i "%%M"=="gemma:2b" (
            call :verify_ollama_model_inference "%%M"
            if errorlevel 1 exit /b 1
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
