@echo off
:: # test.cmd
::
:: ## Overview
:: Serves as the Windows test entry point for the Node.js Server component.
:: It automatically delegates execution to the common `test_base.cmd`
:: to run standardized testing assertions for `node`.
:: 
:: ## Usage
:: Call this script to trigger Node.js Server component testing on Windows.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "node" "."
