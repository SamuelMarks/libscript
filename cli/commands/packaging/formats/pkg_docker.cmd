@echo off
setlocal EnableDelayedExpansion
:: # pkg_docker.cmd
::
:: ## Overview
:: Implements packaging logic for the 'docker' format on Windows.
:: Generates Dockerfile with ADD layer caching in online mode or air-gapped COPY cache/ mode.
::
:: ## Usage
:: call cli\commands\packaging\formats\pkg_docker.cmd [OPTIONS] [PKG] [VERSION] [URL]
::
:: ## Parameters
:: --offline, -o       : Enable 100%% air-gapped Dockerfile generation using COPY cache/
:: --online            : Enable online Dockerfile generation with ADD layer caching
:: --base, --base-image: Specify container base image (default: debian:bookworm-slim)
:: --artifact, -a      : Target packaging artifact type (deb, rpm, apk, txz, msi, exe)
:: --layer, -l         : Filter components by architectural layer

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
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "LIBSCRIPT_ROOT_DIR=%SCRIPT_DIR%\..\..\..\.."
)

set "BASE_IMAGE=debian:bookworm-slim"
set "IS_OFFLINE=0"
if "%LIBSCRIPT_OFFLINE%"=="1" set "IS_OFFLINE=1"
set "PKG="
set "VER=latest"
set "OVERRIDE_URL="
set "ARTIFACT_TYPE="
set "LAYER_FILTER="

:: ## parse_loop
:: Parses command-line flags and positional arguments.
:parse_loop
if "%~1"=="" goto generate
if /I "%~1"=="--offline" (
    set "IS_OFFLINE=1"
    shift
    goto parse_loop
)
if /I "%~1"=="-o" (
    set "IS_OFFLINE=1"
    shift
    goto parse_loop
)
if /I "%~1"=="--online" (
    set "IS_OFFLINE=0"
    shift
    goto parse_loop
)
if /I "%~1"=="--base" (
    set "BASE_IMAGE=%~2"
    shift & shift
    goto parse_loop
)
if /I "%~1"=="--base-image" (
    set "BASE_IMAGE=%~2"
    shift & shift
    goto parse_loop
)
if /I "%~1"=="--layer" (
    set "LAYER_FILTER=%~2"
    shift & shift
    goto parse_loop
)
if /I "%~1"=="-l" (
    set "LAYER_FILTER=%~2"
    shift & shift
    goto parse_loop
)
if /I "%~1"=="--artifact" (
    set "ARTIFACT_TYPE=%~2"
    if /I "%~2"=="deb" set "BASE_IMAGE=debian:bookworm-slim"
    if /I "%~2"=="rpm" set "BASE_IMAGE=almalinux:9"
    if /I "%~2"=="apk" set "BASE_IMAGE=alpine:latest"
    if /I "%~2"=="txz" set "BASE_IMAGE=freebsd"
    if /I "%~2"=="msi" set "BASE_IMAGE=mcr.microsoft.com/windows/servercore:ltsc2022"
    if /I "%~2"=="exe" set "BASE_IMAGE=mcr.microsoft.com/windows/servercore:ltsc2022"
    shift & shift
    goto parse_loop
)
if /I "%~1"=="-a" (
    set "ARTIFACT_TYPE=%~2"
    if /I "%~2"=="deb" set "BASE_IMAGE=debian:bookworm-slim"
    if /I "%~2"=="rpm" set "BASE_IMAGE=almalinux:9"
    if /I "%~2"=="apk" set "BASE_IMAGE=alpine:latest"
    if /I "%~2"=="txz" set "BASE_IMAGE=freebsd"
    if /I "%~2"=="msi" set "BASE_IMAGE=mcr.microsoft.com/windows/servercore:ltsc2022"
    if /I "%~2"=="exe" set "BASE_IMAGE=mcr.microsoft.com/windows/servercore:ltsc2022"
    shift & shift
    goto parse_loop
)
if "!PKG!"=="" (
    set "PKG=%~1"
    shift
    goto parse_loop
)
if "!VER!"=="latest" (
    set "arg_token=%~1"
    if "!arg_token:~0,4!"=="http" (
        set "OVERRIDE_URL=%~1"
    ) else (
        set "VER=%~1"
    )
    shift
    goto parse_loop
)
if "!OVERRIDE_URL!"=="" (
    set "OVERRIDE_URL=%~1"
    shift
    goto parse_loop
)
shift
goto parse_loop

:: ## generate
:: Synthesizes Dockerfile directives for online or offline air-gapped environments.
:generate
if "%IS_OFFLINE%"=="1" (
    if not exist "cache" if not defined LIBSCRIPT_CACHE_DIR (
        echo [WARN] Local cache directory not found. Run hydrate_offline_cache.cmd prior to air-gapped build. >&2
    )
)

echo FROM %BASE_IMAGE%
echo ARG TARGETOS=linux
echo ARG TARGETARCH=amd64
echo ENV LC_ALL=C.UTF-8 LANG=C.UTF-8
echo ENV LIBSCRIPT_ROOT_DIR="/opt/libscript"
echo ENV LIBSCRIPT_BUILD_DIR="/opt/libscript_build"
echo ENV LIBSCRIPT_DATA_DIR="/opt/libscript_data"
echo ENV LIBSCRIPT_CACHE_DIR="/opt/libscript_cache"

