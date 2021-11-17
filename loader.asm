section app vstart=0x8000
; 主引导程序
;-----------------------------------------------
VBE_ENABLE equ 4
VBE_BANK equ 5
VBE_INDEX equ 0x01CE
VBE_DATA equ 0x01CF

str_buf equ 0x100

	mov esi,0
	mov ax, 0
	mov gs, ax
	jmp start


GDT_SIZE equ 4*8
GDT_LIMIT equ GDT_SIZE - 1

SELECTOR_whole	equ (0x0001 << 3)
SELECTOR_svga	equ (0x0002 << 3)
SELECTOR_code	equ (0x0003 << 3)

gdt_ptr dw GDT_LIMIT
        dd 0x0000900

g_model dw 0
g_model2 dw 0

g_sel_x dw 0
g_sel_y dw 0
g_sel_bits db 0
g_liner_addr dd 0

start:
    mov ah,3
    mov bh,0
    int 0x10

	;---- es:di
	mov ax, str_buf
	mov es, ax
	mov di,0
	mov ax, 0x4F00
	int 10h

	mov dx,0
	mov cx, 5
	mov bx, 3 ; 0 page, color 
	call printf

	mov ax, [es:0x0E]
	mov si, ax
	mov ax, [es:0x10]
	mov ds, ax

next_gmode:
	mov cx, [ds:si]
	cmp cx, 0xFFFF
	jz end

	push cx
	mov bx,0
	call getInfo
	pop cx

	cmp al,24
	;cmp al,25  ;-- debug 32bits
	jnz not_24bit
	mov [gs:g_model],cx
not_24bit:
	jc skip_cur

	mov [gs:g_model2],cx
	mov ecx, 0
	mov cx, bx
	mov bx, 3 ; 0 page, color 
	call  printf

skip_cur:
	add si,2
	jmp next_gmode

end:
	mov bx, 0
	mov al, 'F'
	call char_cat
	mov al, 'i'
	call char_cat
	mov al, 'n'
	call char_cat
	mov al, 'a'
	call char_cat
	mov al, 'l'
	call char_cat
	mov al, ':'
	call char_cat
	
	mov ecx, 0
	mov cx, [gs:g_model]
	cmp cx, 0
	jnz show_select
	mov cx, [gs:g_model2]
	cmp cx, 0
	jz show_error
show_select:
	call getInfo
	mov ecx, 0
	mov cx, bx
	mov bx, 4 ; 0 page, color 
	call  printf

	mov eax,0
	mov bx, 0
	mov ax, [gs:g_sel_x]
	call int_cat

	mov al, 'x'
	call char_cat

	mov ax, [gs:g_sel_y]
	call int_cat

	mov al, ':'
	call char_cat

	mov al, [gs:g_sel_bits]
	call int_cat
	mov cx, bx
	mov bx, 4 ; 0 page, color 
	call  printf

jmp show_pic

jmp $
show_error:
	mov ax, 0
	mov es, ax
	mov bp, errmsg
	mov bx, 4 ; 0 page, color 
	mov cx, 3
	call  printf
jmp $

errmsg: db 'Err'
	;-- cx len  es:bp str
;BH = page number.
;BL = attribute if string contains only characters.
;CX = number of characters in string.
;DH,DL = row,column at which to start writing.
;ES:BP -> string to write
printf:
	push es
	push bp
	mov ax, str_buf
	mov es, ax
	mov bp, 0
	mov ax, 0x1301
;	mov bx, 4 ; 0 page, color 
	mov dl, 0
    int 10h
	inc dh
	pop bp
	pop es
	ret

	;-- al the char, bx -pos
char_cat:
	push ds
	push ax
	mov ax, str_buf
	mov ds, ax
	pop ax
	mov [bx],al
	pop ds
	inc bx
	ret

    ; input al ,out put al
hex_4bit:
	cmp al,10
	jnc .hex_AF
	add al, '0'
	jmp .hex_out
.hex_AF:
	sub al, 10
	add al, 'A'
.hex_out:
	ret

hex_cat:
	push dx
	push ds
	push ax
	mov ax, str_buf
	mov ds, ax
	pop ax
	mov edx,0
	mov dx,ax

	mov al,dh
	and al,0xF0
	shr al,4
	call hex_4bit
	mov [bx],al
	inc bx

	mov al,dh
	and al,0x0F
	call hex_4bit
	mov [bx],al
	inc bx

	mov al,dl
	and al,0xF0
	shr al,4
	call hex_4bit
	mov [bx],al
	inc bx

	mov al,dl
	and al,0x0F
	call hex_4bit
	mov [bx],al
	inc bx

	pop ds
	pop dx
	ret

	;-- ax the int, bx -pos
int_cat:
	push cx
	push es
	push di
	push bp
	push ds
	push dx
	push ax
	mov di, 0
	mov ax, str_buf
	mov ds, ax
	pop ax
	mov ecx, 1000
	mov edx, 0
	div cx,
	cmp al, 0
	jz empty
	add al, 0x30
	mov di,1
	jmp asc
empty:
	mov al, ' '
asc:
	mov [bx],al
	mov ax,dx
	mov ecx, 100
	mov edx, 0
	div cx,
	cmp al,0
	jz empty2
has_z:
	add al, 0x30
	jmp asc2
