#!/bin/sh
# shellcheck disable=SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145


set -feu
${CXX:-c++} --version || g++ --version || clang++ --version
cat << "SRC" > hw.cpp
#include <iostream>
int main() { std::cout << "Hello World\n"; return 0; }
SRC
${CXX:-c++} -o hw hw.cpp || g++ -o hw hw.cpp || clang++ -o hw hw.cpp
./hw
rm -f hw.cpp hw
