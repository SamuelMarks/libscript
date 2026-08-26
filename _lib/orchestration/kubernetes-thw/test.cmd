@echo off
rem ## Overview
rem Test suite for the kubernetes-thw component.
rem
rem ## Usage
rem Execute this script to perform a component-specific test.

setlocal enabledelayedexpansion

sh "%~dp0test.sh"
exit /b %ERRORLEVEL%
