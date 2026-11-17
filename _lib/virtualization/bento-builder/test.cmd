@echo off
:: # test.cmd
::
:: ## Overview
:: Test suite for Bento Builder stack on Windows, verifying hypervisor components, BENTO_DIR and
:: RUBYLIB 2x idempotency, Bento DOS plugin presence, and idempotent DOS box build routing.
::
:: ## Usage
:: call _lib\virtualization\bento-builder\test.cmd

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

echo === Checking Bento Builder environment ^& DOS plugin routing on Windows ===
set "TEST_TMP=%TEMP%\ls_bento_bld_%RANDOM%_%RANDOM%"
if not exist "!TEST_TMP!\bento\lib\bento" mkdir "!TEST_TMP!\bento\lib\bento"
if not exist "!TEST_TMP!\bento\builds\build_complete" mkdir "!TEST_TMP!\bento\builds\build_complete"
if not exist "!TEST_TMP!\bin" mkdir "!TEST_TMP!\bin"

echo # gemspec> "!TEST_TMP!\bento\bento.gemspec"
echo # msdos> "!TEST_TMP!\bento\lib\bento\vagrant_msdos.rb"
echo # freedos> "!TEST_TMP!\bento\lib\bento\vagrant_freedos.rb"
echo MOCK-BOX> "!TEST_TMP!\bento\builds\build_complete\msdos-4.0-x86_64.qemu.box"
echo @exit /b 0> "!TEST_TMP!\bin\vagrant.cmd"

set "BENTO_DIR=!TEST_TMP!\bento"
set "RUBYLIB="
set "STACK="
call "!SCRIPT_DIR!\env.cmd"
set "RUBYLIB_1=!RUBYLIB!"
set "STACK="
call "!SCRIPT_DIR!\env.cmd"
set "RUBYLIB_2=!RUBYLIB!"
if "!RUBYLIB_1!"=="" goto :fail_test
if not "!RUBYLIB_1!"=="!RUBYLIB_2!" goto :fail_test

set "ORIG_PATH=!PATH!"
set "PATH=!TEST_TMP!\bin;!PATH!"
set "STACK="
call "!SCRIPT_DIR!\cli.cmd" build msdos-4.0 "--bento-dir=!TEST_TMP!\bento" > "!TEST_TMP!\bld.log" 2>&1
if errorlevel 1 goto :fail_test
findstr /C:"[SKIP] msdos-4.0 box already built" "!TEST_TMP!\bld.log" >nul || goto :fail_test
set "PATH=!ORIG_PATH!"

if exist "!LIBSCRIPT_ROOT_DIR!\..\bento\bento.gemspec" (
    if not exist "!LIBSCRIPT_ROOT_DIR!\..\bento\lib\bento\vagrant_msdos.rb" goto :fail_test
    if not exist "!LIBSCRIPT_ROOT_DIR!\..\bento\lib\bento\vagrant_freedos.rb" goto :fail_test
)

if exist "!TEST_TMP!" rmdir /s /q "!TEST_TMP!" >nul 2>&1
echo === All Bento Builder checks completed successfully! ===
exit /b 0

:: ## fail_test
:: Cleans up temporary test directory and exits with status 1.
:fail_test
if defined ORIG_PATH set "PATH=!ORIG_PATH!"
if exist "!TEST_TMP!" rmdir /s /q "!TEST_TMP!" >nul 2>&1
echo [FAIL] Bento Builder Windows test failed. 1>&2
exit /b 1
