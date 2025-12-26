; Math / Random functions

BITS 64
CPU X64

section .data
    state dq 10248926342346366

section .text

    rand:
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

    modulus:
        mov rax, rdi
        xor rdx, rdx
        div rsi
        mov rax, rdx
        ret