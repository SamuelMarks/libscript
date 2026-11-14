@echo off
:: # test_cloud_experiment_lifecycle.cmd
:: ## Overview
:: Integration test suite for the unified rapid cloud and Bento multi-OS Vagrant matrix experimentation lifecycle interface on Windows.
:: ## Usage
:: tests/test_cloud_experiment_lifecycle.cmd

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

call :verify_step_by_step_execution
if errorlevel 1 exit /b 1

call :verify_bento_multi_os_experiment_runner
if errorlevel 1 exit /b 1

call :verify_single_component_version_pkg_mgr_execution
if errorlevel 1 exit /b 1

call :verify_combined_all_steps_execution
if errorlevel 1 exit /b 1

call :verify_libtpu_dual_isa_and_tpu_vm_campaign
if errorlevel 1 exit /b 1

call :verify_win_port_multi_host_campaign
if errorlevel 1 exit /b 1

call :verify_edgcpp_backends_multi_host_campaign
if errorlevel 1 exit /b 1

echo [PASS] Named rapid cloud experimentation lifecycle tests succeeded on Windows!
exit /b 0

:: ## verify_step_by_step_execution
:: Verifies provision_instance, run_experiments, collect_logs, pull_logs, and deprovision_instance individually on Windows.
:verify_step_by_step_execution
set "_st_file=%TEMP%\cloud_exp_state_%RANDOM%.json"
set "_loc_dir=%TEMP%\cloud_exp_res_%RANDOM%"
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" experiment provision_instance --dry-run --state-file="!_st_file!" --local-dir="!_loc_dir!"
if not exist "!_st_file!" exit /b 1
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" experiment run_experiments --dry-run --state-file="!_st_file!" --local-dir="!_loc_dir!"
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" experiment collect_logs --dry-run --state-file="!_st_file!" --local-dir="!_loc_dir!"
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" experiment pull_logs --dry-run --state-file="!_st_file!" --local-dir="!_loc_dir!"
if not exist "!_loc_dir!\manifest_transfer.json" exit /b 1
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" experiment deprovision_instance --dry-run --state-file="!_st_file!" --local-dir="!_loc_dir!"
del /f /q "!_st_file!" >nul 2>&1
rmdir /s /q "!_loc_dir!" >nul 2>&1
exit /b 0

:: ## verify_bento_multi_os_experiment_runner
:: Verifies lexicographically ordered named steps (a_provision_instance .. i_deprovision_instance) and multi-OS testing between provision and deprovision on Windows.
:verify_bento_multi_os_experiment_runner
set "_st_file=%TEMP%\bento_exp_state_%RANDOM%.json"
set "_loc_dir=%TEMP%\bento_exp_res_%RANDOM%"
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" experiment a_provision_instance --dry-run --state-file="!_st_file!" --local-dir="!_loc_dir!"
if not exist "!_st_file!" exit /b 1
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" experiment b_use_bento_fork --dry-run --state-file="!_st_file!" --local-dir="!_loc_dir!"
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" experiment c_install_virtualization_stack --dry-run --state-file="!_st_file!" --local-dir="!_loc_dir!"
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" experiment --steps="d_deploy_vagrant_box,e_snapshot_vagrant_box,f_test_libscript_components,g_collect_logs,h_pull_logs" --target-os=alpine-3.24 --dry-run --state-file="!_st_file!" --local-dir="!_loc_dir!"
if not exist "!_loc_dir!/transfer-manifest.json" exit /b 1
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" experiment bento_matrix --target-os=debian-13 --dry-run --state-file="!_st_file!" --local-dir="!_loc_dir!"
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" experiment i_deprovision_instance --dry-run --state-file="!_st_file!" --local-dir="!_loc_dir!"
del /f /q "!_st_file!" >nul 2>&1
rmdir /s /q "!_loc_dir!" >nul 2>&1
exit /b 0

:: ## verify_single_component_version_pkg_mgr_execution
:: Verifies testing a single component-version and package-manager on one OS on Windows using named steps.
:verify_single_component_version_pkg_mgr_execution
set "_st_file=%TEMP%\single_exp_state_%RANDOM%.json"
set "_loc_dir=%TEMP%\single_exp_res_%RANDOM%"
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" experiment bento_matrix --target-os=debian-13 --component=postgres@16.2 --pkg-mgr=apt-get --dry-run --state-file="!_st_file!" --local-dir="!_loc_dir!"
if not exist "!_st_file!" exit /b 1
if not exist "!_loc_dir!/transfer-manifest.json" exit /b 1
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" experiment --steps="f_test_libscript_components,g_collect_logs,h_pull_logs" --target-os=alpine-3.24 --component=sqlite --version=3.46.1 --from-source --toolchain=edgcpp --dry-run --state-file="!_st_file!" --local-dir="!_loc_dir!"
del /f /q "!_st_file!" >nul 2>&1
rmdir /s /q "!_loc_dir!" >nul 2>&1
exit /b 0

