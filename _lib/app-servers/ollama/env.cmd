@echo off
:: # env.cmd
::
:: ## Overview
:: Environment initialization for Ollama on Windows.
::
:: ## Usage
:: Sets up default environment variables for Ollama.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if "%OLLAMA_INSTALL_METHOD%"=="" set "OLLAMA_INSTALL_METHOD=libscript_native"
if "%OLLAMA_VERSION%"=="" set "OLLAMA_VERSION=latest"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
set "PATH=%LIBSCRIPT_HOME%\ollama\%OLLAMA_VERSION%\bin;%PATH%"
