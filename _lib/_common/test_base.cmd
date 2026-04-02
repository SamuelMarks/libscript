@echo off
:: # LibScript Common Test Entrypoint (Windows Batch)
::
:: ## Overview
:: Standardized entrypoint for component testing on Windows.
:: Resolves root, sets paths, and provides assertion helpers.
::
:: ## Usage
:: Your component's `test.cmd` should call this.
::
:: ```batch
:: @echo off
:: call "%~dp0\..\..\..\_lib\_common\test_base.cmd"
:: ```

setlocal EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:: Resolve LIBSCRIPT_ROOT_DIR
if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
    :find_root
    if exist "!d!\ROOT" (set "LIBSCRIPT_ROOT_DIR=!d!") else (
        for %%P in ("!d!") do set "parent=%%~dpP"
        set "d=!parent:~0,-1!"
        if "!d!"=="" (
            echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
            exit /b 1
        )
        goto :find_root
    )
)

:: Common directories
if "%LIBSCRIPT_BUILD_DIR%"=="" set "LIBSCRIPT_BUILD_DIR=%TEMP%\libscript_build"
if "%LIBSCRIPT_DATA_DIR%"=="" set "LIBSCRIPT_DATA_DIR=%TEMP%\libscript_data"

:: Path setup
set "PATH=%LIBSCRIPT_DATA_DIR%\bin;%PATH%"

if not exist "%LIBSCRIPT_BUILD_DIR%" mkdir "%LIBSCRIPT_BUILD_DIR%"
if not exist "%LIBSCRIPT_DATA_DIR%" mkdir "%LIBSCRIPT_DATA_DIR%"

:: Source component environment if exists
if exist "%SCRIPT_DIR%\env.cmd" call "%SCRIPT_DIR%\env.cmd"

:: Delegate to PowerShell if test_win.ps1 or test.ps1 exists
if exist "%~dp0test_win.ps1" (
    set "COMMON_DIR=%LIBSCRIPT_ROOT_DIR%\_lib\_common"
    powershell -ExecutionPolicy Bypass -Command "& { . '!COMMON_DIR!\log.ps1'; . '!COMMON_DIR!\pkg_mgr.ps1'; . '!COMMON_DIR!\service.ps1'; & '%~dp0test_win.ps1' }"
    exit /b !errorlevel!
) else if exist "%~dp0test.ps1" (
    set "COMMON_DIR=%LIBSCRIPT_ROOT_DIR%\_lib\_common"
    powershell -ExecutionPolicy Bypass -Command "& { . '!COMMON_DIR!\log.ps1'; . '!COMMON_DIR!\pkg_mgr.ps1'; . '!COMMON_DIR!\service.ps1'; & '%~dp0test.ps1' }"
    exit /b !errorlevel!
)

:: Dispatch to labels if called with arguments
if not "%~1"=="" goto %~1
exit /b 0

:: -----------------------------------------------------------------------------
:: Testing Assertions
:: -----------------------------------------------------------------------------

:assert_version
set "cmd_name=%~2"
set "expected=%~3"
where %cmd_name% >nul 2>&1
if errorlevel 1 (
    echo [FAIL] %cmd_name% command not found 1>&2
    exit /b 1
)
:: Capture first line of version output
for /f "tokens=*" %%a in ('%cmd_name% --version 2^>^&1') do (
    set "version=%%a"
    goto :check_version
)
:check_version
echo !version! | findstr /i /c:"%expected%" >nul
if errorlevel 1 (
    echo [FAIL] %cmd_name% version check failed. Expected: %expected%, Got: !version! 1>&2
    exit /b 1
)
echo [PASS] %cmd_name% version check: !version! 1>&2
exit /b 0

:assert_exists
if exist "%~2" (
    echo [PASS] Exists: %~2 1>&2
    exit /b 0
) else (
    echo [FAIL] MISSING: %~2 1>&2
    exit /b 1
)

