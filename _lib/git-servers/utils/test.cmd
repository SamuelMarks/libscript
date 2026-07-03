@echo off
:: # test.cmd
::
:: ## Overview
:: Test suite for Git server utils on Windows.
::
:: ## Usage
:: Automatically invoked by the test framework. Asserts git is accessible.

setlocal EnableDelayedExpansion
call "%~dp0\..\_common\test_base.cmd" :assert_version "git" "."
