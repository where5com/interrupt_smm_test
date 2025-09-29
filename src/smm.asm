; picview.asm — read-only viewer (NASM, .COM)
; Build: nasm -f bin picview.asm -o picview.com

bits 16
org 100h

%define PIC1_CMD  0x20
%define PIC1_DAT  0x21
%define PIT_CH0   0x40
%define PIT_CMD   0x43
%define SMM_FLAG  0x0
%define SFNM_FLAG 0x0
start:
    mov eax,0
    cpuid
    mov eax,1
    cpuid

    cli
    call print_int08_cs_ip
    call install_08h_isr
    call print_int08_cs_ip
    sti
    int 0x08


    cli
    call uninstall_08h_isr
    call print_int08_cs_ip

    call reset_smm
    sti

    ; call read_pit




    ret

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



set_pit:
    ret
read_pit:
 
    mov dx, msg_pit_start
    call print
    call newline

    mov dx, str_pit_status
    call print
 
    mov al, 0xC2              ; 11 00 0 001 0  → C0, latch status+count
    in  al, PIT_CH0           ; status byte

    call print_hex8
 	call newline

    mov dx, str_pit_counter
    call print

    in  al, PIT_CH0           ; count LSB
    mov ah, al
    in  al, PIT_CH0           ; count MSB
    xchg ah, al

    call print_hex16
    call newline

    mov dx, msg_pit_end
    call print
    call newline
    ret


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

install_08h_isr:
    push ax
    push bx
    push cx
    push dx
    push es
    mov ax, 0
    mov es, ax           ; ES=0000h 指到 IVT 基底
    mov bx, 8*4          ; offset = 向量號 * 4 = 08h*4 = 20h
    mov dx, [es:bx]      ; DX = IP
    mov cx, [es:bx+2]    ; CX = CS

    mov [int08_cs], cx
    mov [int08_ip], dx

    mov ax , test_isr
    mov [es:bx],ax
    mov ax , cs 
    mov [es:bx+2],ax

    pop es
    pop dx
    pop cx
    pop bx
    pop ax

    ret
    
uninstall_08h_isr:
    push ax
    push bx
    push cx
    push dx
    push es
    mov ax, 0
    mov es, ax           ; ES=0000h 指到 IVT 基底
    mov bx, 8*4          ; offset = 向量號 * 4 = 08h*4 = 20h

    mov ax       , [int08_cs]
    mov [es:bx+2], ax
    mov ax       , [int08_ip]
    mov [es:bx]  , ax

    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret


test_isr:
    cli
    mov dx, msg_isr_start
    call print
 	call newline


    mov byte [sti_flag], 0

    cmp byte [int_cnt], 0x0
    je .from_soft

    cmp byte [int_cnt], 0x1
    je .from_ext1

    cmp byte [int_cnt], 0x2
    je .from_ext2


    cmp byte [int_cnt], 0x10
    je .skip_isr

    jmp .no_source

.from_soft:
    mov byte [sti_flag], 1
    jmp .done

.from_ext1:
    ; ... 處理 ext1 ...
    mov byte [sti_flag], 1

    call set_smm
    jmp .done

.from_ext2:
    ; ... 處理 ext2 ...
    jmp .done

.no_source:
    ; ... 都沒觸發時的處理（可省略） ...

.skip_isr:
    mov dx , msg_skip_isr
    call print
    call newline
    jmp .skip

.done:
    add byte [int_cnt], 1





    mov dx, msg_int_cnt
    call print
    mov al, byte [int_cnt]
    call print_hex8
    call newline


    call read_pic

    cmp byte [sti_flag], 0
    je .passed
    sti     

.passed:
    mov cx, 0x003f
    call .delay


    mov dx, msg_int_cnt
    call print
    mov al, byte [int_cnt]
    call print_hex8
    call newline


 .skip   
    call read_pic

    mov dx, msg_isr_end
    call print
 	call newline
    call .EOI
    sti
    iret

.delay:
    cli
    push cx
    call print_int_cnt
    pop cx
    sti
    loop .delay
    ret
.EOI:
    ; specific EOI 給 IRQ0：OCW2 = 0x60 | IRQ#
    mov  al, 0x60      ; IRQ#=0 → 0x60
    out  PIC1_CMD, al

    ret


set_smm:
    mov al,SMM_FLAG
    cmp al, 0x0
    jne .next
    ret
.next:
    call read_pic

    in al, PIC1_DAT
    or al, 0x1
    out PIC1_DAT, al

    ; specific EOI 給 IRQ0：OCW2 = 0x60 | IRQ#
    mov  al, 0x60      ; IRQ#=0 → 0x60
    out  PIC1_CMD, al

    ; OCW3：bit3=1 表示這是 OCW3
    ; ESMM=1 且 SMM=1 → 進入 SMM
    mov  al, 0x68      ; 0b0110_1000 = ESMM=1,SMM=1,bit3=1
    out  PIC1_CMD, al
    
    mov dx, msg_set_smm
    call print
    call newline
    ret

reset_smm:
    ; 退出 SMM（回到 normal mask mode）：ESMM=1, SMM=0
    

    call read_pic

    in al, PIC1_DAT
    and al, 0xfe
    out PIC1_DAT, al

    mov  al, 0x48      ; 0b0100_1000
    out  PIC1_CMD, al
    
    mov dx, msg_reset_smm
    call print
    call newline
    
    call read_pic
    
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

; print int 0x08 CS:IP
print_int08_cs_ip:
    push ax
    push bx
    push cx
    push dx
    push es

    mov dx, str_cs_ip
    call print

    mov ax, 0
    mov es, ax           ; ES=0000h 指到 IVT 基底
    mov bx, 8*4          ; offset = 向量號 * 4 = 08h*4 = 20h
    
    mov ax, [es:bx+2]    ; DX = CS
    call print_hex16


    mov dl, ':'     ; 要印的字元
    mov ah, 2       ; 功能號：輸出字元
    int 21h

    mov ax, [es:bx]      ; DX = IP
    call print_hex16
 	call newline
    
   
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret
    
; print AL as "0xNN"
print_hex8:
    push ax
    push dx
    mov dx, hex8
    mov [hex8+2], byte '0'
    mov [hex8+3], byte '0'
    mov ah, al
    mov al, ah
    shr al, 4
    call nib
    mov [hex8+2], al
    mov al, ah
    and al, 0x0F
    call nib
    mov [hex8+3], al
    mov ah, 9
    int 21h
    pop dx
    pop ax
    ret

; print ax as "0xNNNN"
print_hex16:
    push ax
    push bx
    push dx
    push si

    mov bx, ax
    mov [hex16], word 0  
    mov [hex16+2], word 0  


    ; nib 1
    mov al,bh
    shr al,4
    call nib
    mov [hex16], al
    
    ; nib 2
    mov al,bh
    and al, 0x0f
    call nib
    mov [hex16+1], al
    
    ; nib 3
    mov al,bl
    shr al,4
    call nib
    mov [hex16+2], al
    
    ; nib 4
    mov al,bl
    and al, 0x0f
    call nib
    mov [hex16+3], al



    mov dx, hex16
    mov ah, 9
    int 21h
    pop si
    pop dx
    pop bx
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


; print string of [dx]
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

 print_int_cnt:
    
    ; mov dx, str_num_of_int
    ; call print
    ; mov al, byte [int_cnt]
    ; call print_hex8

    ; mov dl, ','  
    ; mov ah,2  
    ; int 21h  

    ; mov dl, ' '  
    ; mov ah,2  
    ; int 21h  


    ; mov dx, str_count
    ; call print


    ; mov ax, cx
    ; call print_hex16
    ; call newline
    ;7 8, 19-22
    push ax
    push bx
    push cx
    push dx
    mov bl, [int_cnt]

    mov al, bl
    shr al, 4
    call nib
    mov [msg_int_cntf+6],al

    mov al, bl
    and al, 0x0f
    call nib
    mov [msg_int_cntf+7],al


    ;count
    mov bx, cx
    ; nib 1
    mov al,bh
    shr al,4
    call nib
    mov [msg_int_cntf+18], al
    
    ; nib 2
    mov al,bh
    and al, 0x0f
    call nib
    mov [msg_int_cntf+19], al
    
    ; nib 3
    mov al,bl
    shr al,4
    call nib
    mov [msg_int_cntf+20], al
    
    ; nib 4
    mov al,bl
    and al, 0x0f
    call nib
    mov [msg_int_cntf+21], al


    
    mov dx, msg_int_cntf
    call print
    call newline


    pop dx
    pop cx
    pop bx
    pop ax
    ret

; timier isr 08h


    ; data
msg_stag1 db 'stag 1 : ', '$'
msg_stag2 db 'stag 2 : ', '$'

msg_isr_start db '*** test isr entry *** ', '$'
msg_isr_end   db '*** test isr exits *** ', '$'

msg_pit_start    db '-- PIT CH0 info --', '$'
msg_pit_end      db '------------------', '$'
str_pit_status   db 'STATUS  = ', '$'
str_pit_counter  db 'counter = ', '$'


str_cs_ip db 'CS:IP = ', '$'
msg_temp  db 'IMR/IRR/ISR = ', '$'


str_num_of_int db 'int_id : ','$'
str_count db 'count = ', '$'

str_imr db 'M8259 IMR = ', '$'
str_irr db 'M8259 IRR = ', '$'
str_isr db 'M8259 ISR = ', '$'
hex8  db '0x00', '$'
hex16  db '0000', '$'
imr db 0
irr db 0
isr db 0
int08_cs dw 0
int08_ip dw 0

int_cnt     db 0
sti_flag    db 0

msg_set_smm   db '-- smm is set   --', '$'
msg_reset_smm db '-- smm is reset --', '$'
msg_int_cnt db 'INT count : ', '$'
msg_int_cntf db 'id: 0x00, count : 0000', '$'

msg_soft_int    db 'soft_int    : ' , '$'

msg_skip_isr   db 'too many times for test_isr, skipping isr....', '$'