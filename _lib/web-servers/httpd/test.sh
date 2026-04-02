#!/bin/sh
. "$(dirname "$0")/../../_common/test_base.sh"

#!/bin/sh
. "$(dirname "$0")/../../_common/test_base.sh"

if command -v httpd >/dev/null 2>&1; then
  httpd -v
elif command -v apache2 >/dev/null 2>&1; then
  apache2 -v
elif [ -x /usr/sbin/apache2 ]; then
  /usr/sbin/apache2 -v
elif [ -x /usr/sbin/httpd ]; then
  /usr/sbin/httpd -v
elif [ -x /opt/homebrew/bin/httpd ]; then
  /opt/homebrew/bin/httpd -v
elif [ -x /usr/local/bin/httpd ]; then
  /usr/local/bin/httpd -v
else
  >&2 echo "httpd/apache2 not found"
  exit 1
fi
echo hello from httpd
