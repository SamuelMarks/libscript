@echo off
:: Windows env stub for bun-pm

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%BUN_PM_VERSION%"=="" (
    set "BUN_PM_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\bun-pm\%BUN_PM_VERSION%\bin;%PATH%"
