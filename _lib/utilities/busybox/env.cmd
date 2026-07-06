@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for busybox on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for busybox.

:: Windows env stub for busybox

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%BUSYBOX_VERSION%"=="" (
    set "BUSYBOX_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\busybox\%BUSYBOX_VERSION%\bin;%PATH%"
