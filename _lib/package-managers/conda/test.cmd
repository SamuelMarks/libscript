@echo off
rem ## Overview
rem Test suite for the conda component.
rem
rem ## Usage
rem Execute this script to perform a component-specific test.

setlocal enabledelayedexpansion
set "THIS_FILE=%~f0"

conda --version
