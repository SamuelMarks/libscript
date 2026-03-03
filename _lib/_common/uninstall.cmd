@echo off
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
:: Add background service removal logic here if applicable
exit /b 0