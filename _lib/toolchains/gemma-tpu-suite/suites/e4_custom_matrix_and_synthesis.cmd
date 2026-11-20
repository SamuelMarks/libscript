@echo off
:: # e4_custom_matrix_and_synthesis.cmd
:: ## Overview
:: Suite E4 Windows runner executing custom templated commands across backends and synthesizing comparison_summary.{json,csv,md} and generated_metrics.tex.
:: ## Usage
:: e4_custom_matrix_and_synthesis.cmd <repo_dir> <results_dir> <backends_csv>

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
set "MODEL_NAME=%GEMMA_TPU_SUITE_MODEL%"
if "!MODEL_NAME!"=="" set "MODEL_NAME=google/gemma-4-E4B"
set "SHM_ROOT=%GEMMA_TPU_SUITE_SHM_ROOT%"
if "!SHM_ROOT!"=="" set "SHM_ROOT=%TEMP%\libscript-tpu"
set "REQ_HBM=%GEMMA_TPU_SUITE_REQUIRE_HBM%"
if "!REQ_HBM!"=="" set "REQ_HBM=1"
if not exist "!RESULTS_DIR!\raw" mkdir "!RESULTS_DIR!\raw"

set "_tree_hash=local"
for /f "usebackq delims=" %%H in (`call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\remote_sync.cmd" compute-hash "!REPO_DIR!" 2^>nul`) do set "_tree_hash=%%H"

set "_tpl_f=%TEMP%\e4_tpl_%RANDOM%.txt"
type nul > "!_tpl_f!"
if not "%GEMMA_TPU_SUITE_SKIP_CUSTOM_EXEC%"=="1" (
    if not "!GEMMA_TPU_SUITE_COMMAND_TEMPLATE!"=="" echo.!GEMMA_TPU_SUITE_COMMAND_TEMPLATE!>> "!_tpl_f!"
    if exist "!REPO_DIR!\libscript.json" (
        jq -r "(.ml.command_matrix // [])[]" "!REPO_DIR!\libscript.json" >> "!_tpl_f!" 2>nul
    )
)

set "_t_idx=0"
for /f "usebackq delims=" %%T in ("!_tpl_f!") do (
    if not "%%T"=="" (
        set /a "_t_idx+=1"
        set "_cur_tpl=%%T"
        call :run_tpl_across_backends
        if errorlevel 1 (
            del /f /q "!_tpl_f!" >nul 2>&1
            exit /b !errorlevel!
        )
    )
)
del /f /q "!_tpl_f!" >nul 2>&1

set "_rows_f=%TEMP%\e4_rows_%RANDOM%.json"
echo [] > "!_rows_f!"
set "_list=!BACKENDS_CSV:,= !"
for %%B in (!_list!) do call :collect_backend_row "%%B"

set "_custom_f=%TEMP%\e4_custom_%RANDOM%.json"
echo [] > "!_custom_f!"
for %%C in ("!RESULTS_DIR!\raw\e4_custom_*.json") do (
    if exist "%%~fC" (
        jq --slurpfile c "%%~fC" ". + $c" "!_custom_f!" > "!_custom_f!.tmp"
        move /y "!_custom_f!.tmp" "!_custom_f!" >nul
    )
)

jq -n --arg model "!MODEL_NAME!" --slurpfile rows "!_rows_f!" --slurpfile custom "!_custom_f!" "(([ $rows[0][] | select(.backend_id == \"hf_transformers\") | .inference_tokens_per_sec ][0]) // 1) as $hf_base | (([ $rows[0][] | select(.backend_id == \"jax_native\") | .inference_tokens_per_sec ][0]) // 1) as $jax_base | {suite: \"gemma_tpu\", status: \"ok\", model: $model, backends: [$rows[0][] | . + {speedup_vs_hf_transformers: (if $hf_base > 0 then ((.inference_tokens_per_sec / $hf_base * 1000 | round) / 1000) else 1 end), speedup_vs_jax_native: (if $jax_base > 0 then ((.inference_tokens_per_sec / $jax_base * 1000 | round) / 1000) else 1 end)}], custom_workloads: $custom[0]}" > "!RESULTS_DIR!\comparison_summary.json.tmp"
del /f /q "!_rows_f!" "!_custom_f!" >nul 2>&1
jq -e . "!RESULTS_DIR!\comparison_summary.json.tmp" >nul
if errorlevel 1 exit /b 1
move /y "!RESULTS_DIR!\comparison_summary.json.tmp" "!RESULTS_DIR!\comparison_summary.json" >nul

jq -r "[\"backend_id\",\"inference_tokens_per_sec\",\"sql_execution_accuracy\",\"train_tokens_per_sec_per_chip\",\"peak_tpu_hbm_bytes\",\"speedup_vs_hf_transformers\",\"speedup_vs_jax_native\"], (.backends[] | [.backend_id, .inference_tokens_per_sec, .sql_execution_accuracy, .train_tokens_per_sec_per_chip, .peak_tpu_hbm_bytes, .speedup_vs_hf_transformers, .speedup_vs_jax_native]) | @csv" "!RESULTS_DIR!\comparison_summary.json" > "!RESULTS_DIR!\comparison_summary.csv.tmp"
move /y "!RESULTS_DIR!\comparison_summary.csv.tmp" "!RESULTS_DIR!\comparison_summary.csv" >nul

(
    echo # Gemma 4 7-Backend Cloud TPU Comparison ^(!MODEL_NAME!^)
    echo.
    echo ^| Backend ^| Inference tok/s ^| SQL Exec Acc ^| Train tok/s/chip ^| Peak HBM ^(B^) ^| vs HF ^| vs JAX ^|
    echo ^| :--- ^| ---: ^| ---: ^| ---: ^| ---: ^| ---: ^| ---: ^|
    REM wincheck disable=CMD1013
    REM wincheck disable=CMD1003
    jq -r ".backends[] | \"| `\(.backend_id)` | \(.inference_tokens_per_sec) | \(.sql_execution_accuracy) | \(.train_tokens_per_sec_per_chip) | \(.peak_tpu_hbm_bytes) | \(.speedup_vs_hf_transformers)x | \(.speedup_vs_jax_native)x |\"" "!RESULTS_DIR!\comparison_summary.json"
) > "!RESULTS_DIR!\comparison_summary.md.tmp"
move /y "!RESULTS_DIR!\comparison_summary.md.tmp" "!RESULTS_DIR!\comparison_summary.md" >nul

jq -r ".backends[] | \"\\newcommand{\\GemmaTpuTokPerSec\(.backend_id | gsub(\"_\"; \"\"))}{\(.inference_tokens_per_sec)}\"" "!RESULTS_DIR!\comparison_summary.json" > "!RESULTS_DIR!\generated_metrics.tex.tmp"
move /y "!RESULTS_DIR!\generated_metrics.tex.tmp" "!RESULTS_DIR!\generated_metrics.tex" >nul
exit /b 0

:: ## run_tpl_across_backends
:: Executes the current custom template across every selected backend in BACKENDS_CSV.
:run_tpl_across_backends
set "_be_list=!BACKENDS_CSV:,= !"
for %%B in (!_be_list!) do (
    call :run_tpl_one_backend "%%B"
    if errorlevel 1 exit /b !errorlevel!
)
exit /b 0

:: ## run_tpl_one_backend
:: Renders placeholders and runs one custom template cell with Stage B HBM verification and --resume skip.
:run_tpl_one_backend
set "_c_bid=%~1"
set "_cout=!RESULTS_DIR!\raw\e4_custom_!_t_idx!_!_c_bid!.json"
if not "%GEMMA_TPU_SUITE_RESUME%"=="0" if exist "!_cout!" (
    jq -e --arg th "!_tree_hash!" ".status == \"ok\" and .tree_hash == $th" "!_cout!" >nul 2>&1
    if not errorlevel 1 exit /b 0
)
call "%LIBSCRIPT_ROOT_DIR%\_lib\ml-training\_common\tpu_matrix.cmd" :libscript_tpu_backend_spec "!_c_bid!" "!SHM_ROOT!" >nul
for /f "tokens=2,3 delims=|" %%A in ("!TPU_BACKEND_SPEC!") do (
    set "_c_cbe=%%A"
    set "_c_kbe=%%B"
)
if /i "!_c_kbe!"=="none" set "_c_kbe="
set "_c_w_tmp=!RESULTS_DIR!\raw\.w_e4_!_t_idx!_!_c_bid!.json"
set "_rcmd="
for /f "usebackq delims=" %%R in (`jq -nr --arg tpl "!_cur_tpl!" --arg bid "!_c_bid!" --arg cbe "!_c_cbe!" --arg kbe "!_c_kbe!" --arg out "!_c_w_tmp!" --arg model "!MODEL_NAME!" --arg repo "!REPO_DIR!" "$tpl | gsub(\"\\{backend_id\\}\"; $bid) | gsub(\"\\{cli_backend\\}\"; $cbe) | gsub(\"\\{keras_backend\\}\"; $kbe) | gsub(\"\\{model\\}\"; $model) | gsub(\"\\{batch_size\\}\"; \"8\") | gsub(\"\\{output_json\\}\"; $out) | gsub(\"\\{repo_dir\\}\"; $repo)"`) do set "_rcmd=%%R"

set "KERAS_BACKEND=!_c_kbe!"
set "PJRT_DEVICE=TPU"
call "!SCRIPT_DIR!\stage_ab_telemetry.cmd" :gemma_tpu_exec_with_stage_b "!_c_bid!" "E4" "custom_!_t_idx!" "!SHM_ROOT!" "!REQ_HBM!" "!_cout!" "cd /d \"!REPO_DIR!\" && !_rcmd!"
if errorlevel 1 exit /b !errorlevel!

set "_c_pay={}"
if exist "!_c_w_tmp!" (
    for /f "usebackq delims=" %%P in (`jq -c "." "!_c_w_tmp!" 2^>nul`) do set "_c_pay=%%P"
    del /f /q "!_c_w_tmp!" >nul 2>&1
)
jq -n --arg th "!_tree_hash!" --arg bid "!_c_bid!" --arg tpl "!_cur_tpl!" --argjson idx !_t_idx! --argjson res "!_c_pay!" --argjson fd !STAGE_B_ACCEL_FD! --argjson hbm !STAGE_B_PEAK_HBM! "{subsuite: \"E4\", custom_index: $idx, backend_id: $bid, template: $tpl, tree_hash: $th, status: \"ok\", result: $res, telemetry: {accelerator_fd_opened: $fd, peak_tpu_hbm_bytes: $hbm}}" > "!_cout!.tmp"
jq -e . "!_cout!.tmp" >nul
if errorlevel 1 exit /b 1
move /y "!_cout!.tmp" "!_cout!" >nul
exit /b 0

:: ## collect_backend_row
:: Reads raw E1, E2, and E3 JSON metrics for a single backend and appends a comparison row.
:collect_backend_row
set "_rem_bid=%~1"
set "_r_tps=0"
set "_r_acc=0"
set "_r_tpsc=0"
set "_r_hbm=0"
if exist "!RESULTS_DIR!\raw\e1_inference_!_rem_bid!.json" (
    for /f "usebackq delims=" %%V in (`jq -r ".tokens_per_sec // 0" "!RESULTS_DIR!\raw\e1_inference_!_rem_bid!.json"`) do set "_r_tps=%%V"
    for /f "usebackq delims=" %%V in (`jq -r ".telemetry.peak_tpu_hbm_bytes // 0" "!RESULTS_DIR!\raw\e1_inference_!_rem_bid!.json"`) do set "_r_hbm=%%V"
)
if exist "!RESULTS_DIR!\raw\e2_sql_eval_!_rem_bid!.json" (
    for /f "usebackq delims=" %%V in (`jq -r ".execution_accuracy // 0" "!RESULTS_DIR!\raw\e2_sql_eval_!_rem_bid!.json"`) do set "_r_acc=%%V"
)
if exist "!RESULTS_DIR!\raw\e3_training_!_rem_bid!.json" (
    for /f "usebackq delims=" %%V in (`jq -r ".tokens_per_sec_per_chip // 0" "!RESULTS_DIR!\raw\e3_training_!_rem_bid!.json"`) do set "_r_tpsc=%%V"
)
jq --arg b "!_rem_bid!" --argjson tps !_r_tps! --argjson acc !_r_acc! --argjson tpsc !_r_tpsc! --argjson hbm !_r_hbm! ". + [{backend_id: $b, inference_tokens_per_sec: $tps, sql_execution_accuracy: $acc, train_tokens_per_sec_per_chip: $tpsc, peak_tpu_hbm_bytes: $hbm}]" "!_rows_f!" > "!_rows_f!.tmp"
move /y "!_rows_f!.tmp" "!_rows_f!" >nul
exit /b 0
