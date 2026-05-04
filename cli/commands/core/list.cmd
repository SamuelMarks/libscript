@echo off
setlocal EnableDelayedExpansion
echo Available components:
for /f "delims=" %%f in ('dir /s /b /a:-d "%SCRIPT_DIR%\cli.cmd" 2^>nul') do (
    set "dir_path=%%~dpf"
    set "dir_path=!dir_path:~0,-1!"
    if exist "!dir_path!\vars.schema.json" (
        set "rel_dir=!dir_path:%SCRIPT_DIR%\=!"
        if "!rel_dir!" neq "" (
            set "desc="
            jq -r "if .description then .description else \"\" end" "!dir_path!\vars.schema.json" > "%temp%\desc.txt" 2^>nul
            if not errorlevel 1 (
                set /p desc=^<"%temp%\desc.txt"
            )
            if "!desc!" neq "" (
                echo   !rel_dir! - !desc!
            ) else (
                echo   !rel_dir!
            )
        )
    )
)
if exist "%temp%\desc.txt" del "%temp%\desc.txt"
exit /b 0

