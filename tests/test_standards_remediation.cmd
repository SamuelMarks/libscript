@echo off
:: # test_standards_remediation.cmd
::
:: ## Overview
:: Windows Batch regression suite verifying URL parser parity, catalog.cmd JSON/clean-base output,
:: partitionary.cmd 2x image layout idempotency, and preload_assets.cmd component staging.
::
:: ## Usage
:: tests\test_standards_remediation.cmd

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

set "TEST_TMP=%TEMP%\ls_remediation_%RANDOM%"
if not exist "!TEST_TMP!" mkdir "!TEST_TMP!"

echo ==^> [1/3] Testing url_parser.cmd...
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\engine\common\url_parser.cmd" :git_args_from_url "https://github.com/SamuelMarks/libscript.git" "master" >nul
if not "!repo!"=="https://github.com/SamuelMarks/libscript.git" (
    echo [FAIL] url_parser.cmd repo mismatch: !repo! >&2
    rmdir /s /q "!TEST_TMP!" >nul 2>&1
    exit /b 1
)

echo ==^> [2/3] Testing catalog.cmd --clean-base...
set "STACK="
for /f "delims=" %%O in ('call "!LIBSCRIPT_ROOT_DIR!\_lib\package-managers\msi-rs\preloader\catalog.cmd" --clean-base') do set "_CB=%%O"
if not "!_CB!"=="[]" (
    echo [FAIL] catalog.cmd --clean-base mismatch: !_CB! >&2
    rmdir /s /q "!TEST_TMP!" >nul 2>&1
    exit /b 1
)

echo ==^> [3/3] Testing partitionary.cmd and preload_assets.cmd 2x idempotency...
> "!TEST_TMP!\disk.img" echo mock-disk-image
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\synthesis\disk\partitionary.cmd" layout "!TEST_TMP!\disk.img" --scheme gpt --mode single >nul || exit /b 1
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\synthesis\disk\partitionary.cmd" layout "!TEST_TMP!\disk.img" --scheme gpt --mode single >nul || exit /b 1
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\package-managers\msi-rs\preloader\preload_assets.cmd" "!TEST_TMP!\sysroot" jq >nul || exit /b 1
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\package-managers\msi-rs\preloader\preload_assets.cmd" "!TEST_TMP!\sysroot" jq >nul || exit /b 1

echo ==^> [4/6] Testing audit_stacks.cmd --strict...
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\devtools\audit\audit_stacks.cmd" --strict >nul || exit /b 1

echo ==^> [5/6] Testing paths.cmd, context.cmd, conf_no_all.env.cmd endlocal tunneling and environ.cmd 2x idempotency...
set "STACK="
set "DOWNLOAD_DIR="
call "!LIBSCRIPT_ROOT_DIR!\engine\common\paths.cmd" >nul || exit /b 1
if "!DOWNLOAD_DIR!"=="" (
    echo [FAIL] paths.cmd failed to tunnel DOWNLOAD_DIR across endlocal >&2
    rmdir /s /q "!TEST_TMP!" >nul 2>&1
    exit /b 1
)
set "STACK="
set "LIBSCRIPT_STAMP_DIR="
call "!LIBSCRIPT_ROOT_DIR!\engine\common\context.cmd" >nul || exit /b 1
if "!LIBSCRIPT_STAMP_DIR!"=="" (
    echo [FAIL] context.cmd failed to tunnel LIBSCRIPT_STAMP_DIR across endlocal >&2
    rmdir /s /q "!TEST_TMP!" >nul 2>&1
    exit /b 1
)
set "STACK="
set "RUST_INSTALL="
call "!LIBSCRIPT_ROOT_DIR!\docker\conf_no_all.env.cmd" >nul || exit /b 1
if not "!RUST_INSTALL!"=="0" (
    echo [FAIL] conf_no_all.env.cmd failed to tunnel RUST_INSTALL=0 across endlocal >&2
    rmdir /s /q "!TEST_TMP!" >nul 2>&1
    exit /b 1
)
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\engine\common\environ.cmd" :save_environment "!TEST_TMP!\env_snap.txt" || exit /b 1
for %%Z in ("!TEST_TMP!\env_snap.txt") do set "_SZ1=%%~zZ"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\engine\common\environ.cmd" :save_environment "!TEST_TMP!\env_snap.txt" || exit /b 1
for %%Z in ("!TEST_TMP!\env_snap.txt") do set "_SZ2=%%~zZ"
if not "!_SZ1!"=="!_SZ2!" (
    echo [FAIL] environ.cmd :save_environment is not 2x idempotent ^(!_SZ1! vs !_SZ2!^) >&2
    rmdir /s /q "!TEST_TMP!" >nul 2>&1
    exit /b 1
)

echo ==^> [6/6] Testing docker\create_docker_builder.cmd 2x idempotency...
if not exist "!TEST_TMP!\dk\docker" mkdir "!TEST_TMP!\dk\docker"
copy /y "!LIBSCRIPT_ROOT_DIR!\docker\base.alpine.Dockerfile" "!TEST_TMP!\dk\docker\base.alpine.Dockerfile" >nul
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\docker\create_docker_builder.cmd" -i "!TEST_TMP!\dk" >nul || exit /b 1
for %%Z in ("!TEST_TMP!\dk\docker_builder.cmd") do set "_DK1=%%~zZ"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\docker\create_docker_builder.cmd" -i "!TEST_TMP!\dk" >nul || exit /b 1
for %%Z in ("!TEST_TMP!\dk\docker_builder.cmd") do set "_DK2=%%~zZ"
if not "!_DK1!"=="!_DK2!" (
    echo [FAIL] create_docker_builder.cmd is not 2x idempotent >&2
    rmdir /s /q "!TEST_TMP!" >nul 2>&1
    exit /b 1
)

rmdir /s /q "!TEST_TMP!" >nul 2>&1
echo [PASS] All Windows standards remediation checks passed.
exit /b 0
