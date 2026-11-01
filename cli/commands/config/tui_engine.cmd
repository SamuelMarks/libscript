@echo off
:: # tui_engine.cmd
:: ## Overview
:: Modular TUI engine providing Windows console prompts and PowerShell fallback dialogs.
:: ## Usage
:: call cli/commands/config/tui_engine.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
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

set "_TUI_SUB=%~1"
if not "!_TUI_SUB!"=="" (
    if "!_TUI_SUB:~0,1!"==":" (
        shift
        goto !_TUI_SUB!
    )
)
exit /b 0

:: ## tui_msgbox
:: Displays an informational message box on the Windows console.
:tui_msgbox
set "_TUI_TITLE=%~1"
set "_TUI_TEXT=%~2"
echo. >&2
echo === !_TUI_TITLE! === >&2
echo !_TUI_TEXT! >&2
echo. >&2
set /p "_TUI_DUMMY=Press ENTER to continue..." <con >con 2>&1
exit /b 0

:: ## tui_menu
:: Displays a single-choice menu on the Windows console and writes the selected tag to stdout.
:tui_menu
set "_TUI_TITLE=%~1"
set "_TUI_TEXT=%~2"
shift
shift
echo. >&2
echo === !_TUI_TITLE! === >&2
echo !_TUI_TEXT! >&2
:: ## tui_menu_loop
:: Iterates through menu tag/description pairs and prints each choice.
:tui_menu_loop
if "%~1"=="" goto :tui_menu_prompt
echo   [%~1] %~2 >&2
shift
shift
goto :tui_menu_loop
:: ## tui_menu_prompt
:: Prompts the user to select an option tag from the displayed menu.
:tui_menu_prompt
set "_TUI_CHOICE="
set /p "_TUI_CHOICE=Select option: "
echo !_TUI_CHOICE!
exit /b 0

:: ## tui_input
:: Prompts for text input on the Windows console and writes the result or default to stdout.
:tui_input
set "_TUI_TITLE=%~1"
set "_TUI_PROMPT=%~2"
set "_TUI_DEFAULT=%~3"
set "_TUI_VAL="
set /p "_TUI_VAL=!_TUI_PROMPT! [!_TUI_DEFAULT!]: "
if "!_TUI_VAL!"=="" set "_TUI_VAL=!_TUI_DEFAULT!"
echo !_TUI_VAL!
exit /b 0

