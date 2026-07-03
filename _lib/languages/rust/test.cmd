@echo off
:: # test.cmd
::
:: ## Overview
:: Test suite for Rust on Windows.
::
:: ## Usage
:: Automatically invoked by the test framework to assert Rust is accessible.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "rustc" "."
