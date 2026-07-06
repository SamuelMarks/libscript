@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for jq on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for jq.

:: Windows env stub for jq

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%JQ_VERSION%"=="" (
    set "JQ_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\jq\%JQ_VERSION%\bin;%PATH%"
