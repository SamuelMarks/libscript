@echo off
:: # test_tier1_data_and_server_components.cmd
::
:: ## Overview
:: End-to-end Windows Batch behavioral test suite for the 46 Tier 1 Database (`_lib\databases\*`),
:: Cache (`_lib\caches\*`), Search (`_lib\search\*`), Message Broker (`_lib\message-brokers\*`),
:: Web Server (`_lib\web-servers\*`), and App Server (`_lib\app-servers\*`) recipes
:: added in Sections 10.4, 10.5, and 10.6.
::
:: ## Usage
:: tests\test_tier1_data_and_server_components.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
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
cd /d "%LIBSCRIPT_ROOT_DIR%"

set "FAILURES=0"
set "CHECKS=0"
set "TEST_WS=%TEMP%\libscript_tier1_data_srv_test_%RANDOM%"
if not exist "!TEST_WS!" mkdir "!TEST_WS!"
set "FAKE_LS_HOME=!TEST_WS!\ls_home"
set "FAKE_DL_DIR=!TEST_WS!\downloads"
if not exist "!FAKE_LS_HOME!" mkdir "!FAKE_LS_HOME!"
if not exist "!FAKE_DL_DIR!" mkdir "!FAKE_DL_DIR!"

echo === 1. Verifying 1:1 Windows Companion Parity Across All 46 Components ===
for %%D in (cassandra clickhouse cockroachdb couchdb ferretdb firebird influxdb lmdb mssql neo4j questdb rethinkdb rocksdb scylladb surrealdb tidb timescaledb) do (
    if exist "_lib\databases\%%D\cli.cmd" (
        call :pass_check "databases\%%D has Windows cli.cmd companion"
    ) else (
        call :fail_check "databases\%%D missing Windows cli.cmd companion"
    )
)

for %%C in (dragonfly hazelcast keydb varnish) do (
    if exist "_lib\caches\%%C\cli.cmd" (
        call :pass_check "caches\%%C has Windows cli.cmd companion"
    ) else (
        call :fail_check "caches\%%C missing Windows cli.cmd companion"
    )
)

for %%S in (opensearch solr sonic typesense) do (
    if exist "_lib\search\%%S\cli.cmd" (
        call :pass_check "search\%%S has Windows cli.cmd companion"
    ) else (
        call :fail_check "search\%%S missing Windows cli.cmd companion"
    )
)

for %%M in (activemq pulsar redpanda zeromq) do (
    if exist "_lib\message-brokers\%%M\cli.cmd" (
        call :pass_check "message-brokers\%%M has Windows cli.cmd companion"
    ) else (
        call :fail_check "message-brokers\%%M missing Windows cli.cmd companion"
    )
)

for %%W in (apache envoy haproxy openresty tomcat traefik) do (
    if exist "_lib\web-servers\%%W\cli.cmd" (
        call :pass_check "web-servers\%%W has Windows cli.cmd companion"
    ) else (
        call :fail_check "web-servers\%%W missing Windows cli.cmd companion"
    )
)

for %%A in (glassfish jboss jetty passenger payara php-fpm pm2 puma triton unicorn wildfly) do (
    if exist "_lib\app-servers\%%A\cli.cmd" (
        call :pass_check "app-servers\%%A has Windows cli.cmd companion"
    ) else (
        call :fail_check "app-servers\%%A missing Windows cli.cmd companion"
    )
)

echo === 2. Verifying Windows Package Mapper Resolution ===
set "PKG_MGR=winget"
call "_lib\_common\pkg_mapper.cmd" :map_package surrealdb
if "!MAPPED_PKG!"=="SurrealDB.SurrealDB" (
    call :pass_check "pkg_mapper.cmd maps surrealdb -> SurrealDB.SurrealDB on winget"
) else (
    call :fail_check "pkg_mapper.cmd surrealdb winget mismatch: !MAPPED_PKG!"
)

set "PKG_MGR=winget"
call "_lib\_common\pkg_mapper.cmd" :map_package traefik
if "!MAPPED_PKG!"=="TraefikLabs.Traefik" (
    call :pass_check "pkg_mapper.cmd maps traefik -> TraefikLabs.Traefik on winget"
) else (
    call :fail_check "pkg_mapper.cmd traefik winget mismatch: !MAPPED_PKG!"
)

echo === 3. Verifying Offline Cached Zip Extraction ^& 2x Idempotency (surrealdb 2.1.4) ===
set "STAGE_DIR=!TEST_WS!\stage_surrealdb"
if not exist "!STAGE_DIR!\surrealdb-2.1.4\bin" mkdir "!STAGE_DIR!\surrealdb-2.1.4\bin"
(
    echo @echo off
    echo echo surreal 2.1.4
    echo exit /b 0
) > "!STAGE_DIR!\surrealdb-2.1.4\bin\surreal.cmd"
if not exist "!FAKE_DL_DIR!\surrealdb" mkdir "!FAKE_DL_DIR!\surrealdb"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Compress-Archive -Path '!STAGE_DIR!\surrealdb-2.1.4' -DestinationPath '!FAKE_DL_DIR!\surrealdb\surrealdb-2.1.4.zip' -Force"

set "LIBSCRIPT_HOME=!FAKE_LS_HOME!"
set "DOWNLOAD_DIR=!FAKE_DL_DIR!"
set "SURREALDB_INSTALL_METHOD=libscript_native"
set "SURREALDB_DOWNLOAD_URL=https://example.invalid/surrealdb/surrealdb-2.1.4.zip"
set "STACK="
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install surrealdb 2.1.4 >nul 2>&1
if exist "!FAKE_LS_HOME!\surrealdb\2.1.4\bin\surreal.cmd" (
    call :pass_check "Offline cached zip install of surrealdb 2.1.4 succeeded"
) else (
    call :fail_check "Offline cached zip install of surrealdb 2.1.4 missing bin\surreal.cmd"
)

set "IDEMP_LOG=!TEST_WS!\surrealdb_idemp.log"
set "STACK="
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install surrealdb 2.1.4 > "!IDEMP_LOG!" 2>&1
findstr /I /C:"already installed" "!IDEMP_LOG!" >nul 2>&1
if errorlevel 1 (
    call :fail_check "Second install of surrealdb 2.1.4 did not hit idempotent early exit"
) else (
    call :pass_check "Second install of surrealdb 2.1.4 exited idempotently"
)

rmdir /s /q "!TEST_WS!" >nul 2>&1

if not "!FAILURES!"=="0" (
    echo [FAIL] Tier 1 Data ^& Server Components Windows Suite failed ^(!FAILURES!/!CHECKS! checks failed^) 1>&2
    exit /b 1
)

echo [SUCCESS] All !CHECKS! Windows behavioral checks passed!
exit /b 0

:: ## pass_check
:: Records a passing test assertion.
:pass_check
set /a CHECKS+=1
echo [PASS] %~1
exit /b 0

:: ## fail_check
:: Records a failing test assertion and increments FAILURES.
:fail_check
set /a CHECKS+=1
set /a FAILURES+=1
echo [FAIL] %~1 1>&2
exit /b 0
