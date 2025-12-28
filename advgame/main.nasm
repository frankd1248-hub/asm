; Text-based adventure game written in x86_64 NASM assembly
; Developing this was...

; ABI CONVENTIONS SUMMARY
; caller-saved registers:
;    rax, rcx, rdx, rsi, rdi, r8, r9, r10, r11
; callee-saved registers:
;    rbx, rbp, r12, r13, r14, r15
; argument-passing order (int/ptr)
;    rdi -> rsi -> rdx -> rcx -> r8 -> r9
; return values:
;    rax

; STACK ALIGNMENT SUMMARY
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

section .bss
    strbuf resb 16

section .data
    hp: db 100
    diff: db 0
    heal: db 1
    enemy0: db 1
    enemyhp: db 0

    ; Big-ass block of messages. I could probably make this whole thing better, but I really don't want to.

    err_nulinput: db "Error: NULL input.", 0

    pmt_dirc: db "1 (North), 2 (East), 3 (West), 4 (South): ", 0
    err_dirc: db "Invalid direction.", 0
    msg_nort: db "You walk North.", 0
    msg_east: db "You walk East.", 0
    msg_west: db "You walk West.", 0
    msg_sout: db "You walk South.", 0

    msg_fight_01_1: db "Your HP: ", 0
    msg_fight_01_2: db ", Enemy HP: ", 0
    msg_fight_02: db "What do you do?", 0
    pmt_fight_02: db "1 (Attack), 2 (Block), 3 (Run)", 0
    err_fight_02: db "You got a bit confused and whacked yourself in the face.", 0
    res_fight_02_1_1: db "You dealt ", 0
    res_fight_02_1_2: db " damage! current Enemy HP: ", 0
    res_fight_02_2: db "You blocked the oncoming attack!", 0
    res_fight_02_3_1: db "You failed to escape the battle.", 0
    res_fight_02_3_2: db "You escape the battle.", 0
    msg_fight_03_1: db "The enemy deals ", 0
    msg_fight_03_2: db " damage!", 0
    res_fight_01: db "You lost...", 0
    res_fight_02: db "You won!", 0

    msg_0000: db "Welcome to the Assembly Text Adventure Game!", 0
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
    res_0002_2_v1: db "You find a healing potion!", 0
    res_0002_2_v2: db "It's a dead end.", 0
    res_0002_3: db "You go back to the starting room.", 0
    res_0002_4: db "You enter another dark room.", 0

    pmt_0002_2: db "Do you 1 (use it) or 2 (leave it)? ", 0
    err_0002_2: db "Invalid iniput.", 0
    res_0002_2_1: db "You drank the potion.", 0
    res_0002_2_2: db "You left the potion where it is.", 0

section .text
    global _start

    _start:                                ; Main function
        sub rsp, 8                         ; Align stack
        call init                          ; Initialize terminal modes and other I/O things
        call pregame                       ; Choosing difficulty, which affects fights
        call cls                           ; Clear screen after
        call game_001                      ; Game entry point (I could have named it better)
        call endl
        call restore_terminal              ; The game is about to exit, restore original terminal mode
        add rsp, 8                         ; Re-align stack
        jmp exit                           ; Literally just a syscall

    pregame:
        mov rdi, msg_0000                  ; Print first message
        call putsln

        .getinput:
            mov rdi, pmt_0000              ; Print prompt
            call puts
            call getchar
            mov bl, al                     ; rax gets clobbered by endl, move to rbx for safety
            call endl
            cmp bl, 0                      ; Input is NULL, emit error message
            je .nullinput
            cmp bl, 49                     ; Input is 1, easy mode
            je .Easy
            cmp bl, 50                     ; Input is 2, hard mode
            je .Hard

        .invalid:
            mov rdi, err_0000              ; Invalid input, emit error message
            call putsln
            mov rax, 0
            jmp .getinput                  ; Get input again
            ret

        .nullinput:
            mov rdi, err_nulinput          ; NULL input, emit error message
            call putsln
            jmp .getinput                  ; Get input again

        .Easy:
            mov byte [diff], 1             ; Set difficulty to 1
            mov rdi, res_0000_1            ; Print a message
            call putsln
            jmp .done

        .Hard:
            mov byte [diff], 2             ; Set difficulty to 2
            mov rdi, res_0000_2            ; Print a message
            call putsln
            jmp .done

        .done:
            mov rdi, 1000                  ; Do a delay so that the player can read the message
            call sleep_ms
            ret

    game_001:
        mov rdi, msg_0001                  ; Basements...
        call putsln

        back:
            mov rdi, pmt_dirc              ; Which direction?
            call puts
            call getchar
            mov bl, al                     ; Save value from clobbering
            call endl
            cmp bl, 49
            je .north                      ; Dead end
            cmp bl, 50
            je .east                       ; Room
            cmp bl, 51
            je .west                       ; Fight
            cmp bl, 52
            je .south                      ; Room

        .invalid:
            mov rdi, err_dirc
            call putsln
            mov rax, 0
            jmp game_001
            ret

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
            mov rdi, 1000
            call sleep_ms
            call fight
            mov [enemy0], rax
            jmp game_001

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
            ret
        
        .north:
            mov rdi, msg_nort
            call putsln
            mov rdi, res_0002_1
            call putsln
            ret

        .east:
            cmp byte [heal], 1
            je .pot
            jne .nopot
            ret

            .nopot:
                mov rdi, msg_east
                call putsln
                mov rdi, res_0002_2_v2
                call putsln
                jmp game_002
                ret

            .pot:
                mov rdi, msg_east
                call putsln
                mov rdi, res_0002_2_v1
                call putsln
                mov rdi, pmt_0002_2
                call puts
                call getchar
                mov bl, al
                call endl
                cmp bl, 49
                je .use
                cmp bl, 50
                je .leav
                jmp ._invalid
                ret

            ._invalid:
                mov rdi, err_0002_2
                call putsln
                jmp .east
                ret
            
            .use:
                mov rdi, res_0002_2_1
                call putsln
                add byte [hp], 75
                cmp byte [hp], 100
                jg .set
                jng .done

                .set:
                    mov byte [hp], 100
                
                .done:
                    mov byte [heal], 0
                
                jmp game_002
                ret

            .leav:
                mov rdi, res_0002_2_2
                call putsln
                jmp game_002
                ret

            ret

        .west:
            mov rdi, msg_west
            call putsln
            mov rdi, res_0002_3
            call putsln
            call game_001
            ret

        .south:
            mov rdi, msg_sout
            call putsln
            mov rdi, res_0002_4
            call putsln
            jmp game_002
            ret

        ret

    fight:
        mov byte [enemyhp], 100
        cmp byte [diff], 2
        je .increase

        .loop:
            call cls
            mov rdi, msg_fight_01_1
            call puts
            lea rdi, [strbuf]
            mov al, [hp]
            call utoa
            lea rdi, [strbuf]
            call puts
            mov rdi, msg_fight_01_2
            call puts
            lea rdi, [strbuf]
            mov al, [enemyhp]
            call utoa
            lea rdi, [strbuf]
            call putsln

            mov rdi, msg_fight_02
            call putsln
            mov rdi, pmt_fight_02
            call puts
            call getchar
            mov bl, al
            call endl
            cmp bl, 49
            je .attack
            cmp bl, 50
            je .block
            cmp bl, 51
            je .escape

            mov rdi, err_fight_02
            call putsln

        .enemyturn:
            mov rdi, 4
            mov rsi, 15
            call randrange
            mov bl, al
            sub [hp], bl
            mov rdi, msg_fight_03_1
            call puts
            lea rdi, [strbuf]
            mov al, bl
            call utoa
            lea rdi, [strbuf]
            call puts
            mov rdi, msg_fight_03_2
            call putsln
            mov rdi, 750
            call sleep_ms

        .after:

            cmp byte [hp], 0
            jng .loss
            cmp byte [enemyhp], 0
            jng .win
            jmp .loop
        
        .loss:
            mov rdi, res_fight_01
            call putsln
            jmp exit
        
        .win:
            mov rdi, res_fight_02
            call putsln
            mov rax, 0
            ret

        .increase:
            add byte [enemyhp], 100
            jmp .loop

        .attack:
            mov rdi, 8
            mov rsi, 23
            call randrange
            mov bl, al
            sub [enemyhp], bl
            mov rdi, res_fight_02_1_1
            call puts
            lea rdi, [strbuf]
            mov al, bl
            call utoa
            lea rdi, [strbuf]
            call puts
            mov rdi, res_fight_02_1_2
            call puts
            lea rdi, [strbuf]
            mov al, [enemyhp]
            call utoa
            lea rdi, [strbuf]
            call putsln
            jmp .enemyturn
        
        .block:
            mov rdi, res_fight_02_2
            call putsln
            jmp .loop

        .escape:
            mov rdi, 1
            mov rsi, 20
            call randrange
            cmp al, 15
            je .success
            mov rdi, res_fight_02_3_1
            call putsln
            jmp .enemyturn
        
        .success:
            mov rdi, res_fight_02_3_2
            call putsln
            mov rax, 1
            ret

