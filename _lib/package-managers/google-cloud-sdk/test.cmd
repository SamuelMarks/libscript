@echo off
:: # test.cmd
::
:: ## Overview
:: Testing script for the google-cloud-sdk component on Windows.
:: It verifies that the component is installed correctly and responds as expected.
::
:: ## Usage
:: Execute this script to run tests for the component.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_lib\_common\test_base.cmd"
