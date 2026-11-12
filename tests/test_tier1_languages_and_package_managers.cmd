@echo off
:: # test_tier1_languages_and_package_managers.cmd
::
:: ## Overview
:: End-to-end Windows Batch behavioral test suite for the 20 Tier 1 Language version managers
:: (`_lib\languages\*`) and 4 Tier 1 Package Manager recipes (`_lib\package-managers\*`)
:: added in Sections 10.2 and 10.3.
::
:: ## Usage
:: tests\test_tier1_languages_and_package_managers.cmd

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
set "TEST_WS=%TEMP%\libscript_tier1_lang_test_%RANDOM%"
if not exist "!TEST_WS!" mkdir "!TEST_WS!"
set "FAKE_LS_HOME=!TEST_WS!\ls_home"
set "FAKE_DL_DIR=!TEST_WS!\downloads"
if not exist "!FAKE_LS_HOME!" mkdir "!FAKE_LS_HOME!"
if not exist "!FAKE_DL_DIR!" mkdir "!FAKE_DL_DIR!"

echo === 1. Verifying 1:1 Companion Parity ^& Offline Lifecycle ===
for %%C in (clojure crystal dart erlang fortran gleam groovy haskell lua nim ocaml odin perl prolog racket scala scheme tcl vala vlang) do (
    if exist "_lib\languages\%%C\cli.cmd" (
        call :pass_check "languages\%%C has Windows cli.cmd companion"
    ) else (
        call :fail_check "languages\%%C missing Windows cli.cmd companion"
    )
)

for %%P in (maven-wrapper pkgsrc port yum) do (
    if exist "_lib\package-managers\%%P\cli.cmd" (
        call :pass_check "package-managers\%%P has Windows cli.cmd companion"
    ) else (
        call :fail_check "package-managers\%%P missing Windows cli.cmd companion"
    )
)

echo === 2. Verifying Windows Package Mapper Resolution ===
set "PKG_MGR=winget"
call "_lib\_common\pkg_mapper.cmd" :map_package dart
if "!MAPPED_PKG!"=="Google.DartSDK" (
    call :pass_check "pkg_mapper.cmd maps dart -> Google.DartSDK on winget"
) else (
    call :fail_check "pkg_mapper.cmd dart winget mismatch: !MAPPED_PKG!"
)

set "PKG_MGR=choco"
call "_lib\_common\pkg_mapper.cmd" :map_package scheme
if "!MAPPED_PKG!"=="chezscheme" (
    call :pass_check "pkg_mapper.cmd maps scheme -> chezscheme on choco"
) else (
    call :fail_check "pkg_mapper.cmd scheme choco mismatch: !MAPPED_PKG!"
)

echo === 3. Verifying Offline Cached Zip Extraction ^& 2x Idempotency (gleam 1.7.0) ===
set "STAGE_DIR=!TEST_WS!\stage_gleam"
if not exist "!STAGE_DIR!\gleam-1.7.0\bin" mkdir "!STAGE_DIR!\gleam-1.7.0\bin"
(
    echo @echo off
    echo echo gleam 1.7.0
    echo exit /b 0
) > "!STAGE_DIR!\gleam-1.7.0\bin\gleam.cmd"
if not exist "!FAKE_DL_DIR!\gleam" mkdir "!FAKE_DL_DIR!\gleam"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Compress-Archive -Path '!STAGE_DIR!\gleam-1.7.0' -DestinationPath '!FAKE_DL_DIR!\gleam\gleam-1.7.0.zip' -Force"

set "LIBSCRIPT_HOME=!FAKE_LS_HOME!"
set "DOWNLOAD_DIR=!FAKE_DL_DIR!"
set "GLEAM_INSTALL_METHOD=libscript_native"
set "GLEAM_DOWNLOAD_URL=https://example.invalid/gleam/gleam-1.7.0.zip"
set "STACK="
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install gleam 1.7.0 >nul 2>&1
if exist "!FAKE_LS_HOME!\gleam\1.7.0\bin\gleam.cmd" (
    call :pass_check "Offline cached zip install of gleam 1.7.0 succeeded"
) else (
    call :fail_check "Offline cached zip install of gleam 1.7.0 missing bin\gleam.cmd"
)

set "IDEMP_LOG=!TEST_WS!\gleam_idemp.log"
set "STACK="
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install gleam 1.7.0 > "!IDEMP_LOG!" 2>&1
findstr /I /C:"already installed" "!IDEMP_LOG!" >nul 2>&1
if errorlevel 1 (
    call :fail_check "Second install of gleam 1.7.0 did not hit idempotent early exit"
) else (
    call :pass_check "Second install of gleam 1.7.0 exited idempotently"
)

rmdir /s /q "!TEST_WS!" >nul 2>&1

if not "!FAILURES!"=="0" (
    echo [FAIL] Tier 1 Languages ^& Package Managers Windows Suite failed ^(!FAILURES!/!CHECKS! checks failed^) 1>&2
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
