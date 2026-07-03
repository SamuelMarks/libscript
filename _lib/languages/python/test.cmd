@echo off
:: # test.cmd
::
:: ## Overview
:: Test suite for Python on Windows.
::
:: ## Usage
:: Automatically invoked by the test framework to assert Python is accessible.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "python" "."
