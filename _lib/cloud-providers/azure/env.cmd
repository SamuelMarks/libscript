@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for azure on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for azure.

:: Windows env stub for azure

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%AZURE_VERSION%"=="" (
    set "AZURE_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\azure\%AZURE_VERSION%\bin;%PATH%"
