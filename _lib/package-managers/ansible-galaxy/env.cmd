@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for ansible-galaxy on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for ansible-galaxy.

:: Windows env stub for ansible-galaxy
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%ANSIBLE_GALAXY_VERSION%"=="" (
    set "ANSIBLE_GALAXY_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\ansible-galaxy\%ANSIBLE_GALAXY_VERSION%\bin;%PATH%"
