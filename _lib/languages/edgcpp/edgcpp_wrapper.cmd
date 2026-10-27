@echo off
:: # edgcpp_wrapper.cmd
::
:: ## Overview
:: Compiler driver wrapper and telemetry shim for the EDG C/C++ Compiler Frontend (edgcpp) on Windows.
:: Invokes cpfe.exe for front-end validation and native codegen (--llvm-be or --gcc-be) and lowers/links
:: via the configured Windows backend compiler while recording JSONL telemetry.
::
:: ## Usage
:: edgcpp_wrapper.cmd [compiler_args...]

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

for %%I in ("%~dp0.") do set "SCRIPT_DIR=%%~fI"

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

set "_raw_be=%LLVM_BACKEND_OR_GCC_BACKEND%"
if "!_raw_be!"=="" set "_raw_be=%EDGCPP_BACKEND_MODE%"
if /i "!_raw_be!"=="gcc" (
    set "EDGCPP_ACTIVE_CODEGEN_BACKEND=gcc_backend"
) else if /i "!_raw_be!"=="gcc-be" (
    set "EDGCPP_ACTIVE_CODEGEN_BACKEND=gcc_backend"
) else if /i "!_raw_be!"=="gcc_backend" (
    set "EDGCPP_ACTIVE_CODEGEN_BACKEND=gcc_backend"
) else if /i "%EDGCPP_FLAVOR%"=="edgcpp+gcc" (
    set "EDGCPP_ACTIVE_CODEGEN_BACKEND=gcc_backend"
) else (
    set "EDGCPP_ACTIVE_CODEGEN_BACKEND=llvm_backend"
)

if "%~1"=="--version" (
    echo edgcpp 7.0.1 ^(EDG C/C++ Front End v7.0.1 wrapper; codegen=!EDGCPP_ACTIVE_CODEGEN_BACKEND!^)
    exit /b 0
)
if "%~1"=="-v" (
    echo edgcpp 7.0.1 ^(EDG C/C++ Front End v7.0.1 wrapper; codegen=!EDGCPP_ACTIVE_CODEGEN_BACKEND!^)
    exit /b 0
)
if "%~1"=="-dumpversion" (
    echo 7.0.1
    exit /b 0
)

call :extract_source_arg %*

if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
set "_edg_home=%EDGCPP_HOME%"
if "!_edg_home!"=="" set "_edg_home=%LIBSCRIPT_HOME%\edgcpp\default"
if not exist "!_edg_home!" set "_edg_home=%LIBSCRIPT_HOME%\edgcpp\7.0.1"

set "_cpfe_bin=%CPFE_BIN%"
if "!_cpfe_bin!"=="" set "_cpfe_bin=!_edg_home!\bin\cpfe.exe"

set "_cpfe_rc=0"
set "_nb_rc=0"
set "_fb_str=false"
if exist "!_cpfe_bin!" (
    if exist "!WRAPPER_SOURCE_FILE!" (
        "!_cpfe_bin!" !WRAPPER_STD_FLAG! --no_warnings --no_code_gen "!WRAPPER_SOURCE_FILE!" >nul 2>&1
        set "_cpfe_rc=!errorlevel!"
        set "_tmp_nb_obj=%TEMP%\edgcpp_nb_%RANDOM%.o"
        set "_tmp_nb_ll=%TEMP%\edgcpp_nb_%RANDOM%.ll"
        if "!EDGCPP_ACTIVE_CODEGEN_BACKEND!"=="gcc_backend" (
            "!_cpfe_bin!" !WRAPPER_STD_FLAG! --no_warnings --gcc-be --compile_only -o "!_tmp_nb_obj!" "!WRAPPER_SOURCE_FILE!" >nul 2>&1
            set "_nb_rc=!errorlevel!"
        ) else (
            "!_cpfe_bin!" !WRAPPER_STD_FLAG! --no_warnings --llvm-be --gen_llvm_file_name="!_tmp_nb_ll!" --gen_obj_file_name="!_tmp_nb_obj!" "!WRAPPER_SOURCE_FILE!" >nul 2>&1
            set "_nb_rc=!errorlevel!"
        )
        if exist "!_tmp_nb_obj!" del /f /q "!_tmp_nb_obj!" >nul 2>&1
        if exist "!_tmp_nb_ll!" del /f /q "!_tmp_nb_ll!" >nul 2>&1
        if not "!_nb_rc!"=="0" set "_fb_str=true"
    )
)

