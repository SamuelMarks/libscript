@echo off
:: # test_openedx_stack.cmd
::
:: ## Overview
:: Integration test runner for Open edX components and stack on Windows.

::
:: ## Usage
:: Execute this script to perform testing on Windows.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

echo ==^> Testing nodeenv CLI on Windows...
call "%~dp0/../_lib/package-managers/nodeenv/cli.cmd" help

echo ==^> Testing MySQL CLI on Windows...
call "%~dp0/../_lib/databases/mysql/cli.cmd" help

echo ==^> Testing Gunicorn CLI on Windows...
call "%~dp0/../_lib/app-servers/gunicorn/cli.cmd" help

echo ==^> Testing uWSGI CLI on Windows...
call "%~dp0/../_lib/app-servers/uwsgi/cli.cmd" help

echo ==^> Testing Waitress CLI on Windows...
call "%~dp0/../_lib/app-servers/waitress/cli.cmd" help

echo ==^> Testing Uvicorn CLI on Windows...
call "%~dp0/../_lib/app-servers/uvicorn/cli.cmd" help

echo ==^> Testing Meilisearch CLI on Windows...
call "%~dp0/../_lib/search/meilisearch/cli.cmd" help

echo ==^> Testing Elasticsearch CLI on Windows...
call "%~dp0/../_lib/search/elasticsearch/cli.cmd" help

echo ==^> Testing Exim CLI on Windows...
call "%~dp0/../_lib/utilities/exim/cli.cmd" help

echo ==^> Testing hMailServer CLI on Windows...
call "%~dp0/../_lib/utilities/hmailserver/cli.cmd" help

echo ==^> Testing Open edX Stack CLI on Windows...
call "%~dp0/../stacks/cms/openedx/cli.cmd" help

echo ==^> All Open edX Windows components verified successfully!
exit /b 0
