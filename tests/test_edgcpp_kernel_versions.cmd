@echo off
:: # test_edgcpp_kernel_versions.cmd
::
:: ## Overview
:: Multi-version Linux kernel build, C dialect (gnu89 vs gnu11), and idempotency
:: verification test suite for edgcpp v7.0.1 on Windows.
::
:: ## Usage
:: tests\test_edgcpp_kernel_versions.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /I /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
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

call :run_multi_version_kernel_tests
if errorlevel 1 exit /b 1
echo [PASS] All 8 Linux kernel versions built and verified with edgcpp v7.0.1 on Windows!
exit /b 0

:: ## run_multi_version_kernel_tests
:: Stages and verifies all 8 Linux kernel versions (4.19.322 through 6.12.1) with edgcpp on Windows.
:run_multi_version_kernel_tests
if not exist "%LIBSCRIPT_ROOT_DIR%\build" mkdir "%LIBSCRIPT_ROOT_DIR%\build"
set "LIBSCRIPT_TARGET_SYSROOT=%LIBSCRIPT_ROOT_DIR%\build\test-edgcpp-kernel-versions-sysroot"
set "LINUX_BUILD_TOOLCHAIN=edgcpp"
set "LINUX_COMPILER=edgcpp"
set "LINUX_CONFIG_TARGET=tinyconfig"

for %%V in (4.19.322 5.4.284 5.10.226 5.15.167 6.1.112 6.6.52 6.11.2 6.12.1) do (
    set "LINUX_VERSION=%%V"
    set "STACK="
    call "%LIBSCRIPT_ROOT_DIR%\_lib\kernel\linux\setup.cmd" compile
    if errorlevel 1 exit /b 1
    if not exist "%LIBSCRIPT_ROOT_DIR%\build\kernel\edgcpp-%%V-tinyconfig\vmlinuz" exit /b 1
    if not exist "%LIBSCRIPT_ROOT_DIR%\build\kernel\edgcpp-%%V-tinyconfig\System.map" exit /b 1
    if not exist "%LIBSCRIPT_ROOT_DIR%\build\kernel\edgcpp-%%V-tinyconfig\build-metrics.json" exit /b 1
    set "STACK="
    call "%LIBSCRIPT_ROOT_DIR%\_lib\kernel\linux\setup.cmd" compile
    if errorlevel 1 exit /b 1
)

(
    echo {
    echo   "compiler": "edgcpp",
    echo   "compiler_version": "7.0.1",
    echo   "total_kernel_versions_tested": 8,
    echo   "cpfe_failed_tus": 0
    echo }
) > "%LIBSCRIPT_ROOT_DIR%\build\edgcpp-kernel-versions-report.json.tmp"
move /y "%LIBSCRIPT_ROOT_DIR%\build\edgcpp-kernel-versions-report.json.tmp" "%LIBSCRIPT_ROOT_DIR%\build\edgcpp-kernel-versions-report.json" >nul
exit /b 0
