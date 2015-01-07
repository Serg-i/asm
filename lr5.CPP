#include <stdlib.h>									
#include <stdio.h>
#include <graphics.h>
#include <string.h>
#define scale  10
#define mark_size 2
extern "C" unsigned char* mult_bcd(unsigned char*,unsigned char,unsigned char*,unsigned char);
extern "C" unsigned char* convert_to_bcd(char *,unsigned char);
void draw_axes(int,int,int,int);
void draw_graph_bcd (int,int,int[],int);
void draw_graph_soproc(int,int, int[],int);
int sqr_x_proc(int);
int  sqr_x_bcd(int);
void draw_axes(int x_pos,int y_pos,int x_length,int y_length){
char msg[100];
setcolor(WHITE);
moveto(x_pos,y_pos);
lineto(x_pos, y_pos - y_length);
moveto(x_pos,y_pos);
lineto(x_pos+x_length,y_pos);
for(int i=0;i<x_length;i+=scale){
moveto(x_pos + i,y_pos-mark_size);
lineto(x_pos + i,y_pos+mark_size);
sprintf(msg,"%i",i);
//outtextxy(x_pos+i, y_pos+mark_size+10, msg);
}
for(int j=0;j<y_length;j+=scale){
moveto(x_pos-mark_size,y_pos-j);
lineto(x_pos+mark_size,y_pos-j);
sprintf(msg,"%i",j);
//outtextxy(x_pos-mark_size,y_pos-j, msg);
}
}

void draw_graph_bcd (int x_pos,int y_pos,int arrayX[],int arr_l){
setcolor(GREEN);
moveto(x_pos,y_pos);
for(int i=0;i<arr_l;i++){
lineto(x_pos+arrayX[i],y_pos-sqr_x_bcd(arrayX[i]));
}
}
void draw_graph_soproc(int x_pos,int y_pos, int arrayX[],int arr_l){
setcolor(RED);
moveto(x_pos,y_pos);
for(int i=0;i<arr_l;i++){
lineto(x_pos+arrayX[i],y_pos-sqr_x_proc(arrayX[i]));
}
}
sqr_x_proc(int x) {
int result;
_asm{
	finit
	fild x
	fimul x
	fist result
}
return result;
}
int  sqr_x_bcd(int x){
 char str_x[100];
 itoa(x,str_x,10);
 int l = strlen(str_x);
 unsigned char* bcd_x=convert_to_bcd(str_x,(unsigned char)l);
 char* str_y = mult_bcd(bcd_x,(unsigned char)l,bcd_x,(unsigned char)l);
 int z = atoi(str_y);
 return z;
}

void main()
{
   int x_pos1 = 10;
   int y_pos1 = 340;
   int x_pos2 = 270;
   int y_pos2 = 340;
   int axis_l = 300;
   int args_l=15;
   int args[15] = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15};
   int graphdriver = DETECT, graphmode;
   initgraph(&graphdriver, &graphmode, "..\\bgi");
   draw_axes(x_pos1,y_pos1,axis_l-150,axis_l);
   draw_graph_soproc(x_pos1,y_pos1,args,args_l);
   draw_axes(x_pos2,y_pos2,axis_l-150,axis_l);
   draw_graph_bcd(x_pos2,y_pos2,args,args_l);
   getchar();
   closegraph();
}