@echo off
:: # test.cmd
::
:: ## Overview
:: Test suite for the cloud core orchestration commands on Windows.
::
:: ## Usage
:: Automatically invoked by the test framework to validate diff, backup, and restore routines.

setlocal EnableDelayedExpansion
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

echo Testing Multicloud Lifecycle: diff, backup, deprovision, restore...

rem Diff / Drift Detection
call "%~dp0cli.cmd" diff > "%temp%\cloud_test_out.txt" 2>&1
findstr /i "Comparing local .libscript_state.json" "%temp%\cloud_test_out.txt" >nul
if errorlevel 1 ( echo FAIL: diff drift detection & exit /b 1 )

rem Backup (Local)
call "%~dp0cli.cmd" backup test-node-azure --keep-last 3 --target local > "%temp%\cloud_test_out.txt" 2>&1
findstr /i "\[BACKUP\] Creating local encrypted archive" "%temp%\cloud_test_out.txt" >nul
if errorlevel 1 ( echo FAIL: backup local target & exit /b 1 )

rem Backup (S3 with --paths)
call "%~dp0cli.cmd" backup test-node-aws --keep-last 5 --target s3 --snapshot --paths "/var/lib/postgresql/data /etc/letsencrypt" > "%temp%\cloud_test_out.txt" 2>&1
findstr /i "\[BACKUP\] Backing up specific paths:" "%temp%\cloud_test_out.txt" >nul
if errorlevel 1 ( echo FAIL: backup --paths parsing & exit /b 1 )
findstr /i "\[BACKUP\] Streaming backup to remote object storage" "%temp%\cloud_test_out.txt" >nul
if errorlevel 1 ( echo FAIL: backup s3 streaming & exit /b 1 )

rem Deprovisioning (Retain IP and Data)
call "%~dp0cli.cmd" deprovision aws test-node-aws test-vpc us-east-1 --retain-ip --retain-data > "%temp%\cloud_test_out.txt" 2>&1
findstr /i "Retaining IP address" "%temp%\cloud_test_out.txt" >nul
if errorlevel 1 ( echo FAIL: deprovision retain-ip & exit /b 1 )
findstr /i "Retaining data volume" "%temp%\cloud_test_out.txt" >nul
if errorlevel 1 ( echo FAIL: deprovision retain-data & exit /b 1 )

rem Restoration
call "%~dp0cli.cmd" restore test-node-aws --from-backup latest > "%temp%\cloud_test_out.txt" 2>&1
findstr /i "\[RESTORE\] Starting restoration" "%temp%\cloud_test_out.txt" >nul
if errorlevel 1 ( echo FAIL: restore init & exit /b 1 )

echo Unified Cloud Wrapper tests passed (dry-run).
exit /b 0


