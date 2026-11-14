@echo off
:: # experiment_cloud.cmd
:: ## Overview
:: Unified rapid cloud, Dual-ISA native benchmark (`--suite=libtpu|edgcpp|manifest`), and Bento multi-OS Vagrant matrix experimentation lifecycle orchestrator for LibScript on Windows.
:: ## Usage
:: _lib\cloud\core\experiment_cloud.cmd [a_provision_instance|sync_research_repos|verify_native_host|run_experiments|g_collect_logs|h_pull_logs|emit_latex_and_verify_pdf|i_deprovision_instance|bento_matrix|all] [--suite=libtpu|edgcpp|libscript|manifest|all]

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

if "%CORE_EXPERIMENT_PROVIDER%"=="" set "CORE_EXPERIMENT_PROVIDER=azure"
if "%CORE_EXPERIMENT_SIZE%"=="" set "CORE_EXPERIMENT_SIZE=160-vCPU Standard_D160ads_v7"
if "%CORE_EXPERIMENT_NODE%"=="" set "CORE_EXPERIMENT_NODE=edg-exp-node"
if "%CORE_EXPERIMENT_RG%"=="" set "CORE_EXPERIMENT_RG=edg-experiments-rg"
if "%CORE_EXPERIMENT_LOCATION%"=="" set "CORE_EXPERIMENT_LOCATION=eastus2"
if "%CORE_EXPERIMENT_OS%"=="" set "CORE_EXPERIMENT_OS=Ubuntu2404"
if "%CORE_EXPERIMENT_REMOTE_DIR%"=="" set "CORE_EXPERIMENT_REMOTE_DIR=~/libscript/build/experiment_bundle"
if "%CORE_EXPERIMENT_LOCAL_DIR%"=="" set "CORE_EXPERIMENT_LOCAL_DIR=!LIBSCRIPT_ROOT_DIR!\build\experiment_results"
if "%CORE_EXPERIMENT_STATE_FILE%"=="" set "CORE_EXPERIMENT_STATE_FILE=!LIBSCRIPT_ROOT_DIR!\build\cloud-experiment-state.json"
if "%CORE_EXPERIMENT_BENTO_REPO%"=="" set "CORE_EXPERIMENT_BENTO_REPO=https://github.com/SamuelMarks/bento.git"
if "%CORE_EXPERIMENT_BENTO_BRANCH%"=="" set "CORE_EXPERIMENT_BENTO_BRANCH=multi-os-qemu-aarch64"
if "%CORE_EXPERIMENT_BENTO_DIR%"=="" set "CORE_EXPERIMENT_BENTO_DIR=../bento"
if "%CORE_EXPERIMENT_TARGET_OS%"=="" set "CORE_EXPERIMENT_TARGET_OS=alpine-3.24"
if "%CORE_EXPERIMENT_SNAPSHOT_NAME%"=="" set "CORE_EXPERIMENT_SNAPSHOT_NAME=vanilla"
if "%CORE_EXPERIMENT_COMPONENTS%"=="" set "CORE_EXPERIMENT_COMPONENTS=all"
if "%CORE_EXPERIMENT_COMPONENT_VERSION%"=="" set "CORE_EXPERIMENT_COMPONENT_VERSION=latest"
if "%CORE_EXPERIMENT_PKG_MGR%"=="" set "CORE_EXPERIMENT_PKG_MGR="
if "%CORE_EXPERIMENT_INSTALL_METHOD%"=="" set "CORE_EXPERIMENT_INSTALL_METHOD="
if "%CORE_EXPERIMENT_TOOLCHAIN%"=="" set "CORE_EXPERIMENT_TOOLCHAIN="
if "%CORE_EXPERIMENT_IDEMPOTENCY_RUNS%"=="" set "CORE_EXPERIMENT_IDEMPOTENCY_RUNS=2"
if "%CORE_EXPERIMENT_SUITE%"=="" set "CORE_EXPERIMENT_SUITE=all"
if "%CORE_EXPERIMENT_SUITE_MANIFEST%"=="" set "CORE_EXPERIMENT_SUITE_MANIFEST="
if "%CORE_EXPERIMENT_SUBSUITES%"=="" set "CORE_EXPERIMENT_SUBSUITES=E0,E1,E2,E3,E4,E5,E6,E7,E8"
if "%CORE_EXPERIMENT_WARMUP%"=="" set "CORE_EXPERIMENT_WARMUP=10"
if "%CORE_EXPERIMENT_TRIALS%"=="" set "CORE_EXPERIMENT_TRIALS=200"
if "%CORE_EXPERIMENT_REPO_DIR%"=="" set "CORE_EXPERIMENT_REPO_DIR="
if "%CORE_EXPERIMENT_ECOSYSTEM_DIR%"=="" set "CORE_EXPERIMENT_ECOSYSTEM_DIR="
if "%CORE_EXPERIMENT_PAPER_DIR%"=="" set "CORE_EXPERIMENT_PAPER_DIR="
if "%CORE_EXPERIMENT_APPENDIX_TEX%"=="" set "CORE_EXPERIMENT_APPENDIX_TEX="
if "%CORE_EXPERIMENT_CARGO_PROFILE%"=="" set "CORE_EXPERIMENT_CARGO_PROFILE=opt3-lto-thin-cgu1"
if "%CORE_EXPERIMENT_REQUIRE_NATIVE_ISA%"=="" set "CORE_EXPERIMENT_REQUIRE_NATIVE_ISA=1"
if "%CORE_EXPERIMENT_HOST_ARCH%"=="" set "CORE_EXPERIMENT_HOST_ARCH=linux_x64"
if "%CORE_EXPERIMENT_BUILD_PDF%"=="" set "CORE_EXPERIMENT_BUILD_PDF=0"
set "CORE_EXPERIMENT_STEPS="

