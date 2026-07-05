@echo off
:: Windows env stub for bazel

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%BAZEL_VERSION%"=="" (
    set "BAZEL_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\bazel\%BAZEL_VERSION%\bin;%PATH%"
