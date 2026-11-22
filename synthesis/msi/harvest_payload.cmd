@echo off
:: # harvest_payload.cmd
:: ## Overview
:: Harvests the LibScript repository or staged directories into a deployment staging directory or WiX manifest fragment while respecting exclusion rules using native Batch and gawk without PowerShell.
:: ## Usage
:: call synthesis\msi\harvest_payload.cmd [OPTIONS]

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

set "SOURCE_DIR="
set "OUTPUT_DIR="
set "MANIFEST_FILE="
set "WIX_FRAGMENT="
set "COMPONENT_GROUP=LibscriptHarvestedComponents"
set "DIRECTORY_ID=LIBSCRIPT_FOLDER"
set "ROOT_DIR=!LIBSCRIPT_ROOT_DIR!"
set "INCLUDE_CACHE="
set "INCLUDE_MSI=0"
goto :parse_args

:: ## parse_args
:: Parses CLI flags for payload harvesting and WiX XML fragment synthesis.
:parse_args
if "%~1"=="" goto :execute_harvest
set "_ARG=%~1"
if /i "!_ARG!"=="--help" goto :show_help
if /i "!_ARG!"=="-h" goto :show_help
if /i "!_ARG!"=="/?" goto :show_help
if /i "!_ARG!"=="--source-dir" ( set "SOURCE_DIR=%~2" & shift & shift & goto :parse_args )
if /i "!_ARG!"=="--stage-dir" ( set "SOURCE_DIR=%~2" & shift & shift & goto :parse_args )
if /i "!_ARG:~0,13!"=="--source-dir=" ( set "SOURCE_DIR=!_ARG:~13!" & shift & goto :parse_args )
if /i "!_ARG:~0,12!"=="--stage-dir=" ( set "SOURCE_DIR=!_ARG:~12!" & shift & goto :parse_args )
if /i "!_ARG!"=="--output-dir" ( set "OUTPUT_DIR=%~2" & shift & shift & goto :parse_args )
if /i "!_ARG!"=="--manifest-file" ( set "MANIFEST_FILE=%~2" & shift & shift & goto :parse_args )
if /i "!_ARG!"=="--wix-fragment" ( set "WIX_FRAGMENT=%~2" & shift & shift & goto :parse_args )
if /i "!_ARG!"=="--component-group" ( set "COMPONENT_GROUP=%~2" & shift & shift & goto :parse_args )
if /i "!_ARG!"=="--directory-id" ( set "DIRECTORY_ID=%~2" & shift & shift & goto :parse_args )
if /i "!_ARG!"=="--root-dir" ( set "ROOT_DIR=%~2" & shift & shift & goto :parse_args )
if /i "!_ARG!"=="--include-cache" ( set "INCLUDE_CACHE=%~2" & shift & shift & goto :parse_args )
if /i "!_ARG:~0,16!"=="--include-cache=" ( set "INCLUDE_CACHE=!_ARG:~16!" & shift & goto :parse_args )
if /i "!_ARG!"=="--include-msi" ( set "INCLUDE_MSI=1" & shift & goto :parse_args )
echo [ERROR] Unknown argument: %~1 >&2
exit /b 1

:: ## show_help
:: Displays command-line usage instructions and available options.
:show_help
echo Usage: %~nx0 [OPTIONS]
echo.
echo Options:
echo   --source-dir ^<dir^>       Source directory to harvest files from directly
echo   --output-dir ^<dir^>       Target staging directory for harvested files
echo   --manifest-file ^<path^>   Output file containing relative paths list
echo   --wix-fragment ^<path^>    Output file containing WiX XML fragment
echo   --component-group ^<id^>   WiX ComponentGroup ID ^(default: LibscriptHarvestedComponents^)
echo   --directory-id ^<id^>      WiX Directory ID ^(default: LIBSCRIPT_FOLDER^)
echo   --root-dir ^<path^>        Root repository directory
echo   --include-cache ^<dir^>    Include hydrated offline cache directory into payload
echo   --include-msi            Allow harvesting of .msi installer packages into payload
echo   --help, -h               Show this help text
exit /b 0

