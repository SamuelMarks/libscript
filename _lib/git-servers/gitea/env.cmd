@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for gitea on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for gitea.

:: Windows env stub for gitea

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%GITEA_VERSION%"=="" (
    set "GITEA_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\gitea\%GITEA_VERSION%\bin;%PATH%"
