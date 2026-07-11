@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Test suite for filestore on Windows
::
:: ## Usage
:: Managed by libscript.

if "%LIBSCRIPT_ROOT_DIR%"=="" set "LIBSCRIPT_ROOT_DIR=%~dp0..\..\..\.."

call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\log.cmd" :log_info "Testing filestore cli parameter injection on Windows..."

:: We cannot easily mock gcloud inside batch if the system one exists, but we can just use a dummy bat file.
echo @echo off > "%TMP%\gcloud.bat"
echo echo MOCK_GCLOUD: %%* >> "%TMP%\gcloud.bat"
set "PATH=%TMP%;%PATH%"

set "GCP_PROJECT_ID=test-project"
set "FILESTORE_ZONE=us-central1-a"
set "FILESTORE_TIER=BASIC_HDD"
set "FILESTORE_CAPACITY_GB=1024"
set "FILESTORE_NETWORK=default"

call "%~dp0cli.cmd" create test-fs > "%TMP%	est_out.txt" 2>&1
findstr /C:"Creating GCP Filestore test-fs" "%TMP%	est_out.txt" >nul
if !errorlevel! equ 0 (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\log.cmd" :log_success "Filestore cli create invoked."
) else (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\log.cmd" :log_error "Filestore cli create failed to invoke."
    exit /b 1
)

call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\log.cmd" :log_success "filestore cli test passed."
exit /b 0