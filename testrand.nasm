BITS 64
CPU X64

%include "math.nasm"
%include "utildefs.nasm"

section .bss
    strbuf resb 8

section .text
    global _start

    _start:
        sub rsp, 8
        mov r15, 0
        .begin:
            mov rdi, 100
            mov rsi, 200
            call randrange
            lea rdi, [strbuf]
            call utoa
            lea rdi, [strbuf]
            call puts
            mov dil, ','
            call putchar
            mov dil, ' '
            call putchar
            inc r15
            lea rdi, [strbuf]
            mov rax, r15
            call utoa
            lea rdi, [strbuf]
            call putsln
            cmp r15, 100
        jne .begin
        add rsp, 8
        jmp exit