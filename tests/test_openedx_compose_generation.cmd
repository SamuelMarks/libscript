@echo off
:: # test_openedx_compose_generation.cmd
::
:: ## Overview
:: Integration test validating Docker Compose YAML generation for Open edX on Windows.
::
:: ## Usage
:: call tests\test_openedx_compose_generation.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

for %%I in ("%SCRIPT_DIR%") do set "LIBSCRIPT_ROOT_DIR=%%~fI"

:: ## find_root_loop
:: Iterates upward through the directory tree looking for libscript.cmd.
:find_root_loop
if exist "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" goto found_root
for %%I in ("%LIBSCRIPT_ROOT_DIR%\..") do set "PARENT_DIR=%%~fI"
if "%PARENT_DIR%"=="%LIBSCRIPT_ROOT_DIR%" goto found_root
set "LIBSCRIPT_ROOT_DIR=%PARENT_DIR%"
goto find_root_loop

:: ## found_root
:: Target label reached once the libscript root directory is located.
:found_root

set "TEST_TMP_DIR=%LIBSCRIPT_ROOT_DIR%\tests_tmp\test_openedx_compose_%RANDOM%"
if not exist "%TEST_TMP_DIR%" mkdir "%TEST_TMP_DIR%" >nul 2>&1

echo === Testing Open edX Docker Compose Generation on Windows ===

set "YML_FILE=%TEST_TMP_DIR%\docker-compose.yml"
call "%LIBSCRIPT_ROOT_DIR%\cli\commands\packaging\formats\pkg_docker_compose.cmd" > "%YML_FILE%"

findstr /C:"version: '3.8'" "%YML_FILE%" >nul || (echo [FAIL] Missing version & exit /b 1)
echo [PASS] Verified: Compose file version

findstr /C:"services:" "%YML_FILE%" >nul || (echo [FAIL] Missing services section & exit /b 1)
echo [PASS] Verified: Services section present

findstr /C:"openedx-mysql:" "%YML_FILE%" >nul || (echo [FAIL] Missing MySQL service & exit /b 1)
echo [PASS] Verified: MySQL database service

findstr /C:"openedx-redis:" "%YML_FILE%" >nul || (echo [FAIL] Missing Redis service & exit /b 1)
echo [PASS] Verified: Redis caching service

findstr /C:"openedx-mongodb:" "%YML_FILE%" >nul || (echo [FAIL] Missing MongoDB service & exit /b 1)
echo [PASS] Verified: MongoDB datastore service

findstr /C:"openedx-meilisearch:" "%YML_FILE%" >nul || (echo [FAIL] Missing Meilisearch service & exit /b 1)
echo [PASS] Verified: Meilisearch service

findstr /C:"openedx-lms:" "%YML_FILE%" >nul || (echo [FAIL] Missing LMS service & exit /b 1)
echo [PASS] Verified: Open edX LMS service

findstr /C:"openedx-cms:" "%YML_FILE%" >nul || (echo [FAIL] Missing CMS service & exit /b 1)
echo [PASS] Verified: Open edX CMS service

findstr /C:"openedx-workers:" "%YML_FILE%" >nul || (echo [FAIL] Missing workers service & exit /b 1)
echo [PASS] Verified: Celery background workers service

findstr /C:"openedx-beat:" "%YML_FILE%" >nul || (echo [FAIL] Missing beat service & exit /b 1)
echo [PASS] Verified: Celery Beat periodic scheduler service

findstr /C:"volumes:" "%YML_FILE%" >nul || (echo [FAIL] Missing volumes section & exit /b 1)
echo [PASS] Verified: Volumes section declared

rmdir /s /q "%TEST_TMP_DIR%" 2>nul
echo === Open edX Docker Compose generation Windows tests completed successfully! ===
exit /b 0
