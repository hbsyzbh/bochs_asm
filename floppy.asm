SELECTOR_whole  equ (0x0001 << 3)
SELECTOR_svga   equ (0x0002 << 3)
SELECTOR_code   equ (0x0003 << 3)
VBE_ENABLE equ 4
VBE_BANK equ 5
VBE_INDEX equ 0x01CE
VBE_DATA equ 0x01CF
;-------------------------------------

SECTION MBR vstart=0x7c00
 mov sp, 0x7c00
jmp   start


gdt_ptr dw 32
        dd 0x0000900

start:

        mov        BX,    0         ; ES:BX表示读到内存的地址 0x0800*16 + 0 = 0x8000
        mov ax, 0x900
        mov es, ax
        mov            ch,0 ;CH = low eight bits of cylinder number
        mov            cl,3 ;CL = sector number 1-63 (bits 0-5)
        MOV        DH,00H

load_left:
        call sectorload
        inc cl
        cmp cl, 19
        jnz load_left
		inc dh
        mov cl,1
		cmp dh,2
		jnz load_left

		mov dh,0
        inc ch
        cmp ch, 7
        jnz load_left
        jmp done

sectorload:
        MOV        AH,02H            ; AH=0x02 : AH设置为0x02表示读取磁盘
        MOV        AL,1            ; 要读取的扇区数
        MOV        DL,00H           ; 驱动器号，0表示第一个软盘，是的，软盘。。硬盘C:80H C 硬盘D:81H
        INT        13H               ; 调用BIOS 13号中断，磁盘相关功能
        JC  error
        mov ax,es
        add ax,32
        mov es,ax
        ret

error:
jmp $
done:
;----DISK - READ SECTOR(S) INTO MEMORY
;AH = 02h
;AL = number of sectors to read (must be nonzero)
;CH = low eight bits of cylinder number
;CL = sector number 1-63 (bits 0-5)
;high two bits of cylinder (bits 6-7, hard disk only)
;DH = head number
;DL = drive number (bit 7 set for hard disk)
;ES:BX -> data buffer
;
;Return:
;CF set on error
;if AH = 11h (corrected ECC error), AL = burst length
;CF clear if successful
;AH = status (see #00234)
;AL = number of sectors transferred (only valid if CF set for some
;BIOSes)





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

       mov ax, 0x4F02
        mov bx, 0x010F
        int 10h

; bochs need
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


        mov ax, 0
        mov ds, ax

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


;   jmp readdone
;    jmp $

    mov eax, 2
    mov ebx, 0x10000
    mov ecx, 240

readdone:
    mov eax, 0
    mov ebx, 0
    mov ecx, 60*3
    mov edx, 0
    ;ebx line pos,   edx, img pos,  ecx,graph pos
draw:
    mov byte al, [ds:ebx+edx+0x9000]
;    mov byte al, 0xF0
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
db 0x55,0xaa
