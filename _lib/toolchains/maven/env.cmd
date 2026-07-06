@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for maven on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for maven.

:: Windows env stub for maven

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%MAVEN_VERSION%"=="" (
    set "MAVEN_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\maven\%MAVEN_VERSION%\bin;%PATH%"
