@echo off
:: # tpu_matrix.cmd
::
:: ## Overview
:: Orchestrates isolated 7-backend Google Cloud TPU /dev/shm uv virtualenvs, watermark eviction, --fresh-vm-per-backend cycling, SKU runtime resolution, and multi-host lockstep environment synthesis on Windows.
::
:: ## Usage
:: call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_backend_spec <backend_id>

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        if "%LIBSCRIPT_DEBUG%"=="1" echo [STOP] processing "!THIS_FILE!" >&2
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
:: Dispatches requested subroutine and exports resulting state to parent environment.
:root_found
set "TPU_ALL_BACKENDS=hf_transformers,pytorch_native,keras_jax,keras_tensorflow,keras_pytorch,maxtext,jax_native"
if not "%~1"=="" goto :dispatch_tm_sub
endlocal & set "TPU_ALL_BACKENDS=%TPU_ALL_BACKENDS%"
exit /b 0

:: ## dispatch_tm_sub
:: Invokes the requested subroutine and exports resulting state to the caller.
:dispatch_tm_sub
set "_tm_sub=%~1"
shift
call !_tm_sub! "%~1" "%~2" "%~3" "%~4" "%~5"
set "_tm_rc=!errorlevel!"
endlocal & (
    set "TPU_ALL_BACKENDS=%TPU_ALL_BACKENDS%"
    set "TPU_BACKEND_SPEC=%TPU_BACKEND_SPEC%"
    set "TPU_BACKEND_FAMILY=%TPU_BACKEND_FAMILY%"
    set "TPU_BACKEND_VENV_DIR=%TPU_BACKEND_VENV_DIR%"
    set "TPU_MULTIHOST_ENV=%TPU_MULTIHOST_ENV%"
    set "TPU_VERSION=%TPU_VERSION%"
    exit /b %_tm_rc%
)
:: wincheck disable=CMD3005

:: ## libscript_tpu_resolve_runtime_version
:: Maps a Cloud TPU accelerator SKU (v4, v5e/v5litepod, v5p, v6e) to its canonical TPU VM OS image when runtime_ver is empty or 'auto'.
:libscript_tpu_resolve_runtime_version
set "_tm_sku=%~1"
if "!_tm_sku!"=="" set "_tm_sku=%TPU_ACCELERATOR_TYPE%"
if "!_tm_sku!"=="" set "_tm_sku=v4-8"
set "_tm_ver=%~2"
if not "!_tm_ver!"=="" if /i not "!_tm_ver!"=="auto" (
    set "TPU_VERSION=!_tm_ver!"
    exit /b 0
)
set "TPU_VERSION=tpu-ubuntu2204-base"
if /i "!_tm_sku:~0,9!"=="v5litepod" set "TPU_VERSION=v2-alpha-tpuv5-lite"
if /i "!_tm_sku:~0,4!"=="v5e-" set "TPU_VERSION=v2-alpha-tpuv5-lite"
if /i "!_tm_sku:~0,4!"=="v5p-" set "TPU_VERSION=v2-alpha-tpuv5"
if /i "!_tm_sku:~0,4!"=="v6e-" set "TPU_VERSION=v2-alpha-tpuv6e"
exit /b 0

