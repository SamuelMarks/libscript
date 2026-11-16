@echo off
:: # pkg_ui_runner.cmd
:: ## Overview
:: Top-level generic orchestrator on Windows composing Steps 0-5 (Bento/Vagrant, package resolution,
:: 3x clean-snapshot installs, and guest UI/browser login verification) for installer-e2e suites.
:: ## Usage
:: pkg_ui_runner.cmd --suite-dir=<dir> [--phase=run|provision|sync|collect|teardown] [--target-os=<os>] [--pkg-format=<fmt>] [--pkg-source=github-release|build] [--install-modes=headless,quick,custom] [--dry-run=1]

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
    sh "!SCRIPT_DIR!\pkg_ui_runner.sh" %*
    exit /b !errorlevel!
)

set "PUR_SUITE_DIR=%SUITE_DIR%"
set "PUR_PHASE=run"
if not "%EXPERIMENT_PHASE%"=="" set "PUR_PHASE=%EXPERIMENT_PHASE%"
set "PUR_RESULTS_DIR="
set "PUR_TARGET_OS=%TARGET_OS%"
set "PUR_BENTO_PREFIX=%BENTO_PREFIX%"
set "PUR_PROVIDER=%PROVIDER%"
set "PUR_PKG_FORMAT=%PKG_FORMAT%"
set "PUR_PKG_SOURCE=%PKG_SOURCE%"
set "PUR_INSTALL_MODES=%INSTALL_MODES%"
set "PUR_FORCE_REBUILD=0"
if not "%FORCE_REBUILD%"=="" set "PUR_FORCE_REBUILD=%FORCE_REBUILD%"
set "PUR_DRY_RUN=0"
if not "%DRY_RUN%"=="" set "PUR_DRY_RUN=%DRY_RUN%"

for %%A in (%*) do (
    set "_a=%%~A"
    if /i "!_a!"=="--help" goto :pur_help
    if /i "!_a!"=="-h" goto :pur_help
    if /i "!_a:~0,12!"=="--suite-dir=" set "PUR_SUITE_DIR=!_a:~12!"
    if /i "!_a:~0,8!"=="--phase=" set "PUR_PHASE=!_a:~8!"
    if /i "!_a:~0,14!"=="--results-dir=" set "PUR_RESULTS_DIR=!_a:~14!"
    if /i "!_a:~0,12!"=="--target-os=" set "PUR_TARGET_OS=!_a:~12!"
    if /i "!_a:~0,15!"=="--bento-prefix=" set "PUR_BENTO_PREFIX=!_a:~15!"
    if /i "!_a:~0,11!"=="--provider=" set "PUR_PROVIDER=!_a:~11!"
    if /i "!_a:~0,13!"=="--pkg-format=" set "PUR_PKG_FORMAT=!_a:~13!"
    if /i "!_a:~0,13!"=="--pkg-source=" set "PUR_PKG_SOURCE=!_a:~13!"
    if /i "!_a:~0,16!"=="--install-modes=" set "PUR_INSTALL_MODES=!_a:~16!"
    if /i "!_a:~0,16!"=="--force-rebuild=" set "PUR_FORCE_REBUILD=!_a:~16!"
    if /i "!_a:~0,10!"=="--dry-run=" set "PUR_DRY_RUN=!_a:~10!"
)

if "!PUR_SUITE_DIR!"=="" ( echo [ERROR] --suite-dir required >&2 & exit /b 1 )
set "PUR_SUITE_JSON=!PUR_SUITE_DIR!\suite.json"
if not exist "!PUR_SUITE_JSON!" ( echo [ERROR] Missing !PUR_SUITE_JSON! >&2 & exit /b 1 )

for /f "usebackq delims=" %%I in (`jq -r ".id" "!PUR_SUITE_JSON!"`) do set "PUR_SUITE_ID=%%I"
for /f "usebackq delims=" %%M in (`jq -r ".installer_e2e.packaging_manifest" "!PUR_SUITE_JSON!"`) do set "PUR_MAN_REL=%%M"
set "PUR_MANIFEST=!PUR_SUITE_DIR!\!PUR_MAN_REL:/=\!"
if "!PUR_RESULTS_DIR!"=="" set "PUR_RESULTS_DIR=!LIBSCRIPT_ROOT_DIR!\build\experiments\!PUR_SUITE_ID!"
if not exist "!PUR_RESULTS_DIR!" mkdir "!PUR_RESULTS_DIR!"

if "!PUR_TARGET_OS!"=="" for /f "usebackq delims=" %%O in (`jq -r ".installer_e2e.vagrant.default_target_os // \"windows-11\"" "!PUR_SUITE_JSON!"`) do set "PUR_TARGET_OS=%%O"
if "!PUR_BENTO_PREFIX!"=="" for /f "usebackq delims=" %%B in (`jq -r ".installer_e2e.vagrant.bento_prefix // \"bento\"" "!PUR_SUITE_JSON!"`) do set "PUR_BENTO_PREFIX=%%B"
if "!PUR_PROVIDER!"=="" for /f "usebackq delims=" %%P in (`jq -r ".installer_e2e.vagrant.provider // \"auto\"" "!PUR_SUITE_JSON!"`) do set "PUR_PROVIDER=%%P"
if "!PUR_PKG_FORMAT!"=="" for /f "usebackq delims=" %%F in (`jq -r ".installer_e2e.artifact.default_format // \"auto\"" "!PUR_SUITE_JSON!"`) do set "PUR_PKG_FORMAT=%%F"
if "!PUR_PKG_SOURCE!"=="" for /f "usebackq delims=" %%S in (`jq -r ".installer_e2e.artifact.default_source // \"github-release\"" "!PUR_SUITE_JSON!"`) do set "PUR_PKG_SOURCE=%%S"
if "!PUR_INSTALL_MODES!"=="" for /f "usebackq delims=" %%M in (`jq -r "(.installer_e2e.install_matrix.modes // [\"headless\",\"quick\",\"custom\"]) | join(\",\")" "!PUR_SUITE_JSON!"`) do set "PUR_INSTALL_MODES=%%M"

