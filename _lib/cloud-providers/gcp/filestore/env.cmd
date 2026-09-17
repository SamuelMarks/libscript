@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for filestore on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for filestore.

:: Windows env stub for filestore
set "THIS_FILE=%~f0"
if "%GCP_FILESTORE_ENABLED%"=="" set "GCP_FILESTORE_ENABLED=1"
if "%FILESTORE_VERSION%"=="" set "FILESTORE_VERSION=latest"
set "PATH=%LIBSCRIPT_HOME%\filestore\%FILESTORE_VERSION%\bin;%PATH%"
