@echo off
:: # env.cmd
::
:: ## Overview
:: Sets environment variables for Elasticsearch on Windows.
::
:: ## Usage
:: Call or execute in the current command shell:
::   call env.cmd

set "THIS_FILE=%~f0"

if "%ELASTICSEARCH_HTTP_PORT%"=="" set "ELASTICSEARCH_HTTP_PORT=9200"
if "%ELASTICSEARCH_VERSION%"=="" set "ELASTICSEARCH_VERSION=7.17.21"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"

if exist "%LIBSCRIPT_HOME%\elasticsearch\%ELASTICSEARCH_VERSION%\bin" (
    set "PATH=%LIBSCRIPT_HOME%\elasticsearch\%ELASTICSEARCH_VERSION%\bin;%PATH%"
)
