#!/bin/sh
set -feu
${CC:-cc} --version || gcc --version || clang --version
cat << "SRC" > hw.c
#include <stdio.h>
int main() { printf("Hello World\n"); return 0; }
SRC
${CC:-cc} -o hw hw.c || gcc -o hw hw.c || clang -o hw hw.c
./hw
rm -f hw.c hw
