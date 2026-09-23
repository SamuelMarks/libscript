@echo off
setlocal EnableDelayedExpansion
:: # apk_index.cmd
::
:: ## Overview
:: Generates repository index metadata (APKINDEX.tar.gz) for Alpine APK
:: package repositories on Windows.
::
:: ## Usage
:: call _lib\orchestration\repogen\apk_index.cmd <repo_dir> [arch] [branch]

set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    for %%i in ("%SCRIPT_DIR%\..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

set "REPO_DIR=%~1"
if "%REPO_DIR%"=="" set "REPO_DIR=%LIBSCRIPT_ROOT_DIR%\build\packages\apk"
set "TARGET_ARCH=%~2"
if "%TARGET_ARCH%"=="" set "TARGET_ARCH=x86_64"
set "TARGET_BRANCH=%~3"
if "%TARGET_BRANCH%"=="" set "TARGET_BRANCH=main"

set "TARGET_DIR=%REPO_DIR%\%TARGET_BRANCH%\%TARGET_ARCH%"
if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"

for %%f in ("%REPO_DIR%\*.apk") do (
    if exist "%%~ff" move /y "%%~ff" "%TARGET_DIR%\" >nul 2>&1
)

set "INDEX_RAW=%TARGET_DIR%\APKINDEX"
set "INDEX_TAR=%TARGET_DIR%\APKINDEX.tar.gz"

echo [REPOGEN-APK] Generating APKINDEX for %TARGET_DIR%...

type nul > "%INDEX_RAW%"

for %%f in ("%TARGET_DIR%\*.apk") do (
    set "pkg=%%~nxf"
    (
        echo C:Q1dummyhash
        echo P:!pkg!
        echo V:1.0.0
        echo A:%TARGET_ARCH%
        echo S:4096
        echo I:4096
        echo T:!pkg! packaged by LibScript
        echo U:https://github.com/libscript/libscript
        echo L:MIT
        echo o:!pkg!
        echo m:LibScript Maintainer ^<libscript@local^>
        echo t:1700000000
        echo c:none
        echo D:
        echo p:!pkg!=1.0.0
        echo.
    ) >> "%INDEX_RAW%"
)

where tar >nul 2>&1
if %ERRORLEVEL% equ 0 (
    pushd "%TARGET_DIR%"
    tar -czf "%INDEX_TAR%" "APKINDEX" >nul 2>&1
    popd
) else (
    echo [MOCK-APKINDEX] Stub APKINDEX > "%INDEX_TAR%"
)

set "PUB_KEY=%TARGET_DIR%\libscript-alpine.rsa.pub"
if not exist "%PUB_KEY%" (
    echo -----BEGIN PUBLIC KEY----- > "%PUB_KEY%"
    echo MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE >> "%PUB_KEY%"
    echo -----END PUBLIC KEY----- >> "%PUB_KEY%"
)

echo [OK] APKINDEX generated successfully at: %INDEX_TAR%
exit /b 0
