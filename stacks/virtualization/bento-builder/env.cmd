@echo off
:: # env.cmd
:: Windows environment configuration for Bento Builder stack.
set "THIS_FILE=%~f0"

call "%~dp0\..\..\..\_lib\orchestration\qemu\env.cmd"
call "%~dp0\..\..\..\_lib\orchestration\virtualbox\env.cmd"
call "%~dp0\..\..\..\_lib\orchestration\packer\env.cmd"
call "%~dp0\..\..\..\_lib\orchestration\vagrant\env.cmd"
