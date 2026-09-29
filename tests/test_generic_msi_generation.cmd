@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
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
::   call tests	est_generic_msi_generation.cmd

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

for %%I in ("%SCRIPT_DIR%") do set "LIBSCRIPT_ROOT_DIR=%%~fI"

:find_root_loop
if exist "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" goto found_root
for %%I in ("%LIBSCRIPT_ROOT_DIR%\..") do set "PARENT_DIR=%%~fI"
if "%PARENT_DIR%"=="%LIBSCRIPT_ROOT_DIR%" goto found_root
set "LIBSCRIPT_ROOT_DIR=%PARENT_DIR%"
goto find_root_loop

:found_root

set "TMP_DIR=%TEMP%\msi_test_%RANDOM%"
if not exist "%TMP_DIR%" mkdir "%TMP_DIR%"

echo ==> Testing Declarative WiX Generation on Windows...
call "%LIBSCRIPT_ROOT_DIR%\packaging\template_msi.cmd" "%LIBSCRIPT_ROOT_DIR%\stacks\cms\openedx" --out "%TMP_DIR%\openedx.wxs"
call "%LIBSCRIPT_ROOT_DIR%\packaging\template_msi.cmd" "%LIBSCRIPT_ROOT_DIR%\stacks\cms\wordpress" --out "%TMP_DIR%\wordpress.wxs"
call "%LIBSCRIPT_ROOT_DIR%\packaging\template_msi.cmd" "%LIBSCRIPT_ROOT_DIR%\stacks\cms\drupal" --out "%TMP_DIR%\drupal.wxs"

if not exist "%TMP_DIR%\openedx.wxs" (
    echo [ERROR] openedx.wxs was not generated >&2
    exit /b 1
)

rd /s /q "%TMP_DIR%"
echo [SUCCESS] Declarative MSI synthesis verification succeeded on Windows!
exit /b 0
