#!/bin/bash

#
# Builds, links, and runs a nasm file
# Does not include libc

nasm -f elf64 -g $1.asm
ld $1.o -static -o $1
./$1
