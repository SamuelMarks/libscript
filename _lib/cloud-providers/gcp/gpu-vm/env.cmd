@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for gpu-vm on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for gpu-vm.

:: Windows env stub for gpu-vm
set "THIS_FILE=%~f0"
if "%GCP_GPU_VM_ENABLED%"=="" set "GCP_GPU_VM_ENABLED=1"
if "%GPU_VM_VERSION%"=="" set "GPU_VM_VERSION=latest"
set "PATH=%LIBSCRIPT_HOME%\gpu-vm\%GPU_VM_VERSION%\bin;%PATH%"
