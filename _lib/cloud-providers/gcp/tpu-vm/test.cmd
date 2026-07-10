@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Test suite for tpu-vm on Windows
::
:: ## Usage
:: Managed by libscript.

if "%LIBSCRIPT_ROOT_DIR%"=="" set "LIBSCRIPT_ROOT_DIR=%~dp0..\..\.."

call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\log.cmd" :log_info "Testing tpu-vm cli parameter injection on Windows..."

:: We cannot easily mock gcloud inside batch if the system one exists, but we can just use a dummy bat file.
echo @echo off > "%TMP%\gcloud.bat"
echo echo MOCK_GCLOUD: %%* >> "%TMP%\gcloud.bat"
set "PATH=%TMP%;%PATH%"

set "TPU_SCHEDULING_TYPE=preemptible"
set "TPU_ZONE=us-central2-b"
set "TPU_ACCELERATOR_TYPE=v2-8"
set "TPU_VERSION=tpu-ubuntu2204-base"
set "GCP_PROJECT_ID=test-project"
set "TPU_USE_QUEUED_RESOURCE="

call "%~dp0cli.cmd" create test-instance > "%TMP%\test_out.txt" 2>&1
findstr /C:"--preemptible" "%TMP%\test_out.txt" >nul
if !errorlevel! equ 0 (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\log.cmd" :log_success "TPU_SCHEDULING_TYPE=preemptible correctly injected --preemptible flag."
) else (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\log.cmd" :log_error "TPU_SCHEDULING_TYPE=preemptible failed to inject flag."
    exit /b 1
)

set "TPU_USE_QUEUED_RESOURCE=true"
call "%~dp0cli.cmd" create test-instance > "%TMP%\test_out2.txt" 2>&1
findstr /C:"queued-resources create test-instance-qr" "%TMP%\test_out2.txt" >nul
if !errorlevel! equ 0 (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\log.cmd" :log_success "TPU_USE_QUEUED_RESOURCE=true correctly invoked queued-resources API."
) else (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\log.cmd" :log_error "TPU_USE_QUEUED_RESOURCE=true failed."
    exit /b 1
)

call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\log.cmd" :log_success "tpu-vm cli test passed."
exit /b 0
