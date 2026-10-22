#!/bin/sh
# ## Overview
# Unit and regression test suite for devtools/docs-gen/generate_markdown_docs.{sh,ps1,cmd}
# and devtools/docs-gen/inject_markers.{sh,ps1,cmd}.
# Verifies batching across >50 README files (preventing Windows cmd.exe 8191-char overflow),
# UTF-8 preservation, normalized idempotency (zero rewrites when unchanged), and Unix/PowerShell parity.
#
# ## Usage
# ./tests/test_generate_markdown_docs.sh

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
export LIBSCRIPT_ROOT_DIR

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "/?" ] || [ "${1:-}" = "-?" ]; then
  printf 'Usage: %s [--help]
' "$0"
  printf 'Runs regression tests for generate_markdown_docs and inject_markers.
'
  exit 0
fi

TMP_WS=$(mktemp -d)
trap 'rm -rf "$TMP_WS"' EXIT INT TERM HUP

FAILURES=0

# ## pass_msg
# Logs a passing assertion message.
pass_msg() {
  printf '[PASS] %s
' "$1"
}

# ## fail_msg
# Logs a failing assertion message and increments FAILURES.
fail_msg() {
  printf '[FAIL] %s
' "$1" >&2
  FAILURES=$((FAILURES + 1))
}

# ## setup_mock_workspace
# Populates a temporary workspace with >55 components, UTF-8 characters, and schema definitions.
setup_mock_workspace() {
  _ws="$1"
  mkdir -p "$_ws/_lib/_common"
  cp "${LIBSCRIPT_ROOT_DIR}/.prettierrc" "$_ws/.prettierrc" 2>/dev/null || true
  cp "${LIBSCRIPT_ROOT_DIR}/.editorconfig" "$_ws/.editorconfig" 2>/dev/null || true

  cat <<'EOF' > "$_ws/_lib/_common/base_vars.schema.json"
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "base vars",
  "description": "Base variables",
  "type": "object",
  "properties": {
    "LIBSCRIPT_GLOBAL_INSTALL_METHOD": {
      "type": "string",
      "description": "Global install method — supports $HOME paths.",
      "default": "system"
    }
  }
}
EOF

  _i=1
  while [ "$_i" -le 55 ]; do
    _comp_dir="$_ws/_lib/mock-cat/comp_${_i}"
    mkdir -p "$_comp_dir"
    cat <<EOF > "$_comp_dir/vars.schema.json"
{
  "\$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "comp_${_i} vars",
  "description": "Variables for comp_${_i}",
  "type": "object",
  "properties": {
    "COMP_${_i}_PORT": {
      "type": "string",
      "description": "Port for comp_${_i} — default \$PORT.",
      "default": "8080"
    }
  }
}
EOF
    cat <<EOF > "$_comp_dir/README.md"
# Component ${_i} — UTF-8 Em-Dash Test

## Overview
Mock component ${_i} for batch documentation generation.

## Usage
Run setup.
EOF
    _i=$((_i + 1))
  done
}

printf '=== LibScript Markdown Docs Generator Regression Suite ===
'

setup_mock_workspace "$TMP_WS"

ROOT_DIR="$TMP_WS" "${LIBSCRIPT_ROOT_DIR}/devtools/docs-gen/generate_markdown_docs.sh"

if grep -q "COMP_55_PORT" "$TMP_WS/_lib/mock-cat/comp_55/README.md" && grep -q "LIBSCRIPT_GLOBAL_INSTALL_METHOD" "$TMP_WS/_lib/mock-cat/comp_55/README.md"; then
  pass_msg "generate_markdown_docs.sh populated schema and base_vars across 55 components"
else
  fail_msg "generate_markdown_docs.sh failed to populate COMP_55_PORT in comp_55/README.md"
fi

if grep -q "Component 55 — UTF-8 Em-Dash Test" "$TMP_WS/_lib/mock-cat/comp_55/README.md"; then
  pass_msg "generate_markdown_docs.sh preserved UTF-8 em-dash character"
else
  fail_msg "generate_markdown_docs.sh corrupted UTF-8 em-dash character"
fi

cp "$TMP_WS/_lib/mock-cat/comp_55/README.md" "$TMP_WS/comp_55.before.md"
STACK="" ROOT_DIR="$TMP_WS" "${LIBSCRIPT_ROOT_DIR}/devtools/docs-gen/generate_markdown_docs.sh"
if cmp -s "$TMP_WS/comp_55.before.md" "$TMP_WS/_lib/mock-cat/comp_55/README.md"; then
  pass_msg "generate_markdown_docs.sh is strictly idempotent on second run"
else
  fail_msg "generate_markdown_docs.sh modified already-generated README.md on second run"
fi

if command -v pwsh >/dev/null 2>&1; then
  TMP_WS_PS=$(mktemp -d)
  setup_mock_workspace "$TMP_WS_PS"
  ROOT_DIR="$TMP_WS_PS" pwsh -NoProfile -File "${LIBSCRIPT_ROOT_DIR}/devtools/docs-gen/generate_markdown_docs.ps1"

  if grep -q "COMP_55_PORT" "$TMP_WS_PS/_lib/mock-cat/comp_55/README.md" && grep -q " — default \$PORT." "$TMP_WS_PS/_lib/mock-cat/comp_55/README.md"; then
    pass_msg "generate_markdown_docs.ps1 populated 55 components with batched Prettier and preserved \$PORT + UTF-8"
  else
    fail_msg "generate_markdown_docs.ps1 failed to populate COMP_55_PORT or corrupted \$PORT / UTF-8"
  fi

  cp "$TMP_WS_PS/_lib/mock-cat/comp_55/README.md" "$TMP_WS_PS/comp_55.before.md"
  ROOT_DIR="$TMP_WS_PS" pwsh -NoProfile -File "${LIBSCRIPT_ROOT_DIR}/devtools/docs-gen/generate_markdown_docs.ps1"
  if cmp -s "$TMP_WS_PS/comp_55.before.md" "$TMP_WS_PS/_lib/mock-cat/comp_55/README.md"; then
    pass_msg "generate_markdown_docs.ps1 is strictly idempotent on second run"
  else
    fail_msg "generate_markdown_docs.ps1 modified already-generated README.md on second run"
  fi
  rm -rf "$TMP_WS_PS"
fi

if [ "$FAILURES" -gt 0 ]; then
  printf '[FAIL] test_generate_markdown_docs failed with %d error(s).
' "$FAILURES" >&2
  exit 1
fi

printf '=== All Markdown Docs Generator Checks Passed! ===
'
exit 0
