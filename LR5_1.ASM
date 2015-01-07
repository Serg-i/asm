.model small
;common_data segment para common "data"
.data
buff db 250,?,250 dup(?); buffer for string
buff1 db 250,?,250 dup(?)
result db 100 dup(0)
belki db 50 dup(0)
belki_l db 0
result_l db 0
tmp_numb db 0
;common_data ends
.code
public _mult_bcd
public _convert_to_bcd
;assume ds:common_data
.startup
proc _convert_to_bcd
	push bp
	mov bp,sp
	push dx
	push cx
	push bx
	push di
	push si
	mov cx,255
	lea di,buff1
	call clear_buff
	xor cx,cx
	xor ax,ax
	mov si,[bp+4]
	mov cl,[bp+6]
	lea di,buff1
	add si,cx
	dec si
	to_bcd_loop:
	std
	lodsb
	sub al,30h
	cld
	stosb
	loop to_bcd_loop
	xor ax,ax
	lea ax,buff1
	pop si
	pop di
	pop bx
	pop cx
	pop dx
	pop bp
	ret
endp _convert_to_bcd
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
	mov cl,100
	xor di,di
	clear_result_loop:
		mov result[di],0
		inc di
	loop clear_result_loop
	mov result_l,0
	ret
endp clear_result
;di buff
;cl length
proc clear_buff
	push di
	xor di,di
	mov al,0
	rep stosb
	pop di
	ret
endp clear_buff
;IN:	DI - effective address of first number
;	SI - effective addrest of second number
;	dl - length of first number
;	dh - length of second number
; multiply bcd numbers (tmp) course*usd
;todo:	3)round to given accuracy
;	4)use stack
proc _mult_bcd
	push bp
	mov bp,sp
	push dx
	push cx
	push bx
	push di
	push si
	mov di,[bp+4]
	mov dl,[bp+6]
	mov si,[bp+8]
	mov dh,[bp+10]
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
	inc bx
	mov belki_l,bl
	lea di,belki
	mov dl,bl
	lea si,result
	mov dh,result_l
	call sum_bcd
	jmp mul_general_loop
	end_mult_bcd:
	xor bx,bx
	mov bl,result_l
	lea si,[result+bx]
	dec si
	lea di,buff
	mov cl,100
	call clear_buff	
	mov cl,result_l	
	converter:
	std
	lodsb
	add al,30h
	cld
	stosb
	loop converter
	lea ax,buff
	xor cx,cx
	xor bx,bx
	xor dx,dx
	pop si
	pop di
	pop bx
	pop cx
	pop dx
	pop bp
	ret
endp _mult_bcd
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
endp sum_bcd
end