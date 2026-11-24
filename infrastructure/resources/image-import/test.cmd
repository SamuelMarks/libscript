@echo off
:: # test.cmd
::
:: ## Overview
:: Smoke and 2x-idempotency test for `infrastructure\resources\image-import` on Windows.
::
:: ## Usage
:: test.cmd

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

set "_TMP=!LIBSCRIPT_ROOT_DIR!\tests_tmp\img_import_%RANDOM%"
if not exist "!_TMP!" mkdir "!_TMP!"
set "LIBSCRIPT_BUILD_DIR=!_TMP!\build"
set "LIBSCRIPT_OFFLINE=1"
set "LIBSCRIPT_ALLOW_STUB=1"

call "!SCRIPT_DIR!\cli.cmd" --help >nul
if errorlevel 1 goto :fail_test

for %%D in (linux-distro freebsd-distro illumos-distro reactos-distro unikernel-distro) do (
    set "_ART=!_TMP!\%%D.raw"
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" package-as %%D --format raw --output "!_ART!" --allow-stub >nul
    if errorlevel 1 goto :fail_test
    set "STACK="
    call "!SCRIPT_DIR!\cli.cmd" distro "--disk=!_ART!" --clouds=aws,gcp,azure --dry-run >nul
    if errorlevel 1 goto :fail_test
    set "STACK="
    call "!SCRIPT_DIR!\cli.cmd" distro "--disk=!_ART!" --clouds=aws,gcp,azure --dry-run >nul
    if errorlevel 1 goto :fail_test
    if not exist "!_ART!.multicloud-receipt.json" goto :fail_test
)

rmdir /s /q "!_TMP!" 2>nul
echo [PASS] Windows image-import multicloud distro artifact tests passed.
exit /b 0

:: ## fail_test
:: Cleans temporary directory and exits with failure status.
:fail_test
if exist "!_TMP!" rmdir /s /q "!_TMP!" 2>nul
echo [FAIL] Windows image-import test failed. >&2
exit /b 1
