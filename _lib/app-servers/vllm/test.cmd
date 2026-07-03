:: # test.cmd
::
:: ## Overview
:: Serves as the Windows test entry point for the vLLM Server component.
:: It automatically delegates execution to the common `test_base.cmd`.
:: 
:: ## Usage
:: Call this script to trigger vLLM component testing on Windows.

call "%~dp0\..\..\..\_lib\_common\test_base.cmd"