:: ## libscript_tpu_family_label
:: Emits the canonical 5-family study comparison group label for one of the 7 Gemma 4 TPU backend cells.
:libscript_tpu_family_label
set "_tm_fb=%~1"
set "TPU_BACKEND_FAMILY=Custom"
if /i "!_tm_fb!"=="hf_transformers" set "TPU_BACKEND_FAMILY=Hugging Face Transformers [which wraps PyTorch]"
if /i "!_tm_fb!"=="pytorch_native" set "TPU_BACKEND_FAMILY=PyTorch [native]"
if /i "!_tm_fb!"=="keras_jax" set "TPU_BACKEND_FAMILY=Keras [and its JAX, TensorFlow, and PyTorch backends]"
if /i "!_tm_fb!"=="keras_tensorflow" set "TPU_BACKEND_FAMILY=Keras [and its JAX, TensorFlow, and PyTorch backends]"
if /i "!_tm_fb!"=="keras_pytorch" set "TPU_BACKEND_FAMILY=Keras [and its JAX, TensorFlow, and PyTorch backends]"
if /i "!_tm_fb!"=="maxtext" set "TPU_BACKEND_FAMILY=MaxText [which wraps JAX]"
if /i "!_tm_fb!"=="jax_native" set "TPU_BACKEND_FAMILY=JAX [native]"
echo.!TPU_BACKEND_FAMILY!
exit /b 0

:: ## libscript_tpu_ensure_host_tools
:: Idempotently provisions required Tier 1 _lib\ CLI components on Windows when absent from PATH.
:libscript_tpu_ensure_host_tools
set "_tm_need_gc=%~1"
for %%C in (jq uv python sqlite duckdb huggingface-cli) do (
    where %%C >nul 2>&1
    if errorlevel 1 (
        if not "%GEMMA_4_SQL_SYNTHETIC_FIXTURES%"=="1" if not "%GEMMA_4_SQL_DRY_RUN%"=="1" (
            set "STACK="
            call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install %%C latest >nul 2>&1 || rem
        )
    )
)
if "!_tm_need_gc!"=="1" (
    where gcloud >nul 2>&1
    if errorlevel 1 (
        set "STACK="
        call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install gcp-cli latest >nul 2>&1 || rem
    )
)
exit /b 0

:: ## libscript_tpu_backend_spec
:: Resolves pipe-delimited virtualenv, wheel index, package, and env specification for one of the 7 Gemma 4 TPU backends.
:libscript_tpu_backend_spec
set "_tm_bid=%~1"
set "_tm_shm=%~2"
if "!_tm_shm!"=="" set "_tm_shm=/dev/shm/libscript-tpu"
set "_tm_rt_cfg=auto"
set "_tm_suite_json=%TPU_SUITE_MANIFEST_PATH%"
if "!_tm_suite_json!"=="" set "_tm_suite_json=%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix_defaults.json"
if exist "!_tm_suite_json!" (
    where jq >nul 2>&1
    if not errorlevel 1 (
        for /f "usebackq delims=" %%R in (`jq -r --arg b "!_tm_bid!" "([.tpu_matrix.backends[]? | select(.id == $b) | .tpu_runtime_version][0]) // \"auto\"" "!_tm_suite_json!" 2^>nul`) do set "_tm_rt_cfg=%%R"
    )
)
call :libscript_tpu_resolve_runtime_version "%TPU_ACCELERATOR_TYPE%" "!_tm_rt_cfg!"
set "_tm_rt=!TPU_VERSION!"
set "TPU_BACKEND_SPEC="
if /i "!_tm_bid!"=="hf_transformers" set "TPU_BACKEND_SPEC=pytorch-xla|hf_transformers|none|!_tm_rt!|-f https://storage.googleapis.com/libtpu-releases/index.html|torch torch_xla[tpu] transformers accelerate peft safetensors datasets duckdb|PJRT_DEVICE=TPU XLA_USE_BF16=1 HF_HOME=!_tm_shm!/cache/hf"
if /i "!_tm_bid!"=="pytorch_native" set "TPU_BACKEND_SPEC=pytorch-xla|pytorch_native|none|!_tm_rt!|-f https://storage.googleapis.com/libtpu-releases/index.html|torch torch_xla[tpu] transformers accelerate peft safetensors datasets duckdb|PJRT_DEVICE=TPU XLA_USE_BF16=1 HF_HOME=!_tm_shm!/cache/hf"
if /i "!_tm_bid!"=="keras_jax" set "TPU_BACKEND_SPEC=keras-jax|keras_jax|jax|!_tm_rt!|-f https://storage.googleapis.com/jax-releases/libtpu_releases.html|jax[tpu] keras>=3 keras-hub tensorflow-cpu duckdb|KERAS_BACKEND=jax JAX_PLATFORMS=tpu KERAS_HOME=!_tm_shm!/cache/keras"
if /i "!_tm_bid!"=="keras_tensorflow" set "TPU_BACKEND_SPEC=keras-tf|keras_tensorflow|tensorflow|!_tm_rt!|none|tensorflow-tpu keras>=3 keras-hub duckdb|KERAS_BACKEND=tensorflow KERAS_HOME=!_tm_shm!/cache/keras"
if /i "!_tm_bid!"=="keras_pytorch" set "TPU_BACKEND_SPEC=keras-torch|keras_pytorch|torch|!_tm_rt!|-f https://storage.googleapis.com/libtpu-releases/index.html|torch torch_xla[tpu] keras>=3 keras-hub tensorflow-cpu duckdb|KERAS_BACKEND=torch PJRT_DEVICE=TPU XLA_USE_BF16=1 KERAS_HOME=!_tm_shm!/cache/keras"
if /i "!_tm_bid!"=="maxtext" set "TPU_BACKEND_SPEC=maxtext|maxtext|none|!_tm_rt!|-f https://storage.googleapis.com/jax-releases/libtpu_releases.html|jax[tpu] flax optax orbax-checkpoint omegaconf einops grain aqt maxtext duckdb|JAX_PLATFORMS=tpu HF_HOME=!_tm_shm!/cache/hf"
if /i "!_tm_bid!"=="jax_native" set "TPU_BACKEND_SPEC=jax-native|jax_native|none|!_tm_rt!|-f https://storage.googleapis.com/jax-releases/libtpu_releases.html|jax[tpu] flax optax orbax-checkpoint grain datasets duckdb|JAX_PLATFORMS=tpu HF_HOME=!_tm_shm!/cache/hf"
if "!TPU_BACKEND_SPEC!"=="" (
    echo [ERROR] Unsupported TPU matrix backend identifier: !_tm_bid! 1>&2
    exit /b 1
)
echo.!TPU_BACKEND_SPEC!
exit /b 0

