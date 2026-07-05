@echo off
:: Windows env stub for vllm

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%VLLM_VERSION%"=="" (
    set "VLLM_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\vllm\%VLLM_VERSION%\bin;%PATH%"
