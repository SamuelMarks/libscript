@echo off
:: # versioning.cmd
::
:: ## Overview
:: Provides common utilities for managing component versions on Windows.
:: It includes subroutines to resolve component version directories
:: and create NTFS directory junctions (`mklink /J`) for version aliases.
:: 
:: ## Usage
:: Call subroutines like `:libscript_symlink_alias` from other batch scripts to manage versions.

REM versioning.cmd
REM Common utilities for managing native libscript installations and version aliases on Windows.

goto :eof

:libscript_get_version_dir
set "component=%~1"
set "version=%~2"
if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_BASE_DIR=%USERPROFILE%\.libscript"
) else (
    set "LIBSCRIPT_BASE_DIR=%LIBSCRIPT_HOME%"
)
set "LIBSCRIPT_VERSION_DIR=%LIBSCRIPT_BASE_DIR%\%component%\%version%"
goto :eof

:libscript_symlink_alias
set "component=%~1"
set "alias_name=%~2"
set "exact_version=%~3"

if "%alias_name%"=="%exact_version%" goto :eof

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_BASE_DIR=%USERPROFILE%\.libscript"
) else (
    set "LIBSCRIPT_BASE_DIR=%LIBSCRIPT_HOME%"
)
set "base_dir=%LIBSCRIPT_BASE_DIR%\%component%"

if not exist "%base_dir%" mkdir "%base_dir%"

set "alias_path=%base_dir%\%alias_name%"
set "exact_path=%base_dir%\%exact_version%"

if exist "%alias_path%" rmdir "%alias_path%"
mklink /J "%alias_path%" "%exact_path%" >nul
goto :eof
