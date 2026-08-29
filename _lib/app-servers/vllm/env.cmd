@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for vllm on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for vllm.

:: Windows env stub for vllm
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%VLLM_VERSION%"=="" (
    set "VLLM_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\vllm\%VLLM_VERSION%\bin;%PATH%"
