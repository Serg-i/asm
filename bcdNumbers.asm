.model small
.386
.stack 200h
.data
max_length equ 25
accuracy equ 4
comma_pos db 0
buff db 250,?,250 dup(?); buffer for string
course db 0,5,7,3,1; default course
course_l db 5
course_f db 0
usd db 20 dup(0)
usd_l db 0
usd_f db 0 
belki db 40 dup(0)
belki_l db 0
tmp_numb db 0
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
number_error_mess db 10,13,"error: not a number",10,13,"$"
max_length_mess db 10,13, "error: max length is 25 symbols",10,13,"$"
a db 9,9,9,9,9,1
b db 0,0,0,0,4
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
	mov dh,5
	lea di,a
	mov dl,6
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
	mov [usd_f],ah
	lea dx,get_byr_mess
	call write_on_screen
	lea di,course
	mov dl,course_l
	lea si,usd
	mov dh,usd_l
	call mult_bcd
	mov cl,result_l
	lea si,result
	mov al,result_l
	sub al,[usd_f]
	sub al,[course_f]
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
	mov [course_f],ah
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
proc clear_bcd
	mov cl,belki_l
	cmp cl,0
	je end_clear_bcd 
	xor di,di
	clear_bcd_loop:
		mov belki[di],0
		inc di
	loop clear_bcd_loop
	mov belki_l,0
	end_clear_bcd:
	ret 
endp clear_bcd
proc clear_result
	mov cl,result_l
	cmp cl,0
	je end_clear_result
	xor di,di
	clear_result_loop:
		mov result[di],0
		inc di
	loop clear_result_loop
	mov result_l,0
	end_clear_result:
	ret
endp clear_result
; read from buff to SI  
;	IN:	SI- addres of BCD 
;	OUT:	Al - length of bcd
;		AH - fractal length
proc read_number_from_buff
 	xor cx,cx
	xor ax,ax
	xor dx,dx
	xor bx,bx
	mov cl,buff[1]
	mov bl,[buff+1]
	mov al,[buff+1]
	inc bx
	cmp al,max_length
	jg max_length_error
	r_convert_loop:
		mov dl,buff[bx]
		cmp dl,','
		jne r_convert_continue0
		cmp ah,0
		jne number_error 
		mov ah,al
		dec al
		inc ah
		sub ah,bl
		cmp ah,0
		je number_error
		jmp r_convert_continue2
	r_convert_continue0:
		sub dl,30h
		cmp dl,9h
		jna r_convert_continue1
		jmp number_error		
	r_convert_continue1:
		mov [si],dl
		inc si
	r_convert_continue2:
		dec bx
	loop r_convert_loop
	ret 
endp read_number_from_buff
; write bcd number in buff
;IN:	SI - address of BCD
;	CL - length of BCD
;	al - position of comma (from real begining of number)
;	ah - accuracy
proc write_number_to_buf
	xor dx,dx
	xor bx,bx
	add si,cx
	cmp al,cl
	jnl write_number_to_buf_set_initial
	inc cx
	write_number_to_buf_set_initial:
	mov ah,accuracy
	inc bx ;correct start point of buff
	add al,2 ;also need correction
	inc cx ;last number
	w_convert_loop:
		cmp bl,al
		jne w_convert_loop_c0
		mov buff[bx],','
		jmp move_index
	w_convert_loop_c0:
		jle w_convert_loop_c1
		dec ah
	w_convert_loop_c1:	
		mov dl,[si]
		add dl,30h
		mov buff[bx],dl
		cmp ah,0
		jne move_val
		;round 
		dec si
		mov dl,[si]
		cmp dl,5
		jmp end_loop  
	move_val:
		dec si
	move_index:
		inc bx
	loop w_convert_loop
	end_loop:
	mov buff[bx],"$"
	dec bx
	mov buff[1],bl
	ret
endp write_number_to_buf
;write bcd to screen 
proc write_course_on_screen
	lea dx,courseMess
	call write_on_screen
	mov cl,[course_l]
	mov al,[course_l]
	sub al,[course_f]
	lea si,course
	call write_number_to_buf
	lea dx,buff
	add dx,2
	call write_on_screen 
	ret
endp write_course_on_screen
;IN:	DI - effective address of first number
;		SI - effective addrest of second number
;	 	dl - length of first number 
;		dh - length of second number
; multiply bcd numbers (tmp) course*usd
;todo:	1)clear result before perform multiplying
;		2)more than one number in usd:)
;		3)round to given accuracy
;		4)use stack
proc mult_bcd
	push di
	xor ax,ax;start at first digit
	mov al,dh
	add si,ax
	push si
	push dx
	call clear_result 
	mul_general_loop:
	call clear_bcd
	mov tmp_numb,0
	xor ax,ax
	xor dx,dx
	xor bx,bx 
	xor cx,cx
	xor di,di
	xor si,si
	pop dx; dl - first_l, dh - second_l
	pop si;second
	pop di;first 
	cmp dh,0
	jna end_mult_bcd
	dec si
	mov al,[si]
	mov tmp_numb,al
	dec dh
	cmp dh,0
	push di
	jna adding_zero_not_needed
	mov cl,dh
	xor bx,bx
	add_zeroes_at_end:
		mov belki[bx],0
		inc bx
	loop add_zeroes_at_end
	sub di,bx
	adding_zero_not_needed:
	push si
	push dx; save length of numbers
	mov cl,dl
	xor dx,dx
	clc
	mul_loop:
		mov al,[di+bx]
		mul tmp_numb
		aam
		adc al,dl
		aaa
		mov dl,ah
		mov belki[bx],al
		inc bx
	loop mul_loop
	jnc add_to_result
	adc belki[bx],0
	inc bx	
add_to_result:
	mov belki[bx],dl
	mov belki_l,bl 
	lea di,belki
	mov dl,bl
	lea si,result
	mov dh,result_l
	call sum_bcd
	jmp mul_general_loop
	end_mult_bcd:
	ret
endp mult_bcd
;IN:	DI - effective address of first number
;	SI - effective addrest of second number
;	dl - length of first number 
;	dh - length of second number
;OUT:	result - summ
;	result_l - length of summ
proc sum_bcd
	xor cx,cx
	xor ax,ax
	xor bx,bx
	cmp dx,0
	je end_sum_bcd
	cmp dl,0
	jne first_not_zero
	mov cl,dh
	mov di,si
	jmp set_numb
	first_not_zero:
	cmp dh,0
	jne both_not_zero
	mov cl,dl
	set_numb:
		mov al,[di]
		mov result[bx],al
		inc di
		inc bx
	loop set_numb
	jmp end_sum_bcd
both_not_zero:
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
	je end_sum_bcd
	jg greater_num
	sub dh,dl
	mov cl,dh
	mov di,si
	clc
	jmp correct_num
	greater_num:
	sub dl,dh 
	mov cl,dl
	clc
	correct_num:
		mov al,[di]
		adc al,0
		aaa
		mov result[bx],al
		inc bx
		inc di
	loop correct_num
	adc result[bx],0
	end_sum_bcd:
	mov result_l,bl
	ret
	xor di,di 
	xor si,si
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
	jc file_error
exit_create_file:	
	ret
endp open_file
;errors
file_error:
	lea dx,file_error_mess
	call write_on_screen
	jmp exit
number_error:
	lea dx,number_error_mess
	call write_on_screen
	jmp menu
max_length_error:
	lea dx,max_length_mess
	call write_on_screen
	jmp menu
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