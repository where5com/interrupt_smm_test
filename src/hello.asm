org 0x7c00

    mov ah, 0x0E
    mov al, 'H'
    int 0x10
    mov al, 'i'
    int 0x10

hang:
    jmp hang

times 510-($-$$) db 0   ; 補到 510 bytes
dw 0xAA55               ; boot signature
