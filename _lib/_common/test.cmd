@echo off
:: # test.cmd
::
:: ## Overview
:: Serves as the primary Windows test entry point for components.
:: It automatically delegates execution to the common `test_base.cmd`
:: to run standardized testing assertions.
:: 
:: ## Usage
:: Call this script to trigger component testing on Windows.

setlocal EnableDelayedExpansion
call "%~dp0\test_base.cmd"
