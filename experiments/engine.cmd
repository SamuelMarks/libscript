@echo off
:: # engine.cmd
:: ## Overview
:: Open/Closed Research Experiment Plugin Engine on Windows auto-discovering `experiments\<suite-id>\suite.json`
:: suites and executing `list`, `scaffold`, `validate`, `provision`, `sync`, `run`, `collect`, `render-latex`, `update-readme`, `test`, and `teardown`.
:: ## Usage
:: experiments\engine.cmd <list|scaffold|validate|provision|sync|run|collect|render-latex|update-readme|test|teardown> [suite-id] [--key=value ...]

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
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found
set "EXP_ROOT=!SCRIPT_DIR!"
if not "%LIBSCRIPT_EXPERIMENTS_DIR%"=="" set "EXP_ROOT=%LIBSCRIPT_EXPERIMENTS_DIR%"
set "VERB=%~1"
if "!VERB!"=="" set "VERB=list"
if /i "!VERB!"=="--help" goto :help
if /i "!VERB!"=="-h" goto :help

if /i "!VERB!"=="scaffold" (
    set "FWD_ARGS="
    call :collect_after_first %*
    call "!LIBSCRIPT_ROOT_DIR!\cli\commands\experiment\scaffold.cmd" !FWD_ARGS!
    exit /b !errorlevel!
)
if /i "!VERB!"=="update-readme" (
    set "FWD_ARGS="
    call :collect_after_first %*
    call "!LIBSCRIPT_ROOT_DIR!\tests\update_results.cmd" !FWD_ARGS!
    exit /b !errorlevel!
)

call :ensure_jq
if errorlevel 1 exit /b 1

if /i "!VERB!"=="list" (
    for /d %%D in ("!EXP_ROOT!\*") do (
        REM wincheck disable=CMD1013
        REM wincheck disable=CMD1003
        if exist "%%~fD\suite.json" jq -r "\"\(.id)\t\(.substrate // \"local-native\")\t\(.title)\"" "%%~fD\suite.json"
    )
    exit /b 0
)

set "SUITE_ID=%~2"
if "!SUITE_ID!"=="" ( echo [ERROR] ^<suite-id^> required for verb "!VERB!" >&2 & exit /b 1 )
set "SUITE_DIR=!EXP_ROOT!\!SUITE_ID!"
set "SUITE_JSON=!SUITE_DIR!\suite.json"
if not exist "!SUITE_JSON!" ( echo [ERROR] Experiment plugin not found: !SUITE_JSON! >&2 & exit /b 1 )

set "FWD_ARGS="
set "_VAR_ERR=0"
call :validate_and_export_suite_vars %*
if "!_VAR_ERR!"=="1" exit /b 1
goto :dispatch_verb

:: ## collect_after_first
:: Collects all CLI arguments after the first verb token into FWD_ARGS without truncation.
:collect_after_first
set "_caf_idx=0"
for %%A in (%*) do (
    set /a "_caf_idx+=1"
    REM wincheck disable=CMD2003
    if !_caf_idx! GTR 1 set "FWD_ARGS=!FWD_ARGS! "%%~A""
)
exit /b 0

:: ## validate_and_export_suite_vars
:: Collects all CLI arguments after verb and suite-id, validates against vars.schema.json, and exports UPPER_SNAKE variables.
:validate_and_export_suite_vars
set "_csa_idx=0"
for %%A in (%*) do (
    set /a "_csa_idx+=1"
    REM wincheck disable=CMD2003
    if !_csa_idx! GTR 2 (
        set "FWD_ARGS=!FWD_ARGS! "%%~A""
        call :validate_single_var "%%~A"
        if errorlevel 1 (
            set "_VAR_ERR=1"
            exit /b 1
        )
    )
)
exit /b 0

:: ## ensure_jq
:: Ensures jq is available on PATH, bootstrapping _lib\utilities\jq idempotently if required.
:ensure_jq
where jq >nul 2>&1
if not errorlevel 1 exit /b 0
if exist "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" >nul 2>&1
)
where jq >nul 2>&1
if not errorlevel 1 exit /b 0
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install jq latest >nul 2>&1
if exist "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" >nul 2>&1
)
where jq >nul 2>&1
if errorlevel 1 (
    echo [ERROR] jq is required by experiments\engine.cmd >&2
    exit /b 1
)
exit /b 0

:: ## validate_suite_manifest
:: Validates suite.json required fields, substrate enum, and installer_e2e packaging_manifest existence.
:validate_suite_manifest
jq -e "(.id | type == \"string\" and length > 0) and (.title | type == \"string\" and length > 0) and (.protocol_version | type == \"string\" and length > 0) and (.subsuites | type == \"array\" and length > 0) and ((.substrate // \"local-native\") | IN(\"local-native\", \"vagrant-os-matrix\", \"installer-e2e\", \"cloud-vm\", \"tpu-slice\", \"gke-xpk\"))" "!SUITE_JSON!" >nul 2>&1
if errorlevel 1 exit /b 1
set "_PKG_MANIFEST="
for /f "usebackq delims=" %%M in (`jq -r ".installer_e2e.packaging_manifest // empty" "!SUITE_JSON!"`) do set "_PKG_MANIFEST=%%M"
if not "!_PKG_MANIFEST!"=="" (
    set "_PKG_WIN=!_PKG_MANIFEST:/=\!"
    if not exist "!SUITE_DIR!\!_PKG_WIN!" (
        if not exist "!_PKG_WIN!" (
            echo [ERROR] Missing packaging_manifest referenced by suite.json: !_PKG_MANIFEST! >&2
            exit /b 1
        )
    )
)
exit /b 0

:: ## validate_single_var
:: Validates a single --key=value flag against vars.schema.json and exports UPPER_SNAKE environment variable.
:validate_single_var
set "_vsv_arg=%~1"
if not "!_vsv_arg:~0,2!"=="--" exit /b 0
echo "!_vsv_arg!" | findstr /C:"=" >nul 2>&1
if errorlevel 1 exit /b 0
for /f "tokens=1* delims==" %%K in ("!_vsv_arg:~2!") do (
    set "_raw_k=%%K"
    set "_raw_v=%%L"
)
for %%W in (results-dir paper-dir repo-dir subsuites tfrc-config backends model output json suite-dir phase) do (
    if /i "!_raw_k!"=="%%W" exit /b 0
)
for /f "usebackq delims=" %%U in (`jq -rn --arg k "!_raw_k!" "$k | ascii_upcase | gsub(\"-\"; \"_\")"`) do set "_env_k=%%U"
for %%C in (target-os bento-prefix bento-dir provider pkg-format pkg-source release-repo release-tag install-modes force-rebuild dry-run) do (
    if /i "!_raw_k!"=="%%C" (
        set "!_env_k!=!_raw_v!"
        exit /b 0
    )
)
if exist "!SUITE_DIR!\vars.schema.json" (
    jq -e --arg k "!_env_k!" "(.properties // {}) | has($k)" "!SUITE_DIR!\vars.schema.json" >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] Unknown suite flag --!_raw_k! ^(not declared in !SUITE_DIR!\vars.schema.json^) >&2
        exit /b 1
    )
)
set "!_env_k!=!_raw_v!"
exit /b 0

:: ## dispatch_verb
:: Routes validated experiment lifecycle verbs to suite entrypoints or generic installer-e2e hooks.
:dispatch_verb
if /i "!VERB!"=="test" (
    set "STACK="
    call "!SUITE_DIR!\test.cmd" !FWD_ARGS!
    exit /b !errorlevel!
)

call :validate_suite_manifest
if errorlevel 1 (
    echo [FAIL] Invalid suite.json: !SUITE_JSON! >&2
    exit /b 1
)

if /i "!VERB!"=="validate" (
    if not exist "!SUITE_DIR!\run.sh" ( echo [FAIL] Missing run.sh in !SUITE_DIR! >&2 & exit /b 1 )
    if not exist "!SUITE_DIR!\run.cmd" ( echo [FAIL] Missing run.cmd in !SUITE_DIR! >&2 & exit /b 1 )
    echo [PASS] Experiment suite "!SUITE_ID!" validated cleanly.
    exit /b 0
)
if /i "!VERB!"=="provision" (
    for /f "usebackq delims=" %%C in (`jq -r ".required_components[]? // empty" "!SUITE_JSON!"`) do (
        where %%C >nul 2>&1
        if not errorlevel 1 (
            echo [PROVISION] Verified required Tier 1 component: %%C
        ) else (
            echo [PROVISION] Installing required Tier 1 component via LibScript: %%C
            set "STACK="
            call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install "%%C" latest
            if errorlevel 1 exit /b 1
        )
    )
    for /f "usebackq delims=" %%S in (`jq -r ".substrate // \"local-native\"" "!SUITE_JSON!"`) do set "_SUB=%%S"
    if /i "!_SUB!"=="installer-e2e" (
        if exist "!LIBSCRIPT_ROOT_DIR!\_lib\_common\experiment\pkg_ui_runner.cmd" (
            set "STACK="
            call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\experiment\pkg_ui_runner.cmd" "--suite-dir=!SUITE_DIR!" "--phase=provision" !FWD_ARGS!
            exit /b !errorlevel!
        )
    )
    exit /b 0
)
if /i "!VERB!"=="sync" goto :phase_hook
if /i "!VERB!"=="collect" goto :phase_hook
if /i "!VERB!"=="teardown" goto :phase_hook
if /i "!VERB!"=="render-latex" (
    set "EXPERIMENT_PHASE=render-latex"
    set "STACK="
    call "!SUITE_DIR!\run.cmd" --render-latex !FWD_ARGS!
    exit /b !errorlevel!
)
if /i "!VERB!"=="run" (
    set "STACK="
    call "!SUITE_DIR!\run.cmd" !FWD_ARGS!
    exit /b !errorlevel!
)
echo [ERROR] Unsupported experiment verb: !VERB! >&2
exit /b 1

:: ## phase_hook
:: Executes sync, collect, or teardown via suite script or installer-e2e pkg_ui_runner.cmd.
:phase_hook
if exist "!SUITE_DIR!\!VERB!.cmd" (
    set "STACK="
    call "!SUITE_DIR!\!VERB!.cmd" !FWD_ARGS!
    exit /b !errorlevel!
)
for /f "usebackq delims=" %%S in (`jq -r ".substrate // \"local-native\"" "!SUITE_JSON!"`) do set "_SUB=%%S"
if /i "!_SUB!"=="installer-e2e" (
    if exist "!LIBSCRIPT_ROOT_DIR!\_lib\_common\experiment\pkg_ui_runner.cmd" (
        set "STACK="
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\experiment\pkg_ui_runner.cmd" "--suite-dir=!SUITE_DIR!" "--phase=!VERB!" !FWD_ARGS!
        exit /b !errorlevel!
    )
)
echo [OK] Experiment "!SUITE_ID!" lifecycle phase "!VERB!" completed.
exit /b 0

:: ## help
:: Displays usage help for experiments\engine.cmd.
:help
echo Usage: libscript.cmd experiment ^<list^|scaffold^|validate^|provision^|sync^|run^|collect^|render-latex^|update-readme^|test^|teardown^> [suite-id] [--key=value ...]
exit /b 0
