@echo off
:: # test_openedx_nsis_generation.cmd
::
:: ## Overview
:: Integration test validating NSIS script generation for Open edX on Windows.
::
:: ## Usage
:: call tests\test_openedx_nsis_generation.cmd

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

set "TEST_TMP_DIR=%LIBSCRIPT_ROOT_DIR%\tests_tmp\test_openedx_nsis_%RANDOM%"
if not exist "%TEST_TMP_DIR%" mkdir "%TEST_TMP_DIR%" >nul 2>&1

echo === Testing Open edX NSIS Script Generation on Windows ===

set "APP_NAME=Open edX"
set "APP_VERSION=1.0.0"
set "APP_PUBLISHER=LibScript Contributors"
set "OUT_FILE=OpenEdX_NSIS_Setup"

set "NSI_FILE=%TEST_TMP_DIR%\output.nsi"
call "%LIBSCRIPT_ROOT_DIR%\packaging\template_nsis.cmd" > "%NSI_FILE%"

findstr /C:"!define APP_NAME "Open edX"" "%NSI_FILE%" >nul || (echo [FAIL] Missing APP_NAME & exit /b 1)
echo [PASS] Verified: Application name

findstr /C:"healthcheck.cmd" "%NSI_FILE%" >nul || (echo [FAIL] Missing healthcheck.cmd & exit /b 1)
echo [PASS] Verified: Healthcheck hook

findstr /C:"workers.cmd" "%NSI_FILE%" >nul || (echo [FAIL] Missing workers.cmd & exit /b 1)
echo [PASS] Verified: Worker hooks

findstr /C:"import_demo.cmd" "%NSI_FILE%" >nul || (echo [FAIL] Missing import_demo.cmd & exit /b 1)
echo [PASS] Verified: Demo content hook

findstr /C:"Management Console" "%NSI_FILE%" >nul || (echo [FAIL] Missing Management Console shortcut & exit /b 1)
echo [PASS] Verified: Management console shortcut

findstr /C:"Section "Uninstall"" "%NSI_FILE%" >nul || (echo [FAIL] Missing Uninstall section & exit /b 1)
echo [PASS] Verified: Uninstaller section

rmdir /s /q "%TEST_TMP_DIR%" 2>nul
echo === Open edX NSIS generation Windows tests completed successfully! ===
exit /b 0
