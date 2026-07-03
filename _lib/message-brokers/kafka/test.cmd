@echo off
:: # test.cmd
::
:: ## Overview
:: Test suite for Kafka on Windows.
::
:: ## Usage
:: Automatically invoked by the test framework to assert kafka is accessible.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "kafka-server-start.sh" "."
