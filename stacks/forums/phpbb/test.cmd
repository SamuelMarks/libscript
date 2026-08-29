@echo off
:: # test.cmd
::
:: ## Overview
:: Implements automated tests to verify the correctness of the phpBB forum software stack.
:: 
:: ## Usage
:: Execute this script to run the test suite for phpbb.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0test.ps1"
