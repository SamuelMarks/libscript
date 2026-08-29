@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for tmux on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for tmux.

:: Windows env stub for tmux
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%TMUX_VERSION%"=="" (
    set "TMUX_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\tmux\%TMUX_VERSION%\bin;%PATH%"
