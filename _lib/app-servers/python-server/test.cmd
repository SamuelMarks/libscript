@echo off
:: # test.cmd
::
:: ## Overview
:: Serves as the Windows test entry point for the Python Server component.
:: It automatically delegates execution to the common `test_base.cmd`
:: to run standardized testing assertions for `python`.
:: 
:: ## Usage
:: Call this script to trigger Python Server component testing on Windows.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "python" "."