if "%IS_OFFLINE%"=="1" (
    echo ENV LIBSCRIPT_OFFLINE="1"
    echo ENV PIP_NO_INDEX="1"
    echo ENV PIP_FIND_LINKS="/opt/libscript_cache/wheels"
    echo ENV npm_config_offline="true"
    echo ENV npm_config_prefer_offline="true"
    echo ENV npm_config_cache="/opt/libscript_cache/npm"
    echo COPY cache/ /opt/libscript_cache/
)

set "BUNDLE_FILE="
if defined PKG (
    if exist "%PKG%\offline_bundle.json" set "BUNDLE_FILE=%PKG%\offline_bundle.json"
    if not defined BUNDLE_FILE if exist "%PKG%\manifest.json" set "BUNDLE_FILE=%PKG%\manifest.json"
    if not defined BUNDLE_FILE if exist "%LIBSCRIPT_ROOT_DIR%\stacks\cms\%PKG%\offline_bundle.json" set "BUNDLE_FILE=%LIBSCRIPT_ROOT_DIR%\stacks\cms\%PKG%\offline_bundle.json"
)

if "%IS_OFFLINE%"=="0" if defined BUNDLE_FILE (
    where jq >nul 2>&1
    if not errorlevel 1 (
        for /f "tokens=1,2,3" %%a in ('jq -r ".runtimes[]? | "\(.extract_dir // "runtimes"^) \(.filename^) \(.url^)"" "!BUNDLE_FILE!" 2^>nul') do (
            if not "%%c"=="" if not "%%c"=="null" echo ADD %%c /opt/libscript_cache/%%a/%%b
        )
        for /f "tokens=1,2,3" %%a in ('jq -r ".databases[]? | "\(.extract_dir // "databases"^) \(.filename^) \(.url^)"" "!BUNDLE_FILE!" 2^>nul') do (
            if not "%%c"=="" if not "%%c"=="null" echo ADD %%c /opt/libscript_cache/%%a/%%b
        )
        for /f "tokens=1,2,3" %%a in ('jq -r ".wheels.packages[]? | "wheels \(.filename^) \(.url^)"" "!BUNDLE_FILE!" 2^>nul') do (
            if not "%%c"=="" if not "%%c"=="null" echo ADD %%c /opt/libscript_cache/%%a/%%b
        )
        for /f "tokens=1,2,3" %%a in ('jq -r "if .codebase.archive_url then "codebase \(.codebase.archive_filename^) \(.codebase.archive_url^)" else empty end" "!BUNDLE_FILE!" 2^>nul') do (
            if not "%%c"=="" if not "%%c"=="null" echo ADD %%c /opt/libscript_cache/%%a/%%b
        )
    )
)

if defined PKG (
    set "PKG_NAME=%PKG%"
    for %%F in ("%PKG%") do set "PKG_CLEAN=%%~nxF"
    set "PKG_UP=!PKG_CLEAN!"
    for %%A in ("a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I" "j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R" "s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z" "-=_") do set "PKG_UP=!PKG_UP:%%~A!"

    echo ENV !PKG_UP!_VERSION="%VER%"
    if "%IS_OFFLINE%"=="0" if defined OVERRIDE_URL (
        echo ENV !PKG_UP!_URL="%OVERRIDE_URL%"
        for %%F in ("%OVERRIDE_URL%") do set "FILENAME=%%~nxF"
        echo ADD ${!PKG_UP!_URL} /opt/libscript_cache/!PKG_CLEAN!/!FILENAME!
    )
)

echo COPY . /opt/libscript
echo WORKDIR /opt/libscript

if defined PKG (
    if "!ARTIFACT_TYPE!"=="deb" (
        echo RUN dpkg -s !PKG_CLEAN! ^>nul 2^>^&1 ^|^| ^(apt-get update ^&^& apt-get install -y /opt/libscript/*-!PKG_CLEAN!_*.deb^)
    ) else if "!ARTIFACT_TYPE!"=="rpm" (
        echo RUN rpm -q !PKG_CLEAN! ^>nul 2^>^&1 ^|^| dnf install -y /opt/libscript/*-!PKG_CLEAN!-*.rpm
    ) else if "!ARTIFACT_TYPE!"=="apk" (
        echo RUN apk info -e !PKG_CLEAN! ^>nul 2^>^&1 ^|^| apk add --allow-untrusted /opt/libscript/*-!PKG_CLEAN!-*.apk
    ) else if "!ARTIFACT_TYPE!"=="txz" (
        echo RUN pkg install -y /opt/libscript/*-!PKG_CLEAN!*.txz /opt/libscript/*-!PKG_CLEAN!*.pkg 2^>nul^|^|true
    ) else if "!ARTIFACT_TYPE!"=="msi" (
        echo RUN for %%I in ^(C:\opt\libscript\*-!PKG_CLEAN!-*.msi^) do msiexec /i "%%I" /qn /norestart
    ) else if "!ARTIFACT_TYPE!"=="exe" (
        echo RUN for %%I in ^(C:\opt\libscript\*-!PKG_CLEAN!-*.exe^) do "%%I" /SILENT /VERYSILENT
    ) else (
        if "%IS_OFFLINE%"=="1" (
            echo RUN ./libscript.sh install %PKG% ${!PKG_UP!_VERSION} --offline
        ) else (
            echo RUN ./libscript.sh install %PKG% ${!PKG_UP!_VERSION}
        )
    )
) else (
    if "%IS_OFFLINE%"=="1" (
        echo RUN ./install_gen.sh --offline
    ) else (
        echo RUN ./install_gen.sh
    )
)

exit /b 0
