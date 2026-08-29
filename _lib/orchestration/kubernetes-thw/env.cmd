@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for kubernetes-thw on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for kubernetes-thw.

:: Windows env stub for kubernetes-thw
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%KUBERNETES_THW_VERSION%"=="" (
    set "KUBERNETES_THW_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\kubernetes-thw\%KUBERNETES_THW_VERSION%\bin;%PATH%"
