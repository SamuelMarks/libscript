@echo off
java -version
echo public class HelloWorld { > HelloWorld.java
echo public static void main(String[] args) { >> HelloWorld.java
echo System.out.println("Hello World"); >> HelloWorld.java
echo } } >> HelloWorld.java
javac HelloWorld.java
java HelloWorld
del HelloWorld.java HelloWorld.class
