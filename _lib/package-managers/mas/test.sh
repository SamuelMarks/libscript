#!/bin/sh
. "$(dirname "$0")/../../_common/test_base.sh"

#!/bin/sh
. "$(dirname "$0")/../../_common/test_base.sh"

if command -v mas >/dev/null 2>&1; then
    mas version || echo "mas found"
  else
    echo "Error: mas not found on macOS!" >&2
    exit 1
  fi
  echo "mas skipped (not macOS)"
