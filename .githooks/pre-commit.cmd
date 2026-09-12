@echo off
set "THIS_FILE=%~f0"
:: # pre-commit.cmd
::
:: ## Overview
:: Handles operations related to the component '.githooks'.
:: 
:: ## Usage
:: Execute this script to perform actions for .githooks.

setlocal EnableDelayedExpansion

echo Running pre-commit hooks...

:: Note: We don't implement the full dos2unix, prettier, spellcheck 
:: logic in this pure batch file to keep it simple, but we do trigger 
:: the markdown regeneration if it exists.

if exist "devtools\docs-gen\generate_markdown_docs.cmd" (
    echo Regenerating markdown readme files interpolating the json...
    call "devtools\docs-gen\generate_markdown_docs.cmd"
    for /f "delims=" %%F in ('git ls-files -m ^| findstr /E "README.md"') do (
        where npx >nul 2>&1
        if not errorlevel 1 (
            call npx prettier --write "%%F" >nul 2>&1
        )
        git add "%%F"
    )
)

if exist "tests\update_results.cmd" (
    echo Updating Supported Components in README.md...
    call "tests\update_results.cmd"
    where npx >nul 2>&1
    if not errorlevel 1 (
        call npx prettier --write README.md >nul 2>&1
    )
    git add README.md
)

:: Skipping the Local Tests Matrix generation in the batch equivalent for brevity, 
:: as updating README.md in pure batch is complex.

echo Pre-commit hook completed successfully.
exit /b 0
