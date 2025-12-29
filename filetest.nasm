; Testing file capabilities

%include "file.nasm"

section .data
    path: db "helloworld.nasm", 0
    path2: db "thing.nasm", 0

section .text
    global _start

    _start:
        lea rdi, [path]
        call readfile
        mov r12, rax
        mov rdi, rax
        call strlen
        mov rdx, rax
        mov rsi, r12
        lea rdi, [path2]
        call writefile
        jmp exit
