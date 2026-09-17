@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for cli on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for cli.

:: Windows env stub for cli
set "THIS_FILE=%~f0"
if "%GCP_CLI_ENABLED%"=="" set "GCP_CLI_ENABLED=1"
if "%CLI_VERSION%"=="" set "CLI_VERSION=latest"
set "PATH=%LIBSCRIPT_HOME%\cli\%CLI_VERSION%\bin;%PATH%"
