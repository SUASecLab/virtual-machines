#!/bin/bash

if [ ! -f dependencies/openjdk-17+35_linux-x64_bin.tar.gz ]; then
    wget -P dependencies https://download.java.net/openjdk/jdk17/ri/openjdk-17+35_linux-x64_bin.tar.gz
else
    echo "OpenJDK 17_35 already downloaded"
fi

if [ ! -f dependencies/apache-ant-1.10.14-bin.tar.gz ]; then
    wget -P dependencies https://dlcdn.apache.org//ant/binaries/apache-ant-1.10.14-bin.tar.gz
else
    echo "Ant 1.10.14 already downloaded"
fi

if [ ! -f dependencies/gcc-arm-none-eabi-9-2020-q2-update-x86_64-linux.tar.bz2 ]; then
    wget -P dependencies https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-rm/9-2020q2/gcc-arm-none-eabi-9-2020-q2-update-x86_64-linux.tar.bz2
else
    echo "ARM GCC already downloaded"
fi

if [ ! -f dependencies/mspgcc-4.7.2-compiled.tar.bz2 ]; then
    wget -P dependencies http://simonduq.github.io/resources/mspgcc-4.7.2-compiled.tar.bz2
else
    echo "MSP GCC already downloaded"
fi