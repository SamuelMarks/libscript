@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2^>^&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" ^>^&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

:: # pre-commit.cmd
::
:: ## Overview
:: Handles operations related to the component '.githooks'.
:: 
:: ## Usage
:: Execute this script to perform actions for .githooks.

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

echo Running pre-commit hooks...

:: 1. Enforce line endings and indent via Prettier where applicable
where npx >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=*" %%F in ('git diff --no-ext-diff --cached --name-only --diff-filter=ACM 2^>nul') do (
        if exist "%%F" (
            set "_EXT=%%~xF"
            if /i "!_EXT!"==".json" (
                call npx --yes prettier --write "%%F" >nul 2>&1
                git add "%%F"
            ) else if /i "!_EXT!"==".yml" (
                call npx --yes prettier --write "%%F" >nul 2>&1
                git add "%%F"
            ) else if /i "!_EXT!"==".yaml" (
                call npx --yes prettier --write "%%F" >nul 2>&1
                git add "%%F"
            ) else if /i "!_EXT!"==".md" (
                call npx --yes prettier --write "%%F" >nul 2>&1
                git add "%%F"
            )
        )
    )
)

:: 2. Spellcheck
where npx >nul 2>&1
if not errorlevel 1 (
    echo Running spellcheck...
    set "TMP_SPELL=%TEMP%\staged_spell_%RANDOM%.txt"
    git diff --no-ext-diff --cached --name-only --diff-filter=ACM > "!TMP_SPELL!" 2>nul
    if exist "!TMP_SPELL!" (
        for %%S in ("!TMP_SPELL!") do if %%~zS gtr 0 (
            call npx --yes --quiet cspell lint --no-progress --no-summary --no-must-find-files --file-list stdin < "!TMP_SPELL!"
            if errorlevel 1 (
                del /f /q "!TMP_SPELL!" >nul 2>&1
                echo [ERROR] Spellcheck failed. Fix typos or add words to .cspell.json.
                exit /b 1
            )
        )
        del /f /q "!TMP_SPELL!" >nul 2>&1
    )
)

:: 3. LibScript Standards Audit
if exist "devtools\audit\audit_standards.cmd" (
    echo Running LibScript engineering standards audit...
    call "devtools\audit\audit_standards.cmd" --staged
    if errorlevel 1 (
        echo [ERROR] Standards audit failed. Please fix violations before committing.
        exit /b 1
    )
)

if exist "devtools\docs-gen\generate_markdown_docs.cmd" (
    echo Regenerating markdown readme files interpolating the json...
    call "devtools\docs-gen\generate_markdown_docs.cmd"
    for /f "delims=" %%F in ('git ls-files -m ^| findstr /E "README.md"') do (
        where npx >nul 2>&1
        if not errorlevel 1 (
            call npx --yes prettier --write "%%F" >nul 2>&1
        )
        git add "%%F"
    )
)

if exist "tests\update_results.cmd" (
    echo Updating Supported Components in README.md...
    call "tests\update_results.cmd" --json
    where npx >nul 2>&1
    if not errorlevel 1 (
        call npx --yes prettier --write README.md >nul 2>&1
    )
    git add README.md
)

echo Pre-commit hook completed successfully.
exit /b 0
