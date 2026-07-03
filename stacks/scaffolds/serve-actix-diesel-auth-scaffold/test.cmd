@echo off
:: # test.cmd
::
:: ## Overview
:: Implements automated tests to verify the correctness of the Actix+Diesel authentication scaffold stack.
:: 
:: ## Usage
:: Execute this script to run the test suite for serve-actix-diesel-auth-scaffold.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\..\_lib\_common\test_base.cmd"
