@echo off
:: Windows env stub for apk

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%APK_VERSION%"=="" (
    set "APK_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\apk\%APK_VERSION%\bin;%PATH%"
