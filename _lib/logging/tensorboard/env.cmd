@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for tensorboard on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for tensorboard.

:: Windows env stub for tensorboard

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%TENSORBOARD_VERSION%"=="" (
    set "TENSORBOARD_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\tensorboard\%TENSORBOARD_VERSION%\bin;%PATH%"
