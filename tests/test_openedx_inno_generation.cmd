@echo off
:: # test_openedx_inno_generation.cmd
::
:: ## Overview
:: Integration test validating Inno Setup script generation for Open edX on Windows.
::
:: ## Usage
:: call tests	est_openedx_inno_generation.cmd

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

set "TEST_TMP_DIR=%LIBSCRIPT_ROOT_DIR%	ests_tmp	est_openedx_inno_%RANDOM%"
if not exist "%TEST_TMP_DIR%" mkdir "%TEST_TMP_DIR%" >nul 2>&1

echo === Testing Open edX Inno Setup Script Generation on Windows ===

set "APP_NAME=Open edX"
set "APP_VERSION=1.0.0"
set "APP_PUBLISHER=LibScript Contributors"
set "OUT_FILE=OpenEdX_Inno_Setup"

set "ISS_FILE=%TEST_TMP_DIR%\output.iss"
call "%LIBSCRIPT_ROOT_DIR%\packaging	emplate_inno.cmd" > "%ISS_FILE%"

findstr /C:"AppName=Open edX" "%ISS_FILE%" >nul || (echo [FAIL] Missing AppName & exit /b 1)
echo [PASS] Verified: Application name

findstr /C:"[Tasks]" "%ISS_FILE%" >nul || (echo [FAIL] Missing Tasks section & exit /b 1)
echo [PASS] Verified: Tasks section present

findstr /C:"workers" "%ISS_FILE%" >nul || (echo [FAIL] Missing workers task & exit /b 1)
echo [PASS] Verified: Workers task present

findstr /C:"demo_content" "%ISS_FILE%" >nul || (echo [FAIL] Missing demo_content task & exit /b 1)
echo [PASS] Verified: Demo content task present

findstr /C:"[Icons]" "%ISS_FILE%" >nul || (echo [FAIL] Missing Icons section & exit /b 1)
echo [PASS] Verified: Icons section present

findstr /C:"Management Console" "%ISS_FILE%" >nul || (echo [FAIL] Missing Management Console shortcut & exit /b 1)
echo [PASS] Verified: Management console shortcut

findstr /C:"Healthcheck" "%ISS_FILE%" >nul || (echo [FAIL] Missing Healthcheck shortcut & exit /b 1)
echo [PASS] Verified: Healthcheck shortcut

findstr /C:"workers.cmd" "%ISS_FILE%" >nul || (echo [FAIL] Missing workers.cmd & exit /b 1)
echo [PASS] Verified: Worker hooks present

rmdir /s /q "%TEST_TMP_DIR%" 2>nul
echo === Open edX Inno Setup generation Windows tests completed successfully! ===
exit /b 0
