@echo off
:: # synthesize_ab.cmd
:: ## Overview
:: Differential synthesis Windows runner (`synthesize_ab.cmd`) for `gemma-4-sql-libtpu`: Verifies Stage A `libtpu.so` SHA-256 distinctness (`og` != `rs`) and synthesizes `ab_comparison_summary.{json,csv,md}` and `generated_metrics.tex`.
:: ## Usage
:: synthesize_ab.cmd <repo_dir> <results_dir> [backends_csv]

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
if "!d!"=="" ( echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2 & exit /b 1 )
goto :find_root

:: ## root_found
:: Verifies per-provider provenance digests and emits A/B summary and LaTeX outputs.
:root_found
set "_repo_arg=%~1"
if "!_repo_arg!"=="" set "_repo_arg=%CD%"
set "_res_arg=%~2"
if "!_res_arg!"=="" set "_res_arg=!LIBSCRIPT_ROOT_DIR!\build\experiment_results\gemma-4-sql-libtpu"
set "BACKENDS_CSV=%~3"
if "!BACKENDS_CSV!"=="" set "BACKENDS_CSV=%GEMMA_4_SQL_BACKENDS%"
if "!BACKENDS_CSV!"=="" set "BACKENDS_CSV=hf_transformers,pytorch_native,keras_jax,keras_tensorflow,keras_pytorch,maxtext,jax_native"

for %%I in ("!_repo_arg!") do set "REPO_DIR=%%~fI"
if not exist "!_res_arg!\og\raw" mkdir "!_res_arg!\og\raw"
if not exist "!_res_arg!\rs\raw" mkdir "!_res_arg!\rs\raw"
for %%I in ("!_res_arg!") do set "RESULTS_DIR=%%~fI"

for %%P in (og rs) do (
    if not exist "!RESULTS_DIR!\%%P\comparison_summary.json" (
        set "GEMMA_4_SQL_LIBTPU_PROVIDER=%%P"
        set "GEMMA_4_SQL_SKIP_CUSTOM_EXEC=1"
        set "GEMMA_4_SQL_LOCAL_EXEC=1"
        set "STACK="
        call "!LIBSCRIPT_ROOT_DIR!\experiments\gemma-4-sql\suites\e4_custom_matrix_and_synthesis.cmd" "!REPO_DIR!" "!RESULTS_DIR!\%%P" "!BACKENDS_CSV!"
        if errorlevel 1 exit /b !errorlevel!
    )
)

if not "%GEMMA_4_SQL_AB_VERIFY_DISTINCT_SHA%"=="0" (
    if exist "!RESULTS_DIR!\og\raw\e0_provenance.json" (
        if exist "!RESULTS_DIR!\rs\raw\e0_provenance.json" (
            jq -e -n --slurpfile og "!RESULTS_DIR!\og\raw\e0_provenance.json" --slurpfile rs "!RESULTS_DIR!\rs\raw\e0_provenance.json" "($og[0].libtpu_provider // \"og\") == \"og\" and ($rs[0].libtpu_provider // \"rs\") == \"rs\" and (([$og[0].stage_a_probes[]? | . as $op | ($rs[0].stage_a_probes[]? | select(.backend_id == $op.backend_id)) as $rp | ((($op.libtpu_mapped_so_sha256 // \"\" | length) > 0) and (($rp.libtpu_mapped_so_sha256 // \"\" | length) > 0) and (($op.libtpu_mapped_so_sha256 == $rp.libtpu_mapped_so_sha256) | not))] | all))" >nul 2>&1
            if errorlevel 1 exit /b 65
        )
    )
)

