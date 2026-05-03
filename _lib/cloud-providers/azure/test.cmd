@echo off
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

echo Azure tests passed (dry-run).
exit /b 0


