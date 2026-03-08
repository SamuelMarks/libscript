@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

if not "%HTTPD_SERVICE_NAME%"=="" (
    sc stop %HTTPD_SERVICE_NAME% >nul 2>&1
    sc delete %HTTPD_SERVICE_NAME% >nul 2>&1
) else (
    sc stop libscript_httpd >nul 2>&1
    sc delete libscript_httpd >nul 2>&1
)

:: Try to uninstall via winget / choco if it was installed that way
where winget >nul 2>&1
if %ERRORLEVEL% equ 0 winget uninstall --id=Apache.HTTPD --silent >nul 2>&1

where choco >nul 2>&1
if %ERRORLEVEL% equ 0 choco uninstall apache-httpd -y >nul 2>&1

:: Default uninstall hook for Windows
if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for %PACKAGE_NAME% at %INSTALLED_DIR%.
    )
) else (
    echo INSTALLED_DIR is not set. Cannot perform default uninstallation.
)
exit /b 0
