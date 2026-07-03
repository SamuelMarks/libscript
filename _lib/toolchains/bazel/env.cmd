@echo off
:: # env.cmd
::
:: ## Overview
:: Environment variable initialization script for the bazel component on Windows.
:: It sets up necessary paths and environment variables required for the component
:: to function correctly within the libscript context.
::
:: ## Usage
:: Call this script to load the environment variables. Do not execute it directly without context.

if "%BAZEL_VERSION%"=="" set BAZEL_VERSION=latest
if "%BAZEL_VERSION%"=="latest" set BAZEL_VERSION=v1.25.0
if "%LIBSCRIPT_HOME%"=="" set LIBSCRIPT_HOME=%USERPROFILE%\.libscript

set PATH=%LIBSCRIPT_HOME%\bazel\%BAZEL_VERSION%\bin;%PATH%
