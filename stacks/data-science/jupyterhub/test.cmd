@echo off
:: # test.cmd
::
:: ## Overview
:: Implements automated tests to verify the correctness of the JupyterHub data science platform stack.
:: 
:: ## Usage
:: Execute this script to run the test suite for jupyterhub.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\..\_lib\_common\test_base.cmd" :assert_version jupyterhub "."
