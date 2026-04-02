#!/bin/sh
. "$(dirname "$0")/../../_common/test_base.sh"

#!/bin/sh
. "$(dirname "$0")/../../_common/test_base.sh"

if command -v pub >/dev/null 2>&1; then
  pub --version || echo "pub found"
elif command -v dart >/dev/null 2>&1; then
  dart pub --version || echo "dart pub found"
else
  echo "pub skipped (not found)"
fi
