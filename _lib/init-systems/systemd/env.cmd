@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for systemd on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for systemd.

:: Windows env stub for systemd

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%SYSTEMD_VERSION%"=="" (
    set "SYSTEMD_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\systemd\%SYSTEMD_VERSION%\bin;%PATH%"
