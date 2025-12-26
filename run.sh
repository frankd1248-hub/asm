#!/bin/bash

nasm -f elf64 -g $1.nasm -w+implicit-abs-deprecated
ld $1.o -static -o $1 -w+implicit-abs-deprecated
./$1