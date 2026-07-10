@echo off
:: # tags.cmd
::
:: ## Overview
:: Provides global configuration for tag-based resource management, and utilities 
:: for formatting tags according to provider requirements (AWS, GCP, Azure) on Windows.
::
:: ## Usage
:: call "%~dp0tags.cmd" :init
:: call "%~dp0tags.cmd" :libscript_format_tags aws

goto :%1

:init
if "%LIBSCRIPT_TAG_ENABLE%"=="" set "LIBSCRIPT_TAG_ENABLE=true"
if "%LIBSCRIPT_TAG_KEY%"=="" set "LIBSCRIPT_TAG_KEY=libscript"
if "%LIBSCRIPT_TAG_VALUE%"=="" set "LIBSCRIPT_TAG_VALUE=managed"
exit /b 0

:libscript_format_tags
set "provider=%~2"
if not "%LIBSCRIPT_TAG_ENABLE%"=="true" exit /b 0

if "%provider%"=="aws" (
    echo --tags Key=%LIBSCRIPT_TAG_KEY%,Value=%LIBSCRIPT_TAG_VALUE%
) else if "%provider%"=="gcp" (
    echo --labels=%LIBSCRIPT_TAG_KEY%=%LIBSCRIPT_TAG_VALUE%
) else if "%provider%"=="azure" (
    echo --tags %LIBSCRIPT_TAG_KEY%=%LIBSCRIPT_TAG_VALUE%
) else (
    echo Error: Unknown cloud provider "%provider%" for tagging. >&2
    exit /b 1
)
exit /b 0

:libscript_format_tag_filter
set "provider=%~2"
if not "%LIBSCRIPT_TAG_ENABLE%"=="true" exit /b 0

if "%provider%"=="aws" (
    echo --filters Name=tag:%LIBSCRIPT_TAG_KEY%,Values=%LIBSCRIPT_TAG_VALUE%
) else if "%provider%"=="gcp" (
    echo --filter=labels.%LIBSCRIPT_TAG_KEY%=%LIBSCRIPT_TAG_VALUE%
) else if "%provider%"=="azure" (
    echo --query "[?tags.%LIBSCRIPT_TAG_KEY% == '%LIBSCRIPT_TAG_VALUE%']"
) else (
    echo Error: Unknown cloud provider "%provider%" for tag filtering. >&2
    exit /b 1
)
exit /b 0
