# Andropiler
A CLI Application to compile your Android Project!

![Build Status](https://github.com/ThatMG393/andropiler/actions/workflows/gradle.yml/badge.svg?branch=master)
![Coverage Status](https://coveralls.io/repos/github/ThatMG393/andropiler/badge.svg?branch=master)
### Introduction
A ported version of [android-compiler](https://github.com/ThatMG393/android-compiler) to Java.

I ported android-compiler to Java because I was having trouble with the bash script, and it kept having weird issues.

Please make an Issue if there is a bug or something else.

### Why I made this
So you can compile Android Projects on Android without having to download AAPT2 
for your CPU Architecture and pass `-Pandroid.aapt2FromMavenOverride` over and over again.

### How it works
This is basically a wrapper for Gradle and GradleW.

### How to build
Requirements:
- Java 17
- Gradle 7.5.1

Open a terminal then do
`bash make.sh` 
then it will automatically compile.

Do `make.sh -h` for more options.
