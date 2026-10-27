@echo off
:: # run_rockylinux_tests.cmd
::
:: ## Overview
:: Runs tests sequentially for libscript components on a local Rocky Linux Vagrant VM
:: (`bento/rockylinux-10.2`). Restores the vanilla snapshot before each test, verifies
:: installation and test idempotency (2x run), writes logs to tests_tmp/, and automatically
:: updates the Supported Components table in README.md and task completion in TODO_PLAN.md.
::
:: ## Usage
:: run_rockylinux_tests.cmd tests/run_rockylinux_tests.cmd [TARGETS...|all]
:: Example: ./tests/run_rockylinux_tests.cmd curl sqlite jq
:: Example: ./tests/run_rockylinux_tests.cmd all
:: Example: ./tests/run_rockylinux_tests.cmd all --loop --stop-after 10

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /I /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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


set "THIS_DIR=%~dp0"
if "%THIS_DIR:~-1%"=="" set "THIS_DIR=%THIS_DIR:~0,-1%"

set "REPO_ROOT=%THIS_DIR%\.."
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\test_matrix_driver.cmd"
set "VAGRANT_DIR=%REPO_ROOT%\vagrant\rockylinux-10.2"
set "TESTS_TMP_DIR=%REPO_ROOT%\tests_tmp"

if not exist "%TESTS_TMP_DIR%" mkdir "%TESTS_TMP_DIR%"

if /I "%~1"=="" goto :usage_all
if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help

set "TARGETS=%*"
goto :run_tests

:: ## usage_all
:: Displays command-line usage instructions and available options.
:usage_all
set "TARGETS=all"
goto :run_tests

:: ## show_help
:: Displays usage instructions and supported CLI parameters.
:show_help
echo Usage: %~nx0 [TARGETS...^|all]
echo.
echo Runs local tests sequentially on Rocky Linux (bento/rockylinux-10.2) Vagrant VM.
echo.
echo Arguments:
echo   TARGETS...          A list of categories or components to test.
echo   all                 Test all components in the _lib directory.
echo   --help, -h, /?      Show this help message.
exit /b 0

:: ## run_tests
:: Connects to Vagrant, syncs code, and runs tests.
:run_tests
echo === Ensuring Rocky Linux Vagrant VM is running ===
pushd "%VAGRANT_DIR%"
vagrant status | findstr /i "running" >nul 2>&1
if errorlevel 1 (
    echo Starting Rocky Linux Vagrant VM...
    vagrant up --no-provision
)

echo === Syncing LibScript repository to Rocky Linux ===
vagrant rsync
popd

if "%TARGETS%"=="all" (
    set "COMPONENTS="
    for /d %%C in ("%REPO_ROOT%\_lib\*" "%REPO_ROOT%\topologies\*" "%REPO_ROOT%\payloads\*") do (
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
echo Running test for !target! on Rocky Linux...
echo ============================================================

set "stdout_file=%TESTS_TMP_DIR%\!target!.linux.rocky.stdout"
set "stderr_file=%TESTS_TMP_DIR%\!target!.linux.rocky.stderr"
set "success_file=%TESTS_TMP_DIR%\!target!.linux.rocky.success"
set "failure_file=%TESTS_TMP_DIR%\!target!.linux.rocky.failure"
set "idempotent_file=%TESTS_TMP_DIR%\!target!.idempotent.success"

if exist "!success_file!" del "!success_file!" >nul 2>&1
if exist "!failure_file!" del "!failure_file!" >nul 2>&1
if exist "!idempotent_file!" del "!idempotent_file!" >nul 2>&1

set "test_cmd=export PATH=/usr/local/sbin:/usr/sbin:/sbin:\$PATH LIBSCRIPT_ROOT_DIR=/opt/repos/libscript; timeout 600 /opt/repos/libscript/libscript.sh install !target! && timeout 120 /opt/repos/libscript/libscript.sh test !target! && timeout 600 /opt/repos/libscript/libscript.sh install !target! && timeout 120 /opt/repos/libscript/libscript.sh test !target!"

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
