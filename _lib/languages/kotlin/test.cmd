@echo off
kotlinc -version
echo fun main() { println("Hello World") } > hw.kt
kotlinc hw.kt -include-runtime -d hw.jar
java -jar hw.jar
del hw.kt hw.jar
