SECTION MBR vstart=0x7c00
	mov sp, 0x7c00
        mov        BX,    0         ; ES:BX表示读到内存的地址 0x0800*16 + 0 = 0x8000
        mov ax, 0x800
        mov es, ax
        mov            ch,0 ;CH = low eight bits of cylinder number
        mov            cl,3 ;CL = sector number 1-63 (bits 0-5)
        MOV        DH,00H   ;DH = head number

load_left:
        call sectorload
        inc cl
        cmp cl, 64
        jnz load_left
        inc dh
        mov cl,1
        cmp dh,16
        jnz load_left

        mov dh,0
        inc ch
        cmp ch, 3
        jnz load_left
        jmp done

sectorload:
        MOV        AH,02H            ; AH=0x02 : AH设置为0x02表示读取磁盘
        MOV        AL,1            ; 要读取的扇区数
        MOV        DL,80H           ; 驱动器号，0表示第一个软盘，是的，软盘。。硬盘C:80H C 硬盘D:81H
        INT        13H               ; 调用BIOS 13号中断，磁盘相关功能
        JC  error
        mov ax,es
        add ax,32; 512 / 16
        mov es,ax
        cmp ax,0x3000
        jz done
        ret

error:
jmp $
done:
jmp 0x8000
jmp $

times 510-($-$$) db 0
db 0x55, 0xaa
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