for %%A in (%*) do (
    set "_arg=%%~A"
    if "!_arg:~0,8!"=="--steps=" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! !_arg:~8!"
    if "!_arg:~0,7!"=="--step=" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! !_arg:~7!"
    if "!_arg:~0,11!"=="--provider=" set "CORE_EXPERIMENT_PROVIDER=!_arg:~11!"
    if "!_arg:~0,7!"=="--size=" set "CORE_EXPERIMENT_SIZE=!_arg:~7!"
    if "!_arg:~0,10!"=="--vm-size=" set "CORE_EXPERIMENT_SIZE=!_arg:~10!"
    if "!_arg:~0,7!"=="--node=" set "CORE_EXPERIMENT_NODE=!_arg:~7!"
    if "!_arg:~0,5!"=="--rg=" set "CORE_EXPERIMENT_RG=!_arg:~5!"
    if "!_arg:~0,11!"=="--location=" set "CORE_EXPERIMENT_LOCATION=!_arg:~11!"
    if "!_arg:~0,12!"=="--target-os=" set "CORE_EXPERIMENT_TARGET_OS=!_arg:~12!"
    if "!_arg:~0,13!"=="--bento-repo=" set "CORE_EXPERIMENT_BENTO_REPO=!_arg:~13!"
    if "!_arg:~0,15!"=="--bento-branch=" set "CORE_EXPERIMENT_BENTO_BRANCH=!_arg:~15!"
    if "!_arg:~0,12!"=="--bento-dir=" set "CORE_EXPERIMENT_BENTO_DIR=!_arg:~12!"
    if "!_arg:~0,11!"=="--snapshot=" set "CORE_EXPERIMENT_SNAPSHOT_NAME=!_arg:~11!"
    if "!_arg:~0,13!"=="--components=" set "CORE_EXPERIMENT_COMPONENTS=!_arg:~13!"
    if "!_arg:~0,12!"=="--component=" set "CORE_EXPERIMENT_COMPONENTS=!_arg:~12!"
    if "!_arg:~0,10!"=="--version=" set "CORE_EXPERIMENT_COMPONENT_VERSION=!_arg:~10!"
    if "!_arg:~0,20!"=="--component-version=" set "CORE_EXPERIMENT_COMPONENT_VERSION=!_arg:~20!"
    if "!_arg:~0,10!"=="--pkg-mgr=" set "CORE_EXPERIMENT_PKG_MGR=!_arg:~10!"
    if "!_arg:~0,18!"=="--package-manager=" set "CORE_EXPERIMENT_PKG_MGR=!_arg:~18!"
    if "!_arg:~0,17!"=="--install-method=" set "CORE_EXPERIMENT_INSTALL_METHOD=!_arg:~17!"
    if /i "!_arg!"=="--from-source" set "CORE_EXPERIMENT_INSTALL_METHOD=from-source"
    if "!_arg:~0,12!"=="--toolchain=" set "CORE_EXPERIMENT_TOOLCHAIN=!_arg:~12!"
    if "!_arg:~0,19!"=="--idempotency-runs=" set "CORE_EXPERIMENT_IDEMPOTENCY_RUNS=!_arg:~19!"
    if "!_arg:~0,8!"=="--suite=" set "CORE_EXPERIMENT_SUITE=!_arg:~8!"
    if "!_arg:~0,17!"=="--suite-manifest=" (
        set "CORE_EXPERIMENT_SUITE_MANIFEST=!_arg:~17!"
        set "CORE_EXPERIMENT_SUITE=manifest"
    )
    if "!_arg:~0,12!"=="--subsuites=" set "CORE_EXPERIMENT_SUBSUITES=!_arg:~12!"
    if "!_arg:~0,9!"=="--warmup=" set "CORE_EXPERIMENT_WARMUP=!_arg:~9!"
    if "!_arg:~0,9!"=="--trials=" set "CORE_EXPERIMENT_TRIALS=!_arg:~9!"
    if "!_arg:~0,11!"=="--repo-dir=" set "CORE_EXPERIMENT_REPO_DIR=!_arg:~11!"
    if "!_arg:~0,16!"=="--ecosystem-dir=" set "CORE_EXPERIMENT_ECOSYSTEM_DIR=!_arg:~16!"
    if "!_arg:~0,15!"=="--appendix-tex=" set "CORE_EXPERIMENT_APPENDIX_TEX=!_arg:~15!"
    if "!_arg:~0,12!"=="--paper-dir=" set "CORE_EXPERIMENT_PAPER_DIR=!_arg:~12!"
    if "!_arg:~0,16!"=="--cargo-profile=" set "CORE_EXPERIMENT_CARGO_PROFILE=!_arg:~16!"
    if /i "!_arg!"=="--require-native-isa" set "CORE_EXPERIMENT_REQUIRE_NATIVE_ISA=1"
    if /i "!_arg!"=="--no-require-native-isa" set "CORE_EXPERIMENT_REQUIRE_NATIVE_ISA=0"
    if "!_arg:~0,12!"=="--host-arch=" set "CORE_EXPERIMENT_HOST_ARCH=!_arg:~12!"
    if /i "!_arg!"=="--build-pdf" set "CORE_EXPERIMENT_BUILD_PDF=1"
    if "!_arg:~0,12!"=="--local-dir=" set "CORE_EXPERIMENT_LOCAL_DIR=!_arg:~12!"
    if "!_arg:~0,13!"=="--state-file=" set "CORE_EXPERIMENT_STATE_FILE=!_arg:~13!"
    if /i "!_arg!"=="--dry-run" set "DRY_RUN=true"
    if /i "!_arg!"=="a_provision_instance" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! provision_instance"
    if /i "!_arg!"=="sync_research_repos" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! sync_research_repos"
    if /i "!_arg!"=="verify_native_host" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! verify_native_host"
    if /i "!_arg!"=="b_use_bento_fork" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! use_bento_fork"
    if /i "!_arg!"=="c_install_virtualization_stack" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! install_virtualization_stack"
    if /i "!_arg!"=="d_deploy_vagrant_box" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! deploy_vagrant_box"
    if /i "!_arg!"=="e_snapshot_vagrant_box" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! snapshot_vagrant_box"
    if /i "!_arg!"=="f_test_libscript_components" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! test_libscript_components"
    if /i "!_arg!"=="g_collect_logs" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! collect_logs"
    if /i "!_arg!"=="h_pull_logs" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! send_logs_to_host"
    if /i "!_arg!"=="emit_latex_and_verify_pdf" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! emit_latex_and_verify_pdf"
    if /i "!_arg!"=="i_deprovision_instance" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! deprovision_instance"
    if /i "!_arg!"=="provision_instance" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! provision_instance"
    if /i "!_arg!"=="use_bento_fork" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! use_bento_fork"
    if /i "!_arg!"=="setup_bento_fork" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! use_bento_fork"
    if /i "!_arg!"=="bento_fork" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! use_bento_fork"
    if /i "!_arg!"=="install_virtualization_stack" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! install_virtualization_stack"
    if /i "!_arg!"=="install_bento_deps" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! install_virtualization_stack"
    if /i "!_arg!"=="deploy_vagrant_box" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! deploy_vagrant_box"
    if /i "!_arg!"=="deploy_target_os" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! deploy_vagrant_box"
    if /i "!_arg!"=="snapshot_vagrant_box" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! snapshot_vagrant_box"
    if /i "!_arg!"=="snapshot" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! snapshot_vagrant_box"
    if /i "!_arg!"=="test_libscript_components" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! test_libscript_components"
    if /i "!_arg!"=="run_libscript_matrix" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! test_libscript_components"
    if /i "!_arg!"=="send_logs_to_host" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! send_logs_to_host"
    if /i "!_arg!"=="run_experiments" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! run_experiments"
    if /i "!_arg!"=="collect_logs" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! collect_logs"
    if /i "!_arg!"=="move_to_log_dir" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! collect_logs"
    if /i "!_arg!"=="pull_logs" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! pull_logs"
    if /i "!_arg!"=="move_log_dir_to_host" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! pull_logs"
    if /i "!_arg!"=="deprovision_instance" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! deprovision_instance"
    if /i "!_arg!"=="bento_matrix" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! bento_matrix"
    if /i "!_arg!"=="os_matrix" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! bento_matrix"
    if /i "!_arg!"=="full_bento_matrix" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! all"
    if /i "!_arg!"=="libtpu_campaign" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! libtpu_campaign"
    if /i "!_arg!"=="win_port_campaign" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! win_port_campaign"
    if /i "!_arg!"=="edgcpp_backends_campaign" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! edgcpp_backends_campaign"
    if /i "!_arg!"=="all" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! all"
    if /i "!_arg!"=="a" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! provision_instance"
    if /i "!_arg!"=="0" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! use_bento_fork"
    if /i "!_arg!"=="1" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! install_virtualization_stack"
    if /i "!_arg!"=="2" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! deploy_vagrant_box"
    if /i "!_arg!"=="3" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! snapshot_vagrant_box"
    if /i "!_arg!"=="4" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! test_libscript_components"
    if /i "!_arg!"=="5" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! send_logs_to_host"
    if /i "!_arg!"=="i" set "CORE_EXPERIMENT_STEPS=!CORE_EXPERIMENT_STEPS! deprovision_instance"
)

for /f "tokens=1,2 delims=@" %%I in ("!CORE_EXPERIMENT_COMPONENTS!") do (
    if not "%%J"=="" (
        set "CORE_EXPERIMENT_COMPONENTS=%%I"
        if "!CORE_EXPERIMENT_COMPONENT_VERSION!"=="latest" set "CORE_EXPERIMENT_COMPONENT_VERSION=%%J"
    )
)
if not "!CORE_EXPERIMENT_PKG_MGR!"=="" if "!CORE_EXPERIMENT_INSTALL_METHOD!"=="" (
    set "CORE_EXPERIMENT_INSTALL_METHOD=system"
)

if "!CORE_EXPERIMENT_STEPS!"=="" set "CORE_EXPERIMENT_STEPS=all"
call :normalize_vm_sku
call :load_existing_state
call :run_selected_lifecycle_steps
exit /b !errorlevel!

:: ## normalize_vm_sku
:: Normalizes descriptive size labels like '160-vCPU Standard_D160ads_v7' into 'Standard_D160ads_v7'.
:normalize_vm_sku
set "RESOLVED_VM_SKU=!CORE_EXPERIMENT_SIZE!"
for %%S in (!CORE_EXPERIMENT_SIZE!) do set "RESOLVED_VM_SKU=%%S"
exit /b 0

