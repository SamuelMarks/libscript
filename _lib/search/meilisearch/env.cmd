@echo off
:: # env.cmd
::
:: ## Overview
:: Sets environment variables for Meilisearch on Windows.
::
:: ## Usage
:: Call or execute in the current command shell:
::   call env.cmd

set "THIS_FILE=%~f0"

if "%MEILISEARCH_PORT%"=="" set "MEILISEARCH_PORT=7700"
if "%MEILISEARCH_VERSION%"=="" set "MEILISEARCH_VERSION=v1.36.0"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"

if exist "%LIBSCRIPT_HOME%\meilisearch\%MEILISEARCH_VERSION%\bin" (
    set "PATH=%LIBSCRIPT_HOME%\meilisearch\%MEILISEARCH_VERSION%\bin;%PATH%"
)
