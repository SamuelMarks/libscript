@echo off
:: Windows env stub for maven

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%MAVEN_VERSION%"=="" (
    set "MAVEN_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\maven\%MAVEN_VERSION%\bin;%PATH%"
