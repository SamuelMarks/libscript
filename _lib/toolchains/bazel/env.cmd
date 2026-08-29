@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for bazel on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for bazel.

:: Windows env stub for bazel
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%BAZEL_VERSION%"=="" (
    set "BAZEL_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\bazel\%BAZEL_VERSION%\bin;%PATH%"
