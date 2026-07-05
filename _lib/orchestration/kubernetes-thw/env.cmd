@echo off
:: Windows env stub for kubernetes-thw

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%KUBERNETES_THW_VERSION%"=="" (
    set "KUBERNETES_THW_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\kubernetes-thw\%KUBERNETES_THW_VERSION%\bin;%PATH%"
