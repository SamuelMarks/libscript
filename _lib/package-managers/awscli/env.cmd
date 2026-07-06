@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for awscli on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for awscli.

:: Windows env stub for awscli

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%AWSCLI_VERSION%"=="" (
    set "AWSCLI_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\awscli\%AWSCLI_VERSION%\bin;%PATH%"
