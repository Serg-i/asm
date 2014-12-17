.model small
.stack
.data
buff db 255,?,255 dup(?); buffer for string 
filePath db "file.txt",0
fileDesc dw ?
menuMess db "write ",10,13," 1 - for loop ",10,13," smth else - to close ",10,13,"$"
menuMessL db 48
helpMess db 10,13,"press esc to exit in menu","$"
helpMessL db 27
endLoopMess db 10,13,"end of loop",10,13,"$"
endLoopMessL db 14
endMessage db 10,13,"Click to close",10,13,"$"
endMessageL db 18 
.code                                      
begin:;1)40h для ввода 2)бесконечный цикл + выход из него  3)весь ввод вывод в файл
mov ax,@data
mov ds,ax
call createFile
menu:
	mov dx,offset menuMess
	mov cl,menuMessL
	call write
	call read 
	cmp buff[1],1
	jne exit
	cmp buff[2],'1'
	jne exit
	call endlessLoop
	jmp menu
;procedures
proc write;cx length of message, ds:dx buffer
	xor ax,ax  
	mov ah,40h
	mov bx,fileDesc
	int 21h
	mov bx,0001h; stdout - êîíñîëü êàê ôàéë 
	xor ax,ax 
	mov ah,40h
	int 21h
	xor ax,ax
ret 
endp write 
proc read
	xor ax,ax
	mov ah,0ah
	lea dx,buff
	int 21h ;проверка наличия символа 
	xor cx,cx
	;cmp dx,'yes'; левое задание
	;jne proverkaNaNet
	;je writeToScreen
	;proverkaNaNet:
	;cmp dx,'no'
	;jne endOfProc
	writeToScreen:
	mov cl,buff[1] 
	mov dx,offset buff+2
	call write; вывод на экран
	endOfProc:
ret
endp read 
proc endlessLoop
	lea dx,helpMess
	mov cl,helpMessL
	call write
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
	mov cl,endLoopMessL
	call write
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
	ret
endp createFile
exit:  
lea dx,endMessage
mov cl,endMessageL
call write
xor ax,ax
int 16h 
mov ah,4ch
int 21h
end begin
