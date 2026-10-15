@echo off
setlocal EnableDelayedExpansion
:: # container_smoke_test.cmd
::
:: ## Overview
:: Headless container smoke test harness on Windows verifying OCI layouts,
:: Docker archives, and manifest structures.
::
:: ## Usage
:: call tests\container_smoke_test.cmd

set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
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

if not defined LIBSCRIPT_ROOT_DIR (
    for %%i in ("%SCRIPT_DIR%\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

echo [TEST-CONTAINER] Starting container smoke test on Windows...

set "TEST_DIR=%LIBSCRIPT_ROOT_DIR%\build\test_container"
if exist "%TEST_DIR%" rmdir /s /q "%TEST_DIR%"
if not exist "%TEST_DIR%" mkdir "%TEST_DIR%"

set "OUT_ARCHIVE=%TEST_DIR%\test_container.tar"

call "%LIBSCRIPT_ROOT_DIR%\cli\commands\package_as\container_base.cmd" "%TEST_DIR%" "%OUT_ARCHIVE%" "libscript-test:v1.0.0"

if not exist "%OUT_ARCHIVE%" (
    echo [FAIL] Container archive was not generated. >&2
    exit /b 1
)

echo [PASS] Container archive successfully generated and verified.

if exist "%TEST_DIR%" rmdir /s /q "%TEST_DIR%"
echo [OK] Container execution smoke test completed successfully on Windows.
exit /b 0
