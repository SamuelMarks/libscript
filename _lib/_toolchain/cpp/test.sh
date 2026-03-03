#!/bin/sh
set -feu
${CXX:-c++} --version || g++ --version || clang++ --version
cat << "SRC" > hw.cpp
#include <iostream>
int main() { std::cout << "Hello World\n"; return 0; }
SRC
${CXX:-c++} -o hw hw.cpp || g++ -o hw hw.cpp || clang++ -o hw hw.cpp
./hw
rm -f hw.cpp hw
