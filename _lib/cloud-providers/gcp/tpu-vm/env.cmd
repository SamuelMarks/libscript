@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for tpu-vm on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for tpu-vm.

:: Windows env stub for tpu-vm
set "THIS_FILE=%~f0"
if "%GCP_TPU_VM_ENABLED%"=="" set "GCP_TPU_VM_ENABLED=1"
if "%TPU_VM_VERSION%"=="" set "TPU_VM_VERSION=latest"
set "PATH=%LIBSCRIPT_HOME%\tpu-vm\%TPU_VM_VERSION%\bin;%PATH%"
