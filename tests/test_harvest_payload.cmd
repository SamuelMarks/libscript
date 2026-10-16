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
:: Ascends the directory tree looking for ROOT or libscript.cmd.
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
powershell -NoProfile -Command "$m = Get-Content '%MANIFEST_FILE%'; $reqs = @('libscript.sh', 'libscript.cmd', '_lib/_common/component_core.cmd', '_lib/web-apps/openedx/setup_generic.cmd', '_lib/web-apps/openedx/cli.cmd'); foreach ($r in $reqs) { if ($m -notcontains $r) { Write-Error ('Missing required file: ' + $r); exit 1 } }"
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

:: Test 5: Verify legal WiX identifier generation, length capping (<= 72 chars), and character sanitization
set "MOCK_STAGE_DIR=%TEST_TMP_DIR%\mock_stage"
if not exist "%MOCK_STAGE_DIR%\node_modules\npm\node_modules\@isaacs\cliui\build\lib" mkdir "%MOCK_STAGE_DIR%\node_modules\npm\node_modules\@isaacs\cliui\build\lib" 2>nul
type nul > "%MOCK_STAGE_DIR%\node_modules\npm\node_modules\@isaacs\cliui\build\lib\index.js"
if not exist "%MOCK_STAGE_DIR%\node_modules\npm\node_modules\@isaacs\cliui\node_modules\emoji-regex\es2015" mkdir "%MOCK_STAGE_DIR%\node_modules\npm\node_modules\@isaacs\cliui\node_modules\emoji-regex\es2015" 2>nul
type nul > "%MOCK_STAGE_DIR%\node_modules\npm\node_modules\@isaacs\cliui\node_modules\emoji-regex\es2015\index.js"
if not exist "%MOCK_STAGE_DIR%\node_modules\npm\node_modules\validate-npm-package-license\node_modules\spdx-expression-parse" mkdir "%MOCK_STAGE_DIR%\node_modules\npm\node_modules\validate-npm-package-license\node_modules\spdx-expression-parse" 2>nul
type nul > "%MOCK_STAGE_DIR%\node_modules\npm\node_modules\validate-npm-package-license\node_modules\spdx-expression-parse\package.json"

set "STAGE_WIX=%TEST_TMP_DIR%\stage_fragment.wxs"
call "%LIBSCRIPT_ROOT_DIR%\packaging\harvest_payload.cmd" --source-dir "%MOCK_STAGE_DIR%" --wix-fragment "%STAGE_WIX%" --component-group "PayloadComponents" --directory-id "INSTALLFOLDER"
if errorlevel 1 (
    echo [FAIL] harvest_payload.cmd failed on mock stage >&2
    exit /b 1
)

powershell -NoProfile -Command "$w = Get-Content '%STAGE_WIX%' -Raw; $matches = [regex]::Matches($w, '(?<!Disk)Id=.([^""]+).'); foreach ($m in $matches) { $id = $m.Groups[1].Value; if ($id.Length -gt 72) { Write-Error ('Identifier exceeds 72 characters: ' + $id); exit 1 }; if ($id -notmatch '^[A-Za-z_][A-Za-z0-9_.]*$') { Write-Error ('Illegal identifier syntax: ' + $id); exit 1 } }"
if errorlevel 1 (
    echo [FAIL] WiX identifier validation failed on stage fragment >&2
    exit /b 1
)
echo [PASS] WiX identifiers are legal, sanitized, and within the 72-character limit

rmdir /s /q "%TEST_TMP_DIR%" 2>nul
echo === All Harvest Payload Windows Tests Passed ===
exit /b 0
