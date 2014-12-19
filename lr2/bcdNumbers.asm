.model small
.stack
.data
buff db 255,?,255 dup(?); buffer for string 
filePath db "file.txt",0
fileDesc dw ?
menuMess db "write ",10,13," 1 - from BYR in USD ",10,13," 2 - from USD in BYR ",10,13," 3 - set course ",10,13,"$"
courseMess db 10,13,"current course is",10,13,"$"
setCourseMess db "write new course",10,13,"1 USD = ","$"
helpMess db 10,13,"press esc to exit in menu","$"
endLoopMess db 10,13,"end of loop",10,13,"$"
endMessage db 10,13,"Click to close",10,13,"$"
.code                                      
begin:
mov ax,@data
mov ds,ax
menu:
 	call write_course
	lea dx,menuMess
	call write_on_screen
	call read_in_buff 
	cmp buff[1],1
	jne exit
	cmp buff[2],'1'
	jne first
	;code
	jmp menu
first:
	cmp buff[2],'2'
	jne second
	;code
	jmp menu
second:	
	cmp buff[2],'3'
	jne exit;
	call write_course
	call read_course
	;code
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
proc createFile
	xor ax,ax 
	mov ah,3ch
	lea dx,filePath
	xor cx,cx
	int 21h
	mov fileDesc,ax
	jc  exit;todo open or create file
	ret; âîçâðàùåíèå óêàçàòåëÿ íà ìåñòî âûçîâà
endp createFile
exit:  
lea dx,endMessage
call write_on_screen
xor ax,ax
int 16h 
mov ah,4ch
int 21h
end begin