set "_jq_ab=%TEMP%\g4s_ab_%RANDOM%.jq"
> "!_jq_ab!" echo ($og[0].backends // []) as $og_b ^| ($rs[0].backends // []) as $rs_b ^|
>> "!_jq_ab!" echo ([ $og_b[] ^| . as $o ^| (($rs_b ^| map(select(.backend_id == $o.backend_id))[0]) // $o) as $r ^| {backend_id: $o.backend_id, comparison_family: $o.comparison_family, tex_slug: ($o.tex_slug // $o.backend_id), og_cold_compile_ms: ($o.cold_compile_ms // 0), rs_cold_compile_ms: ($r.cold_compile_ms // 0), compile_speedup_x: (if ($r.cold_compile_ms // 0) ^> 0 then (((($o.cold_compile_ms // 0) / $r.cold_compile_ms) * 1000 ^| round) / 1000) else 1.0 end), og_decode_tps: ($o.inference_tokens_per_sec // 0), rs_decode_tps: ($r.inference_tokens_per_sec // 0), decode_speedup_x: (if ($o.inference_tokens_per_sec // 0) ^> 0 then (((($r.inference_tokens_per_sec // 0) / $o.inference_tokens_per_sec) * 1000 ^| round) / 1000) else 1.0 end), og_sql_accuracy: ($o.sql_execution_accuracy // 0), rs_sql_accuracy: ($r.sql_execution_accuracy // 0), sql_accuracy_delta: (((($r.sql_execution_accuracy // 0) - ($o.sql_execution_accuracy // 0)) * 10000 ^| round) / 10000), og_train_tpsc: ($o.train_tokens_per_sec_per_chip // 0), rs_train_tpsc: ($r.train_tokens_per_sec_per_chip // 0), train_speedup_x: (if ($o.train_tokens_per_sec_per_chip // 0) ^> 0 then (((($r.train_tokens_per_sec_per_chip // 0) / $o.train_tokens_per_sec_per_chip) * 1000 ^| round) / 1000) else 1.0 end), hbm_delta_pct: (if ($o.peak_tpu_hbm_bytes // 0) ^> 0 then ((((($r.peak_tpu_hbm_bytes // 0) - ($o.peak_tpu_hbm_bytes // 0)) / $o.peak_tpu_hbm_bytes) * 10000 ^| round) / 100) else 0.0 end)}]) as $rows ^|
>> "!_jq_ab!" echo {suite: "gemma-4-sql-libtpu", status: "ok", model: ($og[0].model // "google/gemma-4-E4B"), providers: ["og","rs"], backends: $rows}

jq -n --slurpfile og "!RESULTS_DIR!\og\comparison_summary.json" --slurpfile rs "!RESULTS_DIR!\rs\comparison_summary.json" -f "!_jq_ab!" > "!RESULTS_DIR!\ab_comparison_summary.json.tmp"
del /f /q "!_jq_ab!" >nul 2>&1
jq -e . "!RESULTS_DIR!\ab_comparison_summary.json.tmp" >nul
if errorlevel 1 exit /b 1
move /y "!RESULTS_DIR!\ab_comparison_summary.json.tmp" "!RESULTS_DIR!\ab_comparison_summary.json" >nul

jq -r "[\"backend_id\",\"comparison_family\",\"og_decode_tps\",\"rs_decode_tps\",\"decode_speedup_x\",\"compile_speedup_x\",\"sql_accuracy_delta\",\"train_speedup_x\",\"hbm_delta_pct\"], (.backends[] | [.backend_id,.comparison_family,.og_decode_tps,.rs_decode_tps,.decode_speedup_x,.compile_speedup_x,.sql_accuracy_delta,.train_speedup_x,.hbm_delta_pct]) | @csv" "!RESULTS_DIR!\ab_comparison_summary.json" > "!RESULTS_DIR!\ab_comparison_summary.csv.tmp"
move /y "!RESULTS_DIR!\ab_comparison_summary.csv.tmp" "!RESULTS_DIR!\ab_comparison_summary.csv" >nul
> "!RESULTS_DIR!\ab_comparison_summary.md.tmp" echo # gemma-4-sql A/B Cloud TPU Comparison
move /y "!RESULTS_DIR!\ab_comparison_summary.md.tmp" "!RESULTS_DIR!\ab_comparison_summary.md" >nul
jq -r ".backends[] | \"\\newcommand{\\gemmaFourSqlAb\" + .tex_slug + \"DecodeSpeedupX}{\" + (.decode_speedup_x|tostring) + \"}\"" "!RESULTS_DIR!\ab_comparison_summary.json" > "!RESULTS_DIR!\generated_metrics.tex.tmp"
move /y "!RESULTS_DIR!\generated_metrics.tex.tmp" "!RESULTS_DIR!\generated_metrics.tex" >nul
exit /b 0