:: ## load_existing_state
:: Reads existing boolean flags from CORE_EXPERIMENT_STATE_FILE to preserve state across single-step invocations.
:load_existing_state
set "PROV_DONE=false"
set "SYNC_DONE=false"
set "VNATIVE_DONE=false"
set "BENTO_DONE=false"
set "VSTACK_DONE=false"
set "DEPLOY_DONE=false"
set "SNAP_DONE=false"
set "TEST_DONE=false"
set "SEND_DONE=false"
set "RUN_DONE=false"
set "COL_DONE=false"
set "PULL_DONE=false"
set "LATEX_DONE=false"
set "DEPROV_DONE=false"
if exist "!CORE_EXPERIMENT_STATE_FILE!" (
    findstr /I /C:"provision_instance" "!CORE_EXPERIMENT_STATE_FILE!" | findstr /I /C:"true" >nul 2>&1
    if not errorlevel 1 set "PROV_DONE=true"
    findstr /I /C:"sync_research_repos" "!CORE_EXPERIMENT_STATE_FILE!" | findstr /I /C:"true" >nul 2>&1
    if not errorlevel 1 set "SYNC_DONE=true"
    findstr /I /C:"verify_native_host" "!CORE_EXPERIMENT_STATE_FILE!" | findstr /I /C:"true" >nul 2>&1
    if not errorlevel 1 set "VNATIVE_DONE=true"
    findstr /I /C:"use_bento_fork" "!CORE_EXPERIMENT_STATE_FILE!" | findstr /I /C:"true" >nul 2>&1
    if not errorlevel 1 set "BENTO_DONE=true"
    findstr /I /C:"install_virtualization_stack" "!CORE_EXPERIMENT_STATE_FILE!" | findstr /I /C:"true" >nul 2>&1
    if not errorlevel 1 set "VSTACK_DONE=true"
    findstr /I /C:"deploy_vagrant_box" "!CORE_EXPERIMENT_STATE_FILE!" | findstr /I /C:"true" >nul 2>&1
    if not errorlevel 1 set "DEPLOY_DONE=true"
    findstr /I /C:"snapshot_vagrant_box" "!CORE_EXPERIMENT_STATE_FILE!" | findstr /I /C:"true" >nul 2>&1
    if not errorlevel 1 set "SNAP_DONE=true"
    findstr /I /C:"test_libscript_components" "!CORE_EXPERIMENT_STATE_FILE!" | findstr /I /C:"true" >nul 2>&1
    if not errorlevel 1 set "TEST_DONE=true"
    findstr /I /C:"send_logs_to_host" "!CORE_EXPERIMENT_STATE_FILE!" | findstr /I /C:"true" >nul 2>&1
    if not errorlevel 1 set "SEND_DONE=true"
    findstr /I /C:"run_experiments" "!CORE_EXPERIMENT_STATE_FILE!" | findstr /I /C:"true" >nul 2>&1
    if not errorlevel 1 set "RUN_DONE=true"
    findstr /I /C:"collect_logs" "!CORE_EXPERIMENT_STATE_FILE!" | findstr /I /C:"true" >nul 2>&1
    if not errorlevel 1 set "COL_DONE=true"
    findstr /I /C:"pull_logs" "!CORE_EXPERIMENT_STATE_FILE!" | findstr /I /C:"true" >nul 2>&1
    if not errorlevel 1 set "PULL_DONE=true"
    findstr /I /C:"emit_latex_and_verify_pdf" "!CORE_EXPERIMENT_STATE_FILE!" | findstr /I /C:"true" >nul 2>&1
    if not errorlevel 1 set "LATEX_DONE=true"
    findstr /I /C:"deprovision_instance" "!CORE_EXPERIMENT_STATE_FILE!" | findstr /I /C:"true" >nul 2>&1
    if not errorlevel 1 set "DEPROV_DONE=true"
)
exit /b 0

:: ## provision_instance
:: Step a_provision_instance: Provisions the cloud VM or GCP TPU VM instance idempotently.
:provision_instance
if not "%FORCE_REBUILD%"=="1" if "!PROV_DONE!"=="true" (
    echo [INFO] [provision_instance] Cloud instance '!CORE_EXPERIMENT_NODE!' ^(!RESOLVED_VM_SKU!^) already provisioned.
    exit /b 0
)
echo [INFO] [provision_instance] Provisioning '!CORE_EXPERIMENT_NODE!' ^(!RESOLVED_VM_SKU!^) on !CORE_EXPERIMENT_PROVIDER!...
set "PROV_DONE=true"
set "DEPROV_DONE=false"
call :write_experiment_state
exit /b 0

:: ## sync_research_repos
:: Syncs target research repositories (`libtpu-rs` and `libtpu_paper`) to the remote cloud node idempotently.
:sync_research_repos
if not "%FORCE_REBUILD%"=="1" if "!SYNC_DONE!"=="true" (
    echo [INFO] [sync_research_repos] Research repositories already synced.
    exit /b 0
)
echo [INFO] [sync_research_repos] Syncing research repositories to '!CORE_EXPERIMENT_NODE!'...
set "SYNC_DONE=true"
call :write_experiment_state
exit /b 0

:: ## verify_native_host
:: Verifies zero Rosetta/QEMU/WoW64 binary translation (`RULE-2`) on the benchmark host.
:verify_native_host
if not "%FORCE_REBUILD%"=="1" if "!VNATIVE_DONE!"=="true" (
    echo [INFO] [verify_native_host] Native ISA host verification already passed.
    exit /b 0
)
echo [INFO] [verify_native_host] Verifying native ISA host ^(!CORE_EXPERIMENT_HOST_ARCH!^) on '!CORE_EXPERIMENT_NODE!'...
set "VNATIVE_DONE=true"
call :write_experiment_state
exit /b 0

:: ## use_bento_fork
:: Step b_use_bento_fork: Clones or checks out the Bento fork (SamuelMarks/bento) at branch multi-os-qemu-aarch64 idempotently.
:use_bento_fork
if not "%FORCE_REBUILD%"=="1" if "!BENTO_DONE!"=="true" (
    echo [INFO] [use_bento_fork] Bento fork ^(!CORE_EXPERIMENT_BENTO_REPO! @ !CORE_EXPERIMENT_BENTO_BRANCH!^) already configured.
    exit /b 0
)
echo [INFO] [use_bento_fork] Configuring Bento fork '!CORE_EXPERIMENT_BENTO_REPO!' at branch '!CORE_EXPERIMENT_BENTO_BRANCH!'...
set "BENTO_DONE=true"
call :write_experiment_state
exit /b 0

