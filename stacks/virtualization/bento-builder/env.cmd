@echo off
:: # env.cmd
::
:: ## Overview
:: Windows environment configuration for Bento Builder stack.
::
:: ## Usage
:: Call this script to configure the Bento Builder environment on Windows.

set "THIS_FILE=%~f0"

call "%~dp0\..\..\..\_lib\orchestration\qemu\env.cmd"
call "%~dp0\..\..\..\_lib\orchestration\virtualbox\env.cmd"
call "%~dp0\..\..\..\_lib\orchestration\packer\env.cmd"
call "%~dp0\..\..\..\_lib\orchestration\vagrant\env.cmd"