:: ## execute_harvest
:: Enumerates payload files, filters excluded artifacts, stages files, and emits WiX XML via gawk.
:execute_harvest
call :resolve_awk
if "!AWK_BIN!"=="" (
    echo [ERROR] gawk/awk is required for harvest_payload.cmd ^(run: libscript.cmd depends awk^) >&2
    exit /b 1
)

set "TMP_RAW=%TEMP%\ls_harvest_raw_%RANDOM%.txt"
set "TMP_FLT=%TEMP%\ls_harvest_flt_%RANDOM%.txt"
set "IS_SOURCE_MODE=0"

if not "!SOURCE_DIR!"=="" (
    if not exist "!SOURCE_DIR!" (
        echo [ERROR] Source directory does not exist: !SOURCE_DIR! >&2
        exit /b 1
    )
    for %%S in ("!SOURCE_DIR!") do set "ROOT_DIR=%%~fS"
    set "IS_SOURCE_MODE=1"
    dir /s /b /a-d "!ROOT_DIR!" > "!TMP_RAW!" 2>nul
) else (
    for %%R in ("!ROOT_DIR!") do set "ROOT_DIR=%%~fR"
    where git >nul 2>&1
    if not errorlevel 1 if exist "!ROOT_DIR!\.git" (
        pushd "!ROOT_DIR!"
        git ls-files -c -o --exclude-standard > "!TMP_RAW!" 2>nul
        popd
    )
    if not exist "!TMP_RAW!" dir /s /b /a-d "!ROOT_DIR!" > "!TMP_RAW!" 2>nul
)

set "CACHE_REAL="
if not "!INCLUDE_CACHE!"=="" (
    if exist "!INCLUDE_CACHE!" (
        for %%C in ("!INCLUDE_CACHE!") do set "CACHE_REAL=%%~fC"
    ) else if exist "!ROOT_DIR!\!INCLUDE_CACHE!" (
        for %%C in ("!ROOT_DIR!\!INCLUDE_CACHE!") do set "CACHE_REAL=%%~fC"
    )
)

