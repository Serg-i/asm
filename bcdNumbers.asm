.model small
.386
.stack
.data
buff db 255,?,255 dup(?); buffer for string
a db 6
b db 7  
sum_a label word
sum_b db 0
carry db 0
course db 0,5,7,3,1; default course
usd db 20 dup(?)
usd_len db 0 
belki db 40 dup(?) 
filePath db "file.txt",0
fileDesc dw ?
menuMess db "write ",10,13," 1 - from BYR in USD ",10,13," 2 - from USD in BYR ",10,13," 3 - set course ",10,13,"$"
courseMess db 10,13,"current course is",10,13,"$"
setCourseMess db "write new course",10,13,"1 USD = ","$"
helpMess db 10,13,"press esc to exit in menu","$"
endLoopMess db 10,13,"end of loop",10,13,"$"
endMessage db 10,13,"Click to close",10,13,"$"
file_error_mess db 10,13,"error: program can't open/create a file",10,13,"$"
.code                                      
.startup
mov ax,@data
mov ds,ax
menu:
	call open_file
 	call write_course
	lea dx,menuMess
	call write_on_screen
	call read_in_buff 
	cmp buff[1],1
	jne exit
	cmp buff[2],'1'
	jne first
	mov al,a
	add al,b 
	jnc menu
	adc carry,0
	jmp menu
first:
	cmp buff[2],'2'
	jne second
	jmp menu
second:	
	cmp buff[2],'3'
	jne exit
	call write_course
	call read_course
	jmp menu
;procedures
proc write_on_screen;dx - message
	xor ax,ax
	mov ah,09h
	int 21h
	xor dx,dx
	ret
endp write_on_screen 
proc read_in_buff; save input in buf
	xor ax,ax
	mov ah,0ah
	lea dx,buff
	int 21h
	xor cx,cx
	ret
endp read_in_buff
proc read_number; read from buff in usd 
 	xor cx,cx
	xor di,di
	xor bx,bx
	mov cl,buff[1]
	mov bl,[buff+1]
	inc bx
convert_loop:
	mov dh,buff[bx]
	mov usd[di],dh
	inc di
	dec bx
	loop convert_loop
	ret 
endp read_number
proc write_course
	lea dx,courseMess
	call write_on_screen
;code
	ret
endp write_course
proc read_course
	lea dx,setCourseMess
	call write_on_screen
;code	
	xor ax,ax
	int 16h 
	ret
endp read_course
proc endlessLoop
	lea dx,helpMess
	call write_on_screen
	myLoop:
		int 16h
		xor ah,ah
		mov ah,01h
		jnz myLoop    
		mov ah, 00H    
		int 16H
		cmp ah,01h
		jne myLoop
	lea dx,endLoopMess
	call write_on_screen
	ret 
endp endLessLoop
proc open_file
	xor ax,ax 
	mov ah,3dh
	lea dx,filePath
	mov al,2
	int 21h
	mov fileDesc,ax
	jnc exit_create_file
        xor ax,ax 
	mov ah,3ch
	lea dx,filePath
	xor cx,cx
	int 21h
	mov fileDesc,ax
	jnc exit_create_file
	lea dx,file_error_mess
	call write_on_screen
	jmp exit	
exit_create_file:	
	ret
endp open_file
exit:  
lea dx,endMessage
call write_on_screen
mov ah,3eh
mov bx,fileDesc
int 21h;todo: catch error
xor ax,ax
int 16h 
mov ah,4ch
int 21h
end
