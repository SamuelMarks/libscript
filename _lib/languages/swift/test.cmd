@echo off
:: # test.cmd
::
:: ## Overview
:: Test suite for Swift on Windows.
::
:: ## Usage
:: Automatically invoked by the test framework to assert Swift is accessible.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "swift" "."
