@echo off
rem ## Overview
rem Test suite for the elixir component.
rem
rem ## Usage
rem Execute this script to perform a component-specific test.

setlocal enabledelayedexpansion

elixir -e "IO.puts('hello world!')"
