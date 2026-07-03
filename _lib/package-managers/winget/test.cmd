@echo off
:: # test.cmd
::
:: ## Overview
:: Testing script for the winget component on Windows.
:: It verifies that the component is installed correctly and responds as expected.
::
:: ## Usage
:: Execute this script to run tests for the component.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\test_base.cmd" :assert_version "winget" "."
