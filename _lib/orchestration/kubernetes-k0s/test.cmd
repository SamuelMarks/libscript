@echo off
:: # test.cmd
::
:: ## Overview
:: Test suite for k0s on Windows.
::
:: ## Usage
:: Automatically invoked by the test framework to assert k0s is accessible.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "kubernetes-k0s" "."
