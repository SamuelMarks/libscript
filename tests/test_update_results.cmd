@echo off
:: # test_update_results.cmd
::
:: ## Overview
:: Validates update_results.cmd execution, verifying component discovery,
:: markdown table updating in README.md, and task tracking in TODO_PLAN.md.
::
:: ## Usage
:: test_update_results.cmd tests/test_update_results.cmd

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

:: # test_update_results.cmd
:::: Validates update_results.cmd execution, verifying component discovery,
:: markdown table updating in README.md, and task tracking in TODO_PLAN.md on Windows.
::
:: ## Usage
:: tests\test_update_results.cmd

set "THIS_DIR=%~dp0"
if "%THIS_DIR:~-1%"=="" set "THIS_DIR=%THIS_DIR:~0,-1%"
set "REPO_ROOT=%THIS_DIR%\.."
for %%I in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fI"

set "TEST_TMP=%TEMP%\test_update_results_%RANDOM%"
if not exist "%TEST_TMP%" mkdir "%TEST_TMP%" >nul 2>&1
if not exist "%TEST_TMP%\_lib\catA\compA" mkdir "%TEST_TMP%\_lib\catA\compA" >nul 2>&1
if not exist "%TEST_TMP%\_lib\catB\compB" mkdir "%TEST_TMP%\_lib\catB\compB" >nul 2>&1
if not exist "%TEST_TMP%\stacks\catS\compS" mkdir "%TEST_TMP%\stacks\catS\compS" >nul 2>&1
if not exist "%TEST_TMP%\_lib\_common\helper" mkdir "%TEST_TMP%\_lib\_common\helper" >nul 2>&1
if not exist "%TEST_TMP%\tests_tmp" mkdir "%TEST_TMP%\tests_tmp" >nul 2>&1

type nul > "%TEST_TMP%\libscript.sh"

> "%TEST_TMP%\README.md" (
    echo # Mock Project
    echo.
    echo ## Supported Components
    echo.
    echo ^| Component ^| Linux ^(apk^) ^| Linux ^(deb^) ^| Linux ^(rpm^) ^| Windows ^| SunOS ^| FreeBSD ^|
    echo ^|---^|---^|---^|---^|---^|---^|
    echo ^| `compA` ^| ❓ ^| ❓ ^| ❓ ^| - ^| - ^| - ^|
    echo.
    echo ## License
    echo MIT
)

> "%TEST_TMP%\TODO_PLAN.md" (
    echo - [ ] _lib/catA/compA
    echo   - [ ] **Double-check ^& Idempotency Verified ^(2x run^)**
    echo - [ ] compB
    echo - [ ] compC
    echo - [x] already_done
)

type nul > "%TEST_TMP%\tests_tmp\compA.idempotent.success"
type nul > "%TEST_TMP%\tests_tmp\compA.linux.alpine.success"
type nul > "%TEST_TMP%\tests_tmp\compA.sunos.success"
type nul > "%TEST_TMP%\tests_tmp\compB.windows.failure"
type nul > "%TEST_TMP%\tests_tmp\compS.linux.debian.success"

call "%REPO_ROOT%\tests\update_results.cmd" "%TEST_TMP%"
if errorlevel 1 (
    echo [ERROR] update_results.cmd failed with exit code %ERRORLEVEL%
    rmdir /s /q "%TEST_TMP%" >nul 2>&1
    exit /b 1
)

:: Verification 1: compA has success mark
findstr /c:"| `compA` | ✅ | ❓ | ❓ | - | ✅ | - |" "%TEST_TMP%\README.md" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] compA success status not found in README.md
    rmdir /s /q "%TEST_TMP%" >nul 2>&1
    exit /b 1
)

:: Verification 2: compB has failure mark for windows
findstr /c:"| `compB` | ❓ | ❓ | ❓ | ❌ |" "%TEST_TMP%\README.md" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] compB failure status not found in README.md
    rmdir /s /q "%TEST_TMP%" >nul 2>&1
    exit /b 1
)

:: Verification 2b: compS from stacks directory has debian success mark
findstr /c:"| `compS` | ❓ | ✅ | ❓ |" "%TEST_TMP%\README.md" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] compS stacks component not found in README.md
    rmdir /s /q "%TEST_TMP%" >nul 2>&1
    exit /b 1
)

:: Verification 3: helper from _common must not be in README
findstr /c:"helper" "%TEST_TMP%\README.md" >nul 2>&1
if not errorlevel 1 (
    echo [ERROR] helper from _common found in README.md table
    rmdir /s /q "%TEST_TMP%" >nul 2>&1
    exit /b 1
)

:: Verification 4: TODO_PLAN.md updated
findstr /c:"- [x] _lib/catA/compA" "%TEST_TMP%\TODO_PLAN.md" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] _lib/catA/compA not checked in TODO_PLAN.md
    rmdir /s /q "%TEST_TMP%" >nul 2>&1
    exit /b 1
)

findstr /c:"- [x] **Double-check & Idempotency Verified (2x run)**" "%TEST_TMP%\TODO_PLAN.md" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] compA idempotency check not checked in TODO_PLAN.md
    rmdir /s /q "%TEST_TMP%" >nul 2>&1
    exit /b 1
)

findstr /c:"- [x] compB" "%TEST_TMP%\TODO_PLAN.md" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] compB not checked in TODO_PLAN.md
    rmdir /s /q "%TEST_TMP%" >nul 2>&1
    exit /b 1
)

findstr /c:"- [ ] compC" "%TEST_TMP%\TODO_PLAN.md" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] compC unexpectedly modified in TODO_PLAN.md
    rmdir /s /q "%TEST_TMP%" >nul 2>&1
    exit /b 1
)

:: Verification 5: FreeBSD success and custom output + JSON export
type nul > "%TEST_TMP%\tests_tmp\compA.freebsd.success"
type nul > "%TEST_TMP%\tests_tmp\compA.linux.rocky.success"
copy /Y "%TEST_TMP%\README.md" "%TEST_TMP%\CUSTOM_REPORT.md" >nul

call "%REPO_ROOT%\tests\update_results.cmd" "%TEST_TMP%" --output "%TEST_TMP%\CUSTOM_REPORT.md" --json "%TEST_TMP%\tests_tmp\matrix_results.json"
if errorlevel 1 (
    echo [ERROR] update_results.cmd failed with custom output/json flags
    rmdir /s /q "%TEST_TMP%" >nul 2>&1
    exit /b 1
)

findstr /c:"compA" "%TEST_TMP%\CUSTOM_REPORT.md" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] compA not found in CUSTOM_REPORT.md
    rmdir /s /q "%TEST_TMP%" >nul 2>&1
    exit /b 1
)

if not exist "%TEST_TMP%\tests_tmp\matrix_results.json" (
    echo [ERROR] matrix_results.json was not generated
    rmdir /s /q "%TEST_TMP%" >nul 2>&1
    exit /b 1
)

findstr /c:"\"component\": \"compA\"" "%TEST_TMP%\tests_tmp\matrix_results.json" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] compA not found in matrix_results.json
    rmdir /s /q "%TEST_TMP%" >nul 2>&1
    exit /b 1
)

rmdir /s /q "%TEST_TMP%" >nul 2>&1
echo All tests in test_update_results.cmd passed successfully.
exit /b 0
