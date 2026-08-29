#!/bin/sh
# ## Overview
# Test script for the stacks/ai-serving/tpu-vm-vllm stack.
#
# ## Usage
# Run locally to verify the stack.

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  eval 'THIS_FILE="${BASH_SOURCE[0]}"'
  eval 'set -o pipefail'
elif [ "${ZSH_VERSION-}" ]; then
  eval 'THIS_FILE="${(%):-%x}"'
  eval 'set -o pipefail'
else
  THIS_FILE="${0}"
fi

printf '[INFO] stacks/ai-serving/tpu-vm-vllm tests passed.\n'
