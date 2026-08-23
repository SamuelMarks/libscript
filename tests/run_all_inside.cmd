@echo off
:: ## Overview
:: Runs tests for all components or a specific target component inside the environment.
::
:: ## Usage
:: tests\run_all_inside.cmd [TARGET_COMP]

setlocal EnableDelayedExpansion

set "LIBSCRIPT_ROOT_DIR=C:\opt\repos\libscript"
cd /d "C:\opt\repos\libscript"
if not exist "tests_tmp" mkdir tests_tmp

set "TARGET_COMP=%~1"

for /d %%C in (_lib\*) do (
    if /I not "%%~nxC"=="_common" (
        for /d %%D in ("%%C\*") do (
            set "target=%%~nxD"
            
            set "SKIP=0"
            if not "!TARGET_COMP!"=="" if not "!TARGET_COMP!"=="!target!" set "SKIP=1"
            
            if exist "tests_tmp\!target!.windows.success" set "SKIP=1"
            if exist "tests_tmp\!target!.windows.failure" set "SKIP=1"
            
            if "!SKIP!"=="0" (
                echo Testing !target!...
                set "STDOUT_FILE=tests_tmp\!target!.windows.stdout"
                set "STDERR_FILE=tests_tmp\!target!.windows.stderr"
                
                cmd /c libscript.cmd install "!target!" > "!STDOUT_FILE!" 2> "!STDERR_FILE!"
                if !errorlevel! equ 0 (
                    cmd /c libscript.cmd test "!target!" >> "!STDOUT_FILE!" 2>> "!STDERR_FILE!"
                    if !errorlevel! equ 0 (
                        echo Success > "tests_tmp\!target!.windows.success"
                        echo [OK] !target!
                    ) else (
                        echo Failure > "tests_tmp\!target!.windows.failure"
                        echo [FAILED] !target!
                    )
                ) else (
                    echo Failure > "tests_tmp\!target!.windows.failure"
                    echo [FAILED] !target!
                )
            )
        )
    )
)

endlocal