@echo off
:: # install_bento_builder.cmd
:: Standalone Windows batch script to provision the Bento Builder environment.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

echo ====================================================
echo  Bento Builder Environment Installer (Windows cmd)
echo ====================================================

call "%~dp0stacks\virtualization\bento-builder\setup.cmd" install
echo Installation complete! Running validation tests...
call "%~dp0stacks\virtualization\bento-builder\test.cmd"
