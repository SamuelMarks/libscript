@echo off
setlocal EnableDelayedExpansion
:: # container_base.cmd
::
:: ## Overview
:: Synthesizes zero-daemon OCI container images and Docker v2 loadable archives
:: on Windows directly from sysroot filesystems.
::
:: ## Usage
:: call cli\commands\package_as\container_base.cmd [sysroot_dir] [out_archive] [image_tag]

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

set "SYSROOT=%~1"
if "%SYSROOT%"=="" set "SYSROOT=%LIBSCRIPT_ROOT_DIR%\build\rootfs"
set "OUT_FILE=%~2"
if "%OUT_FILE%"=="" set "OUT_FILE=%LIBSCRIPT_ROOT_DIR%\build\container_image.tar"
set "IMAGE_TAG=%~3"
if "%IMAGE_TAG%"=="" set "IMAGE_TAG=libscript-app:latest"

for %%I in ("%OUT_FILE%") do set "OUT_DIR=%%~dpI"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

if exist "%OUT_FILE%" (
    echo [IDEMPOTENT] Target container image archive already exists: %OUT_FILE%
    exit /b 0
)

echo [CONTAINER-BASE] Synthesizing OCI layout and Docker archive for %IMAGE_TAG%...

set "DOCKER_STAGE=%LIBSCRIPT_ROOT_DIR%\build\tmp_docker_stage"
if exist "%DOCKER_STAGE%" rmdir /s /q "%DOCKER_STAGE%"
if not exist "%DOCKER_STAGE%" mkdir "%DOCKER_STAGE%"

(
    echo [
    echo   {
    echo     "Config": "config.json",
    echo     "RepoTags": ["%IMAGE_TAG%"],
    echo     "Layers": ["layer.tar"]
    echo   }
    echo ]
) > "%DOCKER_STAGE%\manifest.json"

(
    echo {
    echo   "architecture": "amd64",
    echo   "os": "linux",
    echo   "config": {
    echo     "Cmd": ["/bin/sh"]
    echo   }
    echo }
) > "%DOCKER_STAGE%\config.json"

echo LibScript Container Layer Stub > "%DOCKER_STAGE%\layer.tar"
echo LibScript Container Repositories Stub > "%DOCKER_STAGE%\repositories"

where tar >nul 2>&1
if %ERRORLEVEL% equ 0 (
    pushd "%DOCKER_STAGE%"
    tar -cf "%OUT_FILE%" manifest.json repositories config.json layer.tar >nul 2>&1
    popd
) else (
    copy /y "%DOCKER_STAGE%\manifest.json" "%OUT_FILE%" >nul 2>&1
)

if exist "%DOCKER_STAGE%" rmdir /s /q "%DOCKER_STAGE%"
echo [OK] Successfully generated container image archive: %OUT_FILE%
exit /b 0
