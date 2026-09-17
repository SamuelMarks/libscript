@echo off
:: # env.cmd
::
:: ## Overview
:: Environment configuration script for Kubernetes on Windows.
::
:: ## Usage
:: Configures LIBSCRIPT_HOME and PATH for kubernetes.

set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%KUBERNETES_VERSION%"=="" (
    set "KUBERNETES_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\kubernetes\%KUBERNETES_VERSION%\bin;%PATH%"