:: ## libscript_tpu_evict_shm_if_needed
:: Evicts previously completed venv groups when free space falls below watermark while preserving cache\hf and cache\keras.
:libscript_tpu_evict_shm_if_needed
set "_tm_keep=%~1"
set "_tm_shm_root=%~2"
if "!_tm_shm_root!"=="" set "_tm_shm_root=%TEMP%\libscript-tpu"
set "_tm_min_gb=%~3"
if "!_tm_min_gb!"=="" set "_tm_min_gb=%TFRC_SHM_MIN_FREE_GB%"
if "!_tm_min_gb!"=="" set "_tm_min_gb=32"

if not exist "!_tm_shm_root!\venvs" mkdir "!_tm_shm_root!\venvs"
if not exist "!_tm_shm_root!\cache\hf" mkdir "!_tm_shm_root!\cache\hf"
if not exist "!_tm_shm_root!\cache\keras" mkdir "!_tm_shm_root!\cache\keras"

set "_tm_free_kb=%TPU_MOCK_SHM_FREE_KB%"
if "!_tm_free_kb!"=="" (
    set "_tm_raw_b="
    for %%D in ("!_tm_shm_root!") do set "_tm_drv=%%~dD\"
    for /f "tokens=1* delims=:" %%A in ('fsutil volume diskfree "!_tm_drv!" 2^>nul') do (
        if "!_tm_raw_b!"=="" (
            set "_tm_b_val=%%B"
            set "_tm_b_val=!_tm_b_val: =!"
            set "_tm_b_val=!_tm_b_val:,=!"
            for /f "tokens=1 delims=(" %%N in ("!_tm_b_val!") do set "_tm_raw_b=%%N"
        )
    )
    if not "!_tm_raw_b!"=="" (
        if not "!_tm_raw_b:~3!"=="" (
            set "_tm_free_kb=!_tm_raw_b:~0,-3!"
        ) else (
            set "_tm_free_kb=0"
        )
    )
)
if "!_tm_free_kb!"=="" exit /b 0
if not "!_tm_free_kb:~9!"=="" exit /b 0
set /a "_tm_min_kb=_tm_min_gb * 1048576" 2>nul
REM wincheck disable=CMD2003
if !_tm_free_kb! geq !_tm_min_kb! exit /b 0

