@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for gradle on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for gradle.

:: Windows env stub for gradle

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%GRADLE_VERSION%"=="" (
    set "GRADLE_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\gradle\%GRADLE_VERSION%\bin;%PATH%"
