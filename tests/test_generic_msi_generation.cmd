@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /I /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

:: # test_generic_msi_generation.cmd
::
:: ## Overview
:: Windows verification test suite for declarative MSI synthesis.
::
:: ## Usage
::   call tests\test_generic_msi_generation.cmd

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
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

set "TMP_DIR=%TEMP%\msi_test_%RANDOM%"
if not exist "%TMP_DIR%" mkdir "%TMP_DIR%"

echo ==> Testing Declarative WiX Generation on Windows...
call "%LIBSCRIPT_ROOT_DIR%\packaging\template_msi.cmd" "%LIBSCRIPT_ROOT_DIR%\_lib\web-apps\openedx" --out "%TMP_DIR%\openedx.wxs"
call "%LIBSCRIPT_ROOT_DIR%\packaging\template_msi.cmd" "%LIBSCRIPT_ROOT_DIR%\_lib\web-apps\wordpress" --out "%TMP_DIR%\wordpress.wxs"
call "%LIBSCRIPT_ROOT_DIR%\packaging\template_msi.cmd" "%LIBSCRIPT_ROOT_DIR%\_lib\web-apps\drupal" --out "%TMP_DIR%\drupal.wxs"

if not exist "%TMP_DIR%\openedx.wxs" (
    echo [ERROR] openedx.wxs was not generated >&2
    exit /b 1
)

findstr /C:"USER_DB_HOST" "%TMP_DIR%\openedx.wxs" >nul
if errorlevel 1 ( echo [ERROR] Missing USER_DB_HOST in openedx.wxs >&2 & exit /b 1 )

findstr /C:"DatabaseConfigUI" "%TMP_DIR%\openedx.wxs" >nul
if errorlevel 1 ( echo [ERROR] Missing DatabaseConfigUI in openedx.wxs >&2 & exit /b 1 )

findstr /C:"USER_DB_STRATEGY" "%TMP_DIR%\wordpress.wxs" >nul
if errorlevel 1 ( echo [ERROR] Missing USER_DB_STRATEGY in wordpress.wxs >&2 & exit /b 1 )

echo [TEST 5] Synthesizing WiX manifest for Suite Orchestrator Topology...
(
echo {
echo   "name": "enterprise-suite",
echo   "title": "Enterprise Suite Orchestrator",
echo   "version": "2.0.0",
echo   "topology": "suite_orchestrator"
echo }
) > "%TMP_DIR%\mock_orchestrator.json"

call "%LIBSCRIPT_ROOT_DIR%\packaging\template_msi.cmd" "%TMP_DIR%\mock_orchestrator.json" --out "%TMP_DIR%\orchestrator.wxs"

findstr /C:"Enterprise Suite Orchestrator" "%TMP_DIR%\orchestrator.wxs" >nul
if errorlevel 1 ( echo [ERROR] Missing Title in orchestrator.wxs >&2 & exit /b 1 )

findstr /C:"PROP_TOPOLOGY\" Value=\"suite_orchestrator\"" "%TMP_DIR%\orchestrator.wxs" >nul
if errorlevel 1 ( echo [ERROR] Missing Topology in orchestrator.wxs >&2 & exit /b 1 )

findstr /C:"EmbeddedChainer" "%TMP_DIR%\orchestrator.wxs" >nul
if errorlevel 1 ( echo [ERROR] Missing EmbeddedChainer in orchestrator.wxs >&2 & exit /b 1 )

rd /s /q "%TMP_DIR%"
echo [SUCCESS] Declarative MSI synthesis verification succeeded on Windows!
exit /b 0
