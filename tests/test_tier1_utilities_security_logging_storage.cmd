@echo off
:: # test_tier1_utilities_security_logging_storage.cmd
::
:: ## Overview
:: End-to-end Windows Batch behavioral test suite for the 40 Tier 1 Utility, Security,
:: Logging, Storage Layer, and Git Server recipes added in Section 10.7.
::
:: ## Usage
:: tests\test_tier1_utilities_security_logging_storage.cmd

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
set "TEST_WS=%TEMP%\libscript_tier1_util_sec_test_%RANDOM%"
if not exist "!TEST_WS!" mkdir "!TEST_WS!"
set "FAKE_LS_HOME=!TEST_WS!\ls_home"
set "FAKE_DL_DIR=!TEST_WS!\downloads"
if not exist "!FAKE_LS_HOME!" mkdir "!FAKE_LS_HOME!"
if not exist "!FAKE_DL_DIR!" mkdir "!FAKE_DL_DIR!"

echo === 1. Verifying 1:1 Windows Companion Parity Across All 40 Components ===
for %%U in (fd ffmpeg fzf git graphviz htop imagemagick openssl pandoc ripgrep rsync sqlite-tools tar tree unzip vim xorriso xz yq zip zstd) do (
    if exist "_lib\utilities\%%U\cli.cmd" (
        call :pass_check "utilities\%%U has Windows cli.cmd companion"
    ) else (
        call :fail_check "utilities\%%U missing Windows cli.cmd companion"
    )
)

for %%S in (crowdsec fail2ban keycloak step-ca vault wireguard) do (
    if exist "_lib\security\%%S\cli.cmd" (
        call :pass_check "security\%%S has Windows cli.cmd companion"
    ) else (
        call :fail_check "security\%%S missing Windows cli.cmd companion"
    )
)

for %%L in (grafana loki otel-collector prometheus vector) do (
    if exist "_lib\logging\%%L\cli.cmd" (
        call :pass_check "logging\%%L has Windows cli.cmd companion"
    ) else (
        call :fail_check "logging\%%L missing Windows cli.cmd companion"
    )
)

for %%T in (ceph garage glusterfs juicefs seaweedfs zfs) do (
    if exist "_lib\storage-layers\%%T\cli.cmd" (
        call :pass_check "storage-layers\%%T has Windows cli.cmd companion"
    ) else (
        call :fail_check "storage-layers\%%T missing Windows cli.cmd companion"
    )
)

for %%G in (cgit forgejo) do (
    if exist "_lib\git-servers\%%G\cli.cmd" (
        call :pass_check "git-servers\%%G has Windows cli.cmd companion"
    ) else (
        call :fail_check "git-servers\%%G missing Windows cli.cmd companion"
    )
)

echo === 2. Verifying Windows Package Mapper Resolution ===
set "PKG_MGR=winget"
call "_lib\_common\pkg_mapper.cmd" :map_package ripgrep
if "!MAPPED_PKG!"=="BurntSushi.ripgrep.MSVC" (
    call :pass_check "pkg_mapper.cmd maps ripgrep -> BurntSushi.ripgrep.MSVC on winget"
) else (
    call :fail_check "pkg_mapper.cmd ripgrep winget mismatch: !MAPPED_PKG!"
)

set "PKG_MGR=winget"
call "_lib\_common\pkg_mapper.cmd" :map_package vault
if "!MAPPED_PKG!"=="Hashicorp.Vault" (
    call :pass_check "pkg_mapper.cmd maps vault -> Hashicorp.Vault on winget"
) else (
    call :fail_check "pkg_mapper.cmd vault winget mismatch: !MAPPED_PKG!"
)

echo === 3. Verifying Offline Cached Zip Extraction ^& 2x Idempotency (ripgrep 14.1.1) ===
set "STAGE_DIR=!TEST_WS!\stage_ripgrep"
if not exist "!STAGE_DIR!\ripgrep-14.1.1\bin" mkdir "!STAGE_DIR!\ripgrep-14.1.1\bin"
(
    echo @echo off
    echo echo ripgrep 14.1.1
    echo exit /b 0
) > "!STAGE_DIR!\ripgrep-14.1.1\bin\rg.cmd"
if not exist "!FAKE_DL_DIR!\ripgrep" mkdir "!FAKE_DL_DIR!\ripgrep"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Compress-Archive -Path '!STAGE_DIR!\ripgrep-14.1.1' -DestinationPath '!FAKE_DL_DIR!\ripgrep\ripgrep-14.1.1.zip' -Force"

set "LIBSCRIPT_HOME=!FAKE_LS_HOME!"
set "DOWNLOAD_DIR=!FAKE_DL_DIR!"
set "RIPGREP_INSTALL_METHOD=libscript_native"
set "RIPGREP_DOWNLOAD_URL=https://example.invalid/ripgrep/ripgrep-14.1.1.zip"
set "STACK="
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install ripgrep 14.1.1 >nul 2>&1
if exist "!FAKE_LS_HOME!\ripgrep\14.1.1\bin\rg.cmd" (
    call :pass_check "Offline cached zip install of ripgrep 14.1.1 succeeded"
) else (
    call :fail_check "Offline cached zip install of ripgrep 14.1.1 missing bin\rg.cmd"
)

set "IDEMP_LOG=!TEST_WS!\ripgrep_idemp.log"
set "STACK="
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install ripgrep 14.1.1 > "!IDEMP_LOG!" 2>&1
findstr /I /C:"already installed" "!IDEMP_LOG!" >nul 2>&1
if errorlevel 1 (
    call :fail_check "Second install of ripgrep 14.1.1 did not hit idempotent early exit"
) else (
    call :pass_check "Second install of ripgrep 14.1.1 exited idempotently"
)

rmdir /s /q "!TEST_WS!" >nul 2>&1

if not "!FAILURES!"=="0" (
    echo [FAIL] Tier 1 Utilities/Security/Logging/Storage Windows Suite failed ^(!FAILURES!/!CHECKS! checks failed^) 1>&2
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
