@echo off
:: # test.cmd
::
:: ## Overview
:: Implements automated tests to verify the correctness of the Joomla CMS stack.
:: 
:: ## Usage
:: Execute this script to run the test suite for joomla.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\..\_lib\_common\test_base.cmd"
