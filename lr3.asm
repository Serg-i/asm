.model small
.stack 200h
.386
.data
file1_name db 'file1',0h
file1 dw ?
file1_byte_map db 255 dup(?)
file1_byte_map_l db 0
file2_name db 'file2',0h
file2 dw ?
file2_byte_map db 255 dup(?)
file2_byte_map_l db 0
file3_name db 'file3',0h
file3 dw ?
file3_byte_map db 255 dup(?)
file3_byte_map_l db 0
file4_name db 'file4',0h
file4 dw ?
file4_byte_map db 255 dup(?)
file4_byte_map_l db 0
result_file_name db "file",0
result_file dw ?
buffer db 255 dup(0)
ABCD db 0,0,0,0
;errors messages 
file_error_mess db 10,13,"error: program can't open a file",10,13,"$"
file_create_error_mess db 10,13,"error: program can't create a file",10,13,"$"
file_read_error_mess db 10,13,"error: program can't read file",10,13,"$"
.code
.startup
mov ax,@data
mov ds,ax
mov es,ax

;create result file
lea dx,result_file_name
call create_file
mov [result_file],ax

;open file1
lea dx, file1_name
call open_file
mov [file1],ax

;open file2
lea dx, file2_name
call open_file
mov [file2],ax

;open file3
lea dx, file3_name
call open_file
mov [file3],ax

;open file4
lea dx, file4_name
call open_file
mov [file4],ax

;create byte map for file1
mov bx,file1
lea di,file1_byte_map
call get_byte_map
mov [file1_byte_map_l],ah

;create byte map for file2
mov bx,file2
lea di,file2_byte_map
call get_byte_map
mov [file2_byte_map_l],ah

;create byte map for file3
mov bx,file3
lea di,file3_byte_map
call get_byte_map
mov [file3_byte_map_l],ah

;create byte map for file4
mov bx,file4
lea di,file4_byte_map
call get_byte_map
mov [file4_byte_map_l],ah

; 1 'file'
lea si,file1_byte_map
mov cl,file1_byte_map_l
call check_array

mov bx,result_file
mov cl,ah 
lea dx,buffer
call write_to_file

lea si,file2_byte_map
mov cl,file2_byte_map_l
call check_array

mov bx,result_file
mov cl,ah
lea dx,buffer
call write_to_file
; 3 'file '
lea si,file3_byte_map
mov cl,file3_byte_map_l
call check_array

mov bx,result_file
mov cl,ah 
lea dx,buffer
call write_to_file
; 4 'file'
lea si,file4_byte_map
mov cl,file4_byte_map_l
call check_array

mov bx,result_file
mov cl,ah 
lea dx,buffer
call write_to_file

;end
call close_file
mov bx,file1
call close_file
mov bx,file2
call close_file
mov bx,file3
call close_file
mov bx,file4
call close_file
mov ah,4ch
int 21h
;procedures
;IN:	ds:dx - ascii string 
proc write_on_screen
	xor ax,ax
	mov ah,09h
	int 21h
	xor dx,dx
	ret
endp write_on_screen
;IN:	cx length of message
;	ds:dx buffer
;	bx - file descriptor
write_to_file proc
	xor ax,ax  
	mov ah,40h
	int 21h
	;mov bx,0001h; stdout
	xor ax,ax
	ret 
write_to_file endp
;IN:	ds:dx - ascii name of file1
;OUT:	ax - file descriptor 
open_file proc 
	mov ah,3dh		
	xor al,al
	int 21h
	jc file_open_error
	ret			
open_file endp
;IN:	ds:dx - ascii name of file1
;OUT:	ax - file descriptor 
create_file proc
	xor ax,ax
	mov ah,3ch
	xor cx,cx
	int 21h
	jc file_create_error
	ret 
create_file endp
;IN:	bx - file desc
set_start proc
	xor al, al
	xor cx, cx
	xor dx, dx
	mov ah, 42h
	int 21h
	ret
set_start endp
;IN:	bx - file desc 
close_file proc
	mov ah,3eh 
	int 21h
	ret  
close_file endp
;in:	di - address of buffer
clear_buff proc 
	cld 
	xor cx,cx
	mov cx,255
	mov al,0
	rep stosb
	ret
clear_buff endp
;in:	bx - file descriptor
;	dx - address of array	
;out:	cx -length
read_line proc
	push di
	push ax 
	lea di,buffer
	call clear_buff
	mov cl,255
	mov ah,3fh
	int 21h
	jc file_read_error 
	mov cx,ax
	pop ax
	pop di
	ret  