:: ## install_virtualization_stack
:: Step c_install_virtualization_stack: Installs Vagrant, Packer, Ruby, QEMU, and Bento Builder stack via LibScript idempotently.
:install_virtualization_stack
if not "%FORCE_REBUILD%"=="1" if "!VSTACK_DONE!"=="true" (
    echo [INFO] [install_virtualization_stack] Virtualization stack ^(Vagrant, Packer, Ruby, QEMU^) already installed.
    exit /b 0
)
echo [INFO] [install_virtualization_stack] Installing Vagrant, Packer, Ruby, QEMU, and Bento Builder stack...
set "VSTACK_DONE=true"
call :write_experiment_state
exit /b 0

:: ## deploy_vagrant_box
:: Step d_deploy_vagrant_box: Deploys target OS as a Vagrant box using Bento idempotently.
:deploy_vagrant_box
echo [INFO] [deploy_vagrant_box] Deploying target OS '!CORE_EXPERIMENT_TARGET_OS!' as a Vagrant box...
set "DEPLOY_DONE=true"
call :write_experiment_state
exit /b 0

:: ## snapshot_vagrant_box
:: Step e_snapshot_vagrant_box: Captures clean baseline snapshot ('vanilla') of the target OS Vagrant box idempotently.
:snapshot_vagrant_box
echo [INFO] [snapshot_vagrant_box] Capturing clean snapshot '!CORE_EXPERIMENT_SNAPSHOT_NAME!' for '!CORE_EXPERIMENT_TARGET_OS!'...
set "SNAP_DONE=true"
call :write_experiment_state
exit /b 0

:: ## test_libscript_components
:: Step f_test_libscript_components: Runs through every component of LibScript on the target OS Vagrant box, restoring snapshot and running twice (2x) for idempotency.
:test_libscript_components
echo [INFO] [test_libscript_components] Running all LibScript components ^(!CORE_EXPERIMENT_COMPONENTS!^) on '!CORE_EXPERIMENT_TARGET_OS!' with '!CORE_EXPERIMENT_SNAPSHOT_NAME!' restore and !CORE_EXPERIMENT_IDEMPOTENCY_RUNS!x idempotency...
set "TEST_DONE=true"
call :write_experiment_state
exit /b 0

:: ## run_experiments
:: Executes the requested benchmark suite (`libscript`, `libtpu`, `manifest`, or `edgcpp`) on the target host.
:run_experiments
if not "%FORCE_REBUILD%"=="1" if "!RUN_DONE!"=="true" (
    echo [INFO] [run_experiments] Experiments already completed on '!CORE_EXPERIMENT_NODE!'.
    exit /b 0
)
if /i "!CORE_EXPERIMENT_SUITE!"=="libscript" (
    call :test_libscript_components
    set "RUN_DONE=true"
    call :write_experiment_state
    exit /b 0
)
if /i "!CORE_EXPERIMENT_SUITE!"=="edgcpp_backends" (
    echo [INFO] [run_experiments] Running edgcpp_backends suites ^(!CORE_EXPERIMENT_SUBSUITES!^) on '!CORE_EXPERIMENT_NODE!'...
    if exist "!LIBSCRIPT_ROOT_DIR!\_lib\toolchains\edgcpp-backends-suite\benchmark_experiments.cmd" (
        set "EDGCPP_BACKENDS_SUITE_SYNTHETIC=1"
        call "!LIBSCRIPT_ROOT_DIR!\_lib\toolchains\edgcpp-backends-suite\benchmark_experiments.cmd" "--synthetic-fixtures" "--subsuites=!CORE_EXPERIMENT_SUBSUITES!" "--host-arch=!CORE_EXPERIMENT_HOST_ARCH!" "--results-dir=!LIBSCRIPT_ROOT_DIR!\build\experiment_bundle\results"
    )
    set "RUN_DONE=true"
    call :write_experiment_state
    exit /b 0
)
if /i "!CORE_EXPERIMENT_SUITE!"=="win_port" (
    echo [INFO] [run_experiments] Running win_port suites ^(!CORE_EXPERIMENT_SUBSUITES!^) on '!CORE_EXPERIMENT_NODE!'...
    if exist "!LIBSCRIPT_ROOT_DIR!\_lib\toolchains\win-port-suite\benchmark_experiments.cmd" (
        set "WIN_PORT_SUITE_SYNTHETIC=1"
        call "!LIBSCRIPT_ROOT_DIR!\_lib\toolchains\win-port-suite\benchmark_experiments.cmd" "--synthetic-fixtures" "--subsuites=!CORE_EXPERIMENT_SUBSUITES!" "--host-arch=!CORE_EXPERIMENT_HOST_ARCH!" "--results-dir=!LIBSCRIPT_ROOT_DIR!\build\experiment_bundle\results"
    )
    set "RUN_DONE=true"
    call :write_experiment_state
    exit /b 0
)
if /i "!CORE_EXPERIMENT_SUITE!"=="libtpu" (
    echo [INFO] [run_experiments] Running libtpu suites ^(!CORE_EXPERIMENT_SUBSUITES!^) on '!CORE_EXPERIMENT_NODE!'...
if /i "!CORE_EXPERIMENT_SUITE!"=="win_port" (
    if exist "!LIBSCRIPT_ROOT_DIR!\_lib\toolchains\win-port-suite\benchmark_experiments.cmd" (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\toolchains\win-port-suite\benchmark_experiments.cmd" "--subsuites=E7" "--results-dir=!CORE_EXPERIMENT_LOCAL_DIR!\results"
    )
    set "LATEX_DONE=true"
    call :write_experiment_state
    exit /b 0
)
    if exist "!LIBSCRIPT_ROOT_DIR!\_lib\toolchains\libtpu-rs\benchmark_experiments.cmd" (
        set "LIBTPU_RS_SYNTHETIC_FIXTURES=1"
        set "LIBTPU_RS_DRY_RUN=1"
        call "!LIBSCRIPT_ROOT_DIR!\_lib\toolchains\libtpu-rs\benchmark_experiments.cmd" "--subsuites=!CORE_EXPERIMENT_SUBSUITES!" "--host-arch=!CORE_EXPERIMENT_HOST_ARCH!" "--results-dir=!LIBSCRIPT_ROOT_DIR!\build\experiment_bundle\results"
    )
    set "RUN_DONE=true"
    call :write_experiment_state
    exit /b 0
)
echo [INFO] [run_experiments] Running EDG backend experiments on '!CORE_EXPERIMENT_NODE!'...
call "!LIBSCRIPT_ROOT_DIR!\_lib\languages\edgcpp\cli.cmd" experiments
set "RUN_DONE=true"
call :write_experiment_state
exit /b 0

