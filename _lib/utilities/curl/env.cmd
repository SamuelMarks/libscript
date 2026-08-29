@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for curl on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for curl.

:: Windows env stub for curl
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%CURL_VERSION%"=="" (
    set "CURL_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\curl\%CURL_VERSION%\bin;%PATH%"
