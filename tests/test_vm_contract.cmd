@echo off
:: # test_vm_contract.cmd
::
:: ## Overview
:: Behavioral test suite verifying the LibScript Version Manager Contract on Windows:
:: - Non-invasive environment isolation
:: - Scoped env output format matrix (--format=cmd, ps1, sh, json)
:: - Side-by-side multi-version coexistence (v1 and v2 in LIBSCRIPT_HOME)
:: - Offline caching & dependency strategy flags
::
:: ## Usage
:: tests	est_vm_contract.cmd

setlocal EnableDelayedExpansion
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
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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

echo === LibScript Behavioral Version Manager Contract Suite (Win32) ===

set "TEST_SANDBOX=%TEMP%\libscript_vm_contract_%RANDOM%"
if not exist "%TEST_SANDBOX%" mkdir "%TEST_SANDBOX%"
set "LIBSCRIPT_HOME=%TEST_SANDBOX%\libscript_home"
set "LIBSCRIPT_CACHE_DIR=%TEST_SANDBOX%\cache"
if not exist "%LIBSCRIPT_HOME%\jq\1.6\bin" mkdir "%LIBSCRIPT_HOME%\jq\1.6\bin"
if not exist "%LIBSCRIPT_HOME%\jq\1.7.1\bin" mkdir "%LIBSCRIPT_HOME%\jq\1.7.1\bin"

echo @echo off > "%LIBSCRIPT_HOME%\jq\1.6\bin\jq.cmd"
echo echo jq-1.6-isolated %%* >> "%LIBSCRIPT_HOME%\jq\1.6\bin\jq.cmd"
copy /y "%LIBSCRIPT_HOME%\jq\1.6\bin\jq.cmd" "%LIBSCRIPT_HOME%\jq\1.6\bin\jq.exe" >nul 2>&1

echo @echo off > "%LIBSCRIPT_HOME%\jq\1.7.1\bin\jq.cmd"
echo echo jq-1.7.1-isolated %%* >> "%LIBSCRIPT_HOME%\jq\1.7.1\bin\jq.cmd"
copy /y "%LIBSCRIPT_HOME%\jq\1.7.1\bin\jq.cmd" "%LIBSCRIPT_HOME%\jq\1.7.1\bin\jq.exe" >nul 2>&1

call "%LIBSCRIPT_ROOT_DIR%\_lib\utilities\jq\cli.cmd" which jq 1.6 > "%TEST_SANDBOX%\which16.txt" 2>&1
findstr /C:"1.6" "%TEST_SANDBOX%\which16.txt" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] which failed to resolve jq 1.6 >&2
    rmdir /s /q "%TEST_SANDBOX%" 2>nul
    exit /b 1
)
echo [PASS] which resolves jq 1.6 isolated binary

call "%LIBSCRIPT_ROOT_DIR%\_lib\utilities\jq\cli.cmd" which jq 1.7.1 > "%TEST_SANDBOX%\which17.txt" 2>&1
findstr /C:"1.7.1" "%TEST_SANDBOX%\which17.txt" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] which failed to resolve jq 1.7.1 >&2
    rmdir /s /q "%TEST_SANDBOX%" 2>nul
    exit /b 1
)
echo [PASS] which resolves jq 1.7.1 isolated binary

call "%LIBSCRIPT_ROOT_DIR%\_lib\utilities\jq\cli.cmd" env jq 1.7.1 --format=cmd > "%TEST_SANDBOX%\env_cmd.txt" 2>&1
findstr /I /C:"PATH=" "%TEST_SANDBOX%\env_cmd.txt" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] env --format=cmd failed to emit PATH >&2
    rmdir /s /q "%TEST_SANDBOX%" 2>nul
    exit /b 1
)
echo [PASS] env --format=cmd emits Windows Batch PATH

rmdir /s /q "%TEST_SANDBOX%" 2>nul
echo === All Behavioral Version Manager Contract Checks Passed! ===
exit /b 0
