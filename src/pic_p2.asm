; picview.asm — read-only viewer (NASM, .COM)
; Build: nasm -f bin picview.asm -o picview.com

bits 16
org 100h

%define PIC1_CMD  0x20
%define PIC1_DAT  0x21
start:

    call change_08h_isr
    mov dx, str_cs_ip
    call print
    mov dx, int08_cs
    call print
    mov dx, int08_ip
    call print
 	call newline


    ; print info
    mov dx, msg_stag1
    call print
 	call newline
    call read_pic

    mov dx, PIC1_DAT
    mov al, 0x0
    out dx, al

    mov dx, msg_stag2
    call print
 	call newline
    call read_pic


    ret

    ; mov ax, 4C00h
    ; int 21h





read_pic:
    ; IMR
    mov dx, PIC1_DAT
    in  al, dx
    mov [imr], al

    ; IRR (OCW3=0x0A)
    mov dx, PIC1_CMD
    mov al, 0x0A
    out dx, al
    in  al, dx
    mov [irr], al

    ; ISR (OCW3=0x0B)
    mov al, 0x0B
    out dx, al
    in  al, dx
    mov [isr], al

    ; print "IMR/IRR/ISR = 0x?? 0x?? 0x??"
    mov dx, str_imr
    call print

    mov al, [imr]  
 	call print_hex8  
 	call newline

    mov dx, str_irr
    call print

    mov al, [irr]  
 	call print_hex8  
 	call newline

    mov dx, str_isr
    call print

    mov al, [isr]  
 	call print_hex8  
 	call newline


    ret

change_08h_isr:
    ; 讀 INT 08h 的 ISR CS:IP
    push es
    mov ax, 0
    mov es, ax           ; ES=0000h 指到 IVT 基底
    mov bx, 8*4          ; offset = 向量號 * 4 = 08h*4 = 20h
    mov dx, [es:bx]      ; DX = IP
    mov cx, [es:bx+2]    ; CX = CS

    mov [int08_cs], cx
    mov [int08_ip], dx

    pop es
    ret

; --- helpers ---
space:  
    mov dl, ' '  
    mov ah,2  
    int 21h  
    ret

crlf:   
    mov dl, 13   
    mov ah,2  
    int 21h
        
    mov dl, 10   
    mov ah,2  
    int 21h  
    ret

; print AL as "0xNN"
print_hex8:
    push ax
    push dx
    mov dx, hex
    mov [hex+2], byte '0'
    mov [hex+3], byte '0'
    mov ah, al
    mov al, ah
    shr al, 4
    call nib
    mov [hex+2], al
    mov al, ah
    and al, 0x0F
    call nib
    mov [hex+3], al
    mov ah, 9
    int 21h
    pop dx
    pop ax
    ret

nib:    
    cmp al,9  
    jbe .d
    add al, 'A'-10      
    ret
.d:     
    add al, '0'     
    ret



print:
    mov ah, 9
    int 21h
    ret

newline:
    mov  dl, 13           ; CR
    mov  ah, 2
    int  21h
    mov  dl, 10           ; LF
    mov  ah, 2
    int  21h
    ret


; timier isr 08h


    ; data
msg_stag1 db 'stag 1 : ', '$'
msg_stag2 db 'stag 2 : ', '$'

str_cs_ip db 'CS:IP = ', '$'
msg_temp  db 'IMR/IRR/ISR = ', '$'
str_imr db 'M8259 IMR = ', '$'
str_irr db 'M8259 IRR = ', '$'
str_isr db 'M8259 ISR = ', '$'
hex  db '0x00', '$'
imr db 0
irr db 0
isr db 0
int08_cs db 0
int08_ip db 0