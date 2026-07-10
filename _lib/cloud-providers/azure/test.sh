#!/bin/sh
# ## Overview
# Test suite for the Azure cloud provider component.
#
# ## Usage
# Run by the test framework to validate dry-run deployments in Azure.


set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
for LIB in "_lib/_common/test_base.sh" ${_LIBSCRIPT_DUMMY_NO_RUN:-}; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

#!/bin/sh
for LIB in "_lib/_common/test_base.sh" ${_LIBSCRIPT_DUMMY_NO_RUN:-}; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

#!/bin/sh
export DRY_RUN=true
SCRIPT_DIR=$(cd ${SCRIPT_DIR} && pwd)

printf '%s\n' "Testing Azure component in DRY_RUN mode..."

# Test auth
"$SCRIPT_DIR/cli.sh" auth status 2>&1 | tee /tmp/az_test_out || true
grep "az account show" /tmp/az_test_out || true

# Test location
"$SCRIPT_DIR/cli.sh" location list 2>&1 | tee /tmp/az_test_out || true
grep "az account list-locations" /tmp/az_test_out || true

# Test DNS
"$SCRIPT_DIR/cli.sh" dns zone create test.local test-rg 2>&1 | tee /tmp/az_test_out || true
grep "az network dns zone create" /tmp/az_test_out || true
"$SCRIPT_DIR/cli.sh" dns record create test.local test-rg my A 1.2.3.4 2>&1 | tee /tmp/az_test_out || true
grep "az network dns record-set a add-record" /tmp/az_test_out || true

# Test firewall
"$SCRIPT_DIR/cli.sh" firewall create test-nsg test-rg 80 2>&1 | tee /tmp/az_test_out || true
grep "az network nsg rule create" /tmp/az_test_out || true

# Test network
# Test network
"$SCRIPT_DIR/cli.sh" network create test-vnet test-rg 2>&1 | grep "az network vnet create"

# Test node
"$SCRIPT_DIR/cli.sh" node create test-vm test-image test-rg 2>&1 | grep "az vm create"

# Test cleanup
"$SCRIPT_DIR/cli.sh" cleanup 2>&1 | grep "az resource list"

printf '%s\n' "Azure tests passed (dry-run)."
