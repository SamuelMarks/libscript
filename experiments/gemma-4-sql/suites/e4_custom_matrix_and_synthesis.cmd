@echo off
:: # e4_custom_matrix_and_synthesis.cmd
:: ## Overview
:: Suite E4 Windows runner executing custom templated commands across backends and synthesizing 5-family + 7-backend comparison_summary.{json,csv,md} and \gemmaFourSql* generated_metrics.tex.
:: ## Usage
:: e4_custom_matrix_and_synthesis.cmd <repo_dir> <results_dir> [backends_csv]

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
:: Canonicalizes paths, executes custom command templates, and synthesizes comparison artifacts.
:root_found
set "_e4_repo_arg=%~1"
if "!_e4_repo_arg!"=="" set "_e4_repo_arg=%CD%"
set "_e4_res_arg=%~2"
if "!_e4_res_arg!"=="" set "_e4_res_arg=%LIBSCRIPT_ROOT_DIR%\build\experiment_results\gemma-4-sql"
set "BACKENDS_CSV=%~3"
if "!BACKENDS_CSV!"=="" set "BACKENDS_CSV=%GEMMA_4_SQL_BACKENDS%"
if "!BACKENDS_CSV!"=="" set "BACKENDS_CSV=hf_transformers,pytorch_native,keras_jax,keras_tensorflow,keras_pytorch,maxtext,jax_native"
set "MODEL_NAME=%GEMMA_4_SQL_MODEL%"
if "!MODEL_NAME!"=="" set "MODEL_NAME=google/gemma-4-E4B"
set "SHM_ROOT=%GEMMA_4_SQL_SHM_ROOT%"
if "!SHM_ROOT!"=="" set "SHM_ROOT=%TEMP%\libscript-tpu"

for %%I in ("!_e4_repo_arg!") do set "REPO_DIR=%%~fI"
if not exist "!_e4_res_arg!\raw" mkdir "!_e4_res_arg!\raw"
for %%I in ("!_e4_res_arg!") do set "RESULTS_DIR=%%~fI"

call "%LIBSCRIPT_ROOT_DIR%\engine\common\remote_sync.cmd" :libscript_compute_tree_hash "!REPO_DIR!" >nul
set "_tree_hash=!LIBSCRIPT_TREE_HASH!"

set "_tpl_f=%TEMP%\e4_tpl_%RANDOM%.txt"
type nul > "!_tpl_f!"
if not "%GEMMA_4_SQL_SKIP_CUSTOM_EXEC%"=="1" (
    if not "!GEMMA_4_SQL_COMMAND_TEMPLATE!"=="" (
        >> "!_tpl_f!" echo.!GEMMA_4_SQL_COMMAND_TEMPLATE!
    )
    if exist "!REPO_DIR!\libscript.json" (
        jq -r "if (.ml.command_matrix | type) == \"array\" then .ml.command_matrix[] elif (.ml.command_matrix | type) == \"string\" then .ml.command_matrix else empty end" "!REPO_DIR!\libscript.json" >> "!_tpl_f!" 2>nul
    )
)

set "_t_idx=0"
for /f "usebackq delims=" %%T in ("!_tpl_f!") do (
    set "_cur_tpl=%%T"
    if not "!_cur_tpl!"=="" (
        set "_be_sp=!BACKENDS_CSV:,= !"
        for %%B in (!_be_sp!) do (
            call :exec_custom_cell "!_t_idx!" "%%B" "!_cur_tpl!"
            if errorlevel 1 (
                set "_ce_rc=!errorlevel!"
                del /f /q "!_tpl_f!" >nul 2>&1
                exit /b !_ce_rc!
            )
        )
        set /a "_t_idx+=1"
    )
)
del /f /q "!_tpl_f!" >nul 2>&1

set "_rows_f=%TEMP%\e4_rows_%RANDOM%.json"
> "!_rows_f!" echo []
set "_be_sp=!BACKENDS_CSV:,= !"
for %%B in (!_be_sp!) do (
    call :append_summary_row "%%B"
)

set "_custom_f=%TEMP%\e4_custom_%RANDOM%.json"
> "!_custom_f!" echo []
for %%C in ("!RESULTS_DIR!\raw\e4_custom_*.json") do (
    if exist "%%~fC" (
        jq --slurpfile c "%%~fC" ". + $c" "!_custom_f!" > "!_custom_f!.tmp"
        move /y "!_custom_f!.tmp" "!_custom_f!" >nul
    )
)

set "_jq_f=%TEMP%\e4_synth_%RANDOM%.jq"
> "!_jq_f!" echo (($rows[0] ^| map(select(.backend_id == "hf_transformers") ^| .inference_tokens_per_sec)[0]) // ($rows[0][0].inference_tokens_per_sec // 1)) as $bt ^|
>> "!_jq_f!" echo (if $bt ^<= 0 then 1 else $bt end) as $sb ^|
>> "!_jq_f!" echo (($rows[0] ^| map(select(.backend_id == "hf_transformers") ^| .train_tokens_per_sec_per_chip)[0]) // ($rows[0][0].train_tokens_per_sec_per_chip // 1)) as $btr ^|
>> "!_jq_f!" echo (if $btr ^<= 0 then 1 else $btr end) as $str ^|
>> "!_jq_f!" echo ($rows[0] ^| map(. + {relative_inference_speedup: (((.inference_tokens_per_sec / $sb) * 1000 ^| round) / 1000), relative_training_speedup: (((.train_tokens_per_sec_per_chip / $str) * 1000 ^| round) / 1000)})) as $enr ^|
>> "!_jq_f!" echo (["Hugging Face Transformers [which wraps PyTorch]","PyTorch [native]","Keras [and its JAX, TensorFlow, and PyTorch backends]","MaxText [which wraps JAX]","JAX [native]"] ^| map(. as $f ^| ($enr ^| map(select(.comparison_family == $f))) as $g ^| select(($g ^| length) ^> 0) ^| {comparison_family: $f, backend_cells: ($g ^| map(.backend_id)), peak_inference_tokens_per_sec: ($g ^| map(.inference_tokens_per_sec) ^| max), mean_sql_execution_accuracy: ((($g ^| map(.sql_execution_accuracy) ^| add) / ($g ^| length)) * 10000 ^| round / 10000), peak_train_tokens_per_sec_per_chip: ($g ^| map(.train_tokens_per_sec_per_chip) ^| max)})) as $fams ^|
>> "!_jq_f!" echo {suite: "gemma-4-sql", title: "gemma-4-sql: TPU performance comparisons betwixt JAX, Keras, and PyTorch on Google's Gemma 4", model: $m, baseline_backend: "hf_transformers", comparison_families: $fams, backends: $enr, custom_workloads: $custom[0]}

jq -n --slurpfile rows "!_rows_f!" --slurpfile custom "!_custom_f!" --arg m "!MODEL_NAME!" -f "!_jq_f!" > "!RESULTS_DIR!\comparison_summary.json.tmp"
del /f /q "!_rows_f!" "!_custom_f!" "!_jq_f!" >nul 2>&1
jq -e . "!RESULTS_DIR!\comparison_summary.json.tmp" >nul
if errorlevel 1 exit /b 1
move /y "!RESULTS_DIR!\comparison_summary.json.tmp" "!RESULTS_DIR!\comparison_summary.json" >nul

jq -r "[\"backend_id\",\"comparison_family\",\"prefill_tokens_per_sec\",\"inference_tokens_per_sec\",\"cold_compile_ms\",\"sqlite_execution_accuracy\",\"duckdb_execution_accuracy\",\"sql_execution_accuracy\",\"train_tokens_per_sec_per_chip\",\"peak_tpu_hbm_bytes\",\"relative_inference_speedup\",\"relative_training_speedup\"], (.backends[] | [.backend_id, .comparison_family, .prefill_tokens_per_sec, .inference_tokens_per_sec, .cold_compile_ms, .sqlite_execution_accuracy, .duckdb_execution_accuracy, .sql_execution_accuracy, .train_tokens_per_sec_per_chip, .peak_tpu_hbm_bytes, .relative_inference_speedup, .relative_training_speedup]) | @csv" "!RESULTS_DIR!\comparison_summary.json" > "!RESULTS_DIR!\comparison_summary.csv.tmp"
move /y "!RESULTS_DIR!\comparison_summary.csv.tmp" "!RESULTS_DIR!\comparison_summary.csv" >nul

> "!RESULTS_DIR!\comparison_summary.md.tmp" echo # gemma-4-sql: TPU performance comparisons betwixt JAX, Keras, and PyTorch on Google's Gemma 4
>> "!RESULTS_DIR!\comparison_summary.md.tmp" echo.
>> "!RESULTS_DIR!\comparison_summary.md.tmp" echo ^| Backend ^| Family ^| Prefill tok/s ^| Decode tok/s ^| SQLite Acc ^| DuckDB Acc ^| Train tok/s/chip ^| Peak TPU HBM ^(B^) ^| Speedup ^|
>> "!RESULTS_DIR!\comparison_summary.md.tmp" echo ^| :--- ^| :--- ^| ---: ^| ---: ^| ---: ^| ---: ^| ---: ^| ---: ^| ---: ^|
jq -r ".backends[] | \"| `\" + .backend_id + \"` | \" + .comparison_family + \" | \" + (.prefill_tokens_per_sec|tostring) + \" | \" + (.inference_tokens_per_sec|tostring) + \" | \" + (.sqlite_execution_accuracy|tostring) + \" | \" + (.duckdb_execution_accuracy|tostring) + \" | \" + (.train_tokens_per_sec_per_chip|tostring) + \" | \" + (.peak_tpu_hbm_bytes|tostring) + \" | \" + (.relative_inference_speedup|tostring) + \"x |\"" "!RESULTS_DIR!\comparison_summary.json" >> "!RESULTS_DIR!\comparison_summary.md.tmp"
move /y "!RESULTS_DIR!\comparison_summary.md.tmp" "!RESULTS_DIR!\comparison_summary.md" >nul

> "!RESULTS_DIR!\generated_metrics.tex.tmp" echo %% Auto-generated by experiments\gemma-4-sql\suites\e4_custom_matrix_and_synthesis.cmd
>> "!RESULTS_DIR!\generated_metrics.tex.tmp" echo \providecommand{\gemmaFourSqlStudyTitle}{gemma-4-sql: TPU performance comparisons betwixt JAX, Keras, and PyTorch on Google's Gemma 4}
jq -r ".backends[] | \"\\providecommand{\\gemmaFourSql\" + .tex_slug + \"PrefillTps}{\" + (.prefill_tokens_per_sec|tostring) + \"}\n\\providecommand{\\gemmaFourSql\" + .tex_slug + \"DecodeTps}{\" + (.inference_tokens_per_sec|tostring) + \"}\n\\providecommand{\\gemmaFourSql\" + .tex_slug + \"CompileMs}{\" + (.cold_compile_ms|tostring) + \"}\n\\providecommand{\\gemmaFourSql\" + .tex_slug + \"SqlAcc}{\" + (.sql_execution_accuracy|tostring) + \"}\n\\providecommand{\\gemmaFourSql\" + .tex_slug + \"DuckdbAcc}{\" + (.duckdb_execution_accuracy|tostring) + \"}\n\\providecommand{\\gemmaFourSql\" + .tex_slug + \"TrainTpsChip}{\" + (.train_tokens_per_sec_per_chip|tostring) + \"}\n\\providecommand{\\gemmaFourSql\" + .tex_slug + \"PeakHbmGiB}{\" + ((((.peak_tpu_hbm_bytes / 1073741824) * 100 | round) / 100)|tostring) + \"}\"" "!RESULTS_DIR!\comparison_summary.json" >> "!RESULTS_DIR!\generated_metrics.tex.tmp"
move /y "!RESULTS_DIR!\generated_metrics.tex.tmp" "!RESULTS_DIR!\generated_metrics.tex" >nul
exit /b 0

:: ## exec_custom_cell
:: Expands and executes a single custom command template cell with Stage B telemetry verification.
:exec_custom_cell
set "_ec_idx=%~1"
set "_ec_bid=%~2"
set "_ec_tpl=%~3"
set "_ec_out=!RESULTS_DIR!\raw\e4_custom_!_ec_idx!_!_ec_bid!.json"
if not "%GEMMA_4_SQL_RESUME%"=="0" if exist "!_ec_out!" (
    jq -e --arg th "!_tree_hash!" ".status == \"ok\" and .tree_hash == $th" "!_ec_out!" >nul 2>&1
    if not errorlevel 1 exit /b 0
)
call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_prepare_backend_venv "!_ec_bid!" "!REPO_DIR!" "!SHM_ROOT!" >nul
if errorlevel 1 exit /b 1
call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_backend_spec "!_ec_bid!" "!SHM_ROOT!" >nul
for /f "tokens=2,3 delims=|" %%C in ("!TPU_BACKEND_SPEC!") do (
    set "_ec_cbe=%%C"
    set "_ec_kbe=%%D"
)
if /i "!_ec_kbe!"=="none" set "_ec_kbe="
set "KERAS_BACKEND=!_ec_kbe!"
set "PATH=!TPU_BACKEND_VENV_DIR!\Scripts;!TPU_BACKEND_VENV_DIR!\bin;!PATH!"
set "_ec_raw=!RESULTS_DIR!\raw\.w_e4_!_ec_idx!_!_ec_bid!.json"
del /f /q "!_ec_raw!" >nul 2>&1

for /f "usebackq delims=" %%X in (`jq -rn --arg tpl "!_ec_tpl!" --arg bid "!_ec_bid!" --arg cbe "!_ec_cbe!" --arg kbe "!_ec_kbe!" --arg out "!_ec_raw!" --arg model "!MODEL_NAME!" --arg repo "!REPO_DIR!" --arg res "!RESULTS_DIR!" "$tpl | gsub(\"\\\\{backend\\\\}\"; $bid) | gsub(\"\\\\{cli_backend\\\\}\"; $cbe) | gsub(\"\\\\{keras_backend\\\\}\"; $kbe) | gsub(\"\\\\{model\\\\}\"; $model) | gsub(\"\\\\{batch_size\\\\}\"; \"8\") | gsub(\"\\\\{output_json\\\\}\"; $out) | gsub(\"\\\\{repo_dir\\\\}\"; $repo) | gsub(\"\\\\{results_dir\\\\}\"; $res)"`) do set "_exp_cmd=%%X"

call "!SCRIPT_DIR!\stage_ab_telemetry.cmd" :gemma_4_sql_exec_with_stage_b "!_ec_bid!" "cd /d \"!REPO_DIR!\" && !_exp_cmd!" "!_ec_out!" "%GEMMA_4_SQL_REQUIRE_HBM%" "!_ec_raw!"
if errorlevel 1 exit /b !errorlevel!

set "_pay_f=%TEMP%\e4_pay_%RANDOM%.json"
if exist "!_ec_raw!" (
    copy /y "!_ec_raw!" "!_pay_f!" >nul
    del /f /q "!_ec_raw!" >nul 2>&1
) else (
    > "!_pay_f!" echo {}
)
jq -n --slurpfile p "!_pay_f!" --arg b "!_ec_bid!" --arg th "!_tree_hash!" --arg cmd "!_exp_cmd!" --argjson idx !_ec_idx! --argjson hbm !STAGE_B_PEAK_HBM! "{suite: \"E4\", experiment_id: \"gemma-4-sql\", backend_id: $b, template_index: $idx, status: \"ok\", tree_hash: $th, command: $cmd, workload_output: $p[0], peak_tpu_hbm_bytes: $hbm}" > "!_ec_out!.tmp"
del /f /q "!_pay_f!" >nul 2>&1
move /y "!_ec_out!.tmp" "!_ec_out!" >nul
exit /b 0

:: ## append_summary_row
:: Reads E1, E2, and E3 JSON cells for a backend and appends a row object to _rows_f.
:append_summary_row
set "_asr_b=%~1"
call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_family_label "!_asr_b!" >nul
set "_asr_slug=Custom"
if /i "!_asr_b!"=="hf_transformers" set "_asr_slug=HfTransformers"
if /i "!_asr_b!"=="pytorch_native" set "_asr_slug=PytorchNative"
if /i "!_asr_b!"=="keras_jax" set "_asr_slug=KerasJax"
if /i "!_asr_b!"=="keras_tensorflow" set "_asr_slug=KerasTensorflow"
if /i "!_asr_b!"=="keras_pytorch" set "_asr_slug=KerasPytorch"
if /i "!_asr_b!"=="maxtext" set "_asr_slug=Maxtext"
if /i "!_asr_b!"=="jax_native" set "_asr_slug=JaxNative"

set "_asr_pre=0"
set "_asr_tps=0"
set "_asr_cms=0"
set "_asr_p50=0"
set "_asr_p99=0"
set "_asr_sqa=0"
set "_asr_dka=0"
set "_asr_acc=0"
set "_asr_tpsc=0"
set "_asr_hbm=0"
if exist "!RESULTS_DIR!\raw\e1_inference_!_asr_b!.json" (
    for /f "usebackq delims=" %%V in (`jq -r ".prefill_tokens_per_sec // 0" "!RESULTS_DIR!\raw\e1_inference_!_asr_b!.json"`) do set "_asr_pre=%%V"
    for /f "usebackq delims=" %%V in (`jq -r ".decode_tokens_per_sec // 0" "!RESULTS_DIR!\raw\e1_inference_!_asr_b!.json"`) do set "_asr_tps=%%V"
    for /f "usebackq delims=" %%V in (`jq -r ".cold_compile_ms // 0" "!RESULTS_DIR!\raw\e1_inference_!_asr_b!.json"`) do set "_asr_cms=%%V"
    for /f "usebackq delims=" %%V in (`jq -r ".latency_ms.p50 // 0" "!RESULTS_DIR!\raw\e1_inference_!_asr_b!.json"`) do set "_asr_p50=%%V"
    for /f "usebackq delims=" %%V in (`jq -r ".latency_ms.p99 // 0" "!RESULTS_DIR!\raw\e1_inference_!_asr_b!.json"`) do set "_asr_p99=%%V"
    for /f "usebackq delims=" %%V in (`jq -r ".telemetry.peak_tpu_hbm_bytes // 0" "!RESULTS_DIR!\raw\e1_inference_!_asr_b!.json"`) do set "_asr_hbm=%%V"
)
if exist "!RESULTS_DIR!\raw\e2_sql_eval_!_asr_b!.json" (
    for /f "usebackq delims=" %%V in (`jq -r ".sqlite_execution_accuracy // 0" "!RESULTS_DIR!\raw\e2_sql_eval_!_asr_b!.json"`) do set "_asr_sqa=%%V"
    for /f "usebackq delims=" %%V in (`jq -r ".duckdb_execution_accuracy // 0" "!RESULTS_DIR!\raw\e2_sql_eval_!_asr_b!.json"`) do set "_asr_dka=%%V"
    for /f "usebackq delims=" %%V in (`jq -r ".sql_execution_accuracy // 0" "!RESULTS_DIR!\raw\e2_sql_eval_!_asr_b!.json"`) do set "_asr_acc=%%V"
)
if exist "!RESULTS_DIR!\raw\e3_training_!_asr_b!.json" (
    for /f "usebackq delims=" %%V in (`jq -r ".peft_tokens_per_sec_per_chip // 0" "!RESULTS_DIR!\raw\e3_training_!_asr_b!.json"`) do set "_asr_tpsc=%%V"
    if "!_asr_hbm!"=="0" for /f "usebackq delims=" %%V in (`jq -r ".telemetry.peak_tpu_hbm_bytes // 0" "!RESULTS_DIR!\raw\e3_training_!_asr_b!.json"`) do set "_asr_hbm=%%V"
)
jq --arg b "!_asr_b!" --arg fam "!TPU_BACKEND_FAMILY!" --arg slug "!_asr_slug!" --argjson pre !_asr_pre! --argjson tps !_asr_tps! --argjson cms !_asr_cms! --argjson p50 !_asr_p50! --argjson p99 !_asr_p99! --argjson sqa !_asr_sqa! --argjson dka !_asr_dka! --argjson acc !_asr_acc! --argjson tpsc !_asr_tpsc! --argjson hbm !_asr_hbm! ". + [{backend_id: $b, comparison_family: $fam, tex_slug: $slug, prefill_tokens_per_sec: $pre, inference_tokens_per_sec: $tps, cold_compile_ms: $cms, latency_p50_ms: $p50, latency_p99_ms: $p99, sqlite_execution_accuracy: $sqa, duckdb_execution_accuracy: $dka, sql_execution_accuracy: $acc, train_tokens_per_sec_per_chip: $tpsc, peak_tpu_hbm_bytes: $hbm}]" "!_rows_f!" > "!_rows_f!.tmp"
move /y "!_rows_f!.tmp" "!_rows_f!" >nul
exit /b 0