echo [TPU-MATRIX] Free space !_tm_free_kb! KiB ^< watermark !_tm_min_kb! KiB; evicting completed venvs ^(preserving cache/{hf,keras}^)... 1>&2
for /d %%D in ("!_tm_shm_root!\venvs\*") do (
    set "_tm_dn=%%~nxD"
    if /i not "!_tm_dn!"=="!_tm_keep!" if /i not "!_tm_dn!"=="tpu-telemetry" (
        rmdir /s /q "%%~fD" >nul 2>&1
        echo [TPU-MATRIX] Evicted completed venv group: !_tm_dn! 1>&2
    )
)
exit /b 0

:: ## libscript_tpu_prepare_backend_venv
:: Idempotently builds a stamp-guarded uv virtualenv and installs workspace requirements + TPU wheels + --no-deps -e workspace.
:libscript_tpu_prepare_backend_venv
set "_tm_bid=%~1"
set "_tm_ws=%~2"
set "_tm_shm_root=%~3"
if "!_tm_shm_root!"=="" set "_tm_shm_root=%TEMP%\libscript-tpu"

where uv >nul 2>&1
if errorlevel 1 (
    set "STACK="
    call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install uv latest >nul 2>&1 || rem
)

call :libscript_tpu_backend_spec "!_tm_bid!" "!_tm_shm_root!" >nul
if errorlevel 1 exit /b 1
for /f "tokens=1,5,6 delims=|" %%A in ("!TPU_BACKEND_SPEC!") do (
    set "_tm_vgroup=%%A"
    set "_tm_flinks=%%B"
    set "_tm_pkgs=%%C"
)
if /i "!_tm_flinks!"=="none" set "_tm_flinks="

set "_tm_vdir=!_tm_shm_root!\venvs\!_tm_vgroup!"
set "_tm_stamp_f=!_tm_vdir!\.libscript_wheels.sha256"

set "_tm_sig_tmp=%TEMP%\tpu_sig_!RANDOM!.txt"
> "!_tm_sig_tmp!" echo.!_tm_vgroup!^|!_tm_flinks!^|!_tm_pkgs!
for %%R in (pyproject.toml requirements.txt requirements-duckdb.txt requirements-pytorch.txt requirements-jax.txt requirements-keras.txt requirements-maxtext.txt) do (
    if exist "!_tm_ws!\%%R" type "!_tm_ws!\%%R" >> "!_tm_sig_tmp!" 2>nul
)
set "_tm_stamp=0"
for /f "skip=1 tokens=1" %%H in ('certutil -hashfile "!_tm_sig_tmp!" SHA256 2^>nul') do (
    if "!_tm_stamp!"=="0" set "_tm_stamp=%%H"
)
if "!_tm_stamp!"=="0" set "_tm_stamp=!_tm_vgroup!-default-stamp"
del /f /q "!_tm_sig_tmp!" >nul 2>&1

set "_tm_py_exe=!_tm_vdir!\Scripts\python.exe"
if not exist "!_tm_py_exe!" if exist "!_tm_vdir!\bin\python" set "_tm_py_exe=!_tm_vdir!\bin\python"

