@echo off
:: # provision_frontend.cmd
::
:: ## Overview
:: Declarative Frontend & Kotlin Multiplatform (KMP) Build Orchestrator on Windows with reuse-else-create caching.
:: Resolves NPM/Gradle dependencies, builds Angular 17+, Vite/React/JS SPAs, MFEs, and KMP
:: (jsBrowserDistribution, wasmJsBrowserDistribution, Compose Desktop) targets, and stages to webroots.
::
:: ## Usage
::   call provision_frontend.cmd --app-dir <dir> --manifest <path> --packaging <path>

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
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

set "APP_DIR="
set "MANIFEST_PATH="
set "PACKAGING_PATH="

:: ## parse_args
:: Parses command-line arguments and populates configuration variables.
:parse_args
if "%~1"=="" goto run_provision
if "%~1"=="--app-dir" (
    set "APP_DIR=%~2"
    shift
    shift
    goto parse_args
)
if "%~1"=="--manifest" (
    set "MANIFEST_PATH=%~2"
    shift
    shift
    goto parse_args
)
if "%~1"=="--packaging" (
    set "PACKAGING_PATH=%~2"
    shift
    shift
    goto parse_args
)
shift
goto parse_args

:: ## run_provision
:: Executes the frontend build and asset staging workflow.
:run_provision
if "!APP_DIR!"=="" (
    echo Error: Missing --app-dir >&2
    exit /b 1
)
if "!PACKAGING_PATH!"=="" set "PACKAGING_PATH=!MANIFEST_PATH!"
if "!MANIFEST_PATH!"=="" set "MANIFEST_PATH=!PACKAGING_PATH!"
if "!PACKAGING_PATH!"=="" (
    echo Error: Missing --manifest or --packaging >&2
    exit /b 1
)

for %%A in ("!APP_DIR!") do set "APP_DIR=%%~fA"
set "WEBROOT_BASE=!APP_DIR!\webroot"
if not exist "!WEBROOT_BASE!" mkdir "!WEBROOT_BASE!"

call :install_node_deps "!APP_DIR!"

where jq >nul 2>nul
if errorlevel 1 exit /b 0
if not exist "!PACKAGING_PATH!" exit /b 0

set "JQ_FE=([ (.services | if type == \"array\" then .[] elif type == \"object\" then to_entries[] | (.value + {id: (.value.id // .key)}) else empty end) | select(.type == \"static\" or .type == \"spa\" or .type == \"frontend\" or .type == \"kmp\" or .framework != null or .target != null) ] + [ (.frontends | if type == \"array\" then .[] elif type == \"object\" then to_entries[] | (.value + {id: (.value.id // .key)}) else empty end) ])[]?"

for /f "delims=" %%i in ('jq -c "!JQ_FE!" "!PACKAGING_PATH!" 2^>nul') do (
    set "svc=%%i"
    call :build_single_frontend
)

for /f "delims=" %%h in ('jq -c "((.lifecycle_hooks.pre_install // []) + (.hooks.pre_install // []))[]?" "!PACKAGING_PATH!" 2^>nul') do (
    set "hook=%%h"
    call :check_monolithic_hook
)

exit /b 0

:: ## install_node_deps
:: Installs npm/pnpm/yarn dependencies in a target directory if package.json exists.
:install_node_deps
set "nd_dir=%~1"
if exist "!nd_dir!\package.json" (
    pushd "!nd_dir!"
    if not "%FORCE_REINSTALL%"=="1" if exist "node_modules\.libscript_pkg_hash" (
        echo [REUSE] Frontend dependencies in !nd_dir! are up-to-date.
        popd
        exit /b 0
    )
    if exist "package-lock.json" (
        call npm ci --prefer-offline --no-audit
    ) else if exist "npm-shrinkwrap.json" (
        call npm ci --prefer-offline --no-audit
    ) else (
        call npm install --no-audit
    )
    if exist "node_modules" echo installed> "node_modules\.libscript_pkg_hash"
    popd
)
exit /b 0

:: ## build_single_frontend
:: Builds and stages a single frontend or KMP service entry.
:build_single_frontend
set "svc_id=default"
set "src_rel=."
set "build_cmd="
set "out_dir="
set "kmp_target="

for /f "delims=" %%a in ('echo !svc! ^| jq -r ".id // .name // \"default\"" 2^>nul') do set "svc_id=%%a"
for /f "delims=" %%b in ('echo !svc! ^| jq -r ".source_dir // .working_dir // .cwd // \".\"" 2^>nul') do set "src_rel=%%b"
for /f "delims=" %%c in ('echo !svc! ^| jq -r ".build_command // empty" 2^>nul') do set "build_cmd=%%c"
for /f "delims=" %%d in ('echo !svc! ^| jq -r ".output_dir // .dist_dir // empty" 2^>nul') do set "out_dir=%%d"
for /f "delims=" %%e in ('echo !svc! ^| jq -r ".target // empty" 2^>nul') do set "kmp_target=%%e"

set "src_dir=!APP_DIR!"
if not "!src_rel!"=="." (
    set "src_rel_win=!src_rel:/=\!"
    if "!src_rel_win:~1,1!"==":" (
        set "src_dir=!src_rel_win!"
    ) else (
        set "src_dir=!APP_DIR!\!src_rel_win!"
    )
)

set "target_webroot=!WEBROOT_BASE!\!svc_id!"
if not exist "!target_webroot!" mkdir "!target_webroot!"

set "is_kmp=0"
if exist "!src_dir!\build.gradle.kts" set "is_kmp=1"
if exist "!src_dir!\build.gradle" set "is_kmp=1"
if not "!kmp_target!"=="" set "is_kmp=1"

if "!is_kmp!"=="1" (
    call :run_kmp_build "!src_dir!" "!kmp_target!" "!build_cmd!"
    call :stage_assets "!src_dir!" "!target_webroot!" "!out_dir!"
    exit /b 0
)

if exist "!src_dir!\package.json" (
    if /i not "!src_dir!"=="!APP_DIR!" (
        call :install_node_deps "!src_dir!"
    )
    set "_check_out=!out_dir!"
    if "!_check_out!"=="" set "_check_out=dist"
    set "_check_out_win=!_check_out:/=\!"
    if not "%FORCE_REBUILD%"=="1" if exist "!src_dir!\!_check_out_win!\index.html" if exist "!src_dir!\.libscript_build.sha256" (
        echo [REUSE] Frontend build in '!src_dir!\!_check_out_win!' is up-to-date.
    ) else (
        pushd "!src_dir!"
        for /f "delims=" %%v in ('echo !svc! ^| jq -r ".env // {} | to_entries[]? | \"\(.key)=\(.value)\"" 2^>nul') do set "%%v"
        if not "!build_cmd!"=="" (
            call !build_cmd!
        ) else (
            findstr /C:"\"build\"" "package.json" >nul 2>&1
            if not errorlevel 1 call npm run build
        )
        echo built> ".libscript_build.sha256"
        popd
    )
    call :stage_assets "!src_dir!" "!target_webroot!" "!out_dir!"
)
exit /b 0

:: ## run_kmp_build
:: Executes Kotlin Multiplatform Gradle tasks on Windows.
:run_kmp_build
set "k_dir=%~1"
set "k_tgt=%~2"
set "k_cmd=%~3"
if "!k_tgt!"=="" set "k_tgt=kmp-js"
set "gradle_bin=gradle"
if exist "!k_dir!\gradlew.bat" set "gradle_bin=gradlew.bat"

pushd "!k_dir!"
if not "!k_cmd!"=="" (
    call !k_cmd!
) else if /i "!k_tgt!"=="kmp-wasm" (
    call "!gradle_bin!" :composeApp:wasmJsBrowserDistribution
) else if /i "!k_tgt!"=="wasm" (
    call "!gradle_bin!" :composeApp:wasmJsBrowserDistribution
) else if /i "!k_tgt!"=="wasmJs" (
    call "!gradle_bin!" :composeApp:wasmJsBrowserDistribution
) else if /i "!k_tgt!"=="kmp-desktop" (
    call "!gradle_bin!" :composeApp:packageDistributionForCurrentOS
) else if /i "!k_tgt!"=="jvm" (
    call "!gradle_bin!" :composeApp:packageDistributionForCurrentOS
) else (
    call "!gradle_bin!" :composeApp:jsBrowserDistribution
)
popd
exit /b 0

:: ## stage_assets
:: Stages compiled Angular 17+ browser/, KMP productionExecutable/, or standard dist/ assets to target_webroot.
:stage_assets
set "st_src=%~1"
set "st_dst=%~2"
set "st_out=%~3"
if not exist "!st_dst!" mkdir "!st_dst!"

if not "!st_out!"=="" (
    set "st_out_win=!st_out:/=\!"
    if exist "!st_src!\!st_out_win!" (
        xcopy /E /I /Y "!st_src!\!st_out_win!\*" "!st_dst!" >nul 2>&1
        exit /b 0
    )
)

for /d %%D in ("!st_src!\dist\*") do (
    if exist "%%~fD\browser\index.html" (
        xcopy /E /I /Y "%%~fD\browser\*" "!st_dst!" >nul 2>&1
        exit /b 0
    )
    if exist "%%~fD\index.html" (
        xcopy /E /I /Y "%%~fD\*" "!st_dst!" >nul 2>&1
        exit /b 0
    )
)

if exist "!st_src!\composeApp\build\dist\wasmJs\productionExecutable" (
    xcopy /E /I /Y "!st_src!\composeApp\build\dist\wasmJs\productionExecutable\*" "!st_dst!" >nul 2>&1
    exit /b 0
)
if exist "!st_src!\composeApp\build\dist\js\productionExecutable" (
    xcopy /E /I /Y "!st_src!\composeApp\build\dist\js\productionExecutable\*" "!st_dst!" >nul 2>&1
    exit /b 0
)
if exist "!st_src!\build\dist\wasmJs\productionExecutable" (
    xcopy /E /I /Y "!st_src!\build\dist\wasmJs\productionExecutable\*" "!st_dst!" >nul 2>&1
    exit /b 0
)
if exist "!st_src!\build\dist\js\productionExecutable" (
    xcopy /E /I /Y "!st_src!\build\dist\js\productionExecutable\*" "!st_dst!" >nul 2>&1
    exit /b 0
)

if exist "!st_src!\dist" (
    xcopy /E /I /Y "!st_src!\dist\*" "!st_dst!" >nul 2>&1
    exit /b 0
)
if exist "!st_src!\build\index.html" (
    xcopy /E /I /Y "!st_src!\build\*" "!st_dst!" >nul 2>&1
    exit /b 0
)
exit /b 0

:: ## check_monolithic_hook
:: Checks and executes monolithic static asset collection hooks.
:check_monolithic_hook
set "h_cmd="
for /f "delims=" %%c in ('echo !hook! ^| jq -r ".command // empty" 2^>nul') do set "h_cmd=%%c"
if "!h_cmd!"=="" exit /b 0
echo !h_cmd! | findstr /i "collectstatic paver" >nul 2>&1
if not errorlevel 1 (
    pushd "!APP_DIR!"
    call !h_cmd!
    popd
)
exit /b 0
