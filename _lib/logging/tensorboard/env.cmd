@echo off
:: Windows env stub for tensorboard

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%TENSORBOARD_VERSION%"=="" (
    set "TENSORBOARD_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\tensorboard\%TENSORBOARD_VERSION%\bin;%PATH%"
