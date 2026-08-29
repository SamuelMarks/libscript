@echo off
:: # test.cmd
::
:: ## Overview
:: Implements automated tests to verify the correctness of the Joomla CMS stack.
:: 
:: ## Usage
:: Execute this script to run the test suite for joomla.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0test.ps1"
