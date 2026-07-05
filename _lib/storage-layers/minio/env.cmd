@echo off
REM ## Overview
REM Environment variable initialization script for the minio component.

IF "%MINIO_VERSION%"=="" SET "MINIO_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\minio\%MINIO_VERSION%\bin;%PATH%"
