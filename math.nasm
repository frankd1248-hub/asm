; Math / Random functions

BITS 64
CPU X64

section .data
    state dq 10248926342346366

section .text

    rand:                        ; XOR-shift random number generator, deterministic
        mov     rax, [state]
        mov     rcx, rax
        shl     rcx, 13
        xor     rax, rcx
        mov     rcx, rax
        shr     rcx, 7
        xor     rax, rcx
        mov     rcx, rax
        shl     rcx, 17
        xor     rax, rcx
        mov     [state], rax
        ret

    randrange:                    ; A few more operations to get a random number in a range
        push rbx
        push rbp
        mov rax, rsi
        sub rax, rdi              ; Getting the correct maximum for after rand
        mov rbx, rax
        mov rbp, rdi              ; Saving lower bound for addition later
        call rand
        mov rdi, rax
        mov rsi, rbx
        call modulus              ; Limit random number to predetermined range
        add rax, rbp              ; Add the lower bound
        pop rbx
        pop rbp
        ret

    modulus:                      ; Just to make life easier
        mov rax, rdi
        xor rdx, rdx
        div rsi           
        mov rax, rdx
        ret

    ; Value from rax
    utoa:
        push    rbx                ; preserve callee-saved register

        mov     rbx, 10
        xor     rcx, rcx           ; digit count

        .convert:
            xor     rdx, rdx
            div     rbx                ; RAX /= 10, RDX = remainder
            add     dl, '0'
            push    rdx                ; push digit
            inc     rcx
            test    rax, rax
            jnz     .convert

        .write:
            mov     rax, rcx           ; return length

        .write_loop:
            pop     rdx
            mov     [rdi], dl
            inc     rdi
            loop    .write_loop

            mov     byte [rdi], 0      ; null terminator

            pop     rbx
            ret