@echo off
:: # test.cmd
::
:: ## Overview
:: Implements automated tests to verify the correctness of the Actix+Diesel authentication scaffold stack.
:: 
:: ## Usage
:: Execute this script to run the test suite for serve-actix-diesel-auth-scaffold.

setlocal EnableDelayedExpansion
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0test.ps1"
