@echo off
:: # pkg_docker_compose.cmd
::
:: ## Overview
:: Implements packaging logic for the 'docker_compose' format on Windows.
:: Generates multi-container docker-compose.yml including Open edX topologies.
:: 
:: ## Usage
:: This script is called by the packaging system and should not be executed manually.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

echo version: '3.8'
echo services:
echo   openedx-mysql:
echo     image: mysql:8.0
echo     environment:
echo       - MYSQL_ROOT_PASSWORD=openedx
echo       - MYSQL_DATABASE=openedx
echo     ports:
echo       - "3306:3306"
echo     healthcheck:
echo       test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
echo       interval: 5s
echo       retries: 5

echo   openedx-redis:
echo     image: redis:7.0-alpine
echo     ports:
echo       - "6379:6379"
echo     healthcheck:
echo       test: ["CMD", "redis-cli", "ping"]
echo       interval: 5s
echo       retries: 5

echo   openedx-mongodb:
echo     image: mongo:6.0
echo     ports:
echo       - "27017:27017"
echo     healthcheck:
echo       test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
echo       interval: 5s
echo       retries: 5

echo   openedx-meilisearch:
echo     image: getmeili/meilisearch:v1.5
echo     ports:
echo       - "7700:7700"
echo     healthcheck:
echo       test: ["CMD-SHELL", "curl -f http://localhost:7700/health || exit 1"]
echo       interval: 5s
echo       retries: 5

echo   openedx-lms:
echo     build:
echo       context: .
echo       dockerfile: docker/postgres.debian.Dockerfile
echo     ports:
echo       - "8000:8000"
echo     volumes:
echo       - openedx_data:/opt/openedx/data
echo       - openedx_logs:/opt/openedx/logs
echo       - openedx_media:/opt/openedx/media
echo       - openedx_backups:/opt/openedx/backups
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
echo     volumes:
echo       - openedx_data:/opt/openedx/data
echo       - openedx_logs:/opt/openedx/logs
echo       - openedx_media:/opt/openedx/media
echo     depends_on:
echo       - openedx-lms

echo   openedx-workers:
echo     build:
echo       context: .
echo       dockerfile: docker/postgres.debian.Dockerfile
echo     command: ["/opt/libscript/stacks/cms/openedx/workers.sh", "start"]
echo     volumes:
echo       - openedx_data:/opt/openedx/data
echo       - openedx_logs:/opt/openedx/logs
echo     depends_on:
echo       - openedx-lms

echo   openedx-beat:
echo     build:
echo       context: .
echo       dockerfile: docker/postgres.debian.Dockerfile
echo     command: ["/opt/libscript/stacks/cms/openedx/workers.sh", "start"]
echo     volumes:
echo       - openedx_data:/opt/openedx/data
echo       - openedx_logs:/opt/openedx/logs
echo     depends_on:
echo       - openedx-lms

echo.
echo volumes:
echo   openedx_data:
echo   openedx_logs:
echo   openedx_media:
echo   openedx_backups:
exit /b 0
