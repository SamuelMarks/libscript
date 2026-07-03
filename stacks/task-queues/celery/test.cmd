@echo off
:: # test.cmd
::
:: ## Overview
:: Implements automated tests to verify the correctness of the Celery task queue stack.
:: 
:: ## Usage
:: Execute this script to run the test suite for celery.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\..\_lib\_common\test_base.cmd" :assert_version celery "."
