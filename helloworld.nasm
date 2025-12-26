; ABI CONVENTIONS SUMMARY
; caller-saved registers:
;    rax, rcx, rdx, rsi, rdi, r8, r9, r10, r11
; callee-saved registers:
;    rbx, rbp, r12, r13, r14, r15
; argument-passing order (int/ptr)
;    rdi -> rsi -> rdx -> rcx -> r8 -> r9
; return values:
;    rax
; RSP % 16 == 8 before call instruction
; RSP % 16 == 0 before syscall
; Linux enters _start with RSP % 16 == 0

BITS 64 ; 64 bit program
CPU X64 ; targeting x86_64 cpu

%include "utildefs.nasm"

section .data
    message: db "Hello, world", 0 ; Message to be printed

section .text
    global _start

    %define SYSCALL_EXIT 60
    %define SYSCALL_WRITE 1
    %define SYSOUT 1

    _start:
        sub rsp, 8
        call print_message          ; Print message "Hello, world!"
        call endl
        jmp exit                    ; Exit program

    print_message:
        mov rdi, message            ; Prepare call for puts
        call puts
        ret
