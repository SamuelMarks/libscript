#!/bin/sh
set -feu
deno --version
deno eval "console.log('Hello World');"
