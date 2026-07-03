@echo off
:: # test.cmd
::
:: ## Overview
:: Test suite for RabbitMQ on Windows.
::
:: ## Usage
:: Automatically invoked by the test framework to assert rabbitmq is accessible.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "rabbitmqctl" "."
