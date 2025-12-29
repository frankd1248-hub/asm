; Testing file capabilities

%include "file.nasm"

section .data
    path: db "helloworld.nasm", 0

section .text
    global _start

    _start:
        sub rsp, 8
        lea rdi, [path]
        call readfile
        mov rdi, rax
        call putsln
        add rsp, 8
        jmp exit
