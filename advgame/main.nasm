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
    res_0000_1: db "You chose easy difficulty.", 0
    res_0000_2: db "You chose hard difficulty.", 0

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

        .getinput:
        mov rdi, pmt_0000
        call puts
        call getchar
        mov bl, al
        call endl
        cmp bl, 0
        je .nullinput
        cmp bl, 49
        je .Easy
        cmp bl, 50
        je .Hard

        .invalid:
        mov rdi, err_0000
        call putsln
        mov rax, 0
        jmp .getinput

        .done:
        call endl
        jmp exit

        .nullinput:
        mov rdi, err_nulinput
        call putsln
        jmp .getinput

        .Easy:
        mov byte [diff], 1
        mov rdi, res_0000_1
        call putsln
        ret

        .Hard:
        mov byte [diff], 2
        mov rdi, res_0000_2
        call putsln
        ret