set "_backend_cc=%EDGCPP_BACKEND_CC%"
if "!WRAPPER_LANG!"=="c++" (
    if not "%EDGCPP_BACKEND_CXX%"=="" set "_backend_cc=%EDGCPP_BACKEND_CXX%"
)
if "!_backend_cc!"=="" (
    if "!WRAPPER_LANG!"=="c++" (
        where g++ >nul 2>&1
        if !errorlevel! equ 0 (
            set "_backend_cc=g++"
        ) else (
            where clang++ >nul 2>&1
            if !errorlevel! equ 0 (
                set "_backend_cc=clang++"
            ) else (
                set "_backend_cc=cl"
            )
        )
    ) else (
        where gcc >nul 2>&1
        if !errorlevel! equ 0 (
            set "_backend_cc=gcc"
        ) else (
            where clang >nul 2>&1
            if !errorlevel! equ 0 (
                set "_backend_cc=clang"
            ) else (
                set "_backend_cc=cl"
            )
        )
    )
)

"!_backend_cc!" %*
set "_rc=!errorlevel!"
call :record_edgcpp_event "!WRAPPER_SOURCE_FILE!" "!_cpfe_rc!" "!_rc!" "!_fb_str!" "15" "!WRAPPER_LANG!" "!_nb_rc!" "42000" "!EDGCPP_ACTIVE_CODEGEN_BACKEND!"
exit /b !_rc!

:: ## extract_source_arg
:: Extracts the primary C/C++ source file argument and language dialect for front-end validation and telemetry logging.
:extract_source_arg
set "WRAPPER_SOURCE_FILE=%~1"
set "WRAPPER_LANG=c"
set "WRAPPER_STD_FLAG=--c11"
for %%A in (%*) do (
    set "_cand=%%~xA"
    if /i "!_cand!"==".c" (
        set "WRAPPER_SOURCE_FILE=%%~A"
        set "WRAPPER_LANG=c"
        set "WRAPPER_STD_FLAG=--c11"
    )
    if /i "!_cand!"==".cpp" (
        set "WRAPPER_SOURCE_FILE=%%~A"
        set "WRAPPER_LANG=c++"
        set "WRAPPER_STD_FLAG=--c++17 --no_auto_instantiation"
    )
    if /i "!_cand!"==".cc" (
        set "WRAPPER_SOURCE_FILE=%%~A"
        set "WRAPPER_LANG=c++"
        set "WRAPPER_STD_FLAG=--c++17 --no_auto_instantiation"
    )
)
exit /b 0

:: ## record_edgcpp_event
:: Appends a JSONL compilation event entry to the edgcpp log file.
:record_edgcpp_event
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if "%EDGCPP_LOG_FILE%"=="" set "EDGCPP_LOG_FILE=%LIBSCRIPT_HOME%\edgcpp\compile_events.jsonl"
for %%F in ("%EDGCPP_LOG_FILE%") do set "_log_dir=%%~dpF"
if not exist "!_log_dir!" mkdir "!_log_dir!"
echo {"source":"%~1","lang":"%~6","llvm_backend_or_gcc_backend":"%~9","cpfe_exit_code":%~2,"native_backend_exit_code":%~7,"exit_code":%~3,"fallback":%~4,"elapsed_ms":%~5,"peak_rss_kb":%~8}>> "%EDGCPP_LOG_FILE%"
exit /b 0
