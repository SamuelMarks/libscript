@echo off
:: # test_win_cmd_rs_vm_and_hooks.cmd
::
:: ## Overview
:: End-to-end Windows Batch behavioral test suite for the win-cmd-rs native version manager
:: (`_lib\toolchains\win-cmd-rs`), multi-version switching, 2x idempotency, MS-DOS DJGPP
:: cross-staging, and `.githooks\pre-commit.cmd` static analysis gating.
::
:: ## Usage
:: tests\test_win_cmd_rs_vm_and_hooks.cmd

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
cd /d "%LIBSCRIPT_ROOT_DIR%"

set "FAILURES=0"
set "CHECKS=0"

echo === 1. Auditing _lib\toolchains\win-cmd-rs Standards ^& Companion Parity ===
call "!LIBSCRIPT_ROOT_DIR!\devtools\audit\audit_version_manager.cmd" "_lib\toolchains\win-cmd-rs" >nul 2>&1
if errorlevel 1 (
    call :fail_check "_lib\toolchains\win-cmd-rs failed Version Manager Contract audit"
) else (
    call :pass_check "_lib\toolchains\win-cmd-rs satisfies Version Manager Contract audit"
)

set "_MISSING_CMD=0"
for %%F in ("_lib\toolchains\win-cmd-rs\*.sh") do (
    if not exist "_lib\toolchains\win-cmd-rs\%%~nF.cmd" (
        call :fail_check "Missing Windows Batch companion for %%~nxF"
        set "_MISSING_CMD=1"
    )
)
if "!_MISSING_CMD!"=="0" (
    call :pass_check "1:1 .sh / .cmd companion parity verified across _lib\toolchains\win-cmd-rs"
)

echo === 2. Testing Isolation, 2x Idempotency ^& Lifecycle Verbs ===
set "TEST_WS=%TEMP%\libscript_wcr_vm_test_!RANDOM!_!RANDOM!"
if not exist "!TEST_WS!" mkdir "!TEST_WS!"
set "FAKE_LS_HOME=!TEST_WS!\ls_home"
if not exist "!FAKE_LS_HOME!" mkdir "!FAKE_LS_HOME!"

set "LIBSCRIPT_HOME=!FAKE_LS_HOME!"
set "LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB=1"
set "STACK="
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install win-cmd-rs 0.0.1
if errorlevel 1 (
    call :fail_check "Initial install of win-cmd-rs 0.0.1 failed"
) else if exist "!FAKE_LS_HOME!\win-cmd-rs\0.0.1\bin\wincheck.exe" (
    if exist "!FAKE_LS_HOME!\win-cmd-rs\0.0.1\bin\wincmd.exe" (
        call :pass_check "Installed win-cmd-rs 0.0.1 ^(wincheck.exe + wincmd.exe^) into isolated LIBSCRIPT_HOME"
    ) else (
        call :fail_check "wincmd.exe missing in !FAKE_LS_HOME!\win-cmd-rs\0.0.1\bin"
    )
) else (
    call :fail_check "wincheck.exe missing in !FAKE_LS_HOME!\win-cmd-rs\0.0.1\bin"
)

set "IDEMP_LOG=!TEST_WS!\idemp.log"
set "STACK="
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install win-cmd-rs 0.0.1 > "!IDEMP_LOG!" 2>&1
findstr /I /C:"already installed" "!IDEMP_LOG!" >nul 2>&1
if errorlevel 1 (
    call :fail_check "Second install of win-cmd-rs 0.0.1 did not hit idempotent early exit"
) else (
    call :pass_check "Second install of win-cmd-rs 0.0.1 exited idempotently"
)

:: Stage synthetic 0.0.2 side-by-side copy to verify use switching & 2x uninstall idempotency offline
if exist "!FAKE_LS_HOME!\win-cmd-rs\0.0.1\bin\wincheck.exe" (
    if not exist "!FAKE_LS_HOME!\win-cmd-rs\0.0.2\bin" mkdir "!FAKE_LS_HOME!\win-cmd-rs\0.0.2\bin"
    copy /y "!FAKE_LS_HOME!\win-cmd-rs\0.0.1\bin\wincheck.exe" "!FAKE_LS_HOME!\win-cmd-rs\0.0.2\bin\wincheck.exe" >nul
    copy /y "!FAKE_LS_HOME!\win-cmd-rs\0.0.1\bin\wincmd.exe" "!FAKE_LS_HOME!\win-cmd-rs\0.0.2\bin\wincmd.exe" >nul
    set "STACK="
    call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" use win-cmd-rs 0.0.2 >nul 2>&1
    set "STACK="
    call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" use win-cmd-rs 0.0.1 >nul 2>&1
    if errorlevel 1 (
        call :fail_check "use verb switching between 0.0.2 and 0.0.1 failed"
    ) else (
        call :pass_check "O^(1^) use verb switching verified between 0.0.2 and 0.0.1"
    )
    set "STACK="
    call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" uninstall win-cmd-rs 0.0.2 >nul 2>&1
    set "STACK="
    call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" uninstall win-cmd-rs 0.0.2 >nul 2>&1
    if not exist "!FAKE_LS_HOME!\win-cmd-rs\0.0.2" (
        call :pass_check "2x consecutive uninstall of win-cmd-rs 0.0.2 succeeded idempotently"
    ) else (
        call :fail_check "uninstall failed to remove !FAKE_LS_HOME!\win-cmd-rs\0.0.2"
    )
)

set "STACK="
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" test win-cmd-rs
if errorlevel 1 (
    call :fail_check "win-cmd-rs component smoke test failed"
) else (
    call :pass_check "win-cmd-rs component smoke test passed"
)

echo === 3. Testing Pre-Commit Hook ^& audit_cmd.cmd Pass/Fail Behavior ===
set "STACK="
call "%LIBSCRIPT_ROOT_DIR%\devtools\audit\audit_cmd.cmd" "%LIBSCRIPT_ROOT_DIR%\tests\test_win_cmd_rs_vm_and_hooks.cmd"
if errorlevel 1 (
    call :fail_check "audit_cmd.cmd failed on test_win_cmd_rs_vm_and_hooks.cmd"
) else (
    call :pass_check "test_win_cmd_rs_vm_and_hooks.cmd passes wincheck with zero warnings/errors"
)

set "HOOK_REPO=!TEST_WS!\hook_repo"
if not exist "!HOOK_REPO!" mkdir "!HOOK_REPO!"
pushd "!HOOK_REPO!"
git init -q
git config user.email "test@example.com"
git config user.name "LibScript Test"
copy /y "%LIBSCRIPT_ROOT_DIR%\.cspell.json" ".cspell.json" >nul 2>&1
(
    echo @echo off
    echo :: # valid.cmd
    echo :: ## Overview
    echo :: Valid batch fixture.
    echo :: ## Usage
    echo :: valid.cmd
    echo echo ok
    echo exit /b 0
) > valid.cmd
git add valid.cmd
set "STACK="
call "%LIBSCRIPT_ROOT_DIR%\.githooks\pre-commit.cmd" >nul 2>&1
set "_HK_VALID_RC=!ERRORLEVEL!"

(
    echo @echo off
    echo if "1"=="1" ^(
    echo     :: broken CMD1001 comment inside block
    echo     echo fail
    echo ^)
) > broken.cmd
git add broken.cmd
set "STACK="
call "%LIBSCRIPT_ROOT_DIR%\.githooks\pre-commit.cmd" >nul 2>&1
set "_HK_BROKEN_RC=!ERRORLEVEL!"
popd

if "!_HK_VALID_RC!"=="0" (
    call :pass_check "pre-commit.cmd passed valid.cmd fixture"
) else (
    call :fail_check "pre-commit.cmd failed unexpectedly on valid.cmd"
)

if not "!_HK_BROKEN_RC!"=="0" (
    call :pass_check "pre-commit.cmd rejected broken.cmd ^(CMD1001^) with non-zero exit"
) else (
    call :fail_check "pre-commit.cmd should have failed on broken.cmd"
)

rmdir /s /q "!TEST_WS!" >nul 2>&1

if not "!FAILURES!"=="0" (
    echo [FAIL] win-cmd-rs Windows Suite failed ^(!FAILURES!/!CHECKS! checks failed^) 1>&2
    exit /b 1
)

echo === All !CHECKS! win-cmd-rs Windows Checks Passed^^! ===
exit /b 0

:: ## pass_check
:: Records a passing assertion in the Windows test suite.
:pass_check
set /a "CHECKS+=1"
echo [PASS] %~1
exit /b 0

:: ## fail_check
:: Records a failing assertion in the Windows test suite.
:fail_check
set /a "CHECKS+=1"
set /a "FAILURES+=1"
echo [FAIL] %~1 1>&2
exit /b 0
