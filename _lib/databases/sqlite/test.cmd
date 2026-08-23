@echo off
rem ## Overview
rem Test suite for the sqlite component.
rem
rem ## Usage
rem Execute this script to perform a component-specific test.

setlocal enabledelayedexpansion

sqlite3 :memory: "SELECT 1;"