set "TMP_FLT_AWK=%TEMP%\ls_harvest_flt_%RANDOM%.awk"
(
    echo BEGIN {
    echo   gsub^(/\\/, "/", root_dir^)
    echo   sub^(/\/$/, "", root_dir^)
    echo }
    echo {
    echo   sub^(/\r$/, "", $0^)
    echo   gsub^(/\\/, "/", $0^)
    echo   rel = $0
    echo   if ^(tolower^(substr^(rel, 1, length^(root_dir^) + 1^)^) == tolower^(root_dir "/"^)^) {
    echo     rel = substr^(rel, length^(root_dir^) + 2^)
    echo   }
    echo   sub^(/^^\.\//, "", rel^)
    echo   if ^(rel == ""^) next
    echo   if ^(src_mode == "1"^) {
    echo     if ^(rel ~ /^^\.git/ ^|^| rel ~ /^^\.vagrant/ ^|^| rel ~ /\.^(tmp^|log^|ppm^|bak^|swp^|wixobj^|wxs^)$/^) next
    echo     if ^(inc_msi == "0" ^&^& rel ~ /\.msi$/^) next
    echo     print rel
    echo   } else {
    echo     if ^(rel ~ /^^^(\.git^|\.vagrant^|tests_tmp\/^|dist\/^|build\/^|tmp\/^|node_modules\/^|cache\/^)/^) next
    echo     if ^(rel ~ /\/^(\.git^|\.github^|\.githooks^|\.vagrant^|tests_tmp^|dist^|build^|tmp^|node_modules^|cache^)^(\/^|$^)/^) next
    echo     if ^(rel ~ /\.^(tmp^|log^|ppm^|bak^|swp^|wixobj^|wxs^)$/^) next
    echo     if ^(rel ~ /^^synthesis\/msi\/screenshots\/release_test\// ^|^| rel == "TODO_PLAN.md"^) next
    echo     if ^(rel ~ /\.msi$/^) { if ^(inc_msi == "1"^) print rel; next }
    echo     print rel
    echo   }
    echo }
) > "!TMP_FLT_AWK!"

"!AWK_BIN!" -v "root_dir=!ROOT_DIR!" -v "src_mode=!IS_SOURCE_MODE!" -v "inc_msi=!INCLUDE_MSI!" -f "!TMP_FLT_AWK!" "!TMP_RAW!" > "!TMP_FLT!"
del /f /q "!TMP_FLT_AWK!" "!TMP_RAW!" >nul 2>&1

if not "!CACHE_REAL!"=="" if exist "!CACHE_REAL!" (
    set "TMP_CACHE_RAW=%TEMP%\ls_harvest_cache_!RANDOM!.txt"
    set "TMP_CACHE_AWK=%TEMP%\ls_harvest_cache_!RANDOM!.awk"
    dir /s /b /a-d "!CACHE_REAL!" > "!TMP_CACHE_RAW!" 2>nul
    (
        echo BEGIN { gsub^(/\\/, "/", c_dir^); sub^(/\/$/, "", c_dir^) }
        echo {
        echo   sub^(/\r$/, "", $0^); gsub^(/\\/, "/", $0^)
        echo   rel = $0
        echo   if ^(tolower^(substr^(rel, 1, length^(c_dir^) + 1^)^) == tolower^(c_dir "/"^)^) rel = substr^(rel, length^(c_dir^) + 2^)
        echo   if ^(rel ^^!= ""^) print "cache/" rel
        echo }
    ) > "!TMP_CACHE_AWK!"
    "!AWK_BIN!" -v "c_dir=!CACHE_REAL!" -f "!TMP_CACHE_AWK!" "!TMP_CACHE_RAW!" >> "!TMP_FLT!"
    del /f /q "!TMP_CACHE_RAW!" "!TMP_CACHE_AWK!" >nul 2>&1
)

set "FILE_COUNT=0"
for /f "usebackq delims=" %%L in ("!TMP_FLT!") do set /a FILE_COUNT+=1
if "!FILE_COUNT!" equ "0" (
    del /f /q "!TMP_FLT!" >nul 2>&1
    echo [ERROR] Harvested 0 files. Payload is empty. >&2
    exit /b 1
)

if not "!MANIFEST_FILE!"=="" (
    for %%M in ("!MANIFEST_FILE!") do if not exist "%%~dpM" mkdir "%%~dpM" 2>nul
    copy /y "!TMP_FLT!" "!MANIFEST_FILE!" >nul
    echo [INFO] Wrote manifest to: !MANIFEST_FILE! ^(!FILE_COUNT! files^)
)

if not "!OUTPUT_DIR!"=="" (
    if not exist "!OUTPUT_DIR!" mkdir "!OUTPUT_DIR!" 2>nul
    for /f "usebackq delims=" %%R in ("!TMP_FLT!") do (
        set "_REL=%%R"
        set "_REL_WIN=!_REL:/=\!"
        set "_SRC=!ROOT_DIR!\!_REL_WIN!"
        if /i "!_REL:~0,6!"=="cache/" if not "!CACHE_REAL!"=="" (
            set "_SUB=!_REL:~6!"
            set "_SUB_WIN=!_SUB:/=\!"
            set "_SRC=!CACHE_REAL!\!_SUB_WIN!"
        )
        set "_DST=!OUTPUT_DIR!\!_REL_WIN!"
        for %%D in ("!_DST!") do if not exist "%%~dpD" mkdir "%%~dpD" 2>nul
        copy /y "!_SRC!" "!_DST!" >nul 2>&1
    )
    echo [INFO] Harvested files copied to: !OUTPUT_DIR!
)

if not "!WIX_FRAGMENT!"=="" (
    for %%W in ("!WIX_FRAGMENT!") do if not exist "%%~dpW" mkdir "%%~dpW" 2>nul
    set "TMP_WIX_AWK=%TEMP%\ls_harvest_wix_!RANDOM!.awk"
    (
        echo function sanitize^(s,   res^) { res = s; gsub^(/[^^a-zA-Z0-9_]/, "_", res^); return res }
        echo function str_hash32^(s, seed, mult, mod,   res, i, len, c^) {
        echo   res = seed; len = length^(s^)
        echo   for ^(i = 1; i ^<= len; i++^) { c = ord[substr^(s, i, 1^)]; res = ^(res * mult + c^) %% mod }
        echo   return res
        echo }
        echo function make_hash^(s,   h1, h2, h3, h4^) {
        echo   h1 = str_hash32^(s, 5381, 33, 2147483647^)
        echo   h2 = str_hash32^(s, 52711, 37, 2147483629^)
        echo   h3 = str_hash32^(s, 7919, 31, 2147483587^)
        echo   h4 = str_hash32^(s, 179424673, 41, 2147483579^)
        echo   return sprintf^("%%08x%%08x%%08x%%08x", h1, h2, h3, h4^)
        echo }
        echo function make_id^(prefix, raw_path,   san, cand, max_pre, avail, trimmed, h^) {
        echo   san = sanitize^(raw_path^); cand = prefix san
        echo   if ^(cand in used_ids ^&^& used_ids[cand] ^^!= raw_path^) cand = ""
        echo   if ^(cand ^^!= "" ^&^& length^(cand^) ^<= 72^) { used_ids[cand] = raw_path; return cand }
        echo   h = make_hash^(raw_path^); max_pre = 72 - 32 - 1; avail = max_pre - length^(prefix^)
        echo   trimmed = ^(avail ^> 0^) ? substr^(san, 1, avail^) : ""
        echo   cand = prefix trimmed "_" h; used_ids[cand] = raw_path; return cand
        echo }
        echo BEGIN {
        echo   q = sprintf^("%%c", 34^)
        echo   for ^(i = 1; i ^<= 255; i++^) ord[sprintf^("%%c", i^)] = i
        echo   gsub^(/\\/, "/", root^); sub^(/\/$/, "", root^)
        echo   gsub^(/\\/, "/", inc_cache^); sub^(/\/$/, "", inc_cache^)
        echo   print "<?xml version=" q "1.0" q " encoding=" q "UTF-8" q "?>"
        echo   print "<Wix xmlns=" q "http://schemas.microsoft.com/wix/2006/wi" q ">"
        echo   print "  <Fragment>"
        echo }
        echo {
        echo   sub^(/\r$/, "", $0^)
        echo   files[NR] = $0
        echo   n = split^($0, parts, "/"^)
        echo   cur = ""
        echo   for ^(i = 1; i ^< n; i++^) {
        echo     prev = cur
        echo     cur = ^(cur == ""^) ? parts[i] : ^(cur "/" parts[i]^)
        echo     if ^(^^!^(cur in dir_exists^)^) {
        echo       dir_exists[cur] = 1; dirs[++d_count] = cur
        echo       dir_name[cur] = parts[i]; dir_parent[cur] = prev
        echo     }
        echo   }
        echo }
        echo END {
        echo   for ^(i = 1; i ^<= d_count; i++^) {
        echo     d = dirs[i]; d_id = make_id^("DIR_", d^); p = dir_parent[d]
        echo     p_id = ^(p == ""^) ? dir_id : make_id^("DIR_", p^)
        echo     print "    <DirectoryRef Id=" q p_id q ">"
        echo     print "      <Directory Id=" q d_id q " Name=" q dir_name[d] q " />"
        echo     print "    </DirectoryRef>"
        echo   }
        echo   for ^(i = 1; i ^<= NR; i++^) {
        echo     f = files[i]; if ^(f == ""^) continue
        echo     c_id = make_id^("CMP_H_", f^); f_id = make_id^("FIL_H_", f^)
        echo     n = split^(f, parts, "/"^); dir_path = ""
        echo     for ^(j = 1; j ^< n; j++^) dir_path = ^(dir_path == ""^) ? parts[j] : ^(dir_path "/" parts[j]^)
        echo     base_name = parts[n]
        echo     target_dir = ^(dir_path == ""^) ? dir_id : make_id^("DIR_", dir_path^)
        echo     if ^(inc_cache ^^!= "" ^&^& substr^(f, 1, 6^) == "cache/"^) src = inc_cache "/" substr^(f, 7^)
        echo     else src = f
        echo     gsub^(/\//, "\\", src^)
        echo     disk_id = "1"
        echo     if ^(substr^(f, 1, 15^) == "cache/runtimes/" ^|^| substr^(f, 1, 17^) == "cache/webservers/"^) disk_id = "2"
        echo     else if ^(substr^(f, 1, 16^) == "cache/databases/"^) disk_id = "3"
        echo     else if ^(substr^(f, 1, 15^) == "cache/codebase/" ^|^| substr^(f, 1, 13^) == "cache/wheels/" ^|^| substr^(f, 1, 10^) == "cache/npm/" ^|^| substr^(f, 1, 19^) == "cache/applications/"^) disk_id = "4"
        echo     print "    <DirectoryRef Id=" q target_dir q ">"
        echo     print "      <Component Id=" q c_id q " Guid=" q "*" q ">"
        echo     print "        <File Id=" q f_id q " Name=" q base_name q " Source=" q src q " KeyPath=" q "yes" q " DiskId=" q disk_id q " />"
        echo     print "      </Component>"
        echo     print "    </DirectoryRef>"
        echo   }
        echo   print "    <ComponentGroup Id=" q comp_group q ">"
        echo   for ^(i = 1; i ^<= NR; i++^) {
        echo     f = files[i]; if ^(f == ""^) continue
        echo     if ^(inc_cache ^^!= "" ^&^& substr^(f, 1, 6^) == "cache/"^) continue
        echo     print "      <ComponentRef Id=" q make_id^("CMP_H_", f^) q " />"
        echo   }
        echo   print "    </ComponentGroup>"
        echo   if ^(inc_cache ^^!= ""^) {
        echo     print "    <ComponentGroup Id=" q "LibscriptOfflineCacheComponents" q ">"
        echo     for ^(i = 1; i ^<= NR; i++^) {
        echo       f = files[i]; if ^(f == ""^) continue
        echo       if ^(substr^(f, 1, 6^) == "cache/"^) print "      <ComponentRef Id=" q make_id^("CMP_H_", f^) q " />"
        echo     }
        echo     print "    </ComponentGroup>"
        echo   }
        echo   print "  </Fragment>"
        echo   print "</Wix>"
        echo }
    ) > "!TMP_WIX_AWK!"
    "!AWK_BIN!" -v "root=!ROOT_DIR!" -v "dir_id=!DIRECTORY_ID!" -v "comp_group=!COMPONENT_GROUP!" -v "inc_cache=!CACHE_REAL!" -f "!TMP_WIX_AWK!" "!TMP_FLT!" > "!WIX_FRAGMENT!.tmp"
    set "_WIX_RC=!ERRORLEVEL!"
    del /f /q "!TMP_WIX_AWK!" >nul 2>&1
    if "!_WIX_RC!" neq "0" (
        del /f /q "!WIX_FRAGMENT!.tmp" "!TMP_FLT!" >nul 2>&1
        echo [ERROR] Failed to synthesize WiX XML fragment via !AWK_BIN! >&2
        exit /b 1
    )
    move /y "!WIX_FRAGMENT!.tmp" "!WIX_FRAGMENT!" >nul
    echo [INFO] Generated WiX XML fragment: !WIX_FRAGMENT!
)

del /f /q "!TMP_FLT!" >nul 2>&1
echo [PASS] Harvesting complete ^(!FILE_COUNT! files identified^).
exit /b 0

:: ## resolve_awk
:: Locates or bootstraps gawk.exe/awk.exe via LibScript component isolation.
:resolve_awk
set "AWK_BIN="
for %%A in (gawk.exe awk.exe gawk awk) do (
    if "!AWK_BIN!"=="" (
        for /f "delims=" %%P in ('where %%A 2^>nul') do if "!AWK_BIN!"=="" set "AWK_BIN=%%P"
    )
)
if not "!AWK_BIN!"=="" exit /b 0
set "_LS_H=%LIBSCRIPT_HOME%"
if "!_LS_H!"=="" set "_LS_H=%USERPROFILE%\.libscript"
if exist "!_LS_H!\gawk\default\bin\gawk.exe" (
    set "AWK_BIN=!_LS_H!\gawk\default\bin\gawk.exe"
    exit /b 0
)
if exist "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" depends awk >nul 2>&1
    if exist "!_LS_H!\gawk\default\bin\gawk.exe" set "AWK_BIN=!_LS_H!\gawk\default\bin\gawk.exe"
)
exit /b 0
