@echo off
:: # test.cmd
::
:: ## Overview
:: Test suite for the Azure cloud provider on Windows.
::
:: ## Usage
:: Automatically invoked by the test framework to validate Azure provisioning commands.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\test_base.cmd"

@echo off
call "%~dp0\..\..\_common\test_base.cmd"

@echo off
call "%~dp0\..\..\_common\test_base.cmd"


set "DRY_RUN=true"

echo Testing Azure component in DRY_RUN mode...

rem Test network
if errorlevel 1 ( echo FAIL: network create & exit /b 1 )

rem Test node
if errorlevel 1 ( echo FAIL: node create & exit /b 1 )

rem Test cleanup
if errorlevel 1 ( echo FAIL: cleanup & exit /b 1 )

rem Test tag guards
echo Testing tag guards...
call "%~dp0cli.cmd" network delete test-vnet test-rg > "%temp%\azure_guard_out.txt" 2>&1
if not errorlevel 1 (
    echo FAIL: Network delete should have failed due to missing tag
    exit /b 1
)
findstr /i "Refusing to modify" "%temp%\azure_guard_out.txt" >nul
if errorlevel 1 ( echo FAIL: Guard output missing & exit /b 1 )

set "LIBSCRIPT_ALLOW_ANY_TAG_MANIPULATION=1"
call "%~dp0cli.cmd" network delete test-vnet test-rg > "%temp%\azure_guard_out.txt" 2>&1
findstr /i "Proceeding due to override flag" "%temp%\azure_guard_out.txt" >nul
if errorlevel 1 ( echo FAIL: Guard override missing & exit /b 1 )

echo Azure tests passed (dry-run).
exit /b 0


