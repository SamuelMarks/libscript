@echo off
setlocal EnableDelayedExpansion
:: # test_package_as_docker_offline.cmd
::
:: ## Overview
:: Validates Dockerfile and Docker Compose export architecture on Windows.
:: Tests both online ADD layer caching and completely air-gapped offline modes.
::
:: ## Usage
:: call tests\test_package_as_docker_offline.cmd

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
    set "LIBSCRIPT_ROOT_DIR=%SCRIPT_DIR%\.."
)

set "TEST_TMP_DIR=%LIBSCRIPT_ROOT_DIR%\tests_tmp\test_docker_offline_%RANDOM%"
if not exist "%TEST_TMP_DIR%" mkdir "%TEST_TMP_DIR%"

echo === Testing Online Dockerfile Generation with ADD Layer Caching ===
set "DOCKERFILE_ONLINE=%TEST_TMP_DIR%\Dockerfile.online"
call "%LIBSCRIPT_ROOT_DIR%\cli\commands\packaging\formats\pkg_docker.cmd" --online python 3.11 https://example.com/python-3.11.tar.gz > "%DOCKERFILE_ONLINE%"

call :assert_contains "%DOCKERFILE_ONLINE%" "LIBSCRIPT_CACHE_DIR=" "Cache directory env variable declared"
call :assert_contains "%DOCKERFILE_ONLINE%" "ADD ${PYTHON_URL} /opt/libscript_cache/python/python-3.11.tar.gz" "ADD instruction for layer caching synthesized"
call :assert_contains "%DOCKERFILE_ONLINE%" "RUN ./libscript.sh install python" "Install command references component"
call :assert_not_contains "%DOCKERFILE_ONLINE%" "COPY cache/ /opt/libscript_cache/" "COPY cache not present in online mode"
call :assert_not_contains "%DOCKERFILE_ONLINE%" "LIBSCRIPT_OFFLINE" "LIBSCRIPT_OFFLINE not set in online mode"

echo === Testing Air-Gapped Offline Dockerfile Generation ===
set "DOCKERFILE_OFFLINE=%TEST_TMP_DIR%\Dockerfile.offline"
call "%LIBSCRIPT_ROOT_DIR%\cli\commands\packaging\formats\pkg_docker.cmd" --offline python 3.11 > "%DOCKERFILE_OFFLINE%"

call :assert_contains "%DOCKERFILE_OFFLINE%" "LIBSCRIPT_OFFLINE="1"" "LIBSCRIPT_OFFLINE=1 set in offline mode"
call :assert_contains "%DOCKERFILE_OFFLINE%" "PIP_NO_INDEX="1"" "PIP_NO_INDEX=1 configured"
call :assert_contains "%DOCKERFILE_OFFLINE%" "PIP_FIND_LINKS="/opt/libscript_cache/wheels"" "PIP_FIND_LINKS directed to cache/wheels"
call :assert_contains "%DOCKERFILE_OFFLINE%" "COPY cache/ /opt/libscript_cache/" "COPY cache/ directive present in offline header"
call :assert_contains "%DOCKERFILE_OFFLINE%" "RUN ./libscript.sh install python ${PYTHON_VERSION} --offline" "Offline flag passed to installer"
call :assert_not_contains "%DOCKERFILE_OFFLINE%" "ADD http" "No remote ADD instructions present in offline mode"

echo === Testing Open edX Air-Gapped Offline Docker Compose Generation ===
set "COMPOSE_OFFLINE=%TEST_TMP_DIR%\docker-compose.yml"
call "%LIBSCRIPT_ROOT_DIR%\cli\commands\packaging\formats\pkg_docker_compose.cmd" --offline mysql latest redis latest mongodb latest meilisearch latest openedx latest > "%COMPOSE_OFFLINE%"

call :assert_contains "%COMPOSE_OFFLINE%" "version: '3.8'" "Compose file version declared"
call :assert_contains "%COMPOSE_OFFLINE%" "libscript_offline_cache:/opt/libscript_cache:ro" "Read-only offline cache volume mount"
call :assert_contains "%COMPOSE_OFFLINE%" "internal: true" "Internal isolated network configured"
call :assert_contains "%COMPOSE_OFFLINE%" "LIBSCRIPT_OFFLINE=1" "LIBSCRIPT_OFFLINE environment variable configured"
call :assert_contains "%COMPOSE_OFFLINE%" "MYSQL_HOST=mysql" "Internal MySQL host configured"
call :assert_contains "%COMPOSE_OFFLINE%" "REDIS_HOST=redis" "Internal Redis host configured"
call :assert_contains "%COMPOSE_OFFLINE%" "MONGODB_HOST=mongodb" "Internal MongoDB host configured"
call :assert_contains "%COMPOSE_OFFLINE%" "MEILISEARCH_HOST=meilisearch" "Internal Meilisearch host configured"
call :assert_contains "%COMPOSE_OFFLINE%" "nc -z 127.0.0.1 7700" "Local utility healthcheck for Meilisearch without curl"
call :assert_contains "%COMPOSE_OFFLINE%" "openedx/healthcheck.sh" "Local Open edX healthcheck script invocation"

if exist "%TEST_TMP_DIR%" rd /s /q "%TEST_TMP_DIR%"
echo === All Container Offline Export Tests Passed Successfully! ===
exit /b 0

:: ## assert_contains
:: Asserts that a specified pattern exists within a target file.
:assert_contains
findstr /C:"%~2" "%~1" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] Assertion failed: %~3 ^(pattern: "%~2"^) >&2
    exit /b 1
)
echo [PASS] Verified: %~3
exit /b 0

:: ## assert_not_contains
:: Asserts that a prohibited pattern does not exist within a target file.
:assert_not_contains
findstr /C:"%~2" "%~1" >nul 2>&1
if not errorlevel 1 (
    echo [FAIL] Prohibited pattern found: %~3 ^(pattern: "%~2"^) >&2
    exit /b 1
)
echo [PASS] Verified absence: %~3
exit /b 0
