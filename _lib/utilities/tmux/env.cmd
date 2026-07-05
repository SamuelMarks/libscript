@echo off
:: Windows env stub for tmux

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%TMUX_VERSION%"=="" (
    set "TMUX_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\tmux\%TMUX_VERSION%\bin;%PATH%"