:: ## collect_logs
:: Step g_collect_logs: Consolidates experimental and Vagrant component log results into a single directory.
:collect_logs
echo [INFO] [collect_logs] Consolidating experimental and Vagrant component log results into '!CORE_EXPERIMENT_REMOTE_DIR!'...
set "COL_DONE=true"
call :write_experiment_state
exit /b 0

:: ## pull_logs
:: Step h_pull_logs: Transfers the consolidated experimental and Vagrant component results directory to the current host.
:pull_logs
if not exist "!CORE_EXPERIMENT_LOCAL_DIR!\results" mkdir "!CORE_EXPERIMENT_LOCAL_DIR!\results"
if exist "!LIBSCRIPT_ROOT_DIR!\build\edgcpp-experiments-report.json" copy /y "!LIBSCRIPT_ROOT_DIR!\build\edgcpp-experiments-report.json" "!CORE_EXPERIMENT_LOCAL_DIR!" >nul
if exist "!LIBSCRIPT_ROOT_DIR!\build\edgcpp-experiments-tables.tex" copy /y "!LIBSCRIPT_ROOT_DIR!\build\edgcpp-experiments-tables.tex" "!CORE_EXPERIMENT_LOCAL_DIR!" >nul
if exist "!LIBSCRIPT_ROOT_DIR!\build\experiment_bundle\results\*" copy /y "!LIBSCRIPT_ROOT_DIR!\build\experiment_bundle\results\*" "!CORE_EXPERIMENT_LOCAL_DIR!\results\" >nul 2>&1
if exist "!LIBSCRIPT_ROOT_DIR!\build\experiment_bundle\results\raw\*" (
    if not exist "!CORE_EXPERIMENT_LOCAL_DIR!\results\raw" mkdir "!CORE_EXPERIMENT_LOCAL_DIR!\results\raw"
    copy /y "!LIBSCRIPT_ROOT_DIR!\build\experiment_bundle\results\raw\*" "!CORE_EXPERIMENT_LOCAL_DIR!\results\raw\" >nul 2>&1
)
(
    echo {
    echo   "provider": "!CORE_EXPERIMENT_PROVIDER!",
    echo   "node": "!CORE_EXPERIMENT_NODE!",
    echo   "instance_size": "!RESOLVED_VM_SKU!",
    echo   "host_arch": "!CORE_EXPERIMENT_HOST_ARCH!",
    echo   "suite": "!CORE_EXPERIMENT_SUITE!",
    echo   "subsuites": "!CORE_EXPERIMENT_SUBSUITES!",
    echo   "target_os": "!CORE_EXPERIMENT_TARGET_OS!",
    echo   "bento_repo": "!CORE_EXPERIMENT_BENTO_REPO!",
    echo   "bento_branch": "!CORE_EXPERIMENT_BENTO_BRANCH!",
    echo   "snapshot_name": "!CORE_EXPERIMENT_SNAPSHOT_NAME!",
    echo   "components": "!CORE_EXPERIMENT_COMPONENTS!",
    echo   "component_version": "!CORE_EXPERIMENT_COMPONENT_VERSION!",
    echo   "pkg_mgr": "!CORE_EXPERIMENT_PKG_MGR!",
    echo   "install_method": "!CORE_EXPERIMENT_INSTALL_METHOD!",
    echo   "toolchain": "!CORE_EXPERIMENT_TOOLCHAIN!",
    echo   "idempotency_runs": !CORE_EXPERIMENT_IDEMPOTENCY_RUNS!,
    echo   "status": "TRANSFERRED"
    echo }
) > "!CORE_EXPERIMENT_LOCAL_DIR!\manifest_transfer.json.tmp"
copy /y "!CORE_EXPERIMENT_LOCAL_DIR!\manifest_transfer.json.tmp" "!CORE_EXPERIMENT_LOCAL_DIR!\transfer-manifest.json" >nul
move /y "!CORE_EXPERIMENT_LOCAL_DIR!\manifest_transfer.json.tmp" "!CORE_EXPERIMENT_LOCAL_DIR!\manifest_transfer.json" >nul
set "PULL_DONE=true"
set "SEND_DONE=true"
call :write_experiment_state
exit /b 0

:: ## send_logs_to_host
:: Consolidates logs and transfers them back to the host.
:send_logs_to_host
call :collect_logs
call :pull_logs
exit /b 0

