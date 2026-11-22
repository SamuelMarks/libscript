@echo off
:: # run_zero_powershell_suite.cmd
:: ## Overview
:: Enforces zero-PowerShell execution on Windows by stripping all PowerShell directories from
:: `PATH`, prepending fail-closed `powershell.cmd` / `pwsh.cmd` poison shims (exit 99), and
:: running the Windows `.cmd` test and packaging suites.
:: ## Usage
:: call tests\run_zero_powershell_suite.cmd

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

:: Pre-stage native jq.exe before removing PowerShell from PATH
where jq.exe >nul 2>&1
if errorlevel 1 (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" depends jq
)

set "ZPS_WORK=%TEMP%\ls_zero_ps_%RANDOM%_%RANDOM%"
set "POISON_BIN=!ZPS_WORK!\poison_bin"
if not exist "!POISON_BIN!" mkdir "!POISON_BIN!" 2>nul

set "CLEAN_PATH="
set "_REM_PATH=!PATH!"
goto :strip_loop

:: ## strip_loop
:: Iteratively removes PowerShell and pwsh directories from PATH.
:strip_loop
for /f "tokens=1* delims=;" %%A in ("!_REM_PATH!") do (
    set "_SEG=%%A"
    set "_REM_PATH=%%B"
    echo "!_SEG!" | findstr /I "PowerShell pwsh" >nul 2>&1
    if errorlevel 1 (
        if "!CLEAN_PATH!"=="" (
            set "CLEAN_PATH=!_SEG!"
        ) else (
            set "CLEAN_PATH=!CLEAN_PATH!;!_SEG!"
        )
    )
)
if defined _REM_PATH goto :strip_loop

for %%S in (powershell pwsh) do (
    (
        echo @echo off
        echo echo [ERROR] Forbidden %%S invocation in zero-PowerShell mode^^! 1^>^&2
        echo exit /b 99
    ) > "!POISON_BIN!\%%S.cmd"
)

set "PATHEXT=.CMD;.BAT;.EXE;.COM"
set "PATH=!POISON_BIN!;!CLEAN_PATH!"

:: Verify poison shim intercepts bare `powershell` and `pwsh`
call powershell -NoProfile -Command "exit 0" >nul 2>&1
if not "!ERRORLEVEL!"=="99" (
    echo [FAIL] Expected poison powershell shim exit 99, got !ERRORLEVEL! 1>&2
    goto :zps_fail
)

set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\tests\test_win_dos_component_pm.cmd" || goto :zps_fail
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\tests\test_standards_adherence.cmd" || goto :zps_fail
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\tests\test_qemu_msdos_smoke.cmd" || goto :zps_fail

:: Exercise zero-PowerShell packaging generators
if not exist "!ZPS_WORK!\pkg_src\sub" mkdir "!ZPS_WORK!\pkg_src\sub" 2>nul
> "!ZPS_WORK!\pkg_src\sub\hello.txt" echo hello
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\synthesis\msi\template_msi.cmd" "!LIBSCRIPT_ROOT_DIR!\workloads\apps\wordpress\packaging.json" --out "!ZPS_WORK!\wordpress.wxs" || goto :zps_fail
if not exist "!ZPS_WORK!\wordpress.wxs" goto :zps_fail

where gawk.exe >nul 2>&1
if errorlevel 1 where awk.exe >nul 2>&1
if not errorlevel 1 (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\synthesis\msi\harvest_payload.cmd" --source-dir "!ZPS_WORK!\pkg_src" --wix-fragment "!ZPS_WORK!\payload.wxs" || goto :zps_fail
    if not exist "!ZPS_WORK!\payload.wxs" goto :zps_fail
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\synthesis\msi\synthesize_branding.cmd" "!LIBSCRIPT_ROOT_DIR!\workloads\apps\wordpress\packaging.json" --output-dir "!ZPS_WORK!\brand" || goto :zps_fail
    if not exist "!ZPS_WORK!\brand\banner_top.bmp" goto :zps_fail
    if not exist "!ZPS_WORK!\brand\app.ico" goto :zps_fail
)

set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\synthesis\distro\reactos\pkg.cmd" --help >nul || goto :zps_fail

set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\devtools\audit\audit_cmd.cmd" "!LIBSCRIPT_ROOT_DIR!\tests\run_zero_powershell_suite.cmd" "!LIBSCRIPT_ROOT_DIR!\devtools\audit\audit_cmd.cmd" || goto :zps_fail

rmdir /s /q "!ZPS_WORK!" >nul 2>&1
echo [PASS] All Windows .cmd tests and packaging generators succeeded with PowerShell removed from PATH.
exit /b 0

:: ## zps_fail
:: Cleans up temporary artifacts and exits with status 1 on zero-PowerShell suite failure.
:zps_fail
if exist "!ZPS_WORK!" rmdir /s /q "!ZPS_WORK!" >nul 2>&1
echo [FAIL] Windows zero-PowerShell verification suite failed. 1>&2
exit /b 1
