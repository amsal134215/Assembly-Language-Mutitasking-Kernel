;es:di points to a struct which is also a stuct having cs , ip , LPVOIDcs , LPVOIDip.
;cx conatins the priority
;ah == 0xff and al== subservice number
;will return index of pcb in ax if is created and -1 if failed.

[org 0x0100]

jmp start;

TotalPCBs equ 8;
STACKsize equ 256;

PCBARR: times TotalPCBs*16 dw 0;
stack : times TotalPCBs*256 dw 0;
currentindex : dw 0;
currentpriority dw 0;
realtimerint : dd 0;
realint21 : dd 0;


priorityoffset equ 0;
stateoffset equ 1;
;state of PCB is 0 if it is free.
;1 if working and 2 if suspended and 3 if TSR
prevoffset equ 2;
nextoffset equ 3;
axoffset equ 4;
bxoffset equ 6;
cxoffset equ 8;
dxoffset equ 10;
dioffset equ 12;
sioffset equ 14;
bpoffset equ 16;
spoffset equ 18;
ipoffset equ 20;
csoffset equ 22;
ssoffset equ 24;
dsoffset equ 26;
esoffset equ 28;
flagsoffset equ 30;


mytimerint:

cmp word [cs:currentpriority],0;
jne rexecute;

;storing the current state in current index of PCB Array.

push si;
push ds;

push cs;
pop ds;


mov si,[currentindex];
shl si,5;

mov [PCBARR+si+axoffset],ax;
mov [PCBARR+si+bxoffset],bx;
mov [PCBARR+si+cxoffset],cx;
mov [PCBARR+si+dxoffset],dx;
mov [PCBARR+si+dioffset],di;
mov [PCBARR+si+bpoffset],bp;
mov [PCBARR+si+esoffset],es;

pop ax;
mov [PCBARR+si+dsoffset],ax;
pop ax;
mov [PCBARR+si+sioffset],ax;
pop ax;
mov [PCBARR+si+ipoffset],ax;
pop ax;
mov [PCBARR+si+csoffset],ax;
pop ax;
mov [PCBARR+si+flagsoffset],ax;

mov [PCBARR+si+ssoffset],ss;
mov [PCBARR+si+spoffset],sp;

;the state of the program is stored.


;now get the next index of the PCB Array;

xor ah,ah;
mov al,[PCBARR+si+nextoffset];

mov [currentindex],ax; modifying the current index

mov si,ax;
shl si,5;

; no bound checking for the produced address
;lines should be added here

; PCBARR+si is the Address of PCB


;resetting the temporarypriorityoffset
xor ah,ah;
mov al,[PCBARR+si+priorityoffset];
mov [currentpriority],ax;


;restoring the next state

mov ss,[PCBARR+si+ssoffset];
mov sp,[PCBARR+si+spoffset];

mov ax,[PCBARR+si+flagsoffset];
push ax;

mov ax,[PCBARR+si+csoffset];
push ax;

mov ax,[PCBARR+si+ipoffset];
push ax;

mov ax,[PCBARR+si+sioffset];
push ax;

mov ax,[PCBARR+si+dsoffset];
push ax;

mov es,[PCBARR+si+esoffset];


mov ax,[PCBARR+si+axoffset];
mov bx,[PCBARR+si+bxoffset];
mov cx,[PCBARR+si+cxoffset];
mov dx,[PCBARR+si+dxoffset];
mov di,[PCBARR+si+dioffset];
mov bp,[PCBARR+si+bpoffset];

pop ds;
pop si;


rexecute:

cmp word [cs:currentpriority],0;
jbe nodec;

dec word [cs:currentpriority];

nodec:

jmp far [cs:realtimerint];


getfreepcb:

push si;
mov si,1;

mov bx,si;

trynext:
shl bx,5;

cmp byte [cs:PCBARR+bx+stateoffset],0;
je returnfree;

inc si;
mov bx,si;

cmp si,TotalPCBs;
jne trynext;

;all pcb are full
mov bx,-1;
jmp getout;

returnfree:
;mov byte [cs:PCBARR+bx+stateoffset],1;
mov bx,si;

getout:
pop si;
ret;



initpcb:

push bp;
mov bp,sp;

push ds;
push bx;
push si;
push di;

call getfreepcb; will return index of free PCB in bx;

cmp bx,-1;
je nopcbisfree;

mov si,bx;
mov di,bx;

shl bx,5;

mov [cs:PCBARR+bx+dsoffset],ds;

push cs;
pop ds;

mov byte [PCBARR+stateoffset],1;

mov byte [PCBARR+bx+stateoffset],1; This PCB is in use.

mov ax,[bp+6]; cs of requested thread
mov [PCBARR+bx+csoffset],ax;
mov ax,[bp+4]; ip of requested thread;
mov [PCBARR+bx+ipoffset],ax;

mov [PCBARR+bx+esoffset],es;

cmp cx,0; setting priority
jne setpri;
inc cx;
setpri:
mov [PCBARR+bx+priorityoffset],cl;
dec cx;

shl si,8;
add si,stack+STACKsize;

sub si,2;	putting LPVOID on PCBs stack
mov ax,[bp+10];
mov [si],ax;
sub si,2;
mov ax,[bp+8];
mov [si],ax;

sub si,2; terminate trap;
mov [si],cs;
sub si,2;
mov word [si],terminatetrap;

mov [PCBARR+bx+ssoffset],cs; 
mov [PCBARR+bx+spoffset],si;

mov word [PCBARR+bx+axoffset],0;
mov word [PCBARR+bx+bxoffset],0;
mov word [PCBARR+bx+cxoffset],0;
mov word [PCBARR+bx+dxoffset],0;
mov word [PCBARR+bx+dioffset],0;
mov word [PCBARR+bx+sioffset],0;
mov word [PCBARR+bx+bpoffset],0;
mov word [PCBARR+bx+flagsoffset],0x0200;

push di;
call insertion;

mov ax,di;
jmp pcbcreated;

nopcbisfree:
mov ax,-1;

pcbcreated:
pop di;
pop si;
pop bx;
pop ds;
pop bp;

ret 8;

insertion: ; takes index of PCB to be inserted

push bp;
mov bp,sp;

push ax;
push bx;
push si;
push di;
push ds;

push cs;
pop ds;

mov di,[bp+4];

mov bx,di;
shl bx,5;
xor ax,ax;
mov byte [PCBARR+bx+stateoffset],1;
;Inserting PCB at start in the LinkedList With Head Node.
;di has the index of currently filled PCB
mov al,[PCBARR+nextoffset]; read the next of header node
mov si,ax; moved the next of header to si
mov [PCBARR+bx+nextoffset],al; added the read index into newly filled PCB
mov ax,di; newly created PCB index moved in al
mov [PCBARR+nextoffset],al; changed the next of header to newly filled PCB
;next of all the nodes involved is set

;now setting the previous
shl si,5;
mov [PCBARR+si+prevoffset],al;
mov byte [PCBARR+bx+prevoffset],0;
;both previous are overwritten


pop ds;
pop di;
pop si;
pop bx;
pop ax;

pop bp;

ret 2;


terminatetrap:

cli;
mov ax,[cs:currentindex];
push ax;
push word 0;
call terminateSubroutine;
sti;

il : jmp il;


terminateSubroutine: ; take index of PCB to be deleted or suspended. cli before calling.

push bp;
mov bp,sp;

push ax;
push bx;
push si;
push di;

mov si,[bp+6]; index of PCB to be terminated
shl si,5;

xor ah,ah;
xor bh,bh;

mov al,[cs:PCBARR+si+nextoffset];
mov bl,[cs:PCBARR+si+prevoffset];

mov di,bx;
shl di,5;

mov [cs:PCBARR+di+nextoffset],al;
mov di,ax;
shl di,5
mov [cs:PCBARR+di+prevoffset],bl;

;mov word [cs:PCBARR+si],0;
;mov word [cs:currentindex],0;
mov word [cs:currentpriority],0;

mov ax,[bp+4]; key that tells terminate or suspend
mov byte [cs:PCBARR+si+stateoffset],al;

pop di;
pop si;
pop bx;
pop ax;

pop bp;
ret 4;


myint21:

cmp ah,0xff;
jne n4;

cmp al,0x01; create thread returns pcb number in ax;
jne n1;

mov ax,[es:di+4];
push ax;
mov ax,[es:di+6];
push ax;
mov ax,[es:di];
push ax;
mov ax,[es:di+2];
push ax;
call initpcb;

jmp ret21; 

n1:

cmp al,0x02; terminate thread receives pcb number in cx
jne n2;
push si;	; returns 0 if success and -1 if failed
mov si,cx;
shl si,5;
cmp byte [cs:PCBARR+si+stateoffset],0;
jne validno;
mov ax,-1;
jmp notvalidno;
validno:
push cx;
push 0;
call terminateSubroutine;
xor ax,ax;
notvalidno:
pop si;

jmp ret21;

n2:

cmp al,0x03; suspend thread receives pcb number in cx
jne n3;
push si;	; returns 0 if success and -1 if failed
mov si,cx;
shl si,5;
cmp byte [cs:PCBARR+si+stateoffset],0;
jne validno3;
mov ax,-1;
jmp notvalidno3;
validno3:
push cx;
push word 2;	suspend the PCB
call terminateSubroutine;
xor ax,ax;
notvalidno3:
pop si;

jmp ret21;

n3:

cmp al,0x04; resume thread receives pcb number in cx
jne n4;
push si;	; returns 0 if success and -1 if failed
mov si,cx;
shl si,5;
cmp byte [cs:PCBARR+si+stateoffset],2;
je validno4;
mov ax,-1;
jmp notvalidno4;
validno4:
push cx; resume the PCB;
call insertion;
xor ax,ax;
notvalidno4:
pop si;

jmp ret21;

n4:

cmp ax,0x4C00;
jne n5;

push ax;
push di;

xor ax,ax;
mov al,[cs:PCBARR+nextoffset];
mov di,ax;

cmp di,0;
je terelp;

termlp:
shl di,5;

cmp byte [cs:PCBARR+di+stateoffset],3;
je delnot;

shr di,5;
push di;
push word 0;
call terminateSubroutine;

delnot:

shl di,5;
mov al,[cs:PCBARR+di+nextoffset];
mov di,ax;

cmp di,0;
jne termlp;

terelp:

pop di;
pop ax;

jmp endint21;

n5:

cmp ax,0x3100;
jne endint21;

push ax;
push di;

xor ax,ax;
xor di,di;

mov al,[cs:PCBARR+nextoffset];
mov di,ax;

cmp ax,0;
je nothreads;

tsrloop:

shl di,5;

mov byte [cs:PCBARR+di+stateoffset],3;
mov al,[cs:PCBARR+di+nextoffset];

cmp ax,0;
jne tsrloop;

nothreads:

pop di;
pop ax;

jmp endint21;

ret21:
iret;


endint21:

jmp far [cs:realint21]; 


start:

xor ax,ax;
mov es,ax;

mov bx,[es:0x8*4];
mov [cs:realtimerint],bx;
mov bx,[es:(0x8*4)+2];
mov [cs:realtimerint+2],bx;

mov bx,[es:0x21*4];
mov [cs:realint21],bx;
mov bx,[es:(0x21*4)+2];
mov [cs:realint21+2],bx;

cli;

mov word [es:0x8*4],mytimerint;
mov word [es:(0x8*4)+2],cs;

mov word [es:0x21*4],myint21;
mov word [es:(0x21*4)+2],cs;

sti;

mov dx,start;
add dx,15;
shr dx,4;

mov ax,0x3100;
int 0x21;


