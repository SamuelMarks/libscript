@echo off
:: # test.cmd
::
:: ## Overview
:: Serves as the Windows test entry point for the AWS Cloud Provider component CLI wrapper.
:: It runs the CLI wrapper in `DRY_RUN=true` mode to assert that the `aws` underlying
:: commands are constructed correctly for `network`, `firewall`, `storage`, and `cleanup`.
:: 
:: ## Usage
:: Call this script to trigger AWS CLI wrapper testing on Windows.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\test_base.cmd"

@echo off
call "%~dp0\..\..\_common\test_base.cmd"

@echo off
call "%~dp0\..\..\_common\test_base.cmd"


set "DRY_RUN=true"

echo Testing AWS component in DRY_RUN mode...

rem Test network
echo Captured VPC_ID: '!VPC_ID!'
if "!VPC_ID!" neq "vpc-12345678" ( echo VPC_ID mismatch & exit /b 1 )

rem Test firewall
echo Running firewall create...
findstr /i "aws ec2 create-security-group" "%temp%\aws_test_out.txt" >nul
if errorlevel 1 ( echo FAIL: firewall create & exit /b 1 )

rem Test storage
echo Running storage create...
findstr /i "aws s3 mb" "%temp%\aws_test_out.txt" >nul
if errorlevel 1 ( echo FAIL: storage create & exit /b 1 )

rem Test cleanup
echo Running cleanup...
findstr /i "aws resourcegroupstaggingapi" "%temp%\aws_test_out.txt" >nul
if errorlevel 1 ( echo FAIL: cleanup & exit /b 1 )

rem Test tag guards
echo Testing tag guards...
call "%~dp0cli.cmd" network delete test-vpc > "%temp%\aws_guard_out.txt" 2>&1
if not errorlevel 1 (
    echo FAIL: Network delete should have failed due to missing tag
    exit /b 1
)
findstr /i "Refusing to modify" "%temp%\aws_guard_out.txt" >nul
if errorlevel 1 ( echo FAIL: Guard output missing & exit /b 1 )

set "LIBSCRIPT_ALLOW_ANY_TAG_MANIPULATION=1"
call "%~dp0cli.cmd" network delete test-vpc > "%temp%\aws_guard_out.txt" 2>&1
findstr /i "Proceeding due to override flag" "%temp%\aws_guard_out.txt" >nul
if errorlevel 1 ( echo FAIL: Guard override missing & exit /b 1 )

echo AWS tests passed (dry-run).
if exist "%temp%\aws_test_out.txt" del "%temp%\aws_test_out.txt"
exit /b 0


