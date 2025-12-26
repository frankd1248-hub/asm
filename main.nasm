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

BITS 64
CPU X64

%include "utildefs.nasm"

section .data
    errormsg: db "NULL input", 0    ; Setup error message as global variable

section .text
    global _start

    _start:
        call inputwrapper           ; Get input
        cmp al, 27
        je .exit                    ; Exit program if ESC key pressed
        jmp _start

        .exit:
            call endl
            jmp exit

    inputwrapper:
        call getchar                ; Attempt to get a character from standard input
        cmp al, 0                   ; Emit error message if input is NULL
        je .error                   ; Go to error label

        ret

        .error:
            mov rdi, errormsg
            call puts               ; Print error message
            call endl               ; Print newline
            jmp exit                ; Exit program
