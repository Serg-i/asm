.model small
.386
.stack 200h
.data
max_length equ 25
accuracy equ 4
zero_flag db 1
comma_flag db 0
comma_pos db 0
buff db 250,?,250 dup(?); buffer for string
course db 0,5,7,3,1,45 dup(0); default course
course_l db 5
course_f db 0
usd db 50 dup(0)
usd_l db 0
usd_f db 0 
belki db 50 dup(0)
belki_l db 0
tmp_numb db 0
filePath db "file.txt",0
fileDesc dw ?
menuMess db 10,13,"write ",10,13," 1 - from USD in BYR ",10,13," 2 - set course ",10,13,"$"
courseMess db 10,13,"current course is ","$"
course_mess_l db 20
setCourseMess db 10,13,"write new course",10,13,"1 USD = ","$"
set_usd_mess db 10,13,"write fund in usd: ","$"
usd_mess db 10,13,"fund in usd: ","$"
usd_mess_l db 15
get_byr_mess db 10,13,"fund in byr: ","$"
get_byr_mess_l db 15
helpMess db 10,13,"press esc to exit in menu","$"
endLoopMess db 10,13,"end of loop",10,13,"$"
endMessage db 10,13,"Click to close",10,13,"$"
file_error_mess db 10,13,"error: program can't open/create a file",10,13,"$"
number_error_mess db 10,13,"error: not a number",10,13,"$"
max_length_mess db 10,13, "error: max length is 25 symbols",10,13,"$"
a db 9,9,9,9,9,1
b db 0,0,0,0,4
result db 100 dup(0)
result_l db 0
.code                                      
.startup
mov ax,@data
mov ds,ax
call write_course_on_screen
call open_file
menu:
	lea dx,menuMess
	call write_on_screen
	call read_in_buff 
	cmp buff[1],1
	jne exit
	cmp buff[2],'1'
	jne first
	lea dx,set_usd_mess
	call write_on_screen
	call clear_buff
	call clear_usd
	call read_in_buff
	lea si,usd
	call read_number_from_buff
	mov [usd_l],al
	mov [usd_f],ah
	lea dx,usd_mess
	mov cl,usd_mess_l
	call write_to_file
	lea dx,buff
	add dx,2
	mov cl,[buff+1]
	dec cx
	call write_to_file
	lea dx,get_byr_mess
	call write_on_screen
	lea di,course
	mov dl,course_l
	lea si,usd
	mov dh,usd_l
	call mult_bcd
	call round_number
	mov cl,result_l
	mov dl,result_l
	sub dl,[usd_f]
	sub dl,[course_f]; set position of comma from beginning of number
	lea di,result 
	call write_number_to_buf
	call detect_zeroes_at_begin
	lea dx,buff
	add dx,2
	add dx,ax
	call write_on_screen
	lea dx,get_byr_mess
	mov cl,get_byr_mess_l
	call write_to_file
	lea dx,buff
	add dx,2
	mov cl,[buff+1]
	dec cx
	call write_to_file
	jmp menu
first:	
	cmp buff[2],'2'
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
	lea dx,courseMess
	mov cl,course_mess_l
	call write_to_file
	lea dx,buff
	add dx,2
	mov cl,[buff+1]
	dec cx
	call write_to_file
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
proc clear_usd
	mov cl,usd_l
	cmp cl,0
	je end_clear_usd
	xor di,di
	clear_usd_loop:
		mov usd[di],0
		inc di
	loop clear_usd_loop
	mov usd_l,0
	end_clear_usd:
	ret
endp clear_usd
;in:	BUFF
;out:	ax - length unuseful zeroes 
proc detect_zeroes_at_begin
	xor ax,ax
	xor bx,bx
	xor dx,dx
	add bx,2
	mov dh,[buff+1]
	inc dh
	detect_zeroes_at_begin_l:
	mov dl, buff[bx]
	cmp dl,'0'
	jne end_detect 
	mov dl,buff[bx+1];for 0,01
	cmp dl,','
	je end_detect
	inc bl
	cmp bl,dh ;all zeroes)
	jne detect_zeroes_at_begin_l
	dec bx
	end_detect:
	sub bx,2
	mov ax,bx
	ret
endp detect_zeroes_at_begin
;IN:	buff
;OUT:	boolean
proc detect_comma
	xor cx,cx
	xor bx,bx
	mov cl,[buff+1]
	add bx,2
	detect_comma_loop:
		mov dl, buff[bx]
		cmp dl,','
		jne detect_comma_cont
		mov [comma_flag],1
		detect_comma_cont:
	loop detect_comma_loop
	ret
