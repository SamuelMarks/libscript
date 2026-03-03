#!/bin/sh
set -feu
kotlinc -version
cat << "SRC" > hw.kt
fun main() { println("Hello World") }
SRC
kotlinc hw.kt -include-runtime -d hw.jar
java -jar hw.jar
rm -f hw.kt hw.jar
