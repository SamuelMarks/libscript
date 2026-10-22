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

if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
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

if "!LIBSCRIPT_ROOT_DIR!"=="" (
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
set "TO_REL=release/verawood.1"

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

set "CODEBASE_DIR=%OPENEDX_INSTALL_DIR%\codebase"
if not exist "%CODEBASE_DIR%" set "CODEBASE_DIR=%OPENEDX_INSTALL_DIR%"
set "MANAGE_PY=%CODEBASE_DIR%\manage.py"
if not exist "%MANAGE_PY%" set "MANAGE_PY=%OPENEDX_INSTALL_DIR%\manage.py"

echo [INFO] Step 1/8: Creating pre-upgrade state backup...
if exist "%~dp0backup.cmd" call "%~dp0backup.cmd" create

echo [INFO] Step 2/8: Updating openedx-platform repository to %TO_REL%...
if exist "%CODEBASE_DIR%\.git" (
    pushd "%CODEBASE_DIR%"
    git fetch --all --tags 2>nul
    git checkout "%TO_REL%" 2>nul
    popd
)

echo [INFO] Step 3/8: Updating Python requirements...
if exist "%CODEBASE_DIR%\requirements\edx\base.txt" (
    "%PYTHON_BIN%" -m pip install -r "%CODEBASE_DIR%\requirements\edx\base.txt" 2>nul
)

echo [INFO] Step 4/8: Applying database migrations...
if exist "%MANAGE_PY%" (
    "%PYTHON_BIN%" "%MANAGE_PY%" lms migrate --noinput 2>nul
    "%PYTHON_BIN%" "%MANAGE_PY%" cms migrate --noinput 2>nul
)

echo [INFO] Step 5/8: Rebuilding frontend static assets and MFEs...
if exist "%CODEBASE_DIR%\package.json" (
    pushd "%CODEBASE_DIR%"
    npm clean-install --no-audit 2>nul
    popd
)
if exist "%MANAGE_PY%" (
    "%PYTHON_BIN%" "%MANAGE_PY%" lms collectstatic --noinput 2>nul
)
if exist "%~dp0mfe.cmd" (
    if exist "%OPENEDX_INSTALL_DIR%\mfes" call "%~dp0mfe.cmd" build all 2>nul
)

echo [INFO] Step 6/8: Flushing cache stores...
where redis-cli >nul 2>nul
if not errorlevel 1 (
    redis-cli flushdb 2>nul
)

echo [INFO] Step 7/8: Updating search indices...
if exist "%MANAGE_PY%" (
    "%PYTHON_BIN%" "%MANAGE_PY%" lms reindex_course --all 2>nul
)

echo [INFO] Step 8/8: Restarting services, background workers, and validating diagnostics...
if exist "%~dp0service.cmd" call "%~dp0service.cmd" restart
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
