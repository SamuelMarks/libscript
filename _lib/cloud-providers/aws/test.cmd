@echo off
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

echo AWS tests passed (dry-run).
if exist "%temp%\aws_test_out.txt" del "%temp%\aws_test_out.txt"
exit /b 0


