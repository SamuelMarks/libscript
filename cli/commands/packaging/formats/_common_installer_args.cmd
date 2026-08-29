@echo off
:: # _common_installer_args.cmd
::
:: ## Overview
:: Shared arguments and utility functions for package installers.
:: 
:: ## Usage
:: This script is called by the packaging system and should not be executed manually.
set "THIS_FILE=%~f0"

echo This script (%~nx0) is not implemented natively for Windows.
exit /b 1
