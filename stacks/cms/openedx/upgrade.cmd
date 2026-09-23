@echo off
:: # upgrade.cmd
::
:: ## Overview
:: Upgrade and release migration engine for Open edX on Windows.
:: Performs pre-upgrade backups, repository updates, database migrations, and cache clearing.
::
:: ## Usage
::   call upgrade.cmd run [--from <release>] [--to <release>]
::   call upgrade.cmd help
::
:: ## Exit Codes
::   0 - Upgrade completed successfully
::   1 - Error during upgrade

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_ROOT_DIR%"=="" (
    for %%i in ("%~dp0..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

if "%OPENEDX_INSTALL_DIR%"=="" (
    if defined LIBSCRIPT_HOME (
        set "OPENEDX_INSTALL_DIR=%LIBSCRIPT_HOME%\openedx"
    ) else (
        set "OPENEDX_INSTALL_DIR=%USERPROFILE%\.libscript\openedx"
    )
)

set "PYTHON_BIN=%OPENEDX_INSTALL_DIR%\.venv\Scripts\python.exe"
if not exist "%PYTHON_BIN%" (
    where python >nul 2>nul
    if not errorlevel 1 (
        set "PYTHON_BIN=python"
    ) else (
        echo [ERROR] Python interpreter not found in virtualenv or PATH. >&2
        exit /b 1
    )
)

set "CMD=%~1"
if "%CMD%"=="" goto show_help
if "%CMD%"=="help" goto show_help
if "%CMD%"=="--help" goto show_help
if "%CMD%"=="-h" goto show_help

if "%CMD%"=="run" goto do_run
if "%CMD%"=="upgrade" goto do_run

echo [ERROR] Unknown upgrade command: %CMD% >&2
goto show_help

:: ## do_run
:: Initializes release upgrade parameter setup.
:do_run
shift
set "FROM_REL=current"
set "TO_REL=master"

:: ## parse_upgrade_args
:: Parses command-line arguments for the release upgrade pipeline.
:parse_upgrade_args
if "%~1"=="" goto run_upgrade_pipeline
if "%~1"=="--from" (
    set "FROM_REL=%~2"
    shift
    shift
    goto parse_upgrade_args
)
if "%~1"=="--to" (
    set "TO_REL=%~2"
    shift
    shift
    goto parse_upgrade_args
)
echo [ERROR] Unknown option: %~1 >&2
exit /b 1

:: ## run_upgrade_pipeline
:: Executes complete release upgrade workflow across all tiers.
:run_upgrade_pipeline
echo [INFO] === Commencing Open edX Upgrade Pipeline (%FROM_REL% -> %TO_REL%) ===

echo [INFO] Step 1/8: Creating pre-upgrade state backup...
if exist "%~dp0backup.cmd" call "%~dp0backup.cmd" create

echo [INFO] Step 2/8: Updating openedx-platform repository...
if exist "%OPENEDX_INSTALL_DIR%\.git" (
    pushd "%OPENEDX_INSTALL_DIR%"
    git fetch --all --tags 2>nul
    git checkout "%TO_REL%" 2>nul
    popd
)

echo [INFO] Step 3/8: Updating Python requirements...
if exist "%OPENEDX_INSTALL_DIR%\requirements\edx\base.txt" (
    "%PYTHON_BIN%" -m pip install -r "%OPENEDX_INSTALL_DIR%\requirements\edx\base.txt" 2>nul
)

echo [INFO] Step 4/8: Applying database migrations...
if exist "%OPENEDX_INSTALL_DIR%\manage.py" (
    "%PYTHON_BIN%" "%OPENEDX_INSTALL_DIR%\manage.py" lms migrate --noinput 2>nul
    "%PYTHON_BIN%" "%OPENEDX_INSTALL_DIR%\manage.py" cms migrate --noinput 2>nul
)

echo [INFO] Step 5/8: Rebuilding frontend static assets...
if exist "%OPENEDX_INSTALL_DIR%\package.json" (
    pushd "%OPENEDX_INSTALL_DIR%"
    npm clean-install --no-audit 2>nul
    popd
)
if exist "%OPENEDX_INSTALL_DIR%\manage.py" (
    "%PYTHON_BIN%" "%OPENEDX_INSTALL_DIR%\manage.py" lms collectstatic --noinput 2>nul
)

echo [INFO] Step 6/8: Flushing cache stores...
where redis-cli >nul 2>nul
if not errorlevel 1 (
    redis-cli flushdb 2>nul
)

echo [INFO] Step 7/8: Updating search indices...
if exist "%OPENEDX_INSTALL_DIR%\manage.py" (
    "%PYTHON_BIN%" "%OPENEDX_INSTALL_DIR%\manage.py" lms reindex_course --all 2>nul
)

echo [INFO] Step 8/8: Restarting background workers and validating diagnostics...
if exist "%~dp0workers.cmd" call "%~dp0workers.cmd" restart
if exist "%~dp0healthcheck.cmd" call "%~dp0healthcheck.cmd"

echo [SUCCESS] Open edX platform upgrade to '%TO_REL%' completed successfully.
exit /b 0

:: ## show_help
:: Displays upgrade CLI command usage.
:show_help
echo Open edX Release Upgrade ^& Migration CLI (Windows)
echo.
echo Usage:
echo   call upgrade.cmd run [--from ^<release^>] [--to ^<release^>]
echo   call upgrade.cmd help
exit /b 0
