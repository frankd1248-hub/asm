; Utilities functions for use in other programs

; List of functions:
; init(void); initializes for other functions
; sleep_ms(int -> rdi); Sleeps for some number of milliseconds
; exit(void); Exits program via a syscall
; cls(void); Clears terminal via ANSI escape codes
; putchar(int -> rdi); Prints one character
; puts(char* -> rdi); Prints a string
; putsln(char* -> rdi) Prints a string followed by a newline
; endl(void); Prints a newline character
; getchar(void) -> int -> rax; Gets one character and temporarily sets terminal to raw mode
;
; All others are only for internal use.


BITS 64
DEFAULT REL
CPU X64

%define SYSREAD   0                ; System read call id
%define SYSWRITE  1                ; System write call id
%define SYSIOCTL 16                ; System I/O control call id
%define SYSNANOSLEEP 35            ; System sleep nanoseconds call id
%define SYSEXIT  60                ; System exit call id

%define STDIN     0                ; Standard input stream id
%define STDOUT    1                ; Standard output stream id

%define TCGETS      0x5401         ; Terminal get
%define TCSETS      0x5402         ; Terminal set

%define ICANON      0x0002         ; Canonical/raw terminal flag
%define ECHO        0x0008         ; Echo on/off flag

%define SIGSEGV  11                ; Segmentation fault signal
%define SA_RESTORER 0x04000000

%define SYS_RT_SIGACTION 13

%define RET_SIGSEGV 139            ; Segmentation fault return value

struc timespec
    .tv_sec   resq 1
    .tv_nsec  resq 1
endstruc

section .bss
    orig_termios resb 64
    sleep_req resb timespec_size
    sleep_rem resb timespec_size

section .data
    clear_seq db 27, "[2J", 27, "[H"
    clear_len equ $ - clear_seq

    sigaction:                     ; Linux sigaction struct
        dq sigsegv_handler         ;
        dq SA_RESTORER             ;
        dq sigrestorer             ;
        times 16 dq 0              ;

section .text

    init:
        mov rax, SYSIOCTL          ; Initialize original terminal to ensure we don't recover to garbage.
        mov rdi, STDIN
        mov rsi, TCGETS
        lea rdx, [orig_termios]
        syscall                    ; ioctl(STDIN, TCGETS, &term_old)

        mov rax, SYS_RT_SIGACTION  ; Install segmentation fault handler
        mov rdi, SIGSEGV
        lea rsi, [sigaction]
        xor rdx, rdx
        mov r10, 8
        syscall
        ret

    sleep_ms:
        ; Convert milliseconds → seconds + nanoseconds
        mov     rax, rdi
        xor     rdx, rdx
        mov     rcx, 1000
        div     rcx                 ; RAX = sec, RDX = ms remainder

        mov     [sleep_req + timespec.tv_sec], rax

        mov     rax, rdx
        mov     rcx, 1_000_000
        mul     rcx                 ; ms -> ns
        mov     [sleep_req + timespec.tv_nsec], rax

        .sleep_loop:
            mov     rax, SYSNANOSLEEP
            lea     rdi, [sleep_req]
            lea     rsi, [sleep_rem]
            syscall

            test    rax, rax
            jns     .done           ; success

            cmp     rax, -4         ; -EINTR
            jne     .done           ; other error -> return

            ; retry with remaining time
            mov     rax, [sleep_rem + timespec.tv_sec]
            mov     [sleep_req + timespec.tv_sec], rax
            mov     rax, [sleep_rem + timespec.tv_nsec]
            mov     [sleep_req + timespec.tv_nsec], rax
            jmp     .sleep_loop

        .done:
            ret

    exit:
        mov rax, SYSEXIT           ; Prepare to call exit function
        mov rdi, 0                 ; Return value
        syscall                    ; Call

    cls:
        mov eax, 1                 ; sys_write
        mov edi, 1                 ; stdout
        lea rsi, [clear_seq]       ; ANSI escape characters to clear the screen and place the cursor on the corner
        mov edx, clear_len         ; Length of sequence
        syscall
        ret

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
        mov rdi, 10
        call sleep_ms
        ret

    endl:
        mov dil, 0xA               ; Newline character
        call putchar
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
            pop rbx                ; Release internally used register
            ret

    putsln:
        call puts
        call endl
        ret
    
    getchar:
        push rbp
        mov  rbp, rsp              ; Setup stack frame
        sub  rsp, 128              ; Reserve 128b (8B) of storage

        push r12
        push r13
        push r14

        lea r12, [orig_termios]    ; old terminal
        lea r13, [rbp-68]          ; new terminal
        lea r14, [rbp-1]           ; character input

        ; ioctl TCGETS, stores the current terminal config in r12
        mov rax, SYSIOCTL
        mov rdi, STDIN
        mov rsi, TCGETS
        mov rdx, r12
        syscall                    ; ioctl(STDIN, TCGETS, &term_old)
        test rax, rax
        js .fail

        ; copy old → new
        mov rcx, 60
        mov rsi, r12
        mov rdi, r13
        rep movsb

        ; disable ICANON | ECHO, enter raw mode, input not automatically printed
        mov eax, [r13 + 12]
            and eax, ~(ICANON | ECHO)
        mov [r13 + 12], eax

        ; ioctl TCSETS, Sets terminal to new configuration
        mov rax, SYSIOCTL
        mov rdi, STDIN
        mov rsi, TCSETS
        mov rdx, r13
        syscall                    ; ioctl(STDIN, TCSETS, term_new)

        ; read char
        mov rax, SYSREAD
        mov rdi, STDIN
            mov rsi, r14
        mov rdx, 1
        syscall                    ; read(STDIN, &char, 1)
        cmp rax, 1
        jne .restore_fail

        .restore:
            ; restore terminal
            mov rax, SYSIOCTL
            mov rdi, STDIN
            mov rsi, TCSETS
            mov rdx, r12
            syscall                ; ioctl(STDIN, TCSETS, term_old)

            mov al, byte [r14]

        .cleanup:
            pop r14
            pop r13
            pop r12
            leave                  ; Reset stack
            ret

        .restore_fail:
            xor al, al             ; Ensure return of 0 (NULL)
            jmp .restore

        .fail:
            xor al, al             ; Ditto
            jmp .cleanup


    restore_terminal:
        mov rax, SYSIOCTL
        mov rdi, STDIN
        mov rsi, TCSETS
        lea rdx, [orig_termios]
        syscall                    ; ioctl(STDIN, TCSETS, &term_old)

    sigsegv_handler:
        mov rax, SYSIOCTL
        mov rdi, STDIN
        mov rsi, TCSETS
        lea rdx, [orig_termios]
        syscall                    ; ioctl(STDIN, TCSETS, &term_old)

        mov rax, SYSEXIT
        mov rdi, RET_SIGSEGV
        syscall                    ; Exit with SIGSEGV return value

    sigrestorer:
        mov rax, 15                ; rt_sigreturn
        syscall