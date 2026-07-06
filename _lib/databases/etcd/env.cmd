@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for etcd on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for etcd.

:: Windows env stub for etcd

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%ETCD_VERSION%"=="" (
    set "ETCD_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\etcd\%ETCD_VERSION%\bin;%PATH%"
