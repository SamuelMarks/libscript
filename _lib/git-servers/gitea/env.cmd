@echo off
:: Windows env stub for gitea

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%GITEA_VERSION%"=="" (
    set "GITEA_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\gitea\%GITEA_VERSION%\bin;%PATH%"
