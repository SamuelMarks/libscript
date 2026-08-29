@echo off
:: # uninstall_generic.cmd
::
:: ## Overview
:: Provides fallback uninstallation logic for the Python Server component on Windows.
:: It explicitly declares that generic uninstallation is skipped or not natively implemented.
:: 
:: ## Usage
:: Called internally as a fallback during the uninstall process.

:: Generic uninstall for Windows skipped
set "THIS_FILE=%~f0"
