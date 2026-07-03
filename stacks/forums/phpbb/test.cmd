@echo off
:: # test.cmd
::
:: ## Overview
:: Implements automated tests to verify the correctness of the phpBB forum software stack.
:: 
:: ## Usage
:: Execute this script to run the test suite for phpbb.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\..\_lib\_common\test_base.cmd"
