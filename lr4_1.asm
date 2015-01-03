.model small 
.stack 200h
.data
message db "string: ",0
format db "%10s"
buffer db 20 dup(?)
.code
	public _main
	extrn _scanf:proc
	extrn _printf:proc   
_main:
mov ax,@data
mov ds,ax
lea dx,buffer
push dx 
lea dx,format 
push dx
call _scanf
add sp,4
lea dx,message
push dx
call _printf
add sp,2
lea dx,buffer
push dx
call _printf
add sp,2
xor ax,ax
int 16h
mov ah,4ch
int 21h
end _main