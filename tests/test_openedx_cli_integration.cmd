@echo off
:: # test_openedx_cli_integration.cmd
::
:: ## Overview
:: Exhaustive native Windows test runner for all Open edX components and stacks.
:: Tests batch script execution under cmd.exe without WSL or Cygwin dependencies.

::
:: ## Usage
:: Execute this script to perform testing on Windows.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

echo [TEST 1/9] Verifying nodeenv on native Windows...
call "%~dp0/../_lib/package-managers/nodeenv/cli.cmd" help
if errorlevel 1 (
    echo [FAIL] nodeenv CLI failed on Windows.
    exit /b 1
)

echo [TEST 2/9] Verifying MySQL on native Windows...
call "%~dp0/../_lib/databases/mysql/cli.cmd" help
if errorlevel 1 (
    echo [FAIL] MySQL CLI failed on Windows.
    exit /b 1
)

echo [TEST 3/9] Verifying Waitress WSGI server on native Windows...
call "%~dp0/../_lib/app-servers/waitress/cli.cmd" help
if errorlevel 1 (
    echo [FAIL] Waitress CLI failed on Windows.
    exit /b 1
)

echo [TEST 4/9] Verifying Uvicorn ASGI server on native Windows...
call "%~dp0/../_lib/app-servers/uvicorn/cli.cmd" help
if errorlevel 1 (
    echo [FAIL] Uvicorn CLI failed on Windows.
    exit /b 1
)

echo [TEST 5/9] Verifying Gunicorn dispatcher on native Windows...
call "%~dp0/../_lib/app-servers/gunicorn/cli.cmd" help
if errorlevel 1 (
    echo [FAIL] Gunicorn CLI failed on Windows.
    exit /b 1
)

echo [TEST 6/9] Verifying Meilisearch search engine on native Windows...
call "%~dp0/../_lib/search/meilisearch/cli.cmd" help
if errorlevel 1 (
    echo [FAIL] Meilisearch CLI failed on Windows.
    exit /b 1
)

echo [TEST 7/9] Verifying hMailServer on native Windows...
call "%~dp0/../_lib/utilities/hmailserver/cli.cmd" help
if errorlevel 1 (
    echo [FAIL] hMailServer CLI failed on Windows.
    exit /b 1
)

echo [TEST 8/9] Verifying Exim Windows dispatcher...
call "%~dp0/../_lib/utilities/exim/cli.cmd" help
if errorlevel 1 (
    echo [FAIL] Exim CLI failed on Windows.
    exit /b 1
)

echo [TEST 9/9] Verifying Open edX stack orchestrator and Tutor parity subcommands on native Windows...
call "%~dp0/../stacks/cms/openedx/cli.cmd" help
if errorlevel 1 (
    echo [FAIL] Open edX stack CLI failed on Windows.
    exit /b 1
)

for %%s in (user demo dbshell healthcheck config backup restore workers theme xblock upgrade mfe) do (
    call "%~dp0/../stacks/cms/openedx/cli.cmd" %%s help
    if errorlevel 1 (
        echo [FAIL] Open edX subcommand '%%s' failed on Windows.
        exit /b 1
    )
)

echo.
echo ==========================================================
echo [SUCCESS] All Open edX components verified on native Windows!
echo ==========================================================
exit /b 0
