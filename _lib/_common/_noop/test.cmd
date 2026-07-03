@echo off
:: # test.cmd
::
:: ## Overview
:: Provides validation and testing logic for the `_noop` component on Windows.
:: It relies on `test_base.cmd` to perform a mock version assertion.
:: 
:: ## Usage
:: Call this script to run the tests for the `_noop` component.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "_noop" "."
