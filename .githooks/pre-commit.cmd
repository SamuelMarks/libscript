@echo off
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
        git add "%%F"
    )
)

:: Skipping the CI Matrix generation in the batch equivalent for brevity, 
:: as it relies heavily on grep, awk, and curl/jq which may not be present 
:: in a standard Windows cmd environment.

echo Pre-commit hook completed successfully.
exit /b 0