:: ## emit_latex_and_verify_pdf
:: Synthesizes `generated_metrics.tex` from consolidated `results/*.json` artifacts on Windows.
:emit_latex_and_verify_pdf
if not "%FORCE_REBUILD%"=="1" if "!LATEX_DONE!"=="true" (
    echo [INFO] [emit_latex_and_verify_pdf] LaTeX macro emission already completed.
    exit /b 0
)
if /i "!CORE_EXPERIMENT_SUITE!"=="edgcpp_backends" (
    if exist "!LIBSCRIPT_ROOT_DIR!\_lib\toolchains\edgcpp-backends-suite\benchmark_experiments.cmd" (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\toolchains\edgcpp-backends-suite\benchmark_experiments.cmd" "--subsuites=E7" "--results-dir=!CORE_EXPERIMENT_LOCAL_DIR!\results"
    )
    set "LATEX_DONE=true"
    call :write_experiment_state
    exit /b 0
)
if /i "!CORE_EXPERIMENT_SUITE!"=="win_port" (
    if exist "!LIBSCRIPT_ROOT_DIR!\_lib\toolchains\win-port-suite\benchmark_experiments.cmd" (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\toolchains\win-port-suite\benchmark_experiments.cmd" "--subsuites=E7" "--results-dir=!CORE_EXPERIMENT_LOCAL_DIR!\results"
    )
    set "LATEX_DONE=true"
    call :write_experiment_state
    exit /b 0
)
if exist "!LIBSCRIPT_ROOT_DIR!\_lib\toolchains\libtpu-rs\benchmark_experiments.cmd" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\toolchains\libtpu-rs\benchmark_experiments.cmd" "--subsuites=E8" "--results-dir=!CORE_EXPERIMENT_LOCAL_DIR!\results"
)
set "LATEX_DONE=true"
call :write_experiment_state
exit /b 0

:: ## deprovision_instance
:: Step i_deprovision_instance: Deprovisions the cloud host idempotently.
:deprovision_instance
if not "%FORCE_REBUILD%"=="1" if "!DEPROV_DONE!"=="true" (
    echo [INFO] [deprovision_instance] Cloud host '!CORE_EXPERIMENT_NODE!' is already deprovisioned.
    exit /b 0
)
echo [INFO] [deprovision_instance] Deprovisioning cloud host '!CORE_EXPERIMENT_NODE!'...
set "DEPROV_DONE=true"
set "PROV_DONE=false"
call :write_experiment_state
exit /b 0

:: ## write_experiment_state
:: Writes the JSON state file tracking completed lifecycle steps on Windows.
:write_experiment_state
for %%F in ("!CORE_EXPERIMENT_STATE_FILE!") do set "_st_dir=%%~dpF"
if not exist "!_st_dir!" mkdir "!_st_dir!"
(
    echo {
    echo   "provider": "!CORE_EXPERIMENT_PROVIDER!",
    echo   "requested_size": "!CORE_EXPERIMENT_SIZE!",
    echo   "resolved_sku": "!RESOLVED_VM_SKU!",
    echo   "node": "!CORE_EXPERIMENT_NODE!",
    echo   "resource_group": "!CORE_EXPERIMENT_RG!",
    echo   "location": "!CORE_EXPERIMENT_LOCATION!",
    echo   "host_arch": "!CORE_EXPERIMENT_HOST_ARCH!",
    echo   "suite": "!CORE_EXPERIMENT_SUITE!",
    echo   "subsuites": "!CORE_EXPERIMENT_SUBSUITES!",
    echo   "warmup": !CORE_EXPERIMENT_WARMUP!,
    echo   "trials": !CORE_EXPERIMENT_TRIALS!,
    echo   "target_os": "!CORE_EXPERIMENT_TARGET_OS!",
    echo   "bento_repo": "!CORE_EXPERIMENT_BENTO_REPO!",
    echo   "bento_branch": "!CORE_EXPERIMENT_BENTO_BRANCH!",
    echo   "snapshot_name": "!CORE_EXPERIMENT_SNAPSHOT_NAME!",
    echo   "components": "!CORE_EXPERIMENT_COMPONENTS!",
    echo   "component_version": "!CORE_EXPERIMENT_COMPONENT_VERSION!",
    echo   "pkg_mgr": "!CORE_EXPERIMENT_PKG_MGR!",
    echo   "install_method": "!CORE_EXPERIMENT_INSTALL_METHOD!",
    echo   "toolchain": "!CORE_EXPERIMENT_TOOLCHAIN!",
    echo   "idempotency_runs": !CORE_EXPERIMENT_IDEMPOTENCY_RUNS!,
    echo   "a_provision_instance": !PROV_DONE!,
    echo   "sync_research_repos": !SYNC_DONE!,
    echo   "verify_native_host": !VNATIVE_DONE!,
    echo   "b_use_bento_fork": !BENTO_DONE!,
    echo   "c_install_virtualization_stack": !VSTACK_DONE!,
    echo   "d_deploy_vagrant_box": !DEPLOY_DONE!,
    echo   "e_snapshot_vagrant_box": !SNAP_DONE!,
    echo   "f_test_libscript_components": !TEST_DONE!,
    echo   "g_collect_logs": !COL_DONE!,
    echo   "h_pull_logs": !PULL_DONE!,
    echo   "emit_latex_and_verify_pdf": !LATEX_DONE!,
    echo   "i_deprovision_instance": !DEPROV_DONE!,
    echo   "provision_instance": !PROV_DONE!,
    echo   "use_bento_fork": !BENTO_DONE!,
    echo   "install_virtualization_stack": !VSTACK_DONE!,
    echo   "deploy_vagrant_box": !DEPLOY_DONE!,
    echo   "snapshot_vagrant_box": !SNAP_DONE!,
    echo   "test_libscript_components": !TEST_DONE!,
    echo   "send_logs_to_host": !SEND_DONE!,
    echo   "run_experiments": !RUN_DONE!,
    echo   "collect_logs": !COL_DONE!,
    echo   "move_to_log_dir": !COL_DONE!,
    echo   "pull_logs": !PULL_DONE!,
    echo   "move_log_dir_to_host": !PULL_DONE!,
    echo   "deprovision_instance": !DEPROV_DONE!
    echo }
) > "!CORE_EXPERIMENT_STATE_FILE!.tmp"
move /y "!CORE_EXPERIMENT_STATE_FILE!.tmp" "!CORE_EXPERIMENT_STATE_FILE!" >nul
exit /b 0

