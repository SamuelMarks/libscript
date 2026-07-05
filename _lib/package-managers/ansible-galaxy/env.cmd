@echo off
:: Windows env stub for ansible-galaxy

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%ANSIBLE_GALAXY_VERSION%"=="" (
    set "ANSIBLE_GALAXY_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\ansible-galaxy\%ANSIBLE_GALAXY_VERSION%\bin;%PATH%"
