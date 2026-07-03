@echo off
:: # test.cmd
::
:: ## Overview
:: Test suite for etcd on Windows.
::
:: ## Usage
:: Automatically invoked by the test framework to assert etcd is accessible.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "etcd" "."
