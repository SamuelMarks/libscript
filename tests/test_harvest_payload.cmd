@echo off
:: # test_harvest_payload.cmd
::
:: ## Overview
:: Validates LibScript repository harvesting and WiX fragment generation on Windows.
:: Verifies that required core engine and stack components are harvested,
:: excluded artifacts (.git, tests_tmp, temporary files) are filtered,
:: and valid WiX fragment XML is synthesized.
::
:: ## Usage
:: call tests\test_harvest_payload.cmd

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

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:: ## find_root
for %%I in ("%SCRIPT_DIR%") do set "LIBSCRIPT_ROOT_DIR=%%~fI"
:find_root_loop
if exist "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" goto found_root
for %%I in ("%LIBSCRIPT_ROOT_DIR%\..") do set "PARENT_DIR=%%~fI"
if "%PARENT_DIR%"=="%LIBSCRIPT_ROOT_DIR%" goto found_root
set "LIBSCRIPT_ROOT_DIR=%PARENT_DIR%"
goto find_root_loop
:found_root

set "TEST_TMP_DIR=%LIBSCRIPT_ROOT_DIR%\tests_tmp\test_harvest_payload_%RANDOM%"
if not exist "%TEST_TMP_DIR%" mkdir "%TEST_TMP_DIR%" 2>nul

echo === Testing LibScript Repository Harvester (Windows) ===

set "MANIFEST_FILE=%TEST_TMP_DIR%\manifest.txt"
set "WIX_FILE=%TEST_TMP_DIR%\fragment.wxs"

call "%LIBSCRIPT_ROOT_DIR%\packaging\harvest_payload.cmd" --manifest-file "%MANIFEST_FILE%" --wix-fragment "%WIX_FILE%"
if errorlevel 1 (
    echo [FAIL] harvest_payload.cmd failed with exit code %ERRORLEVEL% >&2
    exit /b 1
)

:: Test 1: Manifest exists and is not empty
if not exist "%MANIFEST_FILE%" (
    echo [FAIL] Manifest file was not created >&2
    exit /b 1
)
for %%F in ("%MANIFEST_FILE%") do (
    if %%~zF LEQ 0 (
        echo [FAIL] Manifest file is empty >&2
        exit /b 1
    )
)
echo [PASS] Manifest generated successfully

:: Test 2: Essential engine files are included
powershell -NoProfile -Command "$m = Get-Content '%MANIFEST_FILE%'; $reqs = @('libscript.sh', 'libscript.cmd', '_lib/_common/component_core.cmd', 'stacks/cms/openedx/setup_generic.cmd', 'stacks/cms/openedx/cli.cmd'); foreach ($r in $reqs) { if ($m -notcontains $r) { Write-Error ('Missing required file: ' + $r); exit 1 } }"
if errorlevel 1 (
    echo [FAIL] Required engine or stack files missing from manifest >&2
    exit /b 1
)
echo [PASS] All essential engine and stack files present in manifest

:: Test 3: Excluded directories and patterns are strictly absent
powershell -NoProfile -Command "$m = Get-Content '%MANIFEST_FILE%'; $bads = @('.git/', 'tests_tmp/', '.vagrant/', '.tmp', '.log', '.ppm', '.msi', '.wixobj'); foreach ($b in $bads) { if ($m | Where-Object { $_ -like ('*' + $b + '*') }) { Write-Error ('Prohibited pattern present: ' + $b); exit 1 } }"
if errorlevel 1 (
    echo [FAIL] Prohibited pattern found in manifest >&2
    exit /b 1
)
echo [PASS] Prohibited patterns and directories correctly excluded

:: Test 4: WiX fragment exists and has valid structure
if not exist "%WIX_FILE%" (
    echo [FAIL] WiX fragment file was not created >&2
    exit /b 1
)

powershell -NoProfile -Command "$w = Get-Content '%WIX_FILE%' -Raw; if ($w -notmatch '<ComponentGroup Id=.LibscriptHarvestedComponents.>') { Write-Error 'ComponentGroup missing'; exit 1 }; if ($w -notmatch 'KeyPath=.yes.') { Write-Error 'KeyPath attribute missing'; exit 1 }"
if errorlevel 1 (
    echo [FAIL] WiX fragment structure validation failed >&2
    exit /b 1
)
echo [PASS] WiX fragment validated successfully

rmdir /s /q "%TEST_TMP_DIR%" 2>nul
echo === All Harvest Payload Windows Tests Passed ===
exit /b 0
