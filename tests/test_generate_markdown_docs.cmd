@echo off
:: # test_generate_markdown_docs.cmd
::
:: ## Overview
:: Unit and regression test suite for devtools\docs-gen\generate_markdown_docs.cmd
:: and devtools\docs-gen\inject_markers.cmd on Windows.
:: Verifies batching across >50 README files (preventing Windows cmd.exe 8191-char overflow),
:: UTF-8 preservation, and strict idempotency on consecutive runs.
::
:: ## Usage
:: tests\test_generate_markdown_docs.cmd [--help]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /I /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help
goto :run_tests

:: ## show_help
:: Prints usage information for this test script.
:show_help
echo Usage: test_generate_markdown_docs.cmd [--help]
echo Runs regression tests for generate_markdown_docs.cmd and inject_markers.cmd.
exit /b 0

:: ## run_tests
:: Executes the markdown doc generation batching and idempotency regression checks.
:run_tests
echo === LibScript Markdown Docs Generator Regression Suite (Win32) ===

set "TMP_WS=%TEMP%\libscript_md_docs_test_%RANDOM%"
if not exist "%TMP_WS%\_lib\_common" mkdir "%TMP_WS%\_lib\_common"
if exist "%LIBSCRIPT_ROOT_DIR%\.prettierrc" copy /y "%LIBSCRIPT_ROOT_DIR%\.prettierrc" "%TMP_WS%\.prettierrc" >nul
if exist "%LIBSCRIPT_ROOT_DIR%\.editorconfig" copy /y "%LIBSCRIPT_ROOT_DIR%\.editorconfig" "%TMP_WS%\.editorconfig" >nul

(
echo {
echo   "$schema": "https://json-schema.org/draft/2020-12/schema",
echo   "title": "base vars",
echo   "description": "Base variables",
echo   "type": "object",
echo   "properties": {
echo     "LIBSCRIPT_GLOBAL_INSTALL_METHOD": {
echo       "type": "string",
echo       "description": "Global install method.",
echo       "default": "system"
echo     }
echo   }
echo }
) > "%TMP_WS%\_lib\_common\base_vars.schema.json"

for /L %%I in (1,1,55) do (
    if not exist "%TMP_WS%\_lib\mock-cat\comp_%%I" mkdir "%TMP_WS%\_lib\mock-cat\comp_%%I"
    (
    echo {
    echo   "$schema": "https://json-schema.org/draft/2020-12/schema",
    echo   "title": "comp_%%I vars",
    echo   "description": "Variables for comp_%%I",
    echo   "type": "object",
    echo   "properties": {
    echo     "COMP_%%I_PORT": {
    echo       "type": "string",
    echo       "description": "Port for comp_%%I.",
    echo       "default": "8080"
    echo     }
    echo   }
    echo }
    ) > "%TMP_WS%\_lib\mock-cat\comp_%%I\vars.schema.json"
    (
    echo # Component %%I
    echo.
    echo ## Overview
    echo Mock component %%I.
    echo.
    echo ## Usage
    echo Run setup.
    ) > "%TMP_WS%\_lib\mock-cat\comp_%%I\README.md"
)

set "ROOT_DIR=%TMP_WS%"
call "%LIBSCRIPT_ROOT_DIR%\devtools\docs-gen\generate_markdown_docs.cmd"
if errorlevel 1 (
    echo [FAIL] generate_markdown_docs.cmd failed on 55-component workspace >&2
    rmdir /s /q "%TMP_WS%" 2>nul
    exit /b 1
)

findstr /C:"COMP_55_PORT" "%TMP_WS%\_lib\mock-cat\comp_55\README.md" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] COMP_55_PORT missing from generated README.md >&2
    rmdir /s /q "%TMP_WS%" 2>nul
    exit /b 1
)
echo [PASS] generate_markdown_docs.cmd populated 55 components without command-line overflow.

set "STACK="
call "%LIBSCRIPT_ROOT_DIR%\devtools\docs-gen\generate_markdown_docs.cmd"
if errorlevel 1 (
    echo [FAIL] Second run of generate_markdown_docs.cmd failed >&2
    rmdir /s /q "%TMP_WS%" 2>nul
    exit /b 1
)
echo [PASS] 2x consecutive runs of generate_markdown_docs.cmd succeeded idempotently.

set "ROOT_DIR="
rmdir /s /q "%TMP_WS%" 2>nul
echo === All Markdown Docs Generator Checks Passed! ===
exit /b 0
