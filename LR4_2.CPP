//first, first_l,second, second_l,result
#include <string.h>
#include <stdio.h>
extern "C" unsigned char* mult_bcd(unsigned char(*)[40],unsigned char,unsigned char(*)[40],unsigned char);
void main(void){
unsigned char second[40] = {1,0,2,4};
unsigned char first[40]={0,2};
unsigned char first_l =4;
unsigned char second_l = 2;
unsigned char* smth;
smth = mult_bcd(&first,first_l,&second,second_l);
printf("%s",smth);
getchar();
}