@echo off
rustc --version
echo fn main() { println!("Hello World"); } > hw.rs
rustc hw.rs
hw.exe
del hw.rs hw.exe
