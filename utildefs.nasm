; Utilities functions for use in other programs

BITS 64
CPU X64

section .data
    newline db 0xA                 ; Newline character
    lennl equ $-newline            ; Length of newline character (kind of pointless)

section .text

    %define SYSREAD   0            ; System read call id
    %define SYSWRITE  1            ; System write call id
    %define SYSIOCTL 16            ; System I/O control call id
    %define SYSEXIT  60            ; System exit call id

    %define STDIN     0            ; Standard input stream id
    %define STDOUT    1            ; Standard output stream id

    %define TCGETS      0x5401     ; Terminal get
    %define TCSETS      0x5402     ; Terminal set

    %define ICANON      0x0002     ; Canonical/raw terminal flag
    %define ECHO        0x0008     ; Echo on/off flag

    exit:
        mov rax, SYSEXIT           ; Prepare to call exit function
        mov rdi, 0                 ; Return value
        syscall                    ; Call

    ; puts one character onto the terminal.
    ; Parameters:
    ;   ch -- expected in rdi.
    putchar:
        push rbp                   ; Preparing stack
        mov rbp, rsp

        sub rsp, 1                 ; Reserve space for one character
        mov BYTE [rsp+0], dil      ; Push one character (ASCII)

        mov rax, SYSWRITE
        mov rdi, STDOUT
        lea rsi, [rsp]
        mov rdx, 1
        syscall                    ; Write one character

        add rsp, 1
        pop rbp                    ; Reset stack to state before call
        ret

    endl:
        mov rax, SYSWRITE          ; Prepare to call syswrite
        mov rdi, STDOUT            ; Write to standard out
        mov rsi, newline           ; Move newline character to arguments
        mov rdx, lennl             ; Declare length of message
        syscall                    ; Call syswrite
        ret

    puts:
        push rbx                   ; puts will use rbx internally for the string
        mov rbx, rdi               ; Moves the character array pointer to rbx
    
        .loop:
            cmp byte[rbx], 0       ; String is hopefully null-terminated
            je .done

            mov dil, byte[rbx]     ; Get individual character for processing
            call putchar           ; Print one character

            inc rbx                ; Advance to next character
            jmp .loop              ; Loop again

        .done:
            pop rbp                ; Release internally used register
            ret

    getchar:
        ; --- prologue (ABI) ---
        push rbp
        mov  rbp, rsp              ; Setup stack frame
        sub  rsp, 128              ; local storage, 16-byte aligned

        ; Layout:
        ; rbp-128 .. rbp-69  : term_old (60 bytes)
        ; rbp-68  .. rbp-9   : term_new (60 bytes)
        ; rbp-1              : char buffer (1 byte)

        lea r12, [rbp-128]         ; term_old
        lea r13, [rbp-68]          ; term_new
        lea r14, [rbp-1]           ; char buffer

        ; --- ioctl(STDIN, TCGETS, term_old) ---
        mov rax, SYSIOCTL          ; Prepares call
        mov rdi, STDIN
        mov rsi, TCGETS
        mov rdx, r12
        syscall                    ; Calls ioctl(0, TCGETS, &term_old)
        test rax, rax              ; ioctl returns negative value on error
        js .error

        ; --- copy term_old -> term_new ---
        mov rcx, 60
        mov rsi, r12
        mov rdi, r13
        rep movsb                  ; Essentially calls memcpy(term_new, term_old, 60)

        ; --- disable ICANON | ECHO ---
        mov eax, [r13 + 12]        ; Loads c_lflag
        and eax, ~(ICANON | ECHO)  ; Bytewise input, and not printed automatically
        mov [r13 + 12], eax        ; Write modified flags to term_new

        ; --- ioctl(STDIN, TCSETS, term_new) ---
        mov rax, SYSIOCTL
        mov rdi, STDIN
        mov rsi, TCSETS
        mov rdx, r13
        syscall                    ; Calls ioctl(0, TCSETS, term_new), switches terminal to raw mode

        ; --- read(STDIN, &ch, 1) ---
        mov rax, SYSREAD
        mov rdi, STDIN
        mov rsi, r14
        mov rdx, 1
        syscall                    ; Blocks and reads one byte when available
        cmp rax, 1                 ; Ensure only one byte was read
        jne .restore_error

        mov al, byte [r14]         ; save return char

        .restore:
            mov al, byte [r14]
            mov byte [rbp-2], al   ; save return value

            ; restore terminal
            mov rax, SYSIOCTL
            mov rdi, STDIN
            mov rsi, TCSETS
            mov rdx, r12
            syscall

            mov al, byte [rbp-2]   ; restore return value
            leave
            ret

        .restore_error:
            xor al, al             ; Ensures return value of 0 (NULL)
            jmp .restore           ; Restores terminal

        .error:
            xor al, al             ; Early error handling, before raw terminal.
            leave
            ret