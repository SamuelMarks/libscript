@echo off
rem libscript.bat
rem MS-DOS entrypoint for LibScript

if "%1"=="" goto show_help
if "%1"=="--help" goto show_help
if "%1"=="-h" goto show_help
if "%1"=="/?" goto show_help

if "%1"=="list" goto list_components
if "%1"=="search" goto search_components

:run_target
rem Check standard paths for a component
if exist "%1\cli.bat" (
    call "%1\cli.bat" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\_toolchain\%1\cli.bat" (
    call "_lib\_toolchain\%1\cli.bat" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\_storage\%1\cli.bat" (
    call "_lib\_storage\%1\cli.bat" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\_server\%1\cli.bat" (
    call "_lib\_server\%1\cli.bat" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\_common\%1\cli.bat" (
    call "_lib\_common\%1\cli.bat" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "app\third_party\%1\cli.bat" (
    call "app\third_party\%1\cli.bat" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)

rem Fallback to .cmd if running on a newer Windows that mistakenly ran the .bat
if exist "%1\cli.cmd" (
    call "%1\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\_toolchain\%1\cli.cmd" (
    call "_lib\_toolchain\%1\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\_storage\%1\cli.cmd" (
    call "_lib\_storage\%1\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\_server\%1\cli.cmd" (
    call "_lib\_server\%1\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\_common\%1\cli.cmd" (
    call "_lib\_common\%1\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "app\third_party\%1\cli.cmd" (
    call "app\third_party\%1\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)

echo Error: Unknown component '%1' or missing cli.bat/cli.cmd
goto end

:show_help
echo LibScript Global CLI (DOS Mode)
echo ===============================
echo.
echo Usage: libscript [COMMAND] [ARGS...]
echo.
echo Commands:
echo   list                        List all available components (not fully supported in pure DOS)
echo   ^<component^> [OPTIONS...]    Invoke the CLI for a specific component
goto end

:list_components
echo Component listing not fully supported in pure DOS mode.
echo Please refer to the directory structure.
goto end

:search_components
echo Search not fully supported in pure DOS mode.
goto end

:end
