@echo off
:: Windows env stub for cabal

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%CABAL_VERSION%"=="" (
    set "CABAL_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\cabal\%CABAL_VERSION%\bin;%PATH%"
