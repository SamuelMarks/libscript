@echo off
:: ## Overview
:: Cleanup script for vagrant locks.
::
:: ## Usage
:: Used to manually cleanup lock files.

del /Q /F "C:\Users\samuel\.vagrant.d\data\lock.machine-action-66723662e04522e6970af4d0c63b6e87.lock"
exit /b 0