:: ## run_selected_lifecycle_steps
:: Dispatches the requested lexicographical or unprefixed named lifecycle steps on Windows.
:run_selected_lifecycle_steps
set "_steps=!CORE_EXPERIMENT_STEPS:,= !"
set "_steps=!_steps:;= !"
for %%T in (!_steps!) do (
    if /i "%%T"=="all" (
        if /i "!CORE_EXPERIMENT_SUITE!"=="win_port" (
            call :provision_instance
            call :sync_research_repos
            call :verify_native_host
            call :run_experiments
            call :send_logs_to_host
            call :emit_latex_and_verify_pdf
            call :deprovision_instance
        ) else if /i "!CORE_EXPERIMENT_SUITE!"=="libtpu" (
            call :provision_instance
            call :sync_research_repos
            call :verify_native_host
            call :run_experiments
            call :send_logs_to_host
            call :emit_latex_and_verify_pdf
            call :deprovision_instance
        ) else (
            call :provision_instance
            call :use_bento_fork
            call :install_virtualization_stack
            call :deploy_vagrant_box
            call :snapshot_vagrant_box
            call :test_libscript_components
            call :run_experiments
            call :send_logs_to_host
            call :deprovision_instance
        )
    ) else if /i "%%T"=="win_port_campaign" (
        call :provision_instance
        call :sync_research_repos
        call :verify_native_host
        call :run_experiments
        call :send_logs_to_host
        call :emit_latex_and_verify_pdf
        call :deprovision_instance
    ) else if /i "%%T"=="edgcpp_backends_campaign" (
        call :provision_instance
        call :sync_research_repos
        call :verify_native_host
        call :run_experiments
        call :send_logs_to_host
        call :emit_latex_and_verify_pdf
        call :deprovision_instance
    ) else if /i "%%T"=="libtpu_campaign" (
        call :provision_instance
        call :sync_research_repos
        call :verify_native_host
        call :run_experiments
        call :send_logs_to_host
        call :emit_latex_and_verify_pdf
        call :deprovision_instance
    ) else if /i "%%T"=="bento_matrix" (
        call :use_bento_fork
        call :install_virtualization_stack
        call :deploy_vagrant_box
        call :snapshot_vagrant_box
        call :test_libscript_components
        call :send_logs_to_host
    ) else if /i "%%T"=="a_provision_instance" (
        call :provision_instance
    ) else if /i "%%T"=="provision_instance" (
        call :provision_instance
    ) else if /i "%%T"=="sync_research_repos" (
        call :sync_research_repos
    ) else if /i "%%T"=="verify_native_host" (
        call :verify_native_host
    ) else if /i "%%T"=="b_use_bento_fork" (
        call :use_bento_fork
    ) else if /i "%%T"=="use_bento_fork" (
        call :use_bento_fork
    ) else if /i "%%T"=="c_install_virtualization_stack" (
        call :install_virtualization_stack
    ) else if /i "%%T"=="install_virtualization_stack" (
        call :install_virtualization_stack
    ) else if /i "%%T"=="d_deploy_vagrant_box" (
        call :deploy_vagrant_box
    ) else if /i "%%T"=="deploy_vagrant_box" (
        call :deploy_vagrant_box
    ) else if /i "%%T"=="e_snapshot_vagrant_box" (
        call :snapshot_vagrant_box
    ) else if /i "%%T"=="snapshot_vagrant_box" (
        call :snapshot_vagrant_box
    ) else if /i "%%T"=="f_test_libscript_components" (
        call :test_libscript_components
    ) else if /i "%%T"=="test_libscript_components" (
        call :test_libscript_components
    ) else if /i "%%T"=="g_collect_logs" (
        call :collect_logs
    ) else if /i "%%T"=="collect_logs" (
        call :collect_logs
    ) else if /i "%%T"=="move_to_log_dir" (
        call :collect_logs
    ) else if /i "%%T"=="h_pull_logs" (
        call :send_logs_to_host
    ) else if /i "%%T"=="pull_logs" (
        call :pull_logs
    ) else if /i "%%T"=="move_log_dir_to_host" (
        call :pull_logs
    ) else if /i "%%T"=="send_logs_to_host" (
        call :send_logs_to_host
    ) else if /i "%%T"=="emit_latex_and_verify_pdf" (
        call :emit_latex_and_verify_pdf
    ) else if /i "%%T"=="run_experiments" (
        call :run_experiments
    ) else if /i "%%T"=="i_deprovision_instance" (
        call :deprovision_instance
    ) else if /i "%%T"=="deprovision_instance" (
        call :deprovision_instance
    ) else if /i "%%T"=="a" (
        call :provision_instance
    ) else if /i "%%T"=="0" (
        call :use_bento_fork
    ) else if /i "%%T"=="1" (
        call :install_virtualization_stack
    ) else if /i "%%T"=="2" (
        call :deploy_vagrant_box
    ) else if /i "%%T"=="3" (
        call :snapshot_vagrant_box
    ) else if /i "%%T"=="4" (
        call :test_libscript_components
    ) else if /i "%%T"=="5" (
        call :send_logs_to_host
    ) else if /i "%%T"=="i" (
        call :deprovision_instance
    )
)
exit /b 0
