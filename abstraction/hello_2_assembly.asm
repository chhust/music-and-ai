; "Hello, world!" in x86-64 Assembly (MacOS)
; This would crash under Linux bc of different syscalls

section .data
    hello db "Hello, world!", 10            ; string plus newline
    hello_len equ $ - hello                 ; calculate string length

section .text
    global _start

_start:
    mov rax, 0x2000004                      ; prepare syscall: write
    mov rdi, 1                              ; file descriptor (stdout -> console)
    lea rsi, [rel hello]                    ; string location
    mov rdx, hello_len                      ; number of bytes (string length)
    syscall

    mov rax, 0x2000001                      ; prepare syscall: exit
    xor rdi, rdi                            ; return code 0
    syscall
