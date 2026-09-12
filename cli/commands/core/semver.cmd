@echo off
:: # semver.cmd
::
:: ## Overview
:: Handles Semantic Versioning (SemVer) parsing and comparison operations natively in Windows Batch.
:: 
:: ## Usage
:: Execute this script to compare version strings:
:: semver.cmd semver <v1> <operator> <v2>

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if /i "%~1"=="semver" (
    set "v1=%~2"
    set "op=%~3"
    set "v2=%~4"
) else (
    set "v1=%~1"
    set "op=%~2"
    set "v2=%~3"
)

if "!v1!"=="" (
    echo Usage: %~nx0 [semver] ^<v1^> ^<operator^> ^<v2^> 1>&2
    echo Operators: = != ^> ^< ^>= ^<= 1>&2
    exit /b 1
)

:: Strip leading v or V if present
if "!v1:~0,1!"=="v" set "v1=!v1:~1!"
if "!v1:~0,1!"=="V" set "v1=!v1:~1!"
if "!v2:~0,1!"=="v" set "v2=!v2:~1!"
if "!v2:~0,1!"=="V" set "v2=!v2:~1!"

:: Split into major, minor, patch, build
for /f "tokens=1-4 delims=.+-" %%A in ("!v1!") do (
    set "a1=%%A" & set "a2=%%B" & set "a3=%%C" & set "a4=%%D"
)
for /f "tokens=1-4 delims=.+-" %%A in ("!v2!") do (
    set "b1=%%A" & set "b2=%%B" & set "b3=%%C" & set "b4=%%D"
)

if "!a1!"=="" set "a1=0"
if "!a2!"=="" set "a2=0"
if "!a3!"=="" set "a3=0"
if "!a4!"=="" set "a4=0"

if "!b1!"=="" set "b1=0"
if "!b2!"=="" set "b2=0"
if "!b3!"=="" set "b3=0"
if "!b4!"=="" set "b4=0"

:: ## compare_semver
:: Executes compare_semver functionality.
:compare_semver
set "cmp=0"
if !a1! GTR !b1! (set "cmp=1") else if !a1! LSS !b1! (set "cmp=-1") else (
    if !a2! GTR !b2! (set "cmp=1") else if !a2! LSS !b2! (set "cmp=-1") else (
        if !a3! GTR !b3! (set "cmp=1") else if !a3! LSS !b3! (set "cmp=-1") else (
            if !a4! GTR !b4! (set "cmp=1") else if !a4! LSS !b4! (set "cmp=-1") else (
                set "cmp=0"
            )
        )
    )
)

if "!op!"=="="  ( if !cmp! EQU 0 (exit /b 0) else (exit /b 1) )
if "!op!"=="==" ( if !cmp! EQU 0 (exit /b 0) else (exit /b 1) )
if "!op!"=="-eq" ( if !cmp! EQU 0 (exit /b 0) else (exit /b 1) )
if "!op!"=="!=" ( if not !cmp! EQU 0 (exit /b 0) else (exit /b 1) )
if "!op!"=="-ne" ( if not !cmp! EQU 0 (exit /b 0) else (exit /b 1) )
if "!op!"==">"  ( if !cmp! EQU 1 (exit /b 0) else (exit /b 1) )
if "!op!"=="-gt" ( if !cmp! EQU 1 (exit /b 0) else (exit /b 1) )
if "!op!"=="<"  ( if !cmp! EQU -1 (exit /b 0) else (exit /b 1) )
if "!op!"=="-lt" ( if !cmp! EQU -1 (exit /b 0) else (exit /b 1) )
if "!op!"==">=" ( if !cmp! GEQ 0 (exit /b 0) else (exit /b 1) )
if "!op!"=="-ge" ( if !cmp! GEQ 0 (exit /b 0) else (exit /b 1) )
if "!op!"=="<=" ( if !cmp! LEQ 0 (exit /b 0) else (exit /b 1) )
if "!op!"=="-le" ( if !cmp! LEQ 0 (exit /b 0) else (exit /b 1) )

echo Unknown operator: !op! 1>&2
exit /b 1
