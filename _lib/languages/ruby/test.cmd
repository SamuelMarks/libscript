@echo off
rem ## Overview
rem Test suite for the ruby component.
rem
rem ## Usage
rem Execute this script to perform a component-specific test.

setlocal enabledelayedexpansion
set "THIS_FILE=%~f0"

ruby -e "puts 'hello world!'"
