@echo off
:: # test.cmd
::
:: ## Overview
:: Serves as the Windows test entry point for the Rust Server component.
:: It automatically delegates execution to the common `test_base.cmd`
:: to run standardized testing assertions for `cargo`.
:: 
:: ## Usage
:: Call this script to trigger Rust Server component testing on Windows.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "cargo" "."
