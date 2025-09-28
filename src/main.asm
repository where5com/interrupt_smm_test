extern _printf
SECTION .data

    msg             db      'Hello World!', 0Ah , 0h;
    
    num1            dd       100;
    num1_int_fmt    db      'num1=%d', 0Ah, 0h;

    num2            dq       3.14;
    num2_flt_fmt    db       'num2=%lf', 0Ah, 0h;

SECTION .text

global _main
 
_main:

    push ebp
    mov  ebp , esp 

    ; printf("Hello World\n");
    mov  eax , msg
    push eax 
    call _printf
    add  esp, 4

    ; printf("num1=%d",num1)
    mov  eax , [num1]
    push eax 
    mov  ebx , num1_int_fmt
    push ebx , 
    call _printf
    add  esp , 4

    ; printf("num2=%lf",num2)
    movq    xmm0  , [num2]
    sub     esp   , 0x8
    movsd   [esp] , xmm0
    mov     ebx   , num2_flt_fmt
    push    ebx 
    call    _printf
    add     esp   , 0xc

    mov esp , ebp
    pop ebp 

    ret