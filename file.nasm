; File handling functions (read/write)

%include "utildefs.nasm"

section .bss
    strbuf resb 2048                   ; Reserve 2KiB space for reading from file

section .text

    readfile:                          ; Expects file name in rdi
        mov rax, SYSOPEN
        lea rdi, [rdi]
        mov rsi, O_RDONLY
        xor rdx, rdx
        syscall                        ; open(rdi, O_RDONLY, 0)

        cmp rax, 0                     ; Return value negative if error happened
        jl .return

        mov r12, rax                   ; Save file ID

        mov rax, SYSREAD
        mov rdi, r12
        mov rsi, strbuf
        mov rdx, 2048                  ; Try to read a maximum of 2KiB
        syscall                        ; read(r12, &strbuf, 2048)

        mov rax, SYSCLOSE
        mov rdi, r12
        syscall                        ; close(r12)

        lea rax, [strbuf]              ; Return address of string buffer

        .return:
            ret