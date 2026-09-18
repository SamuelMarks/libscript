@echo off
:: # test.cmd
::
:: ## Overview
:: End-to-end integration test runner for Open edX on Windows.
:: Verifies that the LMS and CMS serve registration and login screens,
:: authenticate sessions, and navigate past the login gate without error.
::
:: ## Usage
:: test.cmd [options]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0test_harness.cmd" %*
exit /b %ERRORLEVEL%
