#!/bin/sh
# ## Overview
# Audits all LibScript components on the Windows 11 Vagrant VM to determine
# exact failures, missing download URLs, broken test commands, and unsupported tools.
# Outputs JSON and Markdown summaries.
#
# ## Usage
# ./devtools/audit/audit_windows.sh

set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VAGRANT_DIR="$REPO_ROOT/vagrant/windows-11"
REPORT_JSON="$REPO_ROOT/tests_tmp/windows_audit_report.json"
REPORT_MD="$REPO_ROOT/tests_tmp/windows_audit_report.md"

mkdir -p "$REPO_ROOT/tests_tmp"

# Ensure VM is up
cd "$VAGRANT_DIR"
if ! vagrant status 2>&1 | grep -q "running"; then
    echo "Starting Windows 11 VM..."
    vagrant up --no-provision
fi

vagrant rsync

echo "Auditing components on Windows 11 VM..."

printf '[
' > "$REPORT_JSON"
first=1

for cat_dir in "$REPO_ROOT"/_lib/*; do
    [ ! -d "$cat_dir" ] && continue
    cat_name="$(basename "$cat_dir")"
    [ "$cat_name" = "_common" ] && continue

    for comp_dir in "$cat_dir"/*; do
        [ ! -d "$comp_dir" ] && continue
        comp_name="$(basename "$comp_dir")"

        has_manifest=0; [ -f "$comp_dir/manifest.json" ] && has_manifest=1
        has_setup_cmd=0; [ -f "$comp_dir/setup.cmd" ] && has_setup_cmd=1
        has_setup_generic=0; [ -f "$comp_dir/setup_generic.cmd" ] && has_setup_generic=1
        has_setup_windows=0; [ -f "$comp_dir/setup_windows.cmd" ] && has_setup_windows=1
        has_test_cmd=0; [ -f "$comp_dir/test.cmd" ] && has_test_cmd=1
        has_test_ps1=0; [ -f "$comp_dir/test.ps1" ] && has_test_ps1=1

        # Check blacklist/whitelist
        os_support="supported"
        if [ "$has_manifest" -eq 1 ]; then
            os_support=$(awk '
            BEGIN { in_bl=0; in_wl=0; has_wl=0; wl_match=0; result="supported" }
            /"os_blacklist"\s*:/ {
                in_bl=1; in_wl=0
                if ($0 ~ /"windows"/) { result="blacklisted"; exit }
                if ($0 ~ /\]/) { in_bl=0 }
                next
            }
            /"os_whitelist"\s*:/ {
                in_wl=1; in_bl=0; has_wl=1
                if ($0 ~ /"windows"/ || $0 ~ /"all"/) { wl_match=1 }
                if ($0 ~ /\]/) { in_wl=0 }
                next
            }
            in_bl {
                if ($0 ~ /"windows"/) { result="blacklisted"; exit }
                if ($0 ~ /\]/) { in_bl=0 }
            }
            in_wl {
                if ($0 ~ /"windows"/ || $0 ~ /"all"/) { wl_match=1 }
                if ($0 ~ /\]/) { in_wl=0 }
            }
            END { if (result == "supported" && has_wl && !wl_match) { result="not_whitelisted" }; print result }
            ' "$comp_dir/manifest.json")
        fi

        install_exit=0
        test_exit=0
        install_err=""
        test_err=""

        if [ "$os_support" = "supported" ]; then
            printf "Testing %s/%s... " "$cat_name" "$comp_name"

            # Clean cache/install dir before test
            vagrant ssh -c 'Remove-Item -Recurse -Force "$env:USERPROFILE\.libscript\'"$comp_name"'" -ErrorAction SilentlyContinue' -- -T >/dev/null 2>&1 || true

            # Run install
            inst_out=$(vagrant ssh -c 'Set-Location C:\libscript; cmd.exe /c "C:\libscript\libscript.cmd install '"$comp_name"'"' -- -T 2>&1) || install_exit=$?
            install_err=$(printf '%s\n' "$inst_out" | grep -iE "error|cannot|fail|not found|no download|not recognized" | head -n 1 | tr '"' "'" | tr '\r\n' ' ' | head -c 120)

            # Run test
            tst_out=$(vagrant ssh -c 'Set-Location C:\libscript; cmd.exe /c "C:\libscript\libscript.cmd test '"$comp_name"'"' -- -T 2>&1) || test_exit=$?
            test_err=$(printf '%s\n' "$tst_out" | grep -iE "error|cannot|fail|not found|not recognized" | head -n 1 | tr '"' "'" | tr '\r\n' ' ' | head -c 120)

            # Clean up
            vagrant ssh -c 'Remove-Item -Recurse -Force "$env:USERPROFILE\.libscript\'"$comp_name"'" -ErrorAction SilentlyContinue' -- -T >/dev/null 2>&1 || true

            if [ "$install_exit" -eq 0 ] && [ "$test_exit" -eq 0 ]; then
                printf "PASS
"
            else
                printf "FAIL (inst:%s, test:%s)
" "$install_exit" "$test_exit"
            fi
        else
            printf "Skipping %s/%s (%s)
" "$cat_name" "$comp_name" "$os_support"
        fi

        [ "$first" -eq 0 ] && printf ',
' >> "$REPORT_JSON"
        first=0

        cat <<EOF >> "$REPORT_JSON"
  {
    "category": "$cat_name",
    "component": "$comp_name",
    "os_support": "$os_support",
    "has_setup_cmd": $has_setup_cmd,
    "has_setup_generic": $has_setup_generic,
    "has_setup_windows": $has_setup_windows,
    "has_test_cmd": $has_test_cmd,
    "has_test_ps1": $has_test_ps1,
    "install_exit": $install_exit,
    "test_exit": $test_exit,
    "install_err": "$install_err",
    "test_err": "$test_err"
  }
EOF
    done
done

printf '
]
' >> "$REPORT_JSON"

echo "Audit complete. JSON saved to $REPORT_JSON."
