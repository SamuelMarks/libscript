@echo off
:: # test.cmd
::
:: ## Overview
:: Test suite for Ruby on Windows.
::
:: ## Usage
:: Automatically invoked by the test framework to assert Ruby is accessible.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "ruby" "."
