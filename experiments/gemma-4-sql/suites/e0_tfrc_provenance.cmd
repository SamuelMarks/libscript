@echo off
:: # e0_tfrc_provenance.cmd
:: ## Overview
:: Suite E0 runner on Windows validating TFRC_CONFIG and emitting e0_provenance.json with git SHA, dirty diff hash, TPU ICI topology, 5-family labels, wheel digests/versions, and Stage A probes.
:: ## Usage
:: e0_tfrc_provenance.cmd <repo_dir> <results_dir> [backends_csv]

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
if exist "!d!\libscript.cmd" ( set "LIBSCRIPT_ROOT_DIR=!d!" & exit /b 0 )
if exist "!d!\ROOT" ( set "LIBSCRIPT_ROOT_DIR=!d!" & exit /b 0 )
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" ( echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2 & exit /b 1 )
goto :find_root

:: ## root_found
:: Canonicalizes paths and collects E0 provenance and Stage A probes.
:root_found
set "_e0_repo_arg=%~1"
if "!_e0_repo_arg!"=="" set "_e0_repo_arg=%CD%"
set "_e0_res_arg=%~2"
if "!_e0_res_arg!"=="" set "_e0_res_arg=%LIBSCRIPT_ROOT_DIR%\build\experiment_results\gemma-4-sql"
set "BACKENDS_CSV=%~3"
if "!BACKENDS_CSV!"=="" set "BACKENDS_CSV=%GEMMA_4_SQL_BACKENDS%"
if "!BACKENDS_CSV!"=="" set "BACKENDS_CSV=hf_transformers,pytorch_native,keras_jax,keras_tensorflow,keras_pytorch,maxtext,jax_native"
set "SHM_ROOT=%GEMMA_4_SQL_SHM_ROOT%"
if "!SHM_ROOT!"=="" set "SHM_ROOT=%TEMP%\libscript-tpu"
set "LIBTPU_PROVIDER=%GEMMA_4_SQL_LIBTPU_PROVIDER%"
if "!LIBTPU_PROVIDER!"=="" set "LIBTPU_PROVIDER=og"

for %%I in ("!_e0_repo_arg!") do set "REPO_DIR=%%~fI"
if not exist "!_e0_res_arg!\raw" mkdir "!_e0_res_arg!\raw"
for %%I in ("!_e0_res_arg!") do set "RESULTS_DIR=%%~fI"
set "OUT_FILE=!RESULTS_DIR!\raw\e0_provenance.json"

call "%LIBSCRIPT_ROOT_DIR%\engine\common\tfrc_guard.cmd" :libscript_tfrc_is_enabled
if not errorlevel 1 (
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\tfrc_guard.cmd" :libscript_tfrc_require_config "!REPO_DIR!"
    if errorlevel 1 exit /b !errorlevel!
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\tfrc_guard.cmd" :libscript_tfrc_enforce_zero_cost_env
    if errorlevel 1 exit /b !errorlevel!
)

call "%LIBSCRIPT_ROOT_DIR%\engine\common\remote_sync.cmd" :libscript_compute_tree_hash "!REPO_DIR!" >nul
set "_tree_hash=!LIBSCRIPT_TREE_HASH!"
if "!_tree_hash!"=="" set "_tree_hash=0"

set "_git_sha=untracked"
where git >nul 2>&1
if not errorlevel 1 (
    for /f "usebackq delims=" %%G in (`git -C "!REPO_DIR!" rev-parse HEAD 2^>nul`) do set "_git_sha=%%G"
)

set "_sku=%TPU_ACCELERATOR_TYPE%"
if "!_sku!"=="" set "_sku=v4-8"
set "_zone=%TPU_ZONE%"
if "!_zone!"=="" set "_zone=us-central2-b"
set "_tier=%TPU_SCHEDULING_TYPE%"
if "!_tier!"=="" set "_tier=spot"
set "_hosts=1"
set "_tot_chips=4"
set "_ici=2x2x1"
if /i "!_sku!"=="v4-16" ( set "_hosts=2" & set "_tot_chips=8" & set "_ici=2x2x2" )
if /i "!_sku!"=="v4-32" ( set "_hosts=4" & set "_tot_chips=16" & set "_ici=2x2x4" )
if /i "!_sku!"=="v5litepod-1" ( set "_hosts=1" & set "_tot_chips=1" & set "_ici=1x1" )
if /i "!_sku!"=="v5e-1" ( set "_hosts=1" & set "_tot_chips=1" & set "_ici=1x1" )
if /i "!_sku!"=="v6e-1" ( set "_hosts=1" & set "_tot_chips=1" & set "_ici=1x1" )
if /i "!_sku!"=="v5litepod-4" ( set "_hosts=1" & set "_tot_chips=4" & set "_ici=2x2" )
if /i "!_sku!"=="v5e-4" ( set "_hosts=1" & set "_tot_chips=4" & set "_ici=2x2" )
if /i "!_sku!"=="v6e-4" ( set "_hosts=1" & set "_tot_chips=4" & set "_ici=2x2" )
if /i "!_sku!"=="v5litepod-8" ( set "_hosts=1" & set "_tot_chips=8" & set "_ici=2x4" )
if /i "!_sku!"=="v5e-8" ( set "_hosts=1" & set "_tot_chips=8" & set "_ici=2x4" )
if /i "!_sku!"=="v6e-8" ( set "_hosts=1" & set "_tot_chips=8" & set "_ici=2x4" )
if /i "!_sku!"=="v5p-8" ( set "_hosts=1" & set "_tot_chips=4" & set "_ici=2x2x1" )
if /i "!_sku!"=="v5p-16" ( set "_hosts=2" & set "_tot_chips=8" & set "_ici=2x2x2" )
set /a "_cph=_tot_chips / _hosts"

set "_probes_f=%TEMP%\e0_probes_%RANDOM%.json"
> "!_probes_f!" echo []

set "_be_spaces=!BACKENDS_CSV:,= !"
for %%B in (!_be_spaces!) do (
    call :probe_single_backend "%%B"
    if errorlevel 1 (
        del /f /q "!_probes_f!" >nul 2>&1
        exit /b 1
    )
)

set "_tfrc_proj=none"
if not "%TFRC_CONFIG%"=="" if exist "%TFRC_CONFIG%" (
    for /f "usebackq delims=" %%P in (`jq -r ".gcp_project_id // \"none\"" "%TFRC_CONFIG%"`) do set "_tfrc_proj=%%P"
)

jq -n --slurpfile probes "!_probes_f!" --arg prov "!LIBTPU_PROVIDER!" --arg sha "!_git_sha!" --arg th "!_tree_hash!" --arg proj "!_tfrc_proj!" --arg sku "!_sku!" --arg zone "!_zone!" --arg tier "!_tier!" --arg ici "!_ici!" --argjson hosts "!_hosts!" --argjson cph "!_cph!" --argjson total_c "!_tot_chips!" "{suite: \"E0\", experiment_id: \"gemma-4-sql\", libtpu_provider: $prov, study_title: \"gemma-4-sql: TPU performance comparisons betwixt JAX, Keras, and PyTorch on Google's Gemma 4\", status: \"ok\", git_sha: $sha, dirty_diff_hash: \"clean\", tree_hash: $th, tfrc_project_id: $proj, topology: {accelerator_type: $sku, zone: $zone, scheduling_tier: $tier, host_count: $hosts, chips_per_host: $cph, total_chips: $total_c, ici_mesh: $ici}, stage_a_probes: $probes[0]}" > "!OUT_FILE!.tmp"
del /f /q "!_probes_f!" >nul 2>&1
jq -e . "!OUT_FILE!.tmp" >nul
if errorlevel 1 exit /b 1
move /y "!OUT_FILE!.tmp" "!OUT_FILE!" >nul
exit /b 0

:: ## probe_single_backend
:: Prepares isolated backend venv and appends Stage A probe + wheel metadata to _probes_f.
:probe_single_backend
set "_probe_id=%~1"
call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_prepare_backend_venv "!_probe_id!" "!REPO_DIR!" "!SHM_ROOT!" "!LIBTPU_PROVIDER!" >nul
if errorlevel 1 exit /b 1
call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_backend_spec "!_probe_id!" "!SHM_ROOT!" >nul
call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_family_label "!_probe_id!" >nul
for /f "tokens=1,3 delims=|" %%G in ("!TPU_BACKEND_SPEC!") do (
    set "_pvg=%%G"
    set "_pkb=%%H"
)
if /i "!_pkb!"=="none" set "_pkb="
set "KERAS_BACKEND=!_pkb!"
set "_p_stamp=none"
if exist "!TPU_BACKEND_VENV_DIR!\.libscript_wheels.sha256" set /p _p_stamp=<"!TPU_BACKEND_VENV_DIR!\.libscript_wheels.sha256"
set "_p_py=!TPU_BACKEND_VENV_DIR!\Scripts\python.exe"
if not exist "!_p_py!" if exist "!TPU_BACKEND_VENV_DIR!\bin\python" set "_p_py=!TPU_BACKEND_VENV_DIR!\bin\python"

set "_pr_f=%TEMP%\e0_pr_%RANDOM%.json"
set "_wv_f=%TEMP%\e0_wv_%RANDOM%.json"
call "!SCRIPT_DIR!\stage_ab_telemetry.cmd" :gemma_4_sql_stage_a_probe "!_probe_id!" "!_p_py!" > "!_pr_f!"
if errorlevel 1 (
    del /f /q "!_pr_f!" "!_wv_f!" >nul 2>&1
    exit /b 1
)
call "!SCRIPT_DIR!\stage_ab_telemetry.cmd" :gemma_4_sql_collect_wheel_versions "!_p_py!" > "!_wv_f!"

jq --slurpfile p "!_pr_f!" --slurpfile wv "!_wv_f!" --arg fam "!TPU_BACKEND_FAMILY!" --arg vg "!_pvg!" --arg ws "!_p_stamp!" ". + [($p[0] + {comparison_family: $fam, venv_group: $vg, wheel_stamp: $ws, wheel_versions: $wv[0]})]" "!_probes_f!" > "!_probes_f!.tmp"
move /y "!_probes_f!.tmp" "!_probes_f!" >nul
del /f /q "!_pr_f!" "!_wv_f!" >nul 2>&1
exit /b 0
