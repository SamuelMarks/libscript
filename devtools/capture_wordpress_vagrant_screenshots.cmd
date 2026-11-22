@echo off
:: # capture_wordpress_vagrant_screenshots.cmd
:: ## Overview
:: Backward-compatible Windows wrapper delegating WordPress Vagrant MSI screenshot capture to `pkg_ui_runner.cmd`.
:: ## Usage
:: capture_wordpress_vagrant_screenshots.cmd [--target-os=windows-11] [--pkg-source=build|github-release] [--dry-run=1]

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
set "WP_SUITE_ROOT=!LIBSCRIPT_ROOT_DIR!\tests_tmp\experiments\_transient_suites"
if not exist "!WP_SUITE_ROOT!" mkdir "!WP_SUITE_ROOT!"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" experiment scaffold wordpress "--template=installer-e2e" "--packaging-manifest=!LIBSCRIPT_ROOT_DIR!\workloads\apps\wordpress\packaging.json" "--out-root=!WP_SUITE_ROOT!" >nul
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\experiments\_common\pkg_ui_runner.cmd" "--suite-dir=!WP_SUITE_ROOT!\wordpress" "--target-os=windows-11" "--pkg-format=msi" %*
exit /b !errorlevel!
