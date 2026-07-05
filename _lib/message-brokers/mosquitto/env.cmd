@echo off
:: Windows env stub for mosquitto

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%MOSQUITTO_VERSION%"=="" (
    set "MOSQUITTO_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\mosquitto\%MOSQUITTO_VERSION%\bin;%PATH%"
