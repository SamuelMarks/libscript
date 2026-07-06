@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for azure-cli on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for azure-cli.

:: Windows env stub for azure-cli

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%AZURE_CLI_VERSION%"=="" (
    set "AZURE_CLI_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\azure-cli\%AZURE_CLI_VERSION%\bin;%PATH%"
