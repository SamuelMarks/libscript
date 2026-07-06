@echo off
:: # test_merge.cmd
::
:: ## Overview
:: Testing script for the nginx component on Windows.
:: It verifies that the component is installed correctly and responds as expected.
::
:: ## Usage
:: Execute this script to run tests for the component.

setlocal EnableDelayedExpansion

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0test_merge.ps1"
exit /b %ERRORLEVEL%
