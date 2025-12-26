BITS 64
CPU X64

%include "math.nasm"
%include "utildefs.nasm"

section .bss
    strbuf resb 8

section .text
    global _start

    _start:
        mov rdi, 100
        mov rsi, 200
        call randrange
        lea rdi, [strbuf]
        call utoa
        lea rdi, [strbuf]
        call putsln
        jmp _start