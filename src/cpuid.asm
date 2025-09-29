; cpuid2.asm — build: nasm -f bin cpuid2.asm -o cpuid2.com
bits 16
org 100h
start:
    call cpu_info
    ret

cpu_info:
    ; --- 第一次：EAX=0 ---
    mov dx, msg_cpuid0
    call print

    xor eax, eax
    cpuid
    call print_regs
    call newline
    ; --- 第二次：EAX=1 ---
    mov dx, msg_cpuid1
    call print
    mov eax, 1
    cpuid

    mov al, '?'
    mov ah, 2
    int 21

    call print_regs

    ret

;----------------------------------------
; print_regs : 輸出 EAX/EBX/ECX/EDX (十六進位)
;----------------------------------------
print_regs:
    push edx
    push ecx
    push ebx
    push eax
    mov dx, regEAX
    call print
    pop eax    ; EAX 
    call print_hex32

    mov dx, regEBX
    call print
    pop eax    ; EBX 
    call print_hex32

    mov dx, regECX
    call print
    pop eax    ; ECX 
    call print_hex32

    mov dx, regEDX
    call print
    pop eax    ; EDX 
    call print_hex32

    ret

;----------------------------------------
; print: DS:SI 指向 '$' 結尾字串 → 螢幕
;----------------------------------------
print:
    mov ah, 09h
    int 21h
    ret

;----------------------------------------
; print_hex32: EAX → 8 hex chars 輸出
;----------------------------------------
print_hex32:
    push eax
    mov cx, 8
.next_nib:
    pop eax
    rol eax, 4          ; 每次取最高 nibble
    push eax
    mov bl, al
    and bl, 0Fh
    cmp bl, 9
    jbe .digit
    add bl, 7           ; A–F
.digit:
    add bl, '0'
    mov dl, bl
    mov ah, 02h
    int 21h
    loop .next_nib
    mov dl, ' '
    mov ah, 02h
    int 21h
    pop eax
    ret

;----------------------------------------
; 資料區
;----------------------------------------
msg_cpuid0    db 'CPUID EAX=0 -> ', '$'
msg_cpuid1    db 'CPUID EAX=1 -> ', '$'
regEAX  db 'EAX=', '$'
regEBX  db ' EBX=', '$'
regECX  db ' ECX=', '$'
regEDX  db ' EDX=', '$'

newline:
    mov  dl, 13           ; CR
    mov  ah, 2
    int  21h
    mov  dl, 10           ; LF
    mov  ah, 2
    int  21h
    ret