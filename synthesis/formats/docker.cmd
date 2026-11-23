@echo off
:: # docker.cmd
:: ## Overview
:: Dual-modality container export driver for Docker and Docker Compose on Windows. Generates online layer-cached or air-gapped offline Dockerfile and docker-compose.yml.
:: ## Usage
:: docker.cmd [--compose] [--offline|--online] [args...]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        if "%LIBSCRIPT_DEBUG%"=="1" echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found


if "%~1"=="--help" (
    echo Usage: %~nx0 [--compose] [--offline^|--online] [args...]
    echo Generates Dockerfile or docker-compose.yml.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [--compose] [--offline^|--online] [args...]
    echo Generates Dockerfile or docker-compose.yml.
    exit /b 0
)

for %%I in ("!SCRIPT_DIR!\..\..\..") do set "REPO_ROOT=%%~fI"

set "IS_COMPOSE=0"
for %%A in (%*) do (
    if "%%~A"=="--compose" set "IS_COMPOSE=1"
)

if "%IS_COMPOSE%"=="1" (
    call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\docker_compose.cmd" %*
    exit /b !ERRORLEVEL!
)

set "BASE_IMAGE=debian:bookworm-slim"
set "IS_OFFLINE=0"
if "%LIBSCRIPT_OFFLINE%"=="1" set "IS_OFFLINE=1"

goto :parse_df_args

:: ## parse_df_args
:: Parses optional flags (--offline, --online, --base) before component arguments.
:parse_df_args
if "%~1"=="" goto :emit_df_hdr
if /I "%~1"=="--offline" ( set "IS_OFFLINE=1" & shift & goto :parse_df_args )
if /I "%~1"=="-o" ( set "IS_OFFLINE=1" & shift & goto :parse_df_args )
if /I "%~1"=="--online" ( set "IS_OFFLINE=0" & shift & goto :parse_df_args )
if /I "%~1"=="--base" ( set "BASE_IMAGE=%~2" & shift & shift & goto :parse_df_args )
if /I "%~1"=="--base-image" ( set "BASE_IMAGE=%~2" & shift & shift & goto :parse_df_args )
goto :emit_df_hdr

:: ## emit_df_hdr
:: Emits the Dockerfile header and RUN install layers to stdout.
:emit_df_hdr
if /I "!BASE_IMAGE!"=="debian" set "BASE_IMAGE=debian:bookworm-slim"
if /I "!BASE_IMAGE!"=="alpine" set "BASE_IMAGE=alpine:latest"
echo FROM !BASE_IMAGE!
echo ARG TARGETOS=linux
echo ARG TARGETARCH=amd64
echo ENV LC_ALL=C.UTF-8 LANG=C.UTF-8
echo ENV LIBSCRIPT_ROOT_DIR="/opt/libscript"
echo ENV LIBSCRIPT_BUILD_DIR="/opt/libscript_build"
echo ENV LIBSCRIPT_DATA_DIR="/opt/libscript_data"
echo ENV LIBSCRIPT_CACHE_DIR="/opt/libscript_cache"
if "!IS_OFFLINE!"=="1" echo ENV LIBSCRIPT_OFFLINE="1"
echo COPY . /opt/libscript
echo WORKDIR /opt/libscript

goto :emit_df_pkgs

:: ## emit_df_pkgs
:: Iterates through requested component and version pairs to emit RUN layers.
:emit_df_pkgs
if "%~1"=="" exit /b 0
set "_DF_PKG=%~1"
set "_DF_VER=%~2"
if "!_DF_VER!"=="" set "_DF_VER=latest"
if "!IS_OFFLINE!"=="1" (
    echo RUN ./libscript.sh install !_DF_PKG! "!_DF_VER!" --offline
) else (
    echo RUN ./libscript.sh install !_DF_PKG! "!_DF_VER!"
)
shift
if not "%~1"=="" shift
goto :emit_df_pkgs
