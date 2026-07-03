:: # test.cmd
::
:: ## Overview
:: Serves as the Windows test entry point for the Jetstream component.
:: It automatically delegates execution to the common `test_base.cmd`
:: to run standardized testing assertions.
:: 
:: ## Usage
:: Call this script to trigger Jetstream component testing on Windows.

call "%~dp0\..\..\..\_lib\_common\test_base.cmd"