endp detect_comma
; read from buff to BCD  
;	IN:	SI- addres of BCD 
;	OUT:	Al - length of bcd
;		AH - fractal length
proc read_number_from_buff
	mov [comma_flag],0
	mov [zero_flag],1
	call detect_comma
 	xor cx,cx
	xor ax,ax
	xor dx,dx
	xor bx,bx
	mov cl,buff[1]
	call detect_zeroes_at_begin
	mov dl,al
	sub cl,dl
	cmp cl,0
	je zero_mode
	mov bl,[buff+1]
	mov al,[buff+1]
	inc bx
	cmp al,max_length
	jg max_length_error
	sub al,dl
	r_convert_loop:
		mov dl,buff[bx]
		cmp dl,','
		jne r_convert_continue0
		cmp ah,0
		jne number_error 
		mov ah,[buff+1]
		dec al; -','
		cmp [zero_flag],1 ; for 1,0000(0) input
		jne set_fractal_length
		mov ah,0
		mov [zero_flag],0
		jmp r_convert_continue3
		set_fractal_length:
		inc ah;
		sub ah,bl
		cmp ah,0
		je number_error
		jmp r_convert_continue3
	r_convert_continue0:
		cmp [comma_flag],1
		jne r_convert_continue1
		cmp [zero_flag],1;for 1,010(0) input
		jne r_convert_continue1
		cmp dl,'0'
		jne  r_convert_continue1
		inc dh
		dec al
		jmp r_convert_continue3
	r_convert_continue1:
		mov [zero_flag],0
		sub dl,30h
		cmp dl,9h
		jna r_convert_continue2
		jmp number_error		
	r_convert_continue2:
		mov [si],dl
		inc si
	r_convert_continue3:
		dec bx
	loop r_convert_loop
	jmp end_read; al-[buff+1]
	sub ah,dh
	zero_mode:
	mov dl,0h
	mov [si],dl
	mov al,1
	mov ah,0
	end_read:
	ret
endp read_number_from_buff
;IN:	DI - address of BCD
;	CL - length of BCD
;	dl - position of comma
;	dh - accuracy
;out:	bx - length of number
proc round_number;round result
	xor bx,bx
	;set inital data 
	lea di,result
	mov cl,result_l
	mov dl,[usd_f]
	add dl,[course_f];set position of comma from end of number
	mov dh,accuracy
	;code of procedure
	cmp dl,0
	je end_round_number
	cmp dl,dh 
	jle end_round_number
	sub dl,dh
	sub cl,dl ;decrease counter to round length
	mov bl,dl ; set index to rounded number 
	dec bl; correct pointer 
	mov al,[di + bx ]
	cmp al,5 
	jl end_round_number
	inc bx
	stc 
	round_loop:
	mov al,[di+bx]
	adc al,0
	aaa
	mov [di+bx],al
	inc bx
	loop round_loop
	mov al,[di+bx]
	adc al,0
	mov [di+bx],al
	mov result_l,bl
	end_round_number: 
	ret
endp round_number
; write bcd number in buff
;IN:	di - address of BCD
;	CL - length of BCD
;	dl - position of comma (from real begining of number)
;	dh - accuracy
proc write_number_to_buf
	xor ax,ax
	xor bx,bx
	add di,cx
	cmp dl,cl
	jnl write_number_to_buf_set_initial
	inc cx
	write_number_to_buf_set_initial:
	mov dh,accuracy
	inc bx ;correct start point of buff
	add dl,2 ;also need correction
	inc cx ;last number
	inc dh
	w_convert_loop:
		cmp bl,dl
		jne w_convert_loop_c0
		cmp dl,0
		mov buff[bx],','
		jmp move_index
	w_convert_loop_c0:
		jle w_convert_loop_c1
		dec dh
	w_convert_loop_c1:	
		mov al,[di]
		add al,30h
		mov buff[bx],al
		cmp dh,0
		jne move_val
		;round -remove 
		dec di
		mov al,[di]
		add al,5
		aaa
		jnc end_loop
		inc di
		mov al,[di]
		adc al,30h
		mov buff[bx],al 
		jmp end_loop
	move_val:
		dec di
	move_index:
		inc bx
	loop w_convert_loop
	end_loop:
	mov buff[bx],"$"
	dec bx
	mov buff[1],bl
	ret
endp write_number_to_buf
;write bcd course to screen 
proc write_course_on_screen
	lea dx,courseMess
	call write_on_screen
	mov cl,[course_l]
	mov dl,[course_l]
	sub dl,[course_f]
	lea di,course
	call write_number_to_buf
	lea dx,buff
	add dx,2
	call write_on_screen 
	ret
endp write_course_on_screen
;IN:	DI - effective address of first number
;	SI - effective addrest of second number
;	dl - length of first number 
;	dh - length of second number
; multiply bcd numbers (tmp) course*usd
;todo:	3)round to given accuracy
;	4)use stack
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
;log 
proc write_to_file;cx length of message, ds:dx buffer
	xor ax,ax  
	mov ah,40h
	mov bx,fileDesc
	int 21h
	xor ax,ax
ret 
endp write_to_file	
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