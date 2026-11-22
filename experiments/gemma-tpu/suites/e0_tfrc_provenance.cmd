@echo off
:: # e0_tfrc_provenance.cmd
:: ## Overview
:: Suite E0 runner on Windows validating TFRC_CONFIG and emitting e0_provenance.json with git SHA, dirty diff hash, TPU topology, wheel digests/versions, and Stage A probes.
:: ## Usage
:: e0_tfrc_provenance.cmd <repo_dir> <results_dir> <backends_csv>

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
if exist "!d!\libscript.cmd" ( set "LIBSCRIPT_ROOT_DIR=!d!" & exit /b 0 )
if exist "!d!\ROOT" ( set "LIBSCRIPT_ROOT_DIR=!d!" & exit /b 0 )
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" exit /b 1
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found
set "REPO_DIR=%~1"
set "RESULTS_DIR=%~2"
set "BACKENDS_CSV=%~3"
if "!BACKENDS_CSV!"=="" set "BACKENDS_CSV=hf_transformers,pytorch_native,keras_jax,keras_tensorflow,keras_pytorch,maxtext,jax_native"
set "SHM_ROOT=%GEMMA_TPU_SUITE_SHM_ROOT%"
if "!SHM_ROOT!"=="" set "SHM_ROOT=%TEMP%\libscript-tpu"
set "OUT_FILE=!RESULTS_DIR!\raw\e0_provenance.json"
if not exist "!RESULTS_DIR!\raw" mkdir "!RESULTS_DIR!\raw"

call "%LIBSCRIPT_ROOT_DIR%\engine\common\tfrc_guard.cmd" :libscript_tfrc_is_enabled
if not errorlevel 1 (
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\tfrc_guard.cmd" :libscript_tfrc_require_config "!REPO_DIR!"
    if errorlevel 1 exit /b !errorlevel!
)

set "_tree_hash=local"
for /f "usebackq delims=" %%H in (`call "%LIBSCRIPT_ROOT_DIR%\engine\common\remote_sync.cmd" compute-hash "!REPO_DIR!" 2^>nul`) do set "_tree_hash=%%H"

if not "%GEMMA_TPU_SUITE_RESUME%"=="0" if exist "!OUT_FILE!" (
    jq -e --arg th "!_tree_hash!" ".status == \"ok\" and .tree_hash == $th" "!OUT_FILE!" >nul 2>&1
    if not errorlevel 1 exit /b 0
)

set "_git_sha=untracked"
set "_dirty_hash=clean"
git -C "!REPO_DIR!" rev-parse HEAD >nul 2>&1
if not errorlevel 1 (
    for /f "usebackq delims=" %%G in (`git -C "!REPO_DIR!" rev-parse HEAD 2^>nul`) do set "_git_sha=%%G"
    set "_dirty_tmp=%TEMP%\e0_dirty_!RANDOM!.txt"
    git -C "!REPO_DIR!" status --porcelain > "!_dirty_tmp!" 2>nul
    for %%S in ("!_dirty_tmp!") do (
        REM wincheck disable=CMD2003
        if %%~zS gtr 0 (
            git -C "!REPO_DIR!" diff HEAD >> "!_dirty_tmp!" 2>nul
            for /f "skip=1 tokens=1" %%D in ('certutil -hashfile "!_dirty_tmp!" SHA256 2^>nul') do (
                if "!_dirty_hash!"=="clean" set "_dirty_hash=%%D"
            )
        )
    )
    del /f /q "!_dirty_tmp!" >nul 2>&1
)

set "_sku=%TPU_ACCELERATOR_TYPE%"
if "!_sku!"=="" set "_sku=v4-8"
set "_zone=%TPU_ZONE%"
if "!_zone!"=="" set "_zone=local"
set "_rt=%TPU_VERSION%"
if "!_rt!"=="" set "_rt=auto"

set "_wcnt=1"
set "_cph=4"
set "_tot_chips=4"
set "_ici=2x2x1"
if /i "!_sku!"=="v4-16" ( set "_wcnt=2" & set "_cph=4" & set "_tot_chips=8" & set "_ici=2x2x2" )
if /i "!_sku!"=="v4-32" ( set "_wcnt=4" & set "_cph=4" & set "_tot_chips=16" & set "_ici=2x2x4" )
if /i "!_sku!"=="v5litepod-8" ( set "_wcnt=1" & set "_cph=8" & set "_tot_chips=8" & set "_ici=2x4" )
if /i "!_sku!"=="v6e-8" ( set "_wcnt=1" & set "_cph=8" & set "_tot_chips=8" & set "_ici=2x4" )
if /i "!_sku!"=="v5litepod-16" ( set "_wcnt=2" & set "_cph=8" & set "_tot_chips=16" & set "_ici=4x4" )