read_line endp
;in:	si - addres of array
;	cl - array length
;	al - byte 
;out:	dl 0/1 1 - contain, 0 - !contain
check_byte_in_array proc
 	cld
	push ax
	push di
	mov di,si
	xor dx,dx
	jcxz end_check_byte_in_array
	inc cx 
	repne scasb
	jcxz end_check_byte_in_array
	mov dl,1 
	end_check_byte_in_array:
	pop di
	pop ax
	ret 	
check_byte_in_array endp
;in:	si - source 
;	cl - length of source 
;out:	ah -length of buffer
;	buffer
check_array proc
push cx
lea di,buffer
call clear_buff
pop cx
lea di,buffer
xor ax,ax 
check_array_loop:
	lodsb
	call check_byte
	cmp dl,0
	je next_iter
	stosb
	inc ah
	next_iter:
	dec cx 
jnz check_array_loop
	ret
check_array endp
;IN:	al - byte
;OUt:	dl : 1 - needed, 0-not needed
check_byte proc ;(!ABCD+A!B!C!D+(!A*!D+A*D)*(!B*C+!C*B)) and some part of magic
	push ax
	push cx
	push di
	push si 
	lea di,ABCD
	mov dl,0
	mov [di],dl
	mov [di+1],dl
	mov [di+2],dl
	mov [di+3],dl
	;check for A (file1)
	lea si,file1_byte_map
	mov cl,file1_byte_map_l
	call check_byte_in_array
	mov [di],dl
	;check for B (file2)
	lea si,file2_byte_map
	mov cl,file2_byte_map_l
	call check_byte_in_array
	mov [di+1],dl
	;check for C (file3)
	lea si,file3_byte_map
	mov cl,file3_byte_map_l
	call check_byte_in_array
	mov [di+2],dl
	;check for D (file4)
	lea si,file4_byte_map
	mov cl,file4_byte_map_l
	call check_byte_in_array
	mov [di+3],dl
	;magic 
	;!ABCD
	xor dx,dx 
	mov dl,[di]
	not dl;!A
	and dl,[di+1];B
	and dl,[di+2];C
	and dl,[di+3];D
	jnz end_check_byte
	;A!B!C!D
	xor dx,dx
	xor ax,ax 
	mov dl,[di]
	mov al,[di+1];!B
	not al
	and dl,al
	mov al,[di+2];!C
	not al
	and dl,al
	mov al,[di+3];!D
	not al
	and dl,al
	jnz end_check_byte
	;(!A!D+AD)(!BC+!CB)
	xor dx,dx
	xor ax,ax
	mov dl,[di];!A
	not dl
	mov al,[di+3];!d
	not al
	and dl,al
	mov al,[di];A
	mov ah,[di+3];D
	and al,ah
	or dl,al
	push dx
	xor dx,dx
	xor al,al
	mov al,[di+1];b
	not al 
	and al,[di+2];c
	mov dl,[di+2];c
	not dl
	and dl,[di+1];
	or al,dl;()+()
	pop dx
	and dl,al;()() 
	end_check_byte:
	pop si
	pop di
	pop cx
	pop ax 
	ret 
check_byte endp
;in:	bx - file descriptor
;	di - address of reciever
get_byte_map proc
	xor ax,ax 
	read_file_loop:
	lea dx,buffer
	call read_line
	jcxz end_of_read
	lea si,buffer
	process_buffer:
		lodsb;load symbol from si in al
		push cx 
		push si
		push ax
		mov al,ah; put into ax length of reciever  
		xor ah,ah 
		sub di,ax; get begin of reciever 
		mov cx,ax 
		mov si,di; di address of byte map
		add di,ax; set current position
		pop ax
		jcxz set_char
		call check_byte_in_array
		cmp dl,0
		jne cont
		set_char: 
		stosb
		inc ah
		push ax
		mov dl,al
		mov ah,2h
		int 21h 
		pop ax 
		cont:
		pop si
		pop cx
		dec cx
	jnz process_buffer  
	jmp read_file_loop
	end_of_read:
	push ax
	mov dl,' '
	mov ah,2h
	int 21h
	pop ax
	ret
get_byte_map endp
;errors
file_open_error:
	lea dx,file_error_mess
	call write_on_screen
	jmp exit
file_create_error:
	lea dx,file_create_error_mess
	call write_on_screen
	jmp exit
file_read_error:
	lea dx,file_read_error_mess
	call write_on_screen
	jmp exit
exit:
xor ax,ax 
int 16h
mov ah,4ch
int 21h 
end
