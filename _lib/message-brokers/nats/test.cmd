@echo off
:: # test.cmd
::
:: ## Overview
:: Test suite for NATS on Windows.
::
:: ## Usage
:: Automatically invoked by the test framework to assert nats-server is accessible.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "nats-server" "."
