#!/bin/sh
set -feu
rustc --version
cat << "SRC" > hw.rs
fn main() { println!("Hello World"); }
SRC
rustc hw.rs
./hw
rm -f hw.rs hw
