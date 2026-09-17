@echo off
:: # test.cmd
::
:: ## Overview
:: End-to-end integration test runner for Open edX on Windows.
:: Verifies that the LMS and CMS serve registration and login screens,
:: authenticate sessions, and navigate past the login gate without error.

::
:: ## Usage
:: Execute this script to perform testing on Windows.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0env.cmd"

echo ==^> Executing Open edX End-to-End Registration and Login Verification on Windows...

where python >nul 2>&1
if not errorlevel 1 (
    python "%~dp0test_harness.py"
    exit /b %ERRORLEVEL%
)

where py >nul 2>&1
if not errorlevel 1 (
    py "%~dp0test_harness.py"
    exit /b %ERRORLEVEL%
)

echo [ERROR] Python runtime is required to run the Open edX end-to-end test.
exit /b 1
