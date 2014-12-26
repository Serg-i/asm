.model small
.386
.stack
.data
buff db 255,?,255 dup(?); buffer for string
course db 0,5,7,3,1; default course
course_l db 5
usd db 20 dup(?)
usd_l db 0 
belki db 40 dup(?)
belki_l db 0
filePath db "file.txt",0
fileDesc dw ?
menuMess db 10,13,"write ",10,13," 1 - from BYR in USD ",10,13," 2 - from USD in BYR ",10,13," 3 - set course ",10,13,"$"
courseMess db 10,13,"current course is ","$"
setCourseMess db 10,13,"write new course",10,13,"1 USD = ","$"
set_usd_mess db 10,13,"write fund in usd: ","$"
get_byr_mess db 10,13,"fund in byr:","$"
helpMess db 10,13,"press esc to exit in menu","$"
endLoopMess db 10,13,"end of loop",10,13,"$"
endMessage db 10,13,"Click to close",10,13,"$"
file_error_mess db 10,13,"error: program can't open/create a file",10,13,"$"
a db 9,9,9,9,1
b db 8,1,4,5,6,7,8
result db 50 dup(0)
result_l db 0
.code                                      
.startup
mov ax,@data
mov ds,ax
call write_course_on_screen
menu:
	call open_file
	lea dx,menuMess
	call write_on_screen
	call read_in_buff 
	cmp buff[1],1
	jne exit
	cmp buff[2],'1'
	jne first
	;test sum
	xor dx,dx
	lea si,b
	mov dh,7
	lea di,a
	mov dl,5
	call sum_bcd
	lea si,result
	mov cl,result_l
	call write_number_to_buf
	lea dx,buff
	add dx,2 
	call write_on_screen
	jmp menu
first:
	cmp buff[2],'2'
	jne second
	lea dx,set_usd_mess
	call write_on_screen
	call clear_buff
	call read_in_buff
	lea si,usd
	call read_number_from_buff
	mov [usd_l],al
	lea dx,get_byr_mess
	call write_on_screen
	call mult_bcd
	mov cl,belki_l
	lea si,belki
	call write_number_to_buf	
	lea dx,buff
	add dx,2
	call write_on_screen
	jmp menu
second:	
	cmp buff[2],'3'
	jne exit
	call write_course_on_screen
	lea dx,setCourseMess
	call write_on_screen
	call read_in_buff
	lea si,course
	call read_number_from_buff
	mov [course_l],al 
	call write_course_on_screen
	jmp menu
;procedures
proc write_on_screen;dx - message
	xor ax,ax
	mov ah,09h
	int 21h
	xor dx,dx
	ret
endp write_on_screen 
; save input in buf
proc read_in_buff 
	xor ax,ax
	mov ah,0ah
	lea dx,buff
	int 21h
	xor cx,cx
	ret
endp read_in_buff
proc clear_buff
	xor cx,cx
	xor bx,bx 
	mov cl,[buff + 1]
	add bx,1
	clear_loop:
		mov buff[bx],0
		inc bx
	loop clear_loop
	ret
endp clear_buff
; read from buff to SI  
;	IN:		SI- addres of BCD 
;	OUT:	Al - length of bcd
proc read_number_from_buff
 	xor cx,cx
	xor dx,dx
	xor bx,bx
	mov cl,buff[1]
	mov bl,[buff+1]
	mov al,[buff+1]
	inc bx
	r_convert_loop:
		mov dl,buff[bx]
		sub dl,30h
		mov [si],dl
		inc si
		dec bx
	loop r_convert_loop
	ret 
endp read_number_from_buff
; write bcd number in buff
;	IN:		SI - address of BCD
;			CL - length of BCD
;todo:	1)process fractal numbers(which have given accuracy)
proc write_number_to_buf
	xor dx,dx
	xor bx,bx
	add si,cx
	add bx,1 ;correct start point of buff
	mov buff[1],cl
	inc cx; last number
	w_convert_loop:	
		mov dl,[si]
		add dl,30h 
		mov buff[bx],dl
		inc bx
		dec si
	loop w_convert_loop
	mov buff[bx],"$"
	ret
endp write_number_to_buf
;write bcd to screen 
proc write_course_on_screen
	lea dx,courseMess
	call write_on_screen
	mov cl,[course_l]
	lea si,course
	call write_number_to_buf
	lea dx,buff
	add dx,2
	call write_on_screen 
	ret
endp write_course_on_screen
; multiply bcd numbers (tmp) course*usd
;todo:	1)clear result before perform multiplying
;		2)more than one number in usd:)
;		3)round to given accuracy
proc mult_bcd
	xor ax,ax
	xor bx,bx
	xor dx,dx
	xor cx,cx
	xor di,di;parameter!
	xor si,si;parameter!
	lea si,usd
	lea di,course
	mov cl,course_l;parameter!
	mul_loop:
		mov al,[di]
		mul usd
		aam
		adc al,dl
		aaa
		mov dl,ah
		mov belki[bx],al
		inc di
		inc bx
	loop mul_loop
	mov belki[bx],dl
	mov belki_l,bl;out parameter! or rename to result :)
ret
endp mult_bcd
;IN:	DI - effective address of first number
;		SI - effective addrest of second number
;	 	dl - length of first number 
;		dh - length of second number
;OUT:	result - summ
;		result_l - length of summ
proc sum_bcd
	xor cx,cx
	xor ax,ax
	xor bx,bx
	cmp dl,dh
	jne set_min
	mov cl,dl
	clc
	jmp sum_loop
	set_min:
	jl set_x;cmp x,y
	mov cl,dh
	clc
	jmp sum_loop
	set_x:
	mov cl,dl
	clc
	sum_loop:
		mov al,[si]
		adc al,[di]
		aaa 
		mov result[bx],al
		inc bx 
		inc si 
		inc di
	loop sum_loop
	adc result[bx],0
	cmp dl,dh
	je fin_sum
	clc
	jg greater_num
	sub dh,dl
	mov cl,dh
	mov di,si
	jmp correct_num
	greater_num:
	sub dl,dh 
	mov cl,dl
	correct_num:
		mov al,result[bx]
		adc al,[di]
		aaa
		mov result[bx],al
		inc bx
		inc di
	loop correct_num
	adc result[bx],0
	fin_sum:
	mov result_l,bl
	ret
endp sum_bcd 
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
int 21h;todo: catch errors
xor ax,ax
int 16h 
mov ah,4ch
int 21h
end
