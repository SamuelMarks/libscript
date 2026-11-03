@echo off
:: # run_windows_tests.cmd
:: ## Overview
:: Runs tests sequentially for libscript components on a local Windows 11 Vagrant VM (`bento/windows-11`). Results, execution logs, and statuses are written into tests_tmp/ and the Supported Components table in README.md and task completion in TODO_PLAN.md are automatically updated.
:: ## Usage
:: run_windows_tests.cmd [TARGETS...|all] [--stop-after N] [--skip-uninstall] [--skip-passed] [--loop] [--no-snapshot]

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

set "THIS_DIR=%~dp0"
if "%THIS_DIR:~-1%"=="\" set "THIS_DIR=%THIS_DIR:~0,-1%"
set "REPO_ROOT=%THIS_DIR%\.."
for %%I in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fI"
set "LIBSCRIPT_ROOT_DIR=%REPO_ROOT%"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\test_matrix_driver.cmd"
set "VAGRANT_DIR=%REPO_ROOT%\vagrant\windows-11"
set "TESTS_TMP_DIR=%REPO_ROOT%\tests_tmp"

if not exist "%TESTS_TMP_DIR%" mkdir "%TESTS_TMP_DIR%"

if "%~1"=="" goto :usage_check
if "%~1"=="--help" goto :show_help
if "%~1"=="-h" goto :show_help
if "%~1"=="/?" goto :show_help
goto :start_tests

:: ## usage_check
:: Defaults targets to all when no arguments are supplied.
:usage_check
set "TARGETS=all"
goto :run_tests

:: ## show_help
:: Displays command-line help and usage parameters.
:show_help
echo Usage: run_windows_tests.cmd [TARGETS...^|all] [--stop-after N] [--skip-uninstall] [--skip-passed] [--loop] [--no-snapshot]
echo.
echo Runs local tests sequentially on Windows 11 (bento/windows-11) Vagrant VM.
echo Results are written to tests_tmp\ directory.
exit /b 0

:: ## start_tests
:: Parses command-line targets into the test execution variable.
:start_tests
set "TARGETS=%*"

:: ## run_tests
:: Orchestrates VM verification, repository rsync, and component testing loop.
:run_tests
echo === Ensuring Windows 11 Vagrant VM is running ===
pushd "%VAGRANT_DIR%"
vagrant status | findstr /i "running" >nul 2>&1
if errorlevel 1 (
    echo Starting Windows 11 Vagrant VM...
    vagrant up --no-provision
)

echo === Syncing LibScript repository to Windows 11 ===
vagrant rsync
popd

if "%TARGETS%"=="all" (
    set "COMPONENTS="
    for /d %%C in ("%REPO_ROOT%\_lib\*") do (
        set "cat_name=%%~nxC"
        if not "!cat_name:~0,1!"=="_" (
            if not "!cat_name!"=="bootloaders" if not "!cat_name!"=="storage" if not "!cat_name!"=="runtimes" if not "!cat_name!"=="ml-training" (
                for /d %%D in ("%%C\*") do (
                    set "comp_name=%%~nxD"
                    if not "!comp_name:~0,1!"=="_" (
                        if "!cat_name!/!comp_name!"=="freebsd/distro" (
                            set "COMPONENTS=!COMPONENTS! freebsd/distro"
                        ) else if "!cat_name!/!comp_name!"=="illumos/distro" (
                            set "COMPONENTS=!COMPONENTS! illumos/distro"
                        ) else (
                            set "COMPONENTS=!COMPONENTS! !comp_name!"
                        )
                    )
                )
            )
        )
    )
    set "COMPONENTS=!COMPONENTS! bootloaders/grub bootloaders/limine bootloaders/refind bootloaders/systemd-boot storage/provision_disk runtimes/provision_isolated_runtime ml-training"
    for /d %%T in ("%REPO_ROOT%\topologies\*") do (
        set "COMPONENTS=!COMPONENTS! topologies/%%~nxT"
    )
    for %%S in ("%REPO_ROOT%\payloads\schedulers\*.sh") do (
        set "COMPONENTS=!COMPONENTS! payloads/schedulers/%%~nS"
    )
    for /d %%R in ("%REPO_ROOT%\traits\*") do (
        set "COMPONENTS=!COMPONENTS! traits/%%~nxR"
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
for %%A in ("!target:/=\!") do set "short_target=%%~nxA"
echo ============================================================
echo Running test for !target! on windows-11...
echo ============================================================

set "stdout_file=%TESTS_TMP_DIR%\!short_target!.windows.stdout"
set "stderr_file=%TESTS_TMP_DIR%\!short_target!.windows.stderr"
set "success_file=%TESTS_TMP_DIR%\!short_target!.windows.success"
set "failure_file=%TESTS_TMP_DIR%\!short_target!.windows.failure"
set "idempotent_file=%TESTS_TMP_DIR%\!short_target!.idempotent.success"

if exist "!success_file!" del "!success_file!" >nul 2>&1
if exist "!failure_file!" del "!failure_file!" >nul 2>&1
if exist "!idempotent_file!" del "!idempotent_file!" >nul 2>&1

set "test_cmd=cmd.exe /c "C:\libscript\libscript.cmd install !target! && C:\libscript\libscript.cmd test !target! && C:\libscript\libscript.cmd install !target! && C:\libscript\libscript.cmd test !target!""

pushd "%VAGRANT_DIR%"
vagrant ssh -c "!test_cmd!" > "!stdout_file!" 2> "!stderr_file!"
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
