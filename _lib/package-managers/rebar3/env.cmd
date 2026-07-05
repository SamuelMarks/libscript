@echo off
REM ## Overview
REM Environment variable initialization script for the rebar3 component.

IF "%REBAR3_VERSION%"=="" SET "REBAR3_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\rebar3\%REBAR3_VERSION%\bin;%PATH%"
