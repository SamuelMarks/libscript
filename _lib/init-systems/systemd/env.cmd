@echo off
:: Windows env stub for systemd

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%SYSTEMD_VERSION%"=="" (
    set "SYSTEMD_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\systemd\%SYSTEMD_VERSION%\bin;%PATH%"
