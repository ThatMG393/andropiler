# Introductuon
A ported version of [android-compiler](https://github.com/ThatMG393/android-compiler) to Java.

I ported android-compiler to Java because I was having trouble with the bash script, it kept having weird issues.
Please make an Issue if there is a bug or something else.

# Why I made this
So you can compile Android Projects on Android without having to download AAPT2 and pass `-Pandroid.aapt2FromMavenOverride` over and over again. 

# How it works
This is basically a wrapper for Gradle and Gradle Wrapper.

# Build requirements
- Java 17
- Gradle 7.2
And that's it.
