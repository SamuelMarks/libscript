@echo off
:: # test.cmd
::
:: ## Overview
:: Test suite for Fluent Bit on Windows.
::
:: ## Usage
:: Automatically invoked by the test framework to assert Fluent Bit is accessible.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "fluent-bit" "."
