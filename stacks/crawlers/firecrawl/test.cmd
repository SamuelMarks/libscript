@echo off
:: # test.cmd
::
:: ## Overview
:: Implements automated tests to verify the correctness of the Firecrawl crawler stack.
:: 
:: ## Usage
:: Execute this script to run the test suite for firecrawl.

setlocal EnableDelayedExpansion
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0test.ps1"
