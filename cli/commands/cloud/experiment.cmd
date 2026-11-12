@echo off
:: # experiment.cmd
:: ## Overview
:: CLI command wrapper for the unified rapid cloud and Bento multi-OS Vagrant matrix experimentation lifecycle (`a` / `provision_instance`, `0` / `use_bento_fork`, `1` / `install_virtualization_stack`, `2` / `deploy_vagrant_box`, `3` / `snapshot_vagrant_box`, `4` / `test_libscript_components`, `5` / `send_logs_to_host`, `i` / `deprovision_instance`) on Windows.
:: ## Usage
:: libscript.cmd experiment [a|0|1|2|3|4|5|i|provision_instance|use_bento_fork|install_virtualization_stack|deploy_vagrant_box|snapshot_vagrant_box|test_libscript_components|send_logs_to_host|deprovision_instance|bento_matrix|all] [--target-os=alpine-3.24]

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

call "!LIBSCRIPT_ROOT_DIR!\_lib\cloud\core\experiment_cloud.cmd" %*
exit /b !errorlevel!
