@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Handles the removal and uninstallation process for the Celery task queue stack.
:: 
:: ## Usage
:: Execute this script to remove celery and its associated configurations from the system.

setlocal EnableDelayedExpansion
:: Default uninstall hook for Windows
set "THIS_FILE=%~f0"
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
