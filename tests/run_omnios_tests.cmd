@echo off
set "THIS_FILE=%~f0"
:: # run_omnios_tests.cmd
::
:: ## Overview
:: Native batch script to execute component tests sequentially on OmniOS Vagrant VM.
::
:: ## Usage
:: run_omnios_tests.cmd [TARGETS...|all]

setlocal EnableDelayedExpansion
set "THIS_DIR=%~dp0"
if "%THIS_DIR:~-1%"=="" set "THIS_DIR=%THIS_DIR:~0,-1%"
set "REPO_ROOT=%THIS_DIR%\.."
for %%I in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fI"
set "LIBSCRIPT_ROOT_DIR=%REPO_ROOT%"
set "VAGRANT_DIR=%REPO_ROOT%\vagrant\omnios"
set "TESTS_TMP_DIR=%REPO_ROOT%\tests_tmp"

if not exist "%TESTS_TMP_DIR%" mkdir "%TESTS_TMP_DIR%"

if "%~1"=="" goto :usage_check
if "%~1"=="--help" goto :show_help
if "%~1"=="-h" goto :show_help
if "%~1"=="/?" goto :show_help
goto :start_tests

:: ## usage_check
:: Executes usage_check functionality by defaulting targets to all.
:usage_check
set "TARGETS=all"
goto :run_tests

:: ## show_help
:: Displays command-line help and usage parameters.
:show_help
echo Usage: run_omnios_tests.cmd [TARGETS...^|all]
echo.
echo Runs local tests sequentially on OmniOS Vagrant VM.
echo Results are written to tests_tmp\ directory.
exit /b 0

:: ## start_tests
:: Parses command-line targets into the test execution variable.
:start_tests
set "TARGETS=%*"

:: ## run_tests
:: Orchestrates VM verification, repository rsync, and component testing loop.
:run_tests
echo === Ensuring OmniOS Vagrant VM is running ===
pushd "%VAGRANT_DIR%"
vagrant status | findstr /i "running" >nul 2>&1
if errorlevel 1 (
    echo Starting OmniOS Vagrant VM...
    vagrant up --no-provision
)

echo === Syncing LibScript repository to OmniOS ===
vagrant rsync
popd

if "%TARGETS%"=="all" (
    set "COMPONENTS="
    for /d %%C in ("%REPO_ROOT%\_lib\*") do (
        set "cat_name=%%~nxC"
        if not "!cat_name:~0,1!"=="_" (
            for /d %%D in ("%%C\*") do (
                set "comp_name=%%~nxD"
                if not "!comp_name:~0,1!"=="_" (
                    set "COMPONENTS=!COMPONENTS! !comp_name!"
                )
            )
        )
    )
) else (
    set "COMPONENTS=%TARGETS%"
)

for %%T in (!COMPONENTS!) do (
    call :run_single_test %%T
)

if exist "%REPO_ROOT%\tests\update_results.cmd" (
    call "%REPO_ROOT%\tests\update_results.cmd"
)

exit /b 0

:: ## run_single_test
:: Runs the install, test, and idempotency cycle for a single component target.
:run_single_test
set "target=%~1"
echo ============================================================
echo Running test for !target! on OmniOS...
echo ============================================================

set "stdout_file=%TESTS_TMP_DIR%\!target!.sunos.stdout"
set "stderr_file=%TESTS_TMP_DIR%\!target!.sunos.stderr"
set "success_file=%TESTS_TMP_DIR%\!target!.sunos.success"
set "failure_file=%TESTS_TMP_DIR%\!target!.sunos.failure"
set "idempotent_file=%TESTS_TMP_DIR%\!target!.idempotent.success"

if exist "!success_file!" del "!success_file!" >nul 2>&1
if exist "!failure_file!" del "!failure_file!" >nul 2>&1
if exist "!idempotent_file!" del "!idempotent_file!" >nul 2>&1

set "test_cmd=export LIBSCRIPT_ROOT_DIR=/opt/repos/libscript; /opt/repos/libscript/libscript.sh install !target! && /opt/repos/libscript/libscript.sh test !target! && /opt/repos/libscript/libscript.sh install !target! && /opt/repos/libscript/libscript.sh test !target!"

pushd "%VAGRANT_DIR%"
vagrant ssh --no-tty -c "!test_cmd!" > "!stdout_file!" 2> "!stderr_file!"
if errorlevel 1 (
    echo Failure > "!failure_file!"
    echo [FAILED] !target!
) else (
    echo Success > "!success_file!"
    echo Idempotent > "!idempotent_file!"
    echo [OK] !target! ^(2x install + test verified^)
)
popd
exit /b 0
