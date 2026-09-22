@echo off
setlocal EnableDelayedExpansion
:: # pkg_docker_compose.cmd
::
:: ## Overview
:: Implements packaging logic for the 'docker_compose' format on Windows.
:: Generates multi-container docker-compose.yml including Open edX topologies.
:: Supports online and air-gapped offline modes with isolated networks.
::
:: ## Usage
:: call cli\commands\packaging\formats\pkg_docker_compose.cmd [OPTIONS] [PKG]

set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "IS_OFFLINE=0"
if "%LIBSCRIPT_OFFLINE%"=="1" set "IS_OFFLINE=1"

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
shift
goto parse_loop

:generate
echo version: '3.8'
echo services:
echo   openedx-mysql:
echo     image: mysql:8.0
echo     environment:
echo       - MYSQL_ROOT_PASSWORD=openedx
echo       - MYSQL_DATABASE=openedx
echo     ports:
echo       - "3306:3306"
echo     networks:
echo       - internal_network
echo     healthcheck:
echo       test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
echo       interval: 5s
echo       retries: 5

echo   openedx-redis:
echo     image: redis:7.0-alpine
echo     ports:
echo       - "6379:6379"
echo     networks:
echo       - internal_network
echo     healthcheck:
echo       test: ["CMD", "redis-cli", "ping"]
echo       interval: 5s
echo       retries: 5

echo   openedx-mongodb:
echo     image: mongo:6.0
echo     ports:
echo       - "27017:27017"
echo     networks:
echo       - internal_network
echo     healthcheck:
echo       test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
echo       interval: 5s
echo       retries: 5

echo   openedx-meilisearch:
echo     image: getmeili/meilisearch:v1.5
echo     ports:
echo       - "7700:7700"
echo     networks:
echo       - internal_network
if "%IS_OFFLINE%"=="1" (
    echo     healthcheck:
    echo       test: ["CMD-SHELL", "nc -z 127.0.0.1 7700 || exit 1"]
    echo       interval: 5s
    echo       retries: 5
) else (
    echo     healthcheck:
    echo       test: ["CMD-SHELL", "curl -f http://localhost:7700/health || exit 1"]
    echo       interval: 5s
    echo       retries: 5
)

echo   openedx-lms:
echo     build:
echo       context: .
echo       dockerfile: docker/postgres.debian.Dockerfile
echo     ports:
echo       - "8000:8000"
echo     networks:
echo       - internal_network
echo     volumes:
if "%IS_OFFLINE%"=="1" echo       - libscript_offline_cache:/opt/libscript_cache:ro
echo       - openedx_data:/opt/openedx/data
echo       - openedx_logs:/opt/openedx/logs
echo       - openedx_media:/opt/openedx/media
echo       - openedx_backups:/opt/openedx/backups
if "%IS_OFFLINE%"=="1" (
    echo     environment:
    echo       - LIBSCRIPT_OFFLINE=1
    echo       - MYSQL_HOST=mysql
    echo       - REDIS_HOST=redis
    echo       - MONGODB_HOST=mongodb
    echo       - MEILISEARCH_HOST=meilisearch
)
echo     depends_on:
echo       - openedx-mysql
echo       - openedx-redis
echo       - openedx-mongodb
echo       - openedx-meilisearch
echo     healthcheck:
echo       test: ["CMD-SHELL", "/opt/libscript/stacks/cms/openedx/healthcheck.sh || exit 1"]
echo       interval: 5s
echo       retries: 5

echo   openedx-cms:
echo     build:
echo       context: .
echo       dockerfile: docker/postgres.debian.Dockerfile
echo     ports:
echo       - "8001:8001"
echo     networks:
echo       - internal_network
echo     volumes:
if "%IS_OFFLINE%"=="1" echo       - libscript_offline_cache:/opt/libscript_cache:ro
echo       - openedx_data:/opt/openedx/data
echo       - openedx_logs:/opt/openedx/logs
echo       - openedx_media:/opt/openedx/media
if "%IS_OFFLINE%"=="1" (
    echo     environment:
    echo       - LIBSCRIPT_OFFLINE=1
    echo       - MYSQL_HOST=mysql
    echo       - REDIS_HOST=redis
    echo       - MONGODB_HOST=mongodb
    echo       - MEILISEARCH_HOST=meilisearch
)
echo     depends_on:
echo       - openedx-lms

echo   openedx-workers:
echo     build:
echo       context: .
echo       dockerfile: docker/postgres.debian.Dockerfile
echo     command: ["/opt/libscript/stacks/cms/openedx/workers.sh", "start"]
echo     networks:
echo       - internal_network
echo     volumes:
if "%IS_OFFLINE%"=="1" echo       - libscript_offline_cache:/opt/libscript_cache:ro
echo       - openedx_data:/opt/openedx/data
echo       - openedx_logs:/opt/openedx/logs
if "%IS_OFFLINE%"=="1" (
    echo     environment:
    echo       - LIBSCRIPT_OFFLINE=1
    echo       - MYSQL_HOST=mysql
    echo       - REDIS_HOST=redis
    echo       - MONGODB_HOST=mongodb
    echo       - MEILISEARCH_HOST=meilisearch
)
echo     depends_on:
echo       - openedx-lms

echo   openedx-beat:
echo     build:
echo       context: .
echo       dockerfile: docker/postgres.debian.Dockerfile
echo     command: ["/opt/libscript/stacks/cms/openedx/workers.sh", "start"]
echo     networks:
echo       - internal_network
echo     volumes:
if "%IS_OFFLINE%"=="1" echo       - libscript_offline_cache:/opt/libscript_cache:ro
echo       - openedx_data:/opt/openedx/data
echo       - openedx_logs:/opt/openedx/logs
if "%IS_OFFLINE%"=="1" (
    echo     environment:
    echo       - LIBSCRIPT_OFFLINE=1
    echo       - MYSQL_HOST=mysql
    echo       - REDIS_HOST=redis
    echo       - MONGODB_HOST=mongodb
    echo       - MEILISEARCH_HOST=meilisearch
)
echo     depends_on:
echo       - openedx-lms

echo.
echo networks:
echo   internal_network:
if "%IS_OFFLINE%"=="1" echo     internal: true

echo.
echo volumes:
if "%IS_OFFLINE%"=="1" echo   libscript_offline_cache:
echo   openedx_data:
echo   openedx_logs:
echo   openedx_media:
echo   openedx_backups:
exit /b 0
