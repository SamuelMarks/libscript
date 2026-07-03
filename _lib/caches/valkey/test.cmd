@echo off
:: # test.cmd
::
:: ## Overview
:: Serves as the Windows test entry point for the Valkey Cache component.
:: It automatically delegates execution to the common `test_base.cmd`.
:: 
:: ## Usage
:: Call this script to trigger Valkey component testing on Windows.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "valkey" "."