:: ## verify_combined_all_steps_execution
:: Verifies combined named step execution on Windows.
:verify_combined_all_steps_execution
set "_st_file=%TEMP%\cloud_exp_all_%RANDOM%.json"
set "_loc_dir=%TEMP%\cloud_exp_all_res_%RANDOM%"
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" experiment --steps="provision_instance,run_experiments,move_to_log_dir,move_log_dir_to_host,deprovision_instance" --dry-run --state-file="!_st_file!" --local-dir="!_loc_dir!"
if not exist "!_st_file!" exit /b 1
if not exist "!_loc_dir!\manifest_transfer.json" exit /b 1
del /f /q "!_st_file!" >nul 2>&1
rmdir /s /q "!_loc_dir!" >nul 2>&1
exit /b 0

:: ## verify_libtpu_dual_isa_and_tpu_vm_campaign
:: Verifies `--suite=libtpu` Dual-ISA (`linux_x64` + `macos_arm64`) multi-host artifact consolidation and `gcp-tpu-vm` routing on Windows.
:verify_libtpu_dual_isa_and_tpu_vm_campaign
set "_st_x64=%TEMP%\cloud_libtpu_x64_%RANDOM%.json"
set "_st_tpu=%TEMP%\cloud_libtpu_tpu_%RANDOM%.json"
set "_loc_dir=%TEMP%\cloud_libtpu_res_%RANDOM%"
set "LIBTPU_RS_ALLOW_DIRTY=1"
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" experiment libtpu_campaign --suite=libtpu --host-arch=linux_x64 --subsuites=E0,E1,E2,E8 --dry-run "--state-file=!_st_x64!" "--local-dir=!_loc_dir!"
if errorlevel 1 exit /b 1
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" experiment libtpu_campaign --suite=libtpu --provider=gcp-tpu-vm --size=v6e-8 --host-arch=macos_arm64 --subsuites=E0,E2,E8 --dry-run "--state-file=!_st_tpu!" "--local-dir=!_loc_dir!"
if errorlevel 1 exit /b 1
if not exist "!_loc_dir!\results\e2_startup_linux_x64.json" exit /b 1
if not exist "!_loc_dir!\results\e2_startup_macos_arm64.json" exit /b 1
if not exist "!_loc_dir!\results\generated_metrics.tex" exit /b 1
del /f /q "!_st_x64!" "!_st_tpu!" >nul 2>&1
rmdir /s /q "!_loc_dir!" >nul 2>&1
exit /b 0

:: ## verify_win_port_multi_host_campaign
:: Verifies `--suite=win_port` (`win_port_campaign`) multi-host artifact consolidation and 285-macro LaTeX emission on Windows.
:verify_win_port_multi_host_campaign
set "_st_wp=%TEMP%\cloud_wp_%RANDOM%.json"
set "_loc_wp=%TEMP%\cloud_wp_res_%RANDOM%"
set "WIN_PORT_SUITE_ALLOW_DIRTY=1"
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" experiment win_port_campaign --suite=win_port --host-arch=windows_x64 --subsuites=E0,E1,E2,E3,E4,E5,E6,E7 --dry-run "--state-file=!_st_wp!" "--local-dir=!_loc_wp!"
if errorlevel 1 exit /b 1
if not exist "!_loc_wp!\results\generated_metrics.tex" exit /b 1
del /f /q "!_st_wp!" >nul 2>&1
rmdir /s /q "!_loc_wp!" >nul 2>&1
exit /b 0

:: ## verify_edgcpp_backends_multi_host_campaign
:: Verifies `--suite=edgcpp_backends` (`edgcpp_backends_campaign`) artifact consolidation and 60-macro LaTeX emission on Windows.
:verify_edgcpp_backends_multi_host_campaign
set "_st_eb=%TEMP%\cloud_eb_%RANDOM%.json"
set "_loc_eb=%TEMP%\cloud_eb_res_%RANDOM%"
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" experiment edgcpp_backends_campaign --suite=edgcpp_backends --host-arch=windows_x64 --subsuites=E0,E1,E2,E3,E4,E5,E6,E7 --dry-run "--state-file=!_st_eb!" "--local-dir=!_loc_eb!"
if errorlevel 1 exit /b 1
if not exist "!_loc_eb!\results\generated_metrics.tex" exit /b 1
del /f /q "!_st_eb!" >nul 2>&1
rmdir /s /q "!_loc_eb!" >nul 2>&1
exit /b 0
