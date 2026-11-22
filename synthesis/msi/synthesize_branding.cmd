@echo off
:: # synthesize_branding.cmd
:: ## Overview
:: Universal branding synthesizer generating 24-bit BMP banners, multi-resolution ICO, and aggregated RTF EULA for Windows Installer (MSI) packages on Windows using jq and gawk without PowerShell.
:: ## Usage
:: call synthesis\msi\synthesize_branding.cmd <path_to_packaging.json_or_dir> [--output-dir DIR]

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

set "TARGET_SPEC=%~1"
if "%TARGET_SPEC%"=="" (
    echo [ERROR] No stack directory or packaging.json specified >&2
    exit /b 1
)
shift

set "OUTPUT_DIR="
goto :arg_loop
:: ## arg_loop
:: Parses command-line arguments and populates configuration variables.
:arg_loop
if "%~1"=="" goto :done_args
if /i "%~1"=="--output-dir" ( set "OUTPUT_DIR=%~2" & shift & shift & goto :arg_loop )
if /i "%~1"=="-o" ( set "OUTPUT_DIR=%~2" & shift & shift & goto :arg_loop )
set "OUTPUT_DIR=%~1"
shift
goto :arg_loop

:: ## done_args
:: Extracts palette colors via jq and synthesizes binary BMP/ICO and RTF assets via gawk.
:done_args
set "PKG_JSON=%TARGET_SPEC%"
if exist "%TARGET_SPEC%\packaging.json" set "PKG_JSON=%TARGET_SPEC%\packaging.json"
if not exist "!PKG_JSON!" (
    echo [ERROR] packaging.json not found at: !PKG_JSON! >&2
    exit /b 1
)

if "!OUTPUT_DIR!"=="" (
    for %%P in ("!PKG_JSON!") do set "_PKG_DIR=%%~dpP"
    set "OUTPUT_DIR=!_PKG_DIR!assets"
)
if not exist "!OUTPUT_DIR!" mkdir "!OUTPUT_DIR!" 2>nul

call :resolve_tools
if "!JQ_BIN!"=="" (
    echo [ERROR] jq is required for synthesize_branding.cmd >&2
    exit /b 1
)
if "!AWK_BIN!"=="" (
    echo [ERROR] gawk/awk is required for synthesize_branding.cmd >&2
    exit /b 1
)

set "APP_TITLE=Application"
set "PRIMARY_HEX=0078D4"
set "SECONDARY_HEX=2B88D8"
set "DARK_HEX=101820"
set "EULA_COMPS=Application"

