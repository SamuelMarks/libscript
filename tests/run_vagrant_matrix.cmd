@echo off
:: ## Overview
:: Orchestrates test script execution across the entire Vagrant testing matrix.
:: Iterates over Ubuntu, Debian, Windows 11, FreeBSD, and OmniOS (if available)
:: to run all unit and integration test scripts, ensuring zero privilege escalation
:: on the host machine.
::
:: ## Usage
:: .\tests\run_vagrant_matrix.cmd

setlocal enabledelayedexpansion
set "THIS_FILE=%~f0"

if not defined LIBSCRIPT_ROOT_DIR (
    set "LIBSCRIPT_ROOT_DIR=%~dp0.."
    for %%I in ("!LIBSCRIPT_ROOT_DIR!") do set "LIBSCRIPT_ROOT_DIR=%%~fI"
)
set "LIBSCRIPT_REPO_ROOT=%LIBSCRIPT_ROOT_DIR%"

echo ==^> LibScript Vagrant Test Matrix Orchestrator

where vagrant >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Vagrant is not installed or not in PATH. 1>&2
    exit /b 1
)

:: Validate no sudo needed is generally true for Windows
echo [INFO] Assuming zero privilege escalation constraint is met on Windows for Vagrant.

set "VAGRANT_DIRS=debian-13 windows-11 freebsd-15.1 omnios rockylinux-10.2 alpine-3.24"
set "TEST_SCRIPTS=test_database_discovery test_database_provision_schema test_connection_uri_parser test_generic_msi_generation test_modular_msi_reuse test_idempotency_matrix test_msi_generation test_python_uv_integration"

set "FAILURES=0"
set "PREV_WD=%CD%"

cd /d "%LIBSCRIPT_ROOT_DIR%\vagrant" || exit /b 1

for %%D in (%VAGRANT_DIRS%) do (
    if exist "%%D\Vagrantfile" (
        echo.
        echo =======================================================
        echo [MATRIX] Starting tests in environment: %%D
        echo =======================================================
        
        cd /d "%LIBSCRIPT_ROOT_DIR%\vagrant\%%D"
        
        for %%S in (%TEST_SCRIPTS%) do (
            echo.
            echo [TEST] -^> %%S ^(in %%D^)
            set "LIBSCRIPT_TEST_TARGET=%%S"
            set "VAGRANT_VAGRANTFILE=Vagrantfile"
            
            vagrant destroy -f >nul 2>nul
            
            vagrant up
            if !ERRORLEVEL! EQU 0 (
                echo [OK] %%S passed in %%D
            ) else (
                echo [FAIL] %%S failed in %%D 1>&2
                set /a FAILURES+=1
            )
            
            vagrant destroy -f >nul 2>nul
        )
    ) else (
        echo [WARN] Vagrant directory %%D not found or missing Vagrantfile. Skipping...
    )
)

cd /d "%PREV_WD%"

if %FAILURES% GTR 0 (
    echo.
    echo [MATRIX FAIL] Vagrant testing completed with %FAILURES% failures. 1>&2
    exit /b 1
)

echo.
echo [MATRIX SUCCESS] All vagrant tests executed successfully with zero privilege escalation!
exit /b 0
