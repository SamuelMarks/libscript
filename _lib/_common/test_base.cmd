@echo off
:: # LibScript Common Test Entrypoint (Windows Batch)
:: ## Overview
:: Standardized entrypoint for component testing on Windows. Resolves root, sets paths, and provides assertion helpers.
:: ## Usage
:: Your component's `test.cmd` should call this. ```batch @echo off call "%~dp0\..\..\..\_lib\_common\test_base.cmd" ```

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

:: Resolve LIBSCRIPT_ROOT_DIR
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

if "%LIBSCRIPT_BUILD_DIR%"=="" set "LIBSCRIPT_BUILD_DIR=%TEMP%\libscript_build"
if "%LIBSCRIPT_DATA_DIR%"=="" set "LIBSCRIPT_DATA_DIR=%TEMP%\libscript_data"
if not exist "!LIBSCRIPT_BUILD_DIR!" mkdir "!LIBSCRIPT_BUILD_DIR!"
if not exist "!LIBSCRIPT_DATA_DIR!" mkdir "!LIBSCRIPT_DATA_DIR!"

if exist "%CD%\env.cmd" (
    set "STACK="
    call "%CD%\env.cmd"
)

set "_FIRST_ARG=%~1"
if not "!_FIRST_ARG!"=="" (
    if "!_FIRST_ARG:~0,1!"==":" (
        set "STACK="
        call !_FIRST_ARG! "%~2" "%~3" "%~4"
        exit /b !errorlevel!
    )
)
exit /b 0

:: ## assert_version
:: Verifies that a command exists in PATH and its --version output matches the expected pattern.
:assert_version
set "_AV_CMD=%~1"
set "_AV_EXP=%~2"
if "!_AV_CMD!"=="" (
    echo [FAIL] command not specified >&2
    exit /b 1
)
if "!_AV_CMD!"=="_noop" (
    echo [PASS] _noop version check skipped >&2
    exit /b 0
)
where "!_AV_CMD!" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] !_AV_CMD! command not found >&2
    exit /b 1
)
set "_AV_OUT="
for /f "delims=" %%V in ('"!_AV_CMD!" --version 2^>^&1') do (
    if not defined _AV_OUT set "_AV_OUT=%%V"
)
if "!_AV_EXP!"=="" set "_AV_EXP=."
if "!_AV_EXP!"=="." (
    echo [PASS] !_AV_CMD! version check: !_AV_OUT! >&2
    exit /b 0
)
echo "!_AV_OUT!" | findstr /I /R "!_AV_EXP!" >nul 2>&1
if not errorlevel 1 (
    echo [PASS] !_AV_CMD! version check: !_AV_OUT! >&2
    exit /b 0
)
echo [FAIL] !_AV_CMD! version check failed. Expected pattern: !_AV_EXP!, Got: !_AV_OUT! >&2
exit /b 1

:: ## assert_service_up
:: Verifies that a TCP service on the target host and port is reachable within the timeout.
:assert_service_up
set "_AS_HOST=%~1"
set "_AS_PORT=%~2"
set "_AS_TIMEOUT=%~3"
if "!_AS_TIMEOUT!"=="" set "_AS_TIMEOUT=10"
echo [INFO] Waiting for service at !_AS_HOST!:!_AS_PORT! (timeout !_AS_TIMEOUT!s)... >&2
powershell -NoProfile -Command "$end = (Get-Date).AddSeconds([int]'!_AS_TIMEOUT!'); while ((Get-Date) -lt $end) { try { $c = New-Object System.Net.Sockets.TcpClient('!_AS_HOST!', [int]'!_AS_PORT!'); $c.Close(); exit 0 } catch { Start-Sleep -Seconds 1 } }; exit 1" >nul 2>&1
if not errorlevel 1 (
    echo [PASS] Service at !_AS_HOST!:!_AS_PORT! is UP >&2
    exit /b 0
)
echo [FAIL] Service at !_AS_HOST!:!_AS_PORT! is DOWN >&2
exit /b 1

:: ## assert_exists
:: Verifies that the specified file or directory exists on the filesystem.
:assert_exists
set "_AE_PATH=%~1"
if exist "!_AE_PATH!" (
    echo [PASS] Exists: !_AE_PATH! >&2
    exit /b 0
)
echo [FAIL] MISSING: !_AE_PATH! >&2
exit /b 1
