@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for mosquitto on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for mosquitto.

:: Windows env stub for mosquitto
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%MOSQUITTO_VERSION%"=="" (
    set "MOSQUITTO_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\mosquitto\%MOSQUITTO_VERSION%\bin;%PATH%"
