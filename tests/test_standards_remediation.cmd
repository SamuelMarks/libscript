@echo off
:: # test_standards_remediation.cmd
:: ## Overview
:: Hermetic Windows Batch regression test suite verifying standards audit remediation:
:: packaging .cmd generators, envsubst_safe_exec.cmd delegation, Option A exit-86 compliance,
:: and THIS_FILE path resolution from external working directories.
::
:: ## Usage
:: call tests\test_standards_remediation.cmd

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

set "TEST_WS=%TEMP%\libscript_std_rem_%RANDOM%"
if not exist "!TEST_WS!" mkdir "!TEST_WS!"
set "FAILURES=0"
set "CHECKS=0"

echo === 1. Verifying Packaging .cmd Generators ===
for %%F in (deb rpm apk txz) do (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\cli\commands\packaging\formats\pkg_%%F.cmd" --app-name Demo --app-version 2.0.0 jq 1.7.1 > "!TEST_WS!\out_%%F.sh"
    if errorlevel 1 (
        call :fail_check "pkg_%%F.cmd exited non-zero"
    ) else (
        findstr /C:"Demo" /C:"demo" "!TEST_WS!\out_%%F.sh" >nul 2>&1
        if errorlevel 1 (
            call :fail_check "pkg_%%F.cmd output missing Demo metadata"
        ) else (
            call :pass_check "pkg_%%F.cmd generated valid packaging script"
        )
    )
)

pushd "!TEST_WS!"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\cli\commands\packaging\formats\pkg_pkg.cmd" --out "!TEST_WS!\installer" --welcome-text "Hello" jq 1.7.1 > "!TEST_WS!\pkg_out.txt" 2>&1
popd
if exist "!TEST_WS!\installer_stage\comp_jq\scripts\postinstall" (
    call :pass_check "pkg_pkg.cmd staged component postinstall tree"
) else (
    call :fail_check "pkg_pkg.cmd failed to stage component postinstall tree"
)

echo === 2. Verifying envsubst_safe_exec.cmd Delegation ===
set "FOO_TOKEN=hello_win"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\envsubst_safe_exec.cmd" "val=${FOO_TOKEN}" "!TEST_WS!\es_out.txt"
findstr /C:"val=hello_win" "!TEST_WS!\es_out.txt" >nul 2>&1
if errorlevel 1 (
    call :fail_check "envsubst_safe_exec.cmd failed to interpolate FOO_TOKEN"
) else (
    call :pass_check "envsubst_safe_exec.cmd interpolated FOO_TOKEN via envsubst_safe.cmd"
)

echo === 3. Verifying Option A Exit-86 Proforma ===
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\kubernetes-thw\alpine-systemctl.cmd" >nul 2>&1
if "!ERRORLEVEL!"=="86" (
    call :pass_check "alpine-systemctl.cmd returned Option A exit code 86"
) else (
    call :fail_check "alpine-systemctl.cmd did not return exit code 86"
)

where powershell.exe >nul 2>&1
if not errorlevel 1 (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\kubernetes-thw\alpine-systemctl.ps1" >nul 2>&1
    if "!ERRORLEVEL!"=="86" (
        call :pass_check "alpine-systemctl.ps1 returned Option A exit code 86"
    ) else (
        call :fail_check "alpine-systemctl.ps1 did not return exit code 86"
    )
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "!LIBSCRIPT_ROOT_DIR!\_lib\app-servers\nodejs-server\setup_debian.ps1" >nul 2>&1
    if "!ERRORLEVEL!"=="86" (
        call :pass_check "nodejs-server\setup_debian.ps1 returned Option A exit code 86"
    ) else (
        call :fail_check "nodejs-server\setup_debian.ps1 did not return exit code 86"
    )
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$d = '!TEST_WS!\tmp\double_cr'; New-Item -ItemType Directory -Force -Path $d | Out-Null; $lf = [string][char]10; $crlf = [string][char]13 + $lf; [IO.File]::WriteAllText(\"$d\sample.sh\", (@('#!/bin/sh', '# ## Overview', '# Fixture.', '# ## Usage', '# sample.sh', 'exit 0', '') -join $lf)); [IO.File]::WriteAllText(\"$d\sample.cmd\", (@('@echo off', ':: # sample.cmd', ':: ## Overview', ':: Fixture.', ':: ## Usage', ':: sample.cmd', 'setlocal EnableDelayedExpansion', 'set \"THIS_FILE=%~f0\"', 'if defined STACK (', '    echo \"!STACK!\" | findstr /I /C:\":!THIS_FILE!:\" >nul 2>&1', '    if not errorlevel 1 exit /b 0', ')', 'set \"STACK=%STACK%:!THIS_FILE!:\"', ('echo bad' + [char]13), 'exit /b 0', '') -join $crlf))" >nul 2>&1
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\devtools\audit\audit_standards.cmd" "!TEST_WS!\tmp\double_cr\sample.cmd" > "!TEST_WS!\double_cr_audit.txt" 2>&1
    findstr /C:"BATCH_EOL_CRLF" "!TEST_WS!\double_cr_audit.txt" >nul 2>&1
    if errorlevel 1 (
        call :fail_check "audit_standards.cmd failed to flag BATCH_EOL_CRLF on double-CR fixture"
    ) else (
        call :pass_check "audit_standards.cmd flagged BATCH_EOL_CRLF on double-CR fixture"
    )
)

echo === 4. Verifying os_info.cmd Variable Tunneling ===
set "INIT_SYS="
set "TARGET_OS="
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\os_info.cmd"
if "!INIT_SYS!|!TARGET_OS!"=="windows-scm|windows" (
    call :pass_check "os_info.cmd exported INIT_SYS=windows-scm and TARGET_OS=windows across endlocal"
) else (
    call :fail_check "os_info.cmd failed to export variables across endlocal"
)

if exist "!TEST_WS!" rmdir /s /q "!TEST_WS!" >nul 2>&1

REM wincheck disable=CMD2003
if !FAILURES! gtr 0 (
    echo [FAIL] Standards remediation Windows suite failed ^(!FAILURES!/!CHECKS!^) >&2
    exit /b 1
)
echo === All !CHECKS! Windows Standards Remediation Checks Passed^^! ===
exit /b 0

:: ## pass_check
:: Records and prints a passing assertion.
:pass_check
set /a CHECKS+=1
echo [PASS] %~1
exit /b 0

:: ## fail_check
:: Records and prints a failing assertion.
:fail_check
set /a CHECKS+=1
set /a FAILURES+=1
echo [FAIL] %~1 >&2
exit /b 0
