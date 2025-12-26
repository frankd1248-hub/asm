; Text-based adventure game written in x86_64 NASM assembly

BITS 64
CPU X64

%include "utildefs.nasm"
%include "math.nasm"

section .data
    hp: db 100
    diff: db 0

    err_nulinput: db "Error: NULL input.", 0

    msg_0000: db "Welcome to the ASM Text Adventure Game!", 0
    pmt_0000: db "Choose difficulty: 1 (Easy), 2 (Hard) ", 0
    err_0000: db "Invalid input.", 0

section .text
    global _start

    _start:
        call init
        call pregame
        call endl
        call restore_terminal
        jmp exit

    pregame:
        mov rdi, msg_0000
        call putsln
        mov rdi, pmt_0000

        .getinput:
        call puts
        call getchar
        cmp al, 0
        je .nullinput
        cmp al, 49
        je .Easy
        cmp al, 50
        je .Hard

        mov rdi, err_0000
        call putsln
        jmp .getinput

        call endl
        jmp exit

        .nullinput:
        mov rdi, err_nulinput
        call putsln
        call restore_terminal
        jmp exit

        .Easy:
        mov byte [diff], 1
        ret

        .Hard:
        mov byte [diff], 2
        ret

