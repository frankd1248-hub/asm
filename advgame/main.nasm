; Text-based adventure game written in x86_64 NASM assembly

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


;  Map of dungeon #1:
;
;  |-----------|-----------|-----  ----|
;  |    Gbl    |           |           |
;  |           |Gbl  X             Heal|
;  |           |           |           |
;  |-----  ----|----  -----|-----  ----|
;              |           |
;                      Gold|
;              |           |
;              |-----------|
;
;
;
;
;
;


BITS 64
CPU X64

%include "utildefs.nasm"
%include "math.nasm"

section .data
    hp: db 100
    diff: db 0

    err_nulinput: db "Error: NULL input.", 0

    pmt_dirc: db "1 (North), 2 (East), 3 (West), 4 (South): ", 0
    err_dirc: db "Invalid direction.", 0
    msg_nort: db "You walk North.", 0
    msg_east: db "You walk East.", 0
    msg_west: db "You walk West.", 0
    msg_sout: db "You walk South.", 0

    msg_0000: db "Welcome to the ASM Text Adventure Game!", 0
    pmt_0000: db "Choose difficulty: 1 (Easy), 2 (Hard) ", 0
    err_0000: db "Invalid input.", 0
    res_0000_1: db "You chose easy difficulty.", 0
    res_0000_2: db "You chose hard difficulty.", 0

    msg_0001: db "You wake up in a dark basement. Which direction do you go?", 0
    res_0001_1: db "It's a dead end.", 0
    res_0001_2: db "You enter another, seemingly identical room.", 0
    res_0001_3: db "You bump into a goblin, and he attacks!", 0
    res_0001_4: db "You enter another, seemingly identical room.", 0

    msg_0002: db "You are in a nondescript dark room. Where do you go?", 0
    res_0002_1: db "You enter another dark room.", 0
    res_0002_2: db "You find a healing potion!", 0
    res_0002_3: db "You go back to the starting room.", 0
    res_0002_4: db "You enter another dark room.", 0
    pmt_0002_2: db "Do you 1 (use it) or 2 (leave it)? ", 0

section .text
    global _start

    _start:
        call init
        sub rsp, 8
        call pregame
        call cls
        mov rdi, msg_0001
        call putsln
        call game_001
        call endl
        call restore_terminal
        add rsp, 8
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

    game_001:

        back:
        mov rdi, pmt_dirc
        call puts
        call getchar
        mov bl, al
        call endl
        cmp bl, 49
        je .north
        cmp bl, 50
        je .east
        cmp bl, 51
        je .west
        cmp bl, 52
        je .south

        .invalid:
            mov rdi, err_dirc
            call putsln
            mov rax, 0
            jmp game_001

        .north:
            mov rdi, msg_nort
            call putsln
            mov rdi, res_0001_1
            call putsln
            jmp back
            ret

        .east:
            mov rdi, msg_east
            call putsln
            mov rdi, res_0001_2
            call putsln
            call game_002
            ret

        .west:
            mov rdi, msg_west
            call putsln
            mov rdi, res_0001_3
            call putsln
            ret

        .south:
            mov rdi, msg_sout
            call putsln
            mov rdi, res_0001_4
            call putsln
            ret
        
    game_002:
        mov rdi, msg_0002
        call putsln
        mov rdi, pmt_dirc
        call puts
        call getchar
        mov bl, al
        call endl
        cmp bl, 49
        je .north
        cmp bl, 50
        je .east
        cmp bl, 51
        je .west
        cmp bl, 52
        je .south

        .invalid:
            mov rdi, err_dirc
            call putsln
            mov rax, 0
            jmp game_002
        
        .north:
        .east:
        .west:
        .south:

        ret