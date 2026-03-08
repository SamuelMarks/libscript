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
if exist "_lib\toolchains\%1\cli.bat" (
    call "_lib\toolchains\%1\cli.bat" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\databases\%1\cli.bat" (
    call "_lib\databases\%1\cli.bat" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\web-servers\%1\cli.bat" (
    call "_lib\web-servers\%1\cli.bat" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\languages\%1\cli.bat" (
    call "_lib\languages\%1\cli.bat" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\utilities\%1\cli.bat" (
    call "_lib\utilities\%1\cli.bat" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\package-managers\%1\cli.bat" (
    call "_lib\package-managers\%1\cli.bat" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\git-servers\%1\cli.bat" (
    call "_lib\git-servers\%1\cli.bat" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\caches\%1\cli.bat" (
    call "_lib\caches\%1\cli.bat" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\message-brokers\%1\cli.bat" (
    call "_lib\message-brokers\%1\cli.bat" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\orchestration\%1\cli.bat" (
    call "_lib\orchestration\%1\cli.bat" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\logging\%1\cli.bat" (
    call "_lib\logging\%1\cli.bat" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\security\%1\cli.bat" (
    call "_lib\security\%1\cli.bat" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\init-systems\%1\cli.bat" (
    call "_lib\init-systems\%1\cli.bat" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\storage-layers\%1\cli.bat" (
    call "_lib\storage-layers\%1\cli.bat" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\_common\%1\cli.bat" (
    call "_lib\_common\%1\cli.bat" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "stacks\cms\%1\cli.bat" (
    call "stacks\cms\%1\cli.bat" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "stacks\collaboration\%1\cli.bat" (
    call "stacks\collaboration\%1\cli.bat" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "stacks\crawlers\%1\cli.bat" (
    call "stacks\crawlers\%1\cli.bat" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "stacks\data-science\%1\cli.bat" (
    call "stacks\data-science\%1\cli.bat" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "stacks\ecommerce\%1\cli.bat" (
    call "stacks\ecommerce\%1\cli.bat" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "stacks\erp\%1\cli.bat" (
    call "stacks\erp\%1\cli.bat" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "stacks\forums\%1\cli.bat" (
    call "stacks\forums\%1\cli.bat" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "stacks\networking\%1\cli.bat" (
    call "stacks\networking\%1\cli.bat" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "stacks\scaffolds\%1\cli.bat" (
    call "stacks\scaffolds\%1\cli.bat" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "stacks\task-queues\%1\cli.bat" (
    call "stacks\task-queues\%1\cli.bat" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)

rem Fallback to .cmd if running on a newer Windows that mistakenly ran the .bat
if exist "%1\cli.cmd" (
    call "%1\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\toolchains\%1\cli.cmd" (
    call "_lib\toolchains\%1\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\databases\%1\cli.cmd" (
    call "_lib\databases\%1\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\web-servers\%1\cli.cmd" (
    call "_lib\web-servers\%1\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\languages\%1\cli.cmd" (
    call "_lib\languages\%1\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\utilities\%1\cli.cmd" (
    call "_lib\utilities\%1\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\package-managers\%1\cli.cmd" (
    call "_lib\package-managers\%1\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\git-servers\%1\cli.cmd" (
    call "_lib\git-servers\%1\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\caches\%1\cli.cmd" (
    call "_lib\caches\%1\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\message-brokers\%1\cli.cmd" (
    call "_lib\message-brokers\%1\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\orchestration\%1\cli.cmd" (
    call "_lib\orchestration\%1\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\logging\%1\cli.cmd" (
    call "_lib\logging\%1\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\security\%1\cli.cmd" (
    call "_lib\security\%1\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\init-systems\%1\cli.cmd" (
    call "_lib\init-systems\%1\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\storage-layers\%1\cli.cmd" (
    call "_lib\storage-layers\%1\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "_lib\_common\%1\cli.cmd" (
    call "_lib\_common\%1\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "stacks\cms\%1\cli.cmd" (
    call "stacks\cms\%1\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "stacks\collaboration\%1\cli.cmd" (
    call "stacks\collaboration\%1\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "stacks\crawlers\%1\cli.cmd" (
    call "stacks\crawlers\%1\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "stacks\data-science\%1\cli.cmd" (
    call "stacks\data-science\%1\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "stacks\ecommerce\%1\cli.cmd" (
    call "stacks\ecommerce\%1\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "stacks\erp\%1\cli.cmd" (
    call "stacks\erp\%1\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "stacks\forums\%1\cli.cmd" (
    call "stacks\forums\%1\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "stacks\networking\%1\cli.cmd" (
    call "stacks\networking\%1\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "stacks\scaffolds\%1\cli.cmd" (
    call "stacks\scaffolds\%1\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    goto end
)
if exist "stacks\task-queues\%1\cli.cmd" (
    call "stacks\task-queues\%1\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
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
