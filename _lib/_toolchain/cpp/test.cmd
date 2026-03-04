@echo off
g++ --version || clang++ --version
echo #include ^<iostream^> > hw.cpp
echo int main() { std::cout ^<^< "Hello World\n"; return 0; } >> hw.cpp
g++ -o hw.exe hw.cpp || clang++ -o hw.exe hw.cpp
hw.exe
del hw.cpp hw.exe
