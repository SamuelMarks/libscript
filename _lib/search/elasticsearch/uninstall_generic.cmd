@echo off
:: # uninstall_generic.cmd
::
:: ## Overview
:: Windows generic uninstallation script for Elasticsearch.
::
:: ## Usage
:: Execute this script to uninstall Elasticsearch.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if "%ELASTICSEARCH_VERSION%"=="" set "ELASTICSEARCH_VERSION=7.17.21"
rmdir /s /q "%LIBSCRIPT_HOME%\elasticsearch\%ELASTICSEARCH_VERSION%" 2>nul
exit /b 0
