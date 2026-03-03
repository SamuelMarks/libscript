#!/bin/sh
set -feu
java -version
cat << "SRC" > HelloWorld.java
public class HelloWorld {
    public static void main(String[] args) {
        System.out.println("Hello World");
    }
}
SRC
javac HelloWorld.java
java HelloWorld
rm -f HelloWorld.java HelloWorld.class
