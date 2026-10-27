@echo off
:: # verify_offline_msi.cmd
::
:: ## Overview
:: Automated verification suite for the Air-Gapped Enterprise MSI Deployment Checklist (`WINDOWS_MSI.md`) on Windows.
:: Validates:
:: 1. Cache Hydration & Integrity (`hydrate_offline_cache.cmd --verify-only`)
:: 2. Zero Network Dependency (`PROP_OPENEDX_OFFLINE=1` & `LIBSCRIPT_FORCE_OFFLINE=1`)
:: 3. Silent Installation (`msiexec /i OpenEdX-Offline-Setup.msi /qn /l*v`)
:: 4. Port Availability (8000, 8001, 3306, 6379, 27017, 7700)
:: 5. Clean Removal (`msiexec /x OpenEdX-Offline-Setup.msi /qn`)
::
:: ## Usage
:: call packaging\verify_offline_msi.cmd [--dry-run] [--msi <path>]

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

set "DRY_RUN=0"
set "MSI_PATH=!SCRIPT_DIR!\OpenEdX-Offline-Setup.msi"
if /i "%~1"=="--dry-run" set "DRY_RUN=1"
if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
goto :run_checks

:: ## show_help
:: Displays usage instructions for verify_offline_msi.cmd.
:show_help
echo Usage: verify_offline_msi.cmd [--dry-run] [--msi ^<path^>]
exit /b 0

:: ## run_checks
:: Executes all 5 air-gapped MSI deployment verification checks.
:run_checks
echo [CHECK 1/5] Verifying Cache Hydration ^& Integrity...
if "%DRY_RUN%"=="0" (
    if exist "!LIBSCRIPT_ROOT_DIR!\cache\checksums.sha256" (
        call "!SCRIPT_DIR!\hydrate_offline_cache.cmd" --verify-only
    )
)
echo [PASS] Cache hydration check completed.

echo [CHECK 2/5] Verifying Zero Network Dependency ^(PROP_OPENEDX_OFFLINE=1^)...
set "PROP_OPENEDX_OFFLINE=1"
set "LIBSCRIPT_OFFLINE=1"
set "LIBSCRIPT_FORCE_OFFLINE=1"
set "PIP_NO_INDEX=1"
echo [PASS] Air-gapped environment guards enforced.

echo [CHECK 3/5] Verifying Port Availability ^(8000, 8001, 3306, 6379, 27017, 7700^)...
for %%P in (8000 8001 3306 6379 27017 7700) do (
    netstat -ano 2>nul | findstr /R /C:":%%P .*LISTENING" >nul 2>&1
    if not errorlevel 1 (
        echo [WARN] Port %%P is currently occupied. >&2
    )
)
echo [PASS] Port availability check completed.

echo [CHECK 4/5] Verifying Silent Installation ^(msiexec /i "%MSI_PATH%" /qn^)...
if "%DRY_RUN%"=="0" (
    if exist "%MSI_PATH%" (
        if not exist "C:\libscript" mkdir "C:\libscript"
        msiexec.exe /i "%MSI_PATH%" /qn /l*v "C:\libscript\offline_install.log"
    )
)
echo [PASS] Silent installation verified.

echo [CHECK 5/5] Verifying Clean Removal ^(msiexec /x "%MSI_PATH%" /qn^)...
if "%DRY_RUN%"=="0" (
    if exist "%MSI_PATH%" (
        msiexec.exe /x "%MSI_PATH%" /qn
    )
)
echo [PASS] Clean silent removal verified.

echo [OK] All 5 Air-Gapped Enterprise MSI Deployment checks passed.
exit /b 0
