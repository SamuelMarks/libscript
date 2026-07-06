@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for conan on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for conan.

:: Windows env stub for conan

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%CONAN_VERSION%"=="" (
    set "CONAN_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\conan\%CONAN_VERSION%\bin;%PATH%"
