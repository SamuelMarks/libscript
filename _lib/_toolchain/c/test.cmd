@echo off
gcc --version || clang --version
echo #include ^<stdio.h^> > hw.c
echo int main() { printf("Hello World\n"); return 0; } >> hw.c
gcc -o hw.exe hw.c
hw.exe
del hw.c hw.exe
