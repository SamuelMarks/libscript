#!/bin/sh
set -feu
jq --version
echo '{"message": "Hello World"}' | jq '.message'
