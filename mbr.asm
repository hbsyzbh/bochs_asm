; 主引导程序
;-----------------------------------------------
VBE_ENABLE equ 4
VBE_BANK equ 5
VBE_INDEX equ 0x01CE
VBE_DATA equ 0x01CF

SECTION MBR vstart=0x7c00
    mov sp, 0x7c00
	jmp start

GDT_BASE: dd 0x00000000
          dd 0x00000000
;1 whole
dd 0x0000FFFF
dd 0x00CF9200

;2 svga
dd 0x0000FFFF
dd 0x00cf9200

;3 code
dd 0x0000FFFF
dd 0x00CF9A00

GDT_SIZE equ $ - GDT_BASE
GDT_LIMIT equ GDT_SIZE - 1

SELECTOR_whole	equ (0x0001 << 3)
SELECTOR_svga	equ (0x0002 << 3)
SELECTOR_code	equ (0x0003 << 3)

gdt_ptr dw GDT_LIMIT
        dd 0x0000900

start:
mov ax, 0x4F02
        mov bx, 0x010F
;        mov bx, 0x0112
        int 10h

;jmp liner
;jmp enter_pm

    mov edx, VBE_INDEX
    mov eax, VBE_ENABLE
    OUT dx, ax
    mov edx, VBE_DATA
    mov eax, 0
    OUT dx, ax

    mov edx, VBE_INDEX
    mov eax, VBE_ENABLE
    OUT dx, ax
    mov edx, VBE_DATA
    mov eax, 0x41
    OUT dx, ax


	mov ax, 0x8F
	mov ds, ax 
	mov al, 24
	mov [0], al
	mov ax,0x900
	mov [1], ax

	mov ax, 0x90
	mov ds, ax
	mov ax, 0
	mov [0], ax
	mov [2], ax
	mov [4], ax
	mov [6], ax
	mov ax,0xFFFF
	mov [8], ax
	mov ax,0x0000
	mov [10], ax
	mov ax,0x9200
	mov [12], ax
	mov ax,0x00CF
	mov [14], ax

	mov ax,0xFFFF
	mov [16], ax
	mov ax,0x0000
	mov [18], ax
	mov ax,0x9200
	mov [20], ax
	mov ax,0x00CF
	mov [22], ax


	mov ax,0xFFFF
	mov [24], ax
	mov ax,0x0000
	mov [26], ax
	mov ax,0x9A00
	mov [28], ax
	mov ax,0x00CF
	mov [30], ax

		mov ax, 0
		mov ds, ax
liner:

        mov ax, 0x900
        mov es, ax
        mov di, 0
        mov ax, 0x4F01
        mov cx, 0x101
        int 0x10

        mov ebx, [es:40]   ;ebx liner video memery addr
		mov ax, 0x90
		mov es, ax
		mov word [es:18],bx
		shr ebx,16
		mov byte [es:20],bl
		mov byte [es:23],bh


;=============== 
        ; 打开A20地址线
        in al, 0x92
        or al, 00000010B
        out 0x92, al

        ; 加载gdt
        lgdt [gdt_ptr]

		cli

        ; cr0第0位置1
        mov eax, cr0
        or eax, 0x00000001
        mov cr0, eax

; 刷新流水线
        jmp dword SELECTOR_code:p_mode_start

[bits 32]
p_mode_start:
	mov ax, SELECTOR_whole
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
	mov ax, SELECTOR_svga
    mov gs, ax
    mov ebx, 0
    mov eax, 0
    mov ecx, 0
    mov edx, 0


;	jmp readdone

    mov eax, 2
    mov ebx, 0x10000
    mov ecx, 240

rd_disk_m_32:
    mov esi, eax
    mov di, cx

    mov dx, 0x1f2
    mov al, cl
    out dx, al

    mov eax, esi

    mov dx, 0x1f3
    out dx, al

    mov cl, 8
    shr eax, cl
    mov dx, 0x1f4
    out dx, al

    shr eax, cl
    mov dx, 0x1f5
    out dx, al

    shr eax, cl
    and al, 0x0f
    or al, 0xe0
    mov dx, 0x1f6
    out dx, al

    mov dx, 0x1f7
    mov al, 0x20
    out dx, al

.not_ready:
    nop
    in al, dx
    and al, 0x88
    cmp al, 0x08
    jnz .not_ready

    mov ax, di
    mov dx, 256
    mul dx
    mov cx, ax
    mov dx, 0x1f0

.go_on_read:
    in ax, dx
    mov [ds:ebx], ax
    add ebx, 2
    loop .go_on_read
readdone:
	mov eax, 0
	mov ebx, 0
	mov ecx, 60*3
	mov edx, 0
    ;ebx line pos,   edx, img pos,  ecx,graph pos
draw:
    mov byte al, [ds:ebx+edx+0x10000]
	;mov byte al, 0xF0
    mov byte [gs:ebx+ecx],al
    inc ebx
    cmp ebx,600
    jnz c2
    mov ebx,0
    add ecx,960
    add edx,600
c2:
    cmp edx,600*200
    jnz draw
    jmp $

    times 510-($-$$) db 0
    db 0x55, 0xaa