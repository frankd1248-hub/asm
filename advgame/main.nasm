
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
;  |-----------|
;  |    Exit   |
;  |           |
;  |     7     |
;  |----  -----|-----------|-----------|
;  |    Gbl    |     1     |     2     |
;  |           |Gbl  X             Heal|
;  |     5     |           |           |
;  |-----  ----|----  -----|-----  ----|
;  |     6     |     3     |     4     |
;  |Gbl                Gold|           |
;  |    Heal   |    Heal   |    Gbl    |
;  |-----------|-----------|-----------|
;
;  (Far from implemented)


BITS 64
CPU X64

%include "file.nasm"
%include "math.nasm"
%include "advgame/messages.nasm"

section .data
    hp: db 100
    gold: dw 0
    diff: db 0

    heal2: db 1
    heal3: db 1
    heal6: db 1

    enemy1: db 1
    enemy4: db 1
    enemy5: db 1
    enemy6: db 1

    gold3: db 1

    enemyhp: db 0

section .text
    global _start

    _start:                                ; Main function
        sub rsp, 8                         ; Align stack
        call initutil                      ; Initialize terminal modes and other I/O things
        call initmath                      ; Install SIGINT handler
        call pregame                       ; Choosing difficulty, which affects fights
        call cls                           ; Clear screen after
        call game_001                      ; Game entry point (I could have named it better)
        call endl                          ; End line for clean terminal next line
        call restore_terminal              ; The game is about to exit, restore original terminal mode
        call savestate                     ; Save random state to ensure different random numbers next time
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
            mov rdi, err_dirc              ; Invalid input, emit error message
            call putsln
            mov rax, 0                     ; ????? (I don't remember why I did this)
            jmp game_001
            ret

        .north:
            mov rdi, msg_nort
            call putsln
            mov rdi, res_0001_1
            call putsln
            jmp back                       ; Dead end --> reprompt
            ret

        .east:
            mov rdi, msg_east
            call putsln
            mov rdi, res_0001_2
            call putsln
            call game_002                  ; Moved into another room --> call function
            ret

        .west:
            mov rdi, msg_west
            call putsln
            cmp byte [enemy1], 1
            je .enemy
            mov rdi, res_0001_3_v2
            call putsln
            jmp game_001
            ret

            .enemy:
                mov rdi, res_0001_3_v1
                call putsln
                mov rdi, 1000              ; Time for player to read message
                call sleep_ms
                call fight
                mov byte [enemy1], al      ; Fight enemy. Here, rax holds a boolean return value
                jmp game_001
                ret

        .south:
            mov rdi, msg_sout
            call putsln
            mov rdi, res_0001_4
            call putsln
            call game_003                  ; Move into another room --> Call function
            ret

    game_002:
        mov rdi, msg_0002
        call putsln
        mov rdi, pmt_dirc
        call puts
        call getchar
        mov bl, al                         ; Again, save input from clobbering
        call endl
        cmp bl, 49
        je .north                          ; Room
        cmp bl, 50
        je .east                           ; Healing
        cmp bl, 51
        je .west                           ; Starting room
        cmp bl, 52
        je .south                          ; Room

        .invalid:
            mov rdi, err_dirc
            call putsln
            mov rax, 0                     ; WTF? I mean it works so I won't touch it
            jmp game_002
            ret

        .north:
            mov rdi, msg_nort
            call putsln
            mov rdi, res_0002_1
            call putsln
            ret                            ; Eventually there will be a function call here

        .east:
            cmp byte [heal2], 1             ; Only prompt the player if the potion is there
            je .pot
            jne .nopot
            ret                            ; I don't actually think I need this but I'm too scared to remove it

            .nopot:
                mov rdi, msg_east
                call putsln
                mov rdi, res_0002_2_v2
                call putsln
                jmp game_002               ; Potion already used, go back to room
                ret

            .pot:
                mov rdi, msg_east
                call putsln
                mov rdi, res_0002_2_v1
                call putsln
                mov rdi, pmt_pot           ; Prompt if player wants to use potion
                call puts
                call getchar
                mov bl, al                 ; Agaaaaain, to save from clobbering
                call endl
                cmp bl, 49                 ; Heal the player and delete the potion
                je .use
                cmp bl, 50                 ; Clean up and leave the potion
                je .leav
                jmp ._invalid
                ret

            ._invalid:
                mov rdi, err_pot           ; Invalid input, emit error message
                call putsln
                jmp .east
                ret

            .use:
                mov rdi, res_pot_1
                call putsln
                add byte [hp], 75          ; Try to heal 75HP
                cmp byte [hp], 100         ; Did I overshoot?
                jg .set
                jng .done

                .set:
                    mov byte [hp], 100     ; I did overshoot.

                .done:
                    mov byte [heal2], 0     ; Delete the potion

                jmp game_002
                ret

            .leav:
                mov rdi, res_pot_2         ; Leave the potion there.
                call putsln
                jmp game_002
                ret

            ret

        .west:
            mov rdi, msg_west
            call putsln
            mov rdi, res_0002_3
            call putsln
            call game_001                  ; Go back to the starting room
            ret

        .south:
            mov rdi, msg_sout
            call putsln
            mov rdi, res_0002_4
            call putsln
            jmp game_002
            ret                            ; Eventually there will be a function call here

        ret

    game_003:
        mov rdi, msg_0003
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
            jmp game_003

        .north:
            mov rdi, msg_nort
            call putsln
            mov rdi, res_0003_1
            call putsln
            call game_001
            ret

        .east:
            mov rdi, msg_east
            call putsln
            jmp .gold
            jmp game_003
            ret

        .west:
            mov rdi, msg_west
            call putsln
            mov rdi, res_0003_3
            call putsln
            ret

        .south:
            mov rdi, msg_sout
            call putsln
            jmp .pot
            jmp game_003
            ret

        .gold:
            cmp byte [gold3], 1
            jne .nogold
            mov rdi, res_0003_2_v1
            call putsln
            add word [gold], 50
            mov byte [gold3], 0
            jmp game_003
            ret

        .nogold:
            mov rdi, res_0003_2_v2
            call putsln
            jmp game_003
            ret

        .pot:
            cmp byte [heal3], 1
            jne .nopot
            mov rdi, res_0003_4_v1
            call putsln
            mov rdi, pmt_pot
            call puts
            call getchar
            mov bl, al
            call endl
            cmp bl, 49
            je .use
            cmp bl, 50
            je .leav

            ._invalid:
                mov rdi, err_pot
                call putsln
                jmp .pot
                ret

            .use:
                mov rdi, res_pot_1
                call putsln
                add byte [hp], 75          ; Try to heal 75HP
                cmp byte [hp], 100         ; Did I overshoot?
                jg .set
                jng .done

                .set:
                    mov byte [hp], 100     ; I did overshoot.

                .done:
                    mov byte [heal2], 0     ; Delete the potion

                jmp game_003
                ret

            .leav:
                mov rdi, res_pot_2
                call putsln
                jmp game_003
                ret

        .nopot:
            mov rdi, res_0003_4_v2
            call putsln
            jmp game_003
            ret

        ret

    fight:                                 ; Woah, this is long.
        mov byte [enemyhp], 100            ; Set the enemy health
        cmp byte [diff], 2                 ; If on hard mode, double enemy health.
        je .increase

        .loop:
            call cls                       ; Very big block of messages.
            mov rdi, msg_fight_01_1
            call puts
            lea rdi, [strbuf]
            mov al, [hp]                   ; Prompt the player with their HP
            call utoa
            lea rdi, [strbuf]
            call puts
            mov rdi, msg_fight_01_2
            call puts
            lea rdi, [strbuf]
            mov al, [enemyhp]              ; Prompt the player with enemy's HP
            call utoa
            lea rdi, [strbuf]
            call putsln

            mov rdi, msg_fight_02
            call putsln
            mov rdi, pmt_fight_02          ; Prompt the player for an action
            call puts
            call getchar
            mov bl, al
            call endl
            cmp bl, 49
            je .attack                     ; player wants to attack the enemy
            cmp bl, 50
            je .block                      ; player wants to heal for 8HP
            cmp bl, 51
            je .escape                     ; player wants to attempt to escape the battle (leaves the enemy there)

            mov rdi, err_fight_02          ; Error message
            call putsln
            mov rdi, 1000
            call sleep_ms                  ; Go straight to the enemy's turn, no re-input.

        .enemyturn:
            mov rdi, 4
            mov rsi, 13
            call randrange                 ; Random number for enemy's attack damage
            mov bl, al                     ; Aaaaaaagggggaaaaaiiiin, save it from clobbering.
            sub [hp], bl                   ; Decrease player's health
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
            call sleep_ms                  ; Go straight to win detection

        .after:
            cmp byte [hp], 0               ; If player's hp is equal to or less than 0, they lost
            jng .loss
            cmp byte [enemyhp], 0          ; If enemy's hp is equal to or less than 0, the player wins
            jng .win
            jg  .loop                      ; Otherwise, do another round

        .loss:
            mov rdi, res_fight_01
            call putsln
            jmp exit                       ; Exit the game, no redos.

        .win:
            mov rdi, res_fight_02
            call putsln
            mov rax, 0                     ; Remove the enemy
            ret

        .increase:
            add byte [enemyhp], 100
            jmp .loop

        .attack:
            mov rdi, 8
            mov rsi, 23
            call randrange                 ; Random number for player's attack damage
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
            mov rdi, 1000
            call sleep_ms
            jmp .heal

        .heal:
            add byte [hp], 8
            cmp byte [hp], 100
            jg .set
            jmp .loop

        .set:
            mov byte [hp], 100
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
