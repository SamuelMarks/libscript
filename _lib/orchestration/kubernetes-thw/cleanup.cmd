@echo off
:: ## Overview
:: Cleanup script for vagrant locks.
::
:: ## Usage
:: Used to manually cleanup lock files.
set "THIS_FILE=%~f0"

del /Q /F "%USERPROFILE%\.vagrant.d\data\lock.machine-action-*.lock" 2>nul
exit /b 0
