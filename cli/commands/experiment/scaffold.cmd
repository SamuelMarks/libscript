@echo off
:: # scaffold.cmd
:: ## Overview
:: Scaffolds a compliant `experiments\<suite-id>\` research plugin directory on Windows, supporting `default` and `installer-e2e` templates.
:: ## Usage
:: scaffold.cmd <suite-id> [--title=<title>] [--substrate=<substrate>] [--template=default|installer-e2e] [--packaging-manifest=<path>] [--out-root=<dir>]

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
where sh >nul 2>&1
if not errorlevel 1 (
    sh "!SCRIPT_DIR!\scaffold.sh" %*
    exit /b !errorlevel!
)
set "SUITE_ID="
set "SUBSTRATE=local-native"
set "TEMPLATE=default"
set "PKG_MANIFEST="
set "OUT_ROOT=!LIBSCRIPT_ROOT_DIR!\experiments"
if not "%LIBSCRIPT_EXPERIMENTS_DIR%"=="" set "OUT_ROOT=%LIBSCRIPT_EXPERIMENTS_DIR%"

for %%A in (%*) do (
    set "_arg=%%~A"
    if /i "!_arg:~0,12!"=="--substrate=" (
        set "SUBSTRATE=!_arg:~12!"
    ) else if /i "!_arg:~0,11!"=="--template=" (
        set "TEMPLATE=!_arg:~11!"
    ) else if /i "!_arg:~0,21!"=="--packaging-manifest=" (
        set "PKG_MANIFEST=!_arg:~21!"
    ) else if /i "!_arg:~0,11!"=="--out-root=" (
        set "OUT_ROOT=!_arg:~11!"
    ) else if not "!_arg:~0,2!"=="--" (
        if "!SUITE_ID!"=="" set "SUITE_ID=!_arg!"
    )
)

if "!SUITE_ID!"=="" ( echo [ERROR] suite-id required >&2 & exit /b 1 )
if /i "!TEMPLATE!"=="installer-e2e" set "SUBSTRATE=installer-e2e"
if /i "!SUBSTRATE!"=="installer-e2e" set "TEMPLATE=installer-e2e"
if "!PKG_MANIFEST!"=="" set "PKG_MANIFEST=../../_lib/web-apps/!SUITE_ID!/packaging.json"

set "SDIR=!OUT_ROOT!\!SUITE_ID!"
if not exist "!SDIR!" mkdir "!SDIR!"
if exist "!SDIR!\suite.json" (
    echo [SKIP] Experiment plugin already scaffolded at !SDIR!
    exit /b 0
)

if /i "!TEMPLATE!"=="installer-e2e" (
    jq -n --arg id "!SUITE_ID!" --arg pm "!PKG_MANIFEST!" "{id:$id,title:(\"Empirical Evaluation Suite: \" + $id),protocol_version:\"1.0.0\",substrate:\"installer-e2e\",required_components:[\"jq\"],vars_schema_ref:\"./vars.schema.json\",outputs:{metrics_json:\"metrics.json\",screenshots_dir:\"screenshots\"},installer_e2e:{packaging_manifest:$pm,vagrant:{bento_prefix:\"bento\",default_target_os:\"windows-11\",provider:\"auto\",vanilla_snapshot_name:\"vanilla\"},artifact:{default_format:\"auto\",default_source:\"github-release\",release_repo:\"SamuelMarks/libscript\",release_tag:\"latest\"},install_matrix:{modes:[\"headless\",\"quick\",\"custom\"],isolate_each_mode_via_snapshot:true},verification:{capture_desktop_icons:\"if-applicable\",inherit_packaging_verification_screenshots:true}},subsuites:[{id:\"E0\",title:\"Artifact & Vanilla Snapshot\"},{id:\"E1\",title:\"Headless Install\"},{id:\"E2\",title:\"Quick GUI Install\"},{id:\"E3\",title:\"Custom GUI Install\"}]}" > "!SDIR!\suite.json"
) else (
    jq -n --arg id "!SUITE_ID!" --arg sub "!SUBSTRATE!" "{id:$id,title:(\"Empirical Suite: \" + $id),protocol_version:\"1.0.0\",substrate:$sub,subsuites:[{id:\"E0\",title:\"Baseline\"}]}" > "!SDIR!\suite.json"
)
jq -n "{type:\"object\",description:\"Suite variables\",properties:{DRY_RUN:{type:\"string\",description:\"Dry run toggle\"}}}" > "!SDIR!\vars.schema.json"
echo # !SUITE_ID! > "!SDIR!\README.md"
exit /b 0
