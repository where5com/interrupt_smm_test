; Read 8259A Master PIC status: IMR/IRR/ISR
; Build: nasm -f bin picstat.asm -o picstat.com
; Run  : picstat.com  (in DOS/DOSBox-X)

bits 16
org 100h

%define PIC1_CMD   0x20    ; master command port
%define PIC1_DATA  0x21    ; master data (IMR)
%define OCW3_READ_IRR 0x0A ; RR=1, RIS=0
%define OCW3_READ_ISR 0x0B ; RR=1, RIS=1

start:
    ; DS 已等於 CS（.COM），可直接用資料標籤

    ; --- IMR ---
    in   al, dx_dummy      ; (避免某些舊工具警告，無實際作用)
    mov  dx, PIC1_DATA
    in   al, dx            ; AL = IMR
    mov  [val_imr], al

    ; --- IRR ---
    mov  dx, PIC1_CMD
    mov  al, OCW3_READ_IRR ; 選 IRR
    out  dx, al
    in   al, dx            ; AL = IRR
    mov  [val_irr], al

    ; --- ISR ---
    mov  dx, PIC1_CMD
    mov  al, OCW3_READ_ISR ; 選 ISR
    out  dx, al
    in   al, dx            ; AL = ISR
    mov  [val_isr], al

    ; 列印
    mov  dx, msg_imr
    mov  ah, 9
    int  21h
    mov  al, [val_imr]
    call print_hex8
    call newline

    mov  dx, msg_irr
    mov  ah, 9
    int  21h
    mov  al, [val_irr]
    call print_hex8
    call newline

    mov  dx, msg_isr
    mov  ah, 9
    int  21h
    mov  al, [val_isr]
    call print_hex8
    call newline

    ; 退出
    mov  ax, 4C00h
    int  21h

; --- 子程序：把 AL 當作 8-bit 值印成 "0xNN" ---
; 破壞：AX, BX, CX, DX
print_hex8:
    push ax
    push bx
    push dx

    mov  bx, ax           ; BL=原始值
    mov  dx, hexbuf       ; DS:DX -> "0x00$"

    ; 高 nibble
    mov  al, bl
    shr  al, 4
    call nibble_to_hex
    mov  [hexbuf+2], al

    ; 低 nibble
    mov  al, bl
    and  al, 0x0F
    call nibble_to_hex
    mov  [hexbuf+3], al

    mov  ah, 9
    int  21h              ; 列印 "0xNN$"

    pop  dx
    pop  bx
    pop  ax
    ret

; 將 0..15 轉為 ASCII '0'..'9','A'..'F'，輸出放 AL
nibble_to_hex:
    cmp  al, 9
    jbe  .num
    add  al, 'A' - 10
    ret
.num:
    add  al, '0'
    ret

newline:
    mov  dl, 13           ; CR
    mov  ah, 2
    int  21h
    mov  dl, 10           ; LF
    mov  ah, 2
    int  21h
    ret

; --- 資料區 ---
msg_imr db 'M8259 IMR = ', '$'
msg_irr db 'M8259 IRR = ', '$'
msg_isr db 'M8259 ISR = ', '$'
hexbuf  db '0x00', '$'

val_imr db 0
val_irr db 0
val_isr db 0

dx_dummy dw 0             ; 只是佔位，避免某些組譯器對 IN 無 DX 的抱怨
