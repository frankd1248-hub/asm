; File handling functions (read/write)

%ifndef FILE_NASM_
%define FILE_NASM_

%include "utildefs.nasm"

section .bss
    strbuf resb 2049                   ; Reserve 2KiB space for reading from file and null termination

section .text

    readfile:                          ; rdi = filename
        push r12

        mov rax, SYSOPEN
        mov rsi, O_RDONLY
        xor rdx, rdx
        syscall                        ; open(rdi, O_RDONLY, 0)

        cmp rax, 0
        jl .return

        mov r12, rax                   ; save fd

        mov rax, SYSREAD
        mov rdi, r12
        mov rsi, strbuf
        mov rdx, 2048
        syscall                        ; rax = bytes read

        cmp rax, 0
        jl .close                      ; read error

        ; ---- null-terminate ----
        mov byte [strbuf + rax], 0

        .close:
            mov rax, SYSCLOSE
            mov rdi, r12
            syscall

        lea rax, [strbuf]              ; return buffer pointer

        .return:
            pop r12
            ret


    writefile:                         ; Expects file name in rdi, contents to be written in rsi, length in rdx.
        push r12
        push r13
        push r15

        mov r15, rdx
        mov r13, rsi                   ; Save from clobbering by literally everything

        mov rax, SYSOPEN
        mov rsi, WCTRUNCT
        mov rdx, 0644o                 ; rw-r--r--
        syscall                        ; open(rdi, WCTRUNCT, 0644)

        cmp rax, 0                     ; Return value negative if error happened
        jl .return

        mov r12, rax                   ; Save file ID

        mov rax, SYSWRITE
        mov rdi, r12
        mov rsi, r13
        mov rdx, r15
        syscall

        cmp rax, 0
        jl .close

        .close:
            mov rax, SYSCLOSE
            mov rdi, r12
            syscall                        ; close(r12)

        .return:
            pop r15
            pop r13
            pop r12
            ret

%endif