if "!PUR_DRY_RUN!"=="1" (
    call :pur_execute_dry_run
    exit /b !errorlevel!
)

for /f "usebackq delims=" %%O in (`call "!SCRIPT_DIR!\vagrant_substrate.cmd" resolve-os "!PUR_TARGET_OS!"`) do set "PUR_RES_OS=%%O"
for /f "usebackq delims=" %%F in (`call "!SCRIPT_DIR!\vagrant_substrate.cmd" os-family "!PUR_RES_OS!"`) do set "PUR_FAM=%%F"
for /f "usebackq delims=" %%P in (`call "!SCRIPT_DIR!\vagrant_substrate.cmd" resolve-provider "!PUR_PROVIDER!"`) do set "PUR_RES_PROV=%%P"
for /f "usebackq delims=" %%K in (`call "!SCRIPT_DIR!\pkg_resolver.cmd" infer-format "!PUR_RES_OS!" "!PUR_PKG_FORMAT!"`) do set "PUR_RES_FMT=%%K"

call "!SCRIPT_DIR!\vagrant_substrate.cmd" provision "!PUR_BENTO_PREFIX!" "!PUR_RES_OS!" "!PUR_RES_PROV!" >nul
for /f "usebackq delims=" %%W in (`call "!SCRIPT_DIR!\vagrant_substrate.cmd" prepare-workspace "!PUR_SUITE_ID!" "!PUR_BENTO_PREFIX!" "!PUR_RES_OS!" "!PUR_RES_PROV!"`) do set "PUR_WS=%%W"
call "!SCRIPT_DIR!\vagrant_substrate.cmd" boot "!PUR_WS!" "!PUR_RES_PROV!" "!PUR_FAM!"
if errorlevel 1 exit /b 1
call "!SCRIPT_DIR!\vagrant_substrate.cmd" snapshot-ensure "!PUR_WS!" "!PUR_RES_PROV!" "!PUR_FAM!" "vanilla" "!PUR_SUITE_JSON!"
if errorlevel 1 exit /b 1

for /f "usebackq delims=" %%A in (`call "!SCRIPT_DIR!\pkg_resolver.cmd" resolve "!PUR_SUITE_ID!" "!PUR_MANIFEST!" "!PUR_RES_OS!" "!PUR_RES_FMT!" "!PUR_PKG_SOURCE!"`) do set "PUR_PKG_PATH=%%A"
if "!PUR_PKG_PATH!"=="" exit /b 1

for %%M in (!PUR_INSTALL_MODES:,= !) do (
    set "EXP_MODE_OUT_DIR=!PUR_RESULTS_DIR!\!PUR_RES_OS!\!PUR_RES_FMT!\%%M"
    if not exist "!EXP_MODE_OUT_DIR!" mkdir "!EXP_MODE_OUT_DIR!"
    call "!SCRIPT_DIR!\install_modes.cmd" run-trial "!PUR_WS!" "!PUR_RES_PROV!" "!PUR_FAM!" "vanilla" "%%M" "!PUR_RES_FMT!" "!PUR_PKG_PATH!" "!PUR_SUITE_JSON!"
    if errorlevel 1 exit /b 1
)
jq -n --arg sid "!PUR_SUITE_ID!" "{suite_id:$sid,status:\"converged\"}" > "!PUR_RESULTS_DIR!\metrics.json"
exit /b 0

:: ## pur_execute_dry_run
:: Emits dry-run execution_plan.json and metrics.json without booting a Vagrant VM.
:pur_execute_dry_run
jq -n --arg sid "!PUR_SUITE_ID!" --arg os "!PUR_TARGET_OS!" --arg src "!PUR_PKG_SOURCE!" "{suite_id:$sid,target_os:$os,pkg_source:$src,status:\"dry_run_planned\"}" > "!PUR_RESULTS_DIR!\metrics.json"
copy /y "!PUR_RESULTS_DIR!\metrics.json" "!PUR_RESULTS_DIR!\execution_plan.json" >nul
echo [OK] Dry-run installer-e2e plan emitted -^> !PUR_RESULTS_DIR!\execution_plan.json
exit /b 0

:: ## pur_help
:: Prints CLI usage for pkg_ui_runner.cmd.
:pur_help
echo Usage: pkg_ui_runner.cmd --suite-dir=^<dir^> [--target-os=^<os^>] [--pkg-format=^<fmt^>] [--pkg-source=github-release^|build] [--install-modes=headless,quick,custom] [--dry-run=1]
exit /b 0
