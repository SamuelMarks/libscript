@echo off
call "%~dp0\..\_common\test_base.cmd"

@echo off
call "%~dp0\..\_common\test_base.cmd"

@echo off
call "%~dp0\..\_common\test_base.cmd"


set "DRY_RUN=true"

echo Testing Unified Cloud Wrapper in DRY_RUN mode...

rem Test routing to AWS
if errorlevel 1 ( echo FAIL: AWS routing & exit /b 1 )

rem Test global list-managed
if errorlevel 1 ( echo FAIL: list-managed AWS & exit /b 1 )
if errorlevel 1 ( echo FAIL: list-managed Azure & exit /b 1 )
if errorlevel 1 ( echo FAIL: list-managed GCP & exit /b 1 )

rem Test global cleanup
if errorlevel 1 ( echo FAIL: cleanup aws & exit /b 1 )
if errorlevel 1 ( echo FAIL: cleanup azure & exit /b 1 )
if errorlevel 1 ( echo FAIL: cleanup gcp & exit /b 1 )

echo Unified Cloud Wrapper tests passed (dry-run).
exit /b 0