if exist "!_tm_stamp_f!" if exist "!_tm_py_exe!" (
    set "_tm_prev="
    set /p _tm_prev=<"!_tm_stamp_f!"
    if "!_tm_prev!"=="!_tm_stamp!" (
        echo [TPU-MATRIX] Reusing isolated venv !_tm_vdir! for backend !_tm_bid! ^(stamp=!_tm_stamp!^). 1>&2
        set "TPU_BACKEND_VENV_DIR=!_tm_vdir!"
        echo.!_tm_vdir!
        exit /b 0
    )
)

call :libscript_tpu_evict_shm_if_needed "!_tm_vgroup!" "!_tm_shm_root!" "%TFRC_SHM_MIN_FREE_GB%"

set "LIBSCRIPT_PYTHON_VENV_BACKEND=uv"
set "_tm_pyver=%TPU_PYTHON_VERSION%"
if "!_tm_pyver!"=="" set "_tm_pyver=3.12"
call "%LIBSCRIPT_ROOT_DIR%\engine\common\python_env.cmd" libscript_python_venv "!_tm_vdir!" "!_tm_pyver!" 1>&2
if errorlevel 1 exit /b 1

set "_tm_py_exe=!_tm_vdir!\Scripts\python.exe"
if not exist "!_tm_py_exe!" if exist "!_tm_vdir!\bin\python" set "_tm_py_exe=!_tm_vdir!\bin\python"

if exist "!_tm_ws!\requirements.txt" (
    call uv pip install --python "!_tm_py_exe!" -r "!_tm_ws!\requirements.txt" 1>&2
    if errorlevel 1 exit /b 1
)
if exist "!_tm_ws!\requirements-duckdb.txt" (
    call uv pip install --python "!_tm_py_exe!" -r "!_tm_ws!\requirements-duckdb.txt" 1>&2
    if errorlevel 1 exit /b 1
)

set "_tm_app_deps=duckdb aiosqlite asyncpg fastapi uvicorn datasets sqlglot"
call uv pip install --python "!_tm_py_exe!" !_tm_flinks! !_tm_app_deps! !_tm_pkgs! 1>&2
if errorlevel 1 exit /b 1

if exist "!_tm_ws!\pyproject.toml" (
    call uv pip install --python "!_tm_py_exe!" --no-deps -e "!_tm_ws!" 1>&2
    if errorlevel 1 exit /b 1
) else if exist "!_tm_ws!\setup.py" (
    call uv pip install --python "!_tm_py_exe!" --no-deps -e "!_tm_ws!" 1>&2
    if errorlevel 1 exit /b 1
)

> "!_tm_stamp_f!.tmp" echo.!_tm_stamp!
move /y "!_tm_stamp_f!.tmp" "!_tm_stamp_f!" >nul
set "TPU_BACKEND_VENV_DIR=!_tm_vdir!"
echo.!_tm_vdir!
exit /b 0

:: ## libscript_tpu_multihost_env
:: Synthesizes space-separated KEY=VALUE exports for single-host or multi-host lockstep worker execution.
:libscript_tpu_multihost_env
set "_tm_bid=%~1"
set "_tm_topo_file=%~2"
set "_tm_widx=%~3"
if "!_tm_widx!"=="" set "_tm_widx=0"
set "_tm_shm_root=%~4"
if "!_tm_shm_root!"=="" set "_tm_shm_root=/dev/shm/libscript-tpu"

call :libscript_tpu_backend_spec "!_tm_bid!" "!_tm_shm_root!" >nul
for /f "tokens=7 delims=|" %%E in ("!TPU_BACKEND_SPEC!") do set "_tm_base_env=%%E"