empty2:
	cmp di, 0
	jnz has_z
	mov al, ' '
asc2:
	mov [bx+1],al
	mov ax,dx
	mov ecx, 10
	mov edx, 0
	div cx,
	add al, 0x30
	mov [bx+2],al
	mov ax,dx
	add al, 0x30
	mov [bx+3],al
	pop dx
	pop ds
	pop bp
	pop di
	pop es  
	pop cx
	add bx, 4
	ret

	;--bx
getInfo:
	mov di, 0
	mov ax, 0x92
	mov es, ax
	mov ax, 0x4F01
	int 10h

	cmp ax, 0x004F
	jnz .out

	mov ax,cx
	call hex_cat

	mov al, ' '
	call char_cat

	mov eax,0
	mov ax, [es:0x12]
	mov [gs:g_sel_x],ax
	call int_cat

	mov al, 'x'
	call char_cat

	mov eax,0
	mov ax, [es:0x14]
	mov [gs:g_sel_y],ax
	call int_cat

	mov al, ':'
	call char_cat

	mov eax,0
	mov ax, [es:0x2A]
	mov [gs:g_liner_addr+2],ax
	call hex_cat
	mov eax,0
	mov ax, [es:0x28]
	mov [gs:g_liner_addr],ax
	call hex_cat

	mov eax,0
	mov al, [es:0x19]
	mov [gs:g_sel_bits],al
	push ax ;--save bits
	call int_cat

	mov al, 'b'
	call char_cat

	mov al, 'i'
	call char_cat

	mov al, 't'
	call char_cat

	mov al, 's'
	call char_cat
	pop ax
.out:
	ret

jmp $ ;-- should nerver come here

show_pic:
	mov ebx, 0
	mov ax, 0x4F02
	mov bx, [gs:g_model]
	cmp bx, 0
	jnz use24
	mov bx, [gs:g_model2]
use24:
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
        mov ebx, [gs:g_liner_addr]   ;ebx liner video memery addr
		mov ax, 0x90
		mov es, ax
		mov word [es:18],bx
		shr ebx,16
		mov byte [es:20],bl
		mov byte [es:23],bh


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

    mov al, [g_sel_bits]
	cmp al, 24
    jz draw_24
	jmp draw_32

jmp $ ; -- should never come here

	; in ebx  out ax
get_img_line_pos:
	mov eax, ebx
	push edx
	push ebx
	mov ebx,3
	mul ebx
	mov esi, eax
	pop ebx
	pop edx
	ret

get_32_graph_line_pos:
	mov eax, ebx
	push edx
	push ebx
	mov ebx,4
	mul ebx
	mov esi, eax
	pop ebx
	pop edx
	ret

draw_32:
	; x - 200 / 2
	mov eax, 0
	mov ax, [g_sel_x]
	sub ax, 200
	shr ax, 1
	mov ebx, 4
	mul bx
	mov ecx, eax
	
	mov eax, 0
	mov ax, [g_sel_x]
	mov ebx, 0
	mov bx, [g_sel_y]
	sub bx, 200
	shr bx, 1
	mul ebx
	shl eax,2  ;-- x 4
	add ecx, eax

	mov eax, 0
	mov ebx, 0
;	mov ecx, 0
	mov edx, 0
    ;ebx line pos,   edx, img pos,  ecx,graph pos
.draw:
	call get_img_line_pos
	mov al, 0x0
	shl eax, 8
    mov byte al, [ds:esi+edx+img+2]
	shl eax, 8
    mov byte al, [ds:esi+edx+img+1]
	shl eax , 8
    mov byte al, [ds:esi+edx+img+0]
	push eax
	call get_32_graph_line_pos
	pop eax
    mov [gs:esi+ecx],eax

    inc ebx
    cmp ebx,200
    jnz .c2
    mov ebx,0
    mov bx,[g_sel_x]
    add ecx,ebx
    add ecx,ebx
    add ecx,ebx
    add ecx,ebx
    mov ebx,0
    add edx,600
.c2:
    cmp edx,600*200
    jnz .draw
    jmp $


draw_24:
	; x - 200 / 2
	mov eax, 0
	mov ax, [g_sel_x]
	sub ax, 200
	shr ax, 1
	mov ebx, 3
	mul bx
	mov ecx, eax
	
	mov eax, 0
	mov ax, [g_sel_x]
	mov ebx, 0
	mov bx, [g_sel_y]
	sub bx, 200
	shr bx, 1
	mul ebx
	add ecx, eax
	add ecx, eax
	add ecx, eax

	mov edx, 0
	mov ebx, 0
    ;ebx line pos,   edx, img pos,  ecx,graph pos
.draw:
    mov byte al, [ds:ebx+edx+img]
    mov byte [gs:ebx+ecx],al
    inc ebx
    cmp ebx, 600
    jnz .c2
	mov ebx,0
    mov bx,[g_sel_x]
    add ecx,ebx
    add ecx,ebx
    add ecx,ebx
    mov ebx,0
    add edx,600
.c2:
    cmp edx,600*200
    jnz .draw

    jmp $

img
%include "/media/sf_build_bpi_lede/200x200.txt"
;%include "/media/sf_build_bpi_lede/hua.txt"
;%include "debug.txt"
;%include "debug2.txt"
jmp $
