@echo off
:: Windows env stub for kubernetes-k0s

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%KUBERNETES_K0S_VERSION%"=="" (
    set "KUBERNETES_K0S_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\kubernetes-k0s\%KUBERNETES_K0S_VERSION%\bin;%PATH%"
