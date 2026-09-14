@echo off
set "THIS_FILE=%~f0"
:: # run_windows_tests.cmd
::
:: ## Overview
:: Batch script wrapper to execute component tests sequentially on Windows 11 Vagrant VM.
::
:: ## Usage
:: run_windows_tests.cmd [TARGETS...|all]

setlocal EnableDelayedExpansion
set "THIS_DIR=%~dp0"
set "REPO_ROOT=%THIS_DIR%.."
set "VAGRANT_DIR=%REPO_ROOT%\vagrant\windows-11"
set "TESTS_TMP_DIR=%REPO_ROOT%\tests_tmp"

if not exist "%TESTS_TMP_DIR%" mkdir "%TESTS_TMP_DIR%"

if "%~1"=="" goto :usage_check
if "%~1"=="--help" goto :show_help
if "%~1"=="-h" goto :show_help
if "%~1"=="/?" goto :show_help
goto :start_tests

:: ## usage_check
:: Executes usage_check functionality.
:usage_check
set "TARGETS=all"
goto :run_tests

:: ## show_help
:: Executes show_help functionality.
:show_help
echo Usage: run_windows_tests.cmd [TARGETS...^|all]
echo.
echo Runs local tests sequentially on Windows 11 Vagrant VM.
echo Results are written to tests_tmp\ directory.
exit /b 0

:: ## start_tests
:: Executes start_tests functionality.
:start_tests
set "TARGETS=%*"

:: ## run_tests
:: Executes run_tests functionality.
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
    call sh "%THIS_DIR%run_windows_tests.sh" all
) else (
    call sh "%THIS_DIR%run_windows_tests.sh" %TARGETS%
)

exit /b %errorlevel%
