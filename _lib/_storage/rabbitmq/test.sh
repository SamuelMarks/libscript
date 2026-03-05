#!/bin/sh
# shellcheck disable=SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145


set -feu
. ../../_common/priv.sh
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