set "_tm_wcnt=1"
set "_tm_ip0=127.0.0.1"
set "_tm_ips=127.0.0.1"
if exist "!_tm_topo_file!" (
    for /f "usebackq delims=" %%C in (`jq -r ".worker_count // 1" "!_tm_topo_file!" 2^>nul`) do set "_tm_wcnt=%%C"
    for /f "usebackq delims=" %%I in (`jq -r ".worker0_internal_ip // \"127.0.0.1\"" "!_tm_topo_file!" 2^>nul`) do set "_tm_ip0=%%I"
    for /f "usebackq delims=" %%L in (`jq -r ".worker_ips // \"127.0.0.1\"" "!_tm_topo_file!" 2^>nul`) do set "_tm_ips=%%L"
)

set "TPU_MULTIHOST_ENV=!_tm_base_env! TPU_WORKER_ID=!_tm_widx! TPU_NUM_WORKERS=!_tm_wcnt! TPU_WORKER_HOSTNAMES=!_tm_ips!"
if "!_tm_wcnt!" gtr "1" (
    for %%J in (jax_native maxtext keras_jax) do (
        if /i "!_tm_bid!"=="%%J" set "TPU_MULTIHOST_ENV=!TPU_MULTIHOST_ENV! JAX_COORDINATOR_ADDRESS=!_tm_ip0!:8476 MEGASCALE_COORDINATOR_ADDRESS=!_tm_ip0!:8476 PROCESS_ID=!_tm_widx! NUM_PROCESSES=!_tm_wcnt!"
    )
    for %%P in (hf_transformers pytorch_native keras_pytorch) do (
        if /i "!_tm_bid!"=="%%P" set "TPU_MULTIHOST_ENV=!TPU_MULTIHOST_ENV! PJRT_DEVICE=TPU MASTER_ADDR=!_tm_ip0! MASTER_PORT=8477 PT_XLA_PJRT_DIST_SERVICE_ADDR=!_tm_ip0!:8477"
    )
)
echo.!TPU_MULTIHOST_ENV!
exit /b 0

:: ## libscript_tpu_secret_exports
:: Builds remote shell credential exports (HF_TOKEN, KAGGLE_USERNAME, KAGGLE_KEY) without logging secret values.
:libscript_tpu_secret_exports
set "_tm_sec_out="
set "_tm_hft=%HF_TOKEN%"
if "!_tm_hft!"=="" set "_tm_hft=%HUGGING_FACE_HUB_TOKEN%"
if not "!_tm_hft!"=="" set "_tm_sec_out=export HF_TOKEN='!_tm_hft!' HUGGING_FACE_HUB_TOKEN='!_tm_hft!'; "
if not "%KAGGLE_USERNAME%"=="" set "_tm_sec_out=!_tm_sec_out!export KAGGLE_USERNAME='%KAGGLE_USERNAME%'; "
if not "%KAGGLE_KEY%"=="" set "_tm_sec_out=!_tm_sec_out!export KAGGLE_KEY='%KAGGLE_KEY%'; "
exit /b 0

:: ## libscript_tpu_bootstrap_remote
:: Syncs LibScript and target workspace to all TPU VM workers and bootstraps Python 3.12, uv, jq, sqlite, duckdb, and huggingface-cli idempotently.
:libscript_tpu_bootstrap_remote
set "_tm_tpu=%~1"
set "_tm_repo=%~2"
set "_tm_tpu_cli=%LIBSCRIPT_ROOT_DIR%\infrastructure\providers\gcp-tpu-vm\cli.cmd"
call "!_tm_tpu_cli!" sync-repo "!_tm_tpu!" "%LIBSCRIPT_ROOT_DIR%" "libscript" --all-workers
if errorlevel 1 exit /b !errorlevel!
if not "!_tm_repo!"=="" if exist "!_tm_repo!" (
    call "!_tm_tpu_cli!" sync-repo "!_tm_tpu!" "!_tm_repo!" "workspace" --all-workers
    if errorlevel 1 exit /b !errorlevel!
)
call "!_tm_tpu_cli!" ssh "!_tm_tpu!" --all-workers "--command=mkdir -p /dev/shm/libscript-tpu/venvs /dev/shm/libscript-tpu/cache/hf /dev/shm/libscript-tpu/cache/keras $HOME/results/raw && $HOME/libscript/libscript.sh install python 3.12 && $HOME/libscript/libscript.sh install uv latest && $HOME/libscript/libscript.sh install jq latest && $HOME/libscript/libscript.sh install sqlite latest && $HOME/libscript/libscript.sh install duckdb latest && $HOME/libscript/libscript.sh install huggingface-cli latest"
exit /b !errorlevel!