set "TMP_BR_JQ=%TEMP%\ls_brand_%RANDOM%.jq"
(
    echo ^(.name // "app"^) as $name ^|
    echo ^(.title // $name^) as $title ^|
    echo ^(.branding_palette // {}^) as $p ^|
    echo ^(^($p.primary_color // "#0078D4"^) ^| ltrimstr^("#"^)^) as $primary ^|
    echo ^(^($p.secondary_color // "#2B88D8"^) ^| ltrimstr^("#"^)^) as $secondary ^|
    echo ^(^($p.dark_color // "#101820"^) ^| ltrimstr^("#"^)^) as $dark ^|
    echo ^(^($p.eula_components // [$title]^) ^| join^(", "^)^) as $eula_comps ^|
    echo "APP_TITLE=\($title)",
    echo "PRIMARY_HEX=\($primary)",
    echo "SECONDARY_HEX=\($secondary)",
    echo "DARK_HEX=\($dark)",
    echo "EULA_COMPS=\($eula_comps)"
) > "!TMP_BR_JQ!"

set "TMP_BR_OUT=%TEMP%\ls_brand_%RANDOM%_%RANDOM%.out"
"!JQ_BIN!" -r -f "!TMP_BR_JQ!" "!PKG_JSON!" > "!TMP_BR_OUT!"
if errorlevel 1 (
    del /f /q "!TMP_BR_JQ!" "!TMP_BR_OUT!" >nul 2>&1
    echo [ERROR] Failed to parse !PKG_JSON! with jq >&2
    exit /b 1
)
for /f "usebackq tokens=1,* delims==" %%K in ("!TMP_BR_OUT!") do set "%%K=%%L"
del /f /q "!TMP_BR_JQ!" "!TMP_BR_OUT!" >nul 2>&1

set /a "PR_R=0x!PRIMARY_HEX:~0,2!, PR_G=0x!PRIMARY_HEX:~2,2!, PR_B=0x!PRIMARY_HEX:~4,2!" 2>nul
set /a "SC_R=0x!SECONDARY_HEX:~0,2!, SC_G=0x!SECONDARY_HEX:~2,2!, SC_B=0x!SECONDARY_HEX:~4,2!" 2>nul
set /a "DK_R=0x!DARK_HEX:~0,2!, DK_G=0x!DARK_HEX:~2,2!, DK_B=0x!DARK_HEX:~4,2!" 2>nul

set "AWK_BIN_FLAG="
"!AWK_BIN!" -b "BEGIN{exit 0}" >nul 2>&1
if not errorlevel 1 set "AWK_BIN_FLAG=-b"

set "TMP_BMP_AWK=%TEMP%\ls_bmp_%RANDOM%.awk"
(
    echo function write_u16^(val^) { printf "%%c%%c", val %% 256, int^(val / 256^) %% 256 }
    echo function write_u32^(val^) { printf "%%c%%c%%c%%c", val %% 256, int^(val / 256^) %% 256, int^(val / 65536^) %% 256, int^(val / 16777216^) %% 256 }
    echo BEGIN {
    echo   BINMODE = 3
    echo   w = width + 0; h = height + 0
    echo   row_bytes = w * 3; pad = ^(4 - ^(row_bytes %% 4^)^) %% 4
    echo   img_size = ^(row_bytes + pad^) * h; file_size = 54 + img_size
    echo   printf "BM"; write_u32^(file_size^); write_u16^(0^); write_u16^(0^); write_u32^(54^); write_u32^(40^)
    echo   write_u32^(w^); write_u32^(h^); write_u16^(1^); write_u16^(24^); write_u32^(0^); write_u32^(img_size^)
    echo   write_u32^(2835^); write_u32^(2835^); write_u32^(0^); write_u32^(0^)
    echo   for ^(y = 0; y ^< h; y++^) {
    echo     for ^(x = 0; x ^< w; x++^) {
    echo       if ^(mode == "top"^) {
    echo         if ^(y == 0^) printf "%%c%%c%%c", pr_b, pr_g, pr_r; else printf "%%c%%c%%c", 255, 255, 255
    echo       } else {
    echo         if ^(y ^< 6^) printf "%%c%%c%%c", pr_b, pr_g, pr_r
    echo         else if ^(^(y ^>= 88 ^&^& y ^<= 90 ^&^& x ^>= 16 ^&^& x ^<= 148^) ^|^| ^(y ^>= 192 ^&^& y ^<= 194 ^&^& x ^>= 16 ^&^& x ^<= 148^)^) printf "%%c%%c%%c", sc_b, sc_g, sc_r
    echo         else printf "%%c%%c%%c", dk_b, dk_g, dk_r
    echo       }
    echo     }
    echo     for ^(p = 0; p ^< pad; p++^) printf "%%c", 0
    echo   }
    echo }
) > "!TMP_BMP_AWK!"

"!AWK_BIN!" !AWK_BIN_FLAG! -v mode=side -v width=164 -v height=312 -v pr_r=!PR_R! -v pr_g=!PR_G! -v pr_b=!PR_B! -v sc_r=!SC_R! -v sc_g=!SC_G! -v sc_b=!SC_B! -v dk_r=!DK_R! -v dk_g=!DK_G! -v dk_b=!DK_B! -f "!TMP_BMP_AWK!" > "!OUTPUT_DIR!\banner_side.bmp"
if errorlevel 1 ( del /f /q "!TMP_BMP_AWK!" >nul 2>&1 & echo [ERROR] Failed to synthesize banner_side.bmp >&2 & exit /b 1 )
echo [OK] Generated side banner: !OUTPUT_DIR!\banner_side.bmp ^(164x312^)

"!AWK_BIN!" !AWK_BIN_FLAG! -v mode=top -v width=493 -v height=58 -v pr_r=!PR_R! -v pr_g=!PR_G! -v pr_b=!PR_B! -v sc_r=!SC_R! -v sc_g=!SC_G! -v sc_b=!SC_B! -v dk_r=!DK_R! -v dk_g=!DK_G! -v dk_b=!DK_B! -f "!TMP_BMP_AWK!" > "!OUTPUT_DIR!\banner_top.bmp"
if errorlevel 1 ( del /f /q "!TMP_BMP_AWK!" >nul 2>&1 & echo [ERROR] Failed to synthesize banner_top.bmp >&2 & exit /b 1 )
echo [OK] Generated top banner: !OUTPUT_DIR!\banner_top.bmp ^(493x58^)
del /f /q "!TMP_BMP_AWK!" >nul 2>&1

set "TMP_ICO_AWK=%TEMP%\ls_ico_%RANDOM%.awk"
(
    echo function write_u16^(val^) { printf "%%c%%c", val %% 256, int^(val / 256^) %% 256 }
    echo function write_u32^(val^) { printf "%%c%%c%%c%%c", val %% 256, int^(val / 256^) %% 256, int^(val / 65536^) %% 256, int^(val / 16777216^) %% 256 }
    echo BEGIN {
    echo   BINMODE = 3
    echo   sizes[0] = 48; sizes[1] = 32; sizes[2] = 16; num_sizes = 3
    echo   printf "%%c%%c%%c%%c%%c%%c", 0, 0, 1, 0, num_sizes, 0
    echo   offset = 6 + num_sizes * 16
    echo   for ^(i = 0; i ^< num_sizes; i++^) {
    echo     s = sizes[i]; img_size = s * s * 4; mask_row = int^(^(s + 31^) / 32^) * 4; mask_size = mask_row * s
    echo     blob_size = 40 + img_size + mask_size
    echo     printf "%%c%%c%%c%%c", s, s, 0, 0; write_u16^(1^); write_u16^(32^); write_u32^(blob_size^); write_u32^(offset^)
    echo     offset += blob_size
    echo   }
    echo   for ^(i = 0; i ^< num_sizes; i++^) {
    echo     s = sizes[i]; img_size = s * s * 4; mask_row = int^(^(s + 31^) / 32^) * 4; mask_size = mask_row * s
    echo     write_u32^(40^); write_u32^(s^); write_u32^(s * 2^); write_u16^(1^); write_u16^(32^); write_u32^(0^)
    echo     write_u32^(img_size + mask_size^); write_u32^(0^); write_u32^(0^); write_u32^(0^); write_u32^(0^)
    echo     pad = int^(s * 0.08^); cx = s * 0.5; cy = s * 0.5; r_in = s * 0.25
    echo     for ^(y = 0; y ^< s; y++^) {
    echo       for ^(x = 0; x ^< s; x++^) {
    echo         if ^(x ^>= pad ^&^& x ^< ^(s - pad^) ^&^& y ^>= pad ^&^& y ^< ^(s - pad^)^) {
    echo           dx = x - cx; dy = y - cy
    echo           if ^(sqrt^(dx * dx + dy * dy^) ^< r_in^) printf "%%c%%c%%c%%c", pr_b, pr_g, pr_r, 255
    echo           else printf "%%c%%c%%c%%c", dk_b, dk_g, dk_r, 255
    echo         } else printf "%%c%%c%%c%%c", 0, 0, 0, 0
    echo       }
    echo     }
    echo     for ^(m = 0; m ^< mask_size; m++^) printf "%%c", 0
    echo   }
    echo }
) > "!TMP_ICO_AWK!"

"!AWK_BIN!" !AWK_BIN_FLAG! -v pr_r=!PR_R! -v pr_g=!PR_G! -v pr_b=!PR_B! -v dk_r=!DK_R! -v dk_g=!DK_G! -v dk_b=!DK_B! -f "!TMP_ICO_AWK!" > "!OUTPUT_DIR!\app.ico"
set "_ICO_RC=!ERRORLEVEL!"
del /f /q "!TMP_ICO_AWK!" >nul 2>&1
if "!_ICO_RC!" neq "0" ( echo [ERROR] Failed to synthesize app.ico >&2 & exit /b 1 )
echo [OK] Generated multi-res icon: !OUTPUT_DIR!\app.ico

(
    echo {\rtf1\ansi\deff0 {\fonttbl {\f0 Arial;}}\fs20
    echo {\b !APP_TITLE! End User License Agreement}\par
    echo \par
    echo This deployment package provisions !APP_TITLE! along with its declared service dependencies.\par
    echo \par
    echo Licensed components:\par
    echo !EULA_COMPS!\par
    echo \par
    echo By continuing the installation, you agree to comply with all applicable open-source and commercial licensing terms.\par
    echo }
) > "!OUTPUT_DIR!\license.rtf"
echo [OK] Generated EULA: !OUTPUT_DIR!\license.rtf
echo [SUCCESS] Branding synthesis complete in !OUTPUT_DIR!
exit /b 0

:: ## resolve_tools
:: Resolves jq.exe and gawk.exe from PATH or LibScript component isolation.
:resolve_tools
set "JQ_BIN="
set "AWK_BIN="
for %%J in (jq.exe jq) do if "!JQ_BIN!"=="" for /f "delims=" %%P in ('where %%J 2^>nul') do if "!JQ_BIN!"=="" set "JQ_BIN=%%P"
for %%A in (gawk.exe awk.exe gawk awk) do if "!AWK_BIN!"=="" for /f "delims=" %%P in ('where %%A 2^>nul') do if "!AWK_BIN!"=="" set "AWK_BIN=%%P"
set "_LS_H=%LIBSCRIPT_HOME%"
if "!_LS_H!"=="" set "_LS_H=%USERPROFILE%\.libscript"
if "!JQ_BIN!"=="" if exist "!_LS_H!\jq\default\bin\jq.exe" set "JQ_BIN=!_LS_H!\jq\default\bin\jq.exe"
if "!AWK_BIN!"=="" if exist "!_LS_H!\gawk\default\bin\gawk.exe" set "AWK_BIN=!_LS_H!\gawk\default\bin\gawk.exe"
if "!JQ_BIN!"=="" if exist "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" depends jq >nul 2>&1
    if exist "!_LS_H!\jq\default\bin\jq.exe" set "JQ_BIN=!_LS_H!\jq\default\bin\jq.exe"
)
if "!AWK_BIN!"=="" if exist "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" depends awk >nul 2>&1
    if exist "!_LS_H!\gawk\default\bin\gawk.exe" set "AWK_BIN=!_LS_H!\gawk\default\bin\gawk.exe"
)
exit /b 0
