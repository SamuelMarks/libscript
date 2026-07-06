@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for gcp on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for gcp.

:: Windows env stub for gcp

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%GCP_VERSION%"=="" (
    set "GCP_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\gcp\%GCP_VERSION%\bin;%PATH%"