:: ## libscript_tpu_cycle_vm_for_backend
:: Releases device locks or reprovisions a fresh TPU VM on Windows when --fresh-vm-per-backend or runtime change is active.
:libscript_tpu_cycle_vm_for_backend
set "_tm_tpu=%~1"
set "_tm_bid=%~2"
set "_tm_repo=%~3"
set "_tm_cur_rt=%~4"
set "_tm_tpu_cli=%LIBSCRIPT_ROOT_DIR%\infrastructure\providers\gcp-tpu-vm\cli.cmd"

call :libscript_tpu_backend_spec "!_tm_bid!" >nul
for /f "tokens=4 delims=|" %%R in ("!TPU_BACKEND_SPEC!") do set "_tm_req_rt=%%R"

if "!_tm_cur_rt!"=="" if not "!_tm_req_rt!"=="" (
    set "_tm_ct_tmp=%TEMP%\tpu_cur_topo_!RANDOM!.json"
    call "!_tm_tpu_cli!" topology-info "!_tm_tpu!" > "!_tm_ct_tmp!" 2>nul
    if not errorlevel 1 (
        for /f "usebackq delims=" %%V in (`jq -r ".runtime_version // \"\"" "!_tm_ct_tmp!" 2^>nul`) do set "_tm_cur_rt=%%V"
    )
    del /f /q "!_tm_ct_tmp!" >nul 2>&1
)

if "!TPU_FRESH_VM_PER_BACKEND!"=="1" goto :do_cycle_vm
if /i "!TPU_FRESH_VM_PER_BACKEND!"=="true" goto :do_cycle_vm
if not "!_tm_req_rt!"=="" if not "!_tm_cur_rt!"=="" if /i not "!_tm_req_rt!"=="!_tm_cur_rt!" goto :do_cycle_vm

call "!_tm_tpu_cli!" release-locks "!_tm_tpu!"
exit /b !errorlevel!

:: ## do_cycle_vm
:: Tears down, audits postflight via tfrc_guard.cmd, and reprovisions a fresh TPU VM with auto-TTL and repo sync.
:do_cycle_vm
echo [TPU-MATRIX] Cycling fresh Cloud TPU VM !_tm_tpu! for backend !_tm_bid! ^(runtime=!_tm_req_rt!^)... 1>&2
call "!_tm_tpu_cli!" delete "!_tm_tpu!"
if errorlevel 1 exit /b !errorlevel!
call "%LIBSCRIPT_ROOT_DIR%\engine\common\tfrc_guard.cmd" :libscript_tfrc_is_enabled
if not errorlevel 1 if not "%TPU_ZONE%"=="" (
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\tfrc_guard.cmd" :libscript_tfrc_postflight_audit "%GCP_PROJECT_ID%" "%TPU_ZONE%" "!_tm_tpu!"
    if errorlevel 1 exit /b !errorlevel!
)
set "TPU_VERSION=!_tm_req_rt!"
call "!_tm_tpu_cli!" create "!_tm_tpu!"
if errorlevel 1 exit /b !errorlevel!
call "!_tm_tpu_cli!" wait-ready "!_tm_tpu!"
if errorlevel 1 exit /b !errorlevel!
set "_tm_ttl=%TFRC_MAX_TTL_MINUTES%"
if "!_tm_ttl!"=="" set "_tm_ttl=180"
call "!_tm_tpu_cli!" arm-ttl "!_tm_tpu!" --minutes "!_tm_ttl!"
if errorlevel 1 exit /b !errorlevel!
call :libscript_tpu_bootstrap_remote "!_tm_tpu!" "!_tm_repo!"
exit /b !errorlevel!

