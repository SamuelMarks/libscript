@echo off
:: # test.cmd
::
:: ## Overview
:: Implements automated tests to verify the correctness of the OpenVPN networking stack stack.
:: 
:: ## Usage
:: Execute this script to run the test suite for openvpn.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\..\_lib\_common\test_base.cmd" :assert_version openvpn "."