set "_probes_f=%TEMP%\e0_probes_%RANDOM%.json"
echo [] > "!_probes_f!"

set "_list=!BACKENDS_CSV:,= !"
for %%B in (!_list!) do (
    call :probe_one_backend "%%B"
    if errorlevel 1 (
        del /f /q "!_probes_f!" >nul 2>&1
        exit /b !errorlevel!
    )
)

jq -n --arg git_sha "!_git_sha!" --arg dirty_hash "!_dirty_hash!" --arg tree_hash "!_tree_hash!" --arg sku "!_sku!" --arg rt "!_rt!" --arg zone "!_zone!" --arg tfrc_cfg "!TFRC_CONFIG!" --arg ici "!_ici!" --argjson wcnt !_wcnt! --argjson cph !_cph! --argjson tot_chips !_tot_chips! --slurpfile probes "!_probes_f!" "{subsuite: \"E0\", status: \"ok\", git_commit: $git_sha, dirty_diff_hash: $dirty_hash, tree_hash: $tree_hash, tfrc_config: $tfrc_cfg, tpu_zone: $zone, accelerator_type: $sku, runtime_version: $rt, topology: {worker_count: $wcnt, chips_per_host: $cph, total_chips: $tot_chips, ici_mesh: $ici}, stage_a_probes: $probes[0]}" > "!OUT_FILE!.tmp"
del /f /q "!_probes_f!" >nul 2>&1
jq -e . "!OUT_FILE!.tmp" >nul
if errorlevel 1 exit /b 1
move /y "!OUT_FILE!.tmp" "!OUT_FILE!" >nul
exit /b 0

:: ## probe_one_backend
:: Prepares isolated venv (when uv is available or synthetic mode is enabled) and records Stage A probe + wheel digest for one backend.
:probe_one_backend
set "_p_bid=%~1"
call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_backend_spec "!_p_bid!" "!SHM_ROOT!" >nul
if errorlevel 1 exit /b 1
for /f "tokens=1,3 delims=|" %%A in ("!TPU_BACKEND_SPEC!") do (
    set "_pvg=%%A"
    set "_p_kbe=%%B"
)
if /i "!_p_kbe!"=="none" set "_p_kbe="

set "_p_vdir=!SHM_ROOT!\venvs\!_pvg!"
where uv >nul 2>&1
if not errorlevel 1 (
    call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_prepare_backend_venv "!_p_bid!" "!REPO_DIR!" "!SHM_ROOT!" >nul
    if errorlevel 1 exit /b 1
    set "_p_vdir=!TPU_BACKEND_VENV_DIR!"
)

set "_p_stamp=none"
if exist "!_p_vdir!\.libscript_wheels.sha256" set /p _p_stamp=<"!_p_vdir!\.libscript_wheels.sha256"

set "KERAS_BACKEND=!_p_kbe!"
set "PJRT_DEVICE=TPU"
set "_pf=!RESULTS_DIR!\raw\probe_!_p_bid!.json"
call "!SCRIPT_DIR!\stage_ab_telemetry.cmd" :gemma_tpu_stage_a_probe "!_p_bid!" "!_p_vdir!\Scripts\python.exe" "!_pf!"
if errorlevel 1 exit /b 1

set "_wv_f=%TEMP%\e0_wv_%RANDOM%.json"
call "!SCRIPT_DIR!\stage_ab_telemetry.cmd" :gemma_tpu_collect_wheel_versions "!_p_vdir!\Scripts\python.exe" > "!_wv_f!"

jq --slurpfile p "!_pf!" --slurpfile wv "!_wv_f!" --arg vg "!_pvg!" --arg ws "!_p_stamp!" ". + [($p[0] + {venv_group: $vg, wheel_stamp: $ws, wheel_versions: $wv[0]})]" "!_probes_f!" > "!_probes_f!.tmp"
move /y "!_probes_f!.tmp" "!_probes_f!" >nul
del /f /q "!_wv_f!" >nul 2>&1
exit /b 0