:: ## libscript_tpu_run_lockstep
:: Dispatches a workload across single-host or multi-host TPU workers with credential & coordinator env injection via gcp-tpu-vm cli.cmd.
:libscript_tpu_run_lockstep
set "_tm_tpu=%~1"
set "_tm_bid=%~2"
set "_tm_cmd=%~3"
set "_tm_log_dir=%~4"
set "_tm_tpu_cli=%LIBSCRIPT_ROOT_DIR%\infrastructure\providers\gcp-tpu-vm\cli.cmd"
if not exist "!_tm_log_dir!" mkdir "!_tm_log_dir!"

set "_tm_topo_f=%TEMP%\tpu_lk_topo_!RANDOM!.json"
call "!_tm_tpu_cli!" topology-info "!_tm_tpu!" > "!_tm_topo_f!"
if errorlevel 1 (
    del /f /q "!_tm_topo_f!" >nul 2>&1
    exit /b 1
)
set "_tm_wcnt=1"
set "_tm_ip0=127.0.0.1"
set "_tm_ips=127.0.0.1"
for /f "usebackq delims=" %%C in (`jq -r ".worker_count // 1" "!_tm_topo_f!" 2^>nul`) do set "_tm_wcnt=%%C"
for /f "usebackq delims=" %%I in (`jq -r ".worker0_internal_ip // \"127.0.0.1\"" "!_tm_topo_f!" 2^>nul`) do set "_tm_ip0=%%I"
for /f "usebackq delims=" %%L in (`jq -r ".worker_ips // \"127.0.0.1\"" "!_tm_topo_f!" 2^>nul`) do set "_tm_ips=%%L"

call :libscript_tpu_multihost_env "!_tm_bid!" "!_tm_topo_f!" "0" >nul
call :libscript_tpu_secret_exports
del /f /q "!_tm_topo_f!" >nul 2>&1

if "!_tm_wcnt!" leq "1" (
    call "!_tm_tpu_cli!" ssh "!_tm_tpu!" "--command=!_tm_sec_out!export !TPU_MULTIHOST_ENV!; !_tm_cmd!" > "!_tm_log_dir!\worker_0.log" 2>&1
    exit /b !errorlevel!
)

call :libscript_tpu_backend_spec "!_tm_bid!" >nul
for /f "tokens=7 delims=|" %%E in ("!TPU_BACKEND_SPEC!") do set "_tm_benv=%%E"
set "_tm_dist_extra="
for %%J in (jax_native maxtext keras_jax) do (
    if /i "!_tm_bid!"=="%%J" set "_tm_dist_extra=JAX_COORDINATOR_ADDRESS=!_tm_ip0!:8476 MEGASCALE_COORDINATOR_ADDRESS=!_tm_ip0!:8476"
)
for %%P in (hf_transformers pytorch_native keras_pytorch) do (
    if /i "!_tm_bid!"=="%%P" set "_tm_dist_extra=PJRT_DEVICE=TPU MASTER_ADDR=!_tm_ip0! MASTER_PORT=8477 PT_XLA_PJRT_DIST_SERVICE_ADDR=!_tm_ip0!:8477"
)
call "!_tm_tpu_cli!" ssh "!_tm_tpu!" --all-workers "--command=!_tm_sec_out!_wid=${TPU_WORKER_ID:-0}; export !_tm_benv! TPU_NUM_WORKERS=!_tm_wcnt! TPU_WORKER_HOSTNAMES=!_tm_ips! PROCESS_ID=${_wid} NUM_PROCESSES=!_tm_wcnt! !_tm_dist_extra!; !_tm_cmd!" > "!_tm_log_dir!\workers_all.log" 2>&1
exit /b !errorlevel!
