#!/bin/sh
. "$(dirname "$0")/../../_common/test_base.sh"

#!/bin/sh
. "$(dirname "$0")/../../_common/test_base.sh"

if command -v rabbitmqctl >/dev/null 2>&1; then
  priv rabbitmqctl version
elif [ -x /usr/sbin/rabbitmqctl ]; then
  priv /usr/sbin/rabbitmqctl version
elif [ -x /opt/homebrew/sbin/rabbitmqctl ]; then
  priv /opt/homebrew/sbin/rabbitmqctl version
elif [ -x /usr/local/sbin/rabbitmqctl ]; then
  priv /usr/local/sbin/rabbitmqctl version
else
  echo "rabbitmqctl not found"
  exit 1
fi
