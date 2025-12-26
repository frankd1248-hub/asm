#!/bin/bash

rm $1.o
rm $1
nasm -f elf64 -g $1.nasm
ld $1.o -static -o $1
./$1