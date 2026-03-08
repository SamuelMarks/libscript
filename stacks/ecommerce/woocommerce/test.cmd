@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

set "WWWROOT_CHK=%WWWROOT%"
if "%WWWROOT_CHK%"=="" set "WWWROOT_CHK=C:\inetpub\wwwroot\wordpress"

echo [TEST] Validating WooCommerce on Windows...
if exist "%WWWROOT_CHK%\wp-content\plugins\woocommerce" (
    echo [PASS] WooCommerce directory found at %WWWROOT_CHK%\wp-content\plugins\woocommerce
    exit /b 0
) else (
    echo [FAIL] WooCommerce directory not found at %WWWROOT_CHK%\wp-content\plugins\woocommerce
    exit /b 1
)
