; Math / Random functions

BITS 64
CPU X64

%include "file.asm"

section .bss
    statebuf resb 32

section .data
    state dq 10248926342346366829

    statepath: db "~/Documents/rand.state", 0

    sigaction_int:                 ; Linux sigaction struct
        dq sigint_handler          ; void *sa_handler(int)
        dq SA_RESTORER             ; ???
        dq sigrestorer             ; void *sa_restorer(int)?
        times 16 dq 0              ; sigset_t sa_mask

section .text

    initmath:
        ; Install SIGINT handler (Ctrl-C)
        mov rax, SYS_RT_SIGACTION
        mov rdi, SIGINT
        lea rsi, [sigaction_int]
        xor rdx, rdx
        mov r10, 8
        syscall

    rand:                              ; XOR-shift random number generator, deterministic and fast
        mov     rax, [state]           ; Key to the generator being deterministic
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

    savestate:
        mov rax, [state]
        lea rdi, [statebuf]
        call utoa                      ; Get string for writing to file
        lea rdi, [statebuf]
        call strlen                    ; Get length for writing to file
        mov rdx, rax
        mov rsi, rdi
        lea rdi, [statepath]
        call writefile

    ; lwr -> rdi, upr -> rsi
    randrange:                         ; A few more operations to get a random number in a range
        push rbx
        push rbp
        mov rax, rsi
        sub rax, rdi                   ; Getting the correct maximum for after rand
        mov rbx, rax
        mov rbp, rdi                   ; Saving lower bound for addition later
        call rand
        mov rdi, rax
        mov rsi, rbx
        call modulus                   ; Limit random number to predetermined range
        add rax, rbp                   ; Add the lower bound
        pop rbx
        pop rbp
        ret

    modulus:                           ; Just to make life easier rdi rsi
        mov rax, rdi
        xor rdx, rdx                   ; Clear remainder register
        div rsi                        ; rax -> quotient, rdx -> remainder
        mov rax, rdx
        ret

    ; Value from rax, String pointer in rdi
    utoa:
        push    rbx                    ; preserve callee-saved register

        mov     rbx, 10
        xor     rcx, rcx               ; digit count

        .convert:
            xor     rdx, rdx
            div     rbx                ; RAX /= 10, RDX = remainder
            add     dl, '0'
            push    rdx                ; push digit
            inc     rcx                ; Increment digit count
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

    strto64:
        xor rax, rax        ; result = 0
        xor rcx, rcx        ; index
        mov rbx, 1          ; sign = +1

        mov dl, [rdi]
        cmp dl, '-'
        jne .parse
        mov rbx, -1
        inc rdi

        .parse:
            mov dl, [rdi + rcx]
            test dl, dl
            jz .done

            cmp dl, '0'
            jb .done
            cmp dl, '9'
            ja .done

            imul rax, rax, 10
            sub dl, '0'
            add rax, rdx

            inc rcx
            jmp .parse

        .done:
            imul rax, rbx
            ret

    sigint_handler:
        ; Restore terminal state
        mov rax, SYSIOCTL
        mov rdi, STDIN
        mov rsi, TCSETS
        lea rdx, [orig_termios]
        syscall

        ; Save random state
        ; ...
        ; Oh no.

        ; Convert state number to string
        mov     rax, [state]
        lea     rdi, [statebuf]
        mov     rbx, 10
        xor     rcx, rcx               ; digit count
        .convert:
            xor     rdx, rdx
            div     rbx                ; RAX /= 10, RDX = remainder
            add     dl, '0'
            push    rdx                ; push digit
            inc     rcx                ; Increment digit count
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

        ; Count length of said string
        lea rdi, [statebuf]
        xor rax, rax                   ; length = 0
        .loop:
            cmp byte [rdi + rax], 0
            je .done
            inc rax
            jmp .loop
        .done:
            mov rdx, rax
            mov rsi, rdi
            lea rdi, [statepath]

        ; Write said string to the file
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
            mov rax, SYSWRITE
            mov rdi, STDOUT
            lea rsi, [newl_ch]
            mov rdx, 1
            syscall

            mov rax, SYSEXIT
            mov rdi, RET_SIGINT
            syscall
