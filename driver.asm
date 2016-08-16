[org 0x0100]

jmp start;

PrintNumber:

push bp;
mov bp,sp;
sub sp,2;

mov word [bp-2],0;

mov es,[bp+8]; LPVOID CS
mov si,[bp+6]; LPVOID OFFSET

mov si,[es:si];video memory

mov ax, 0xb800;
mov es,ax;

reprint:
push si;

mov ax,[bp-2];
mov bx,10; base is fixed now.
mov cx,5;

Lp2:
mov dx,0;
div bx;
push dx;

Loop Lp2;

mov cx,5;

break:

pop ax;
add ax,0x30;

cmp ax,58;
jb nothexa;

add ax,7;

nothexa:

mov ah,0x07;

mov word [es:si],ax;
inc si;
inc si;

Loop break;

inc word [bp-2];

pop si;

jmp reprint;

cmp word [bp-2],0;
jne reprint;


pop bp;
add sp,2;

retf;


;push cs;
;push word lpvoid;
;push cs;
;call PrintNumber;

;mov ax,0x4c00;
;int 0x21;
;int 8h;

start:

xor si,si;

mov cx,4;

LP:
push cx;
xor ax,ax;
int 16h;

mov word [csip],cs;
mov word [csip+2],PrintNumber;
mov word [csip+4],ds;
mov word [csip+6],lpvoid;

push ds;
pop es;
mov di,csip;
mov cx,1;
mov ah,0xff;
mov al,0x01;
int 0x21;

pop cx;
add word [lpvoid],160;

;jmp LP;
Loop LP;

mov ah,0xff;
mov al,0x03;
mov cx,2;
int 0x21;

int 16h;

mov ah,0xff;
mov al,0x04;
mov cx,2;
int 0x21;

mov ax,0x3100;
int 0x21;

lpvoid : dw 130;
csip : dw 0,0,0,0;