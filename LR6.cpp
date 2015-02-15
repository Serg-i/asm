#include <sys/types.h>
#include <sys/stat.h>
#include <sys/locking.h>
#include <share.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <io.h>
#include <windows.h>

void mmx(void * man, void * bac, int s)
{
//фон на котором расположен человечек
__int64 mask = 0x2222222222222222;
__int64 mask1 =0xffffffffffffffff;
__asm
{
mov esi, man
mov edi, bac
mov ecx, s
l1:
movq mm2,mask
movq mm0, [esi] //;загрузить восемь байтов человечка 
movq mm1, [edi] //;загрузить восемь байтов фона
pcmpeqb mm2, mm0 //
por mm0, mm2 //сделать человечка с человечка
movq mm4,mm1 //фон сохранить 
por mm1,mm2 // сделать человечка с фона 
pcmpeqb mm1,mm4// создать маску для вырезания человечка из фона 
por mm4,mm1//вырезать человечка с фона
pand mm4,mm0//вставить человечка в фон
movq [edi],mm4  //;сохранить их обратно на изображение 3.48 утра запилено
add esi, 8
add edi, 8
sub ecx,8
cmp ecx,0
jg l1
//emms
}
}

int main(int argc, char* argv[])
{
int h_bmp1, h_bmp2, h_bmp3;
errno_t err_file1 = _sopen_s(&h_bmp1,"man.bmp", _O_RDONLY, _SH_DENYNO,_S_IREAD | _S_IWRITE);
errno_t err_file2 = _sopen_s(&h_bmp2,"background.bmp", _O_RDONLY, _SH_DENYNO,_S_IREAD | _S_IWRITE);
h_bmp3 = _creat( "res.bmp", _S_IREAD | _S_IWRITE );
   if( err_file1||err_file2||(h_bmp3==-1))
      exit( 1 );
unsigned char * buf_bmp1, * buf_bmp2, * man, * background;
unsigned long len_bmp1, len_bmp2;
len_bmp1 = _filelength(h_bmp1);
len_bmp2 = _filelength(h_bmp2);

man = buf_bmp1 = new unsigned char[len_bmp1];
background = buf_bmp2 = new unsigned char[len_bmp2];
buf_bmp1=background;//
_read(h_bmp1, man, len_bmp1);
_read(h_bmp2, background, len_bmp2);

BITMAPFILEHEADER bmp_fh1, bmp_fh2;
BITMAPINFO bmp_inf1, bmp_inf2;
bmp_fh1 = *((BITMAPFILEHEADER*)man);
bmp_fh2 = *((BITMAPFILEHEADER*)background);
man = man + sizeof(BITMAPFILEHEADER);
background = background + sizeof(BITMAPFILEHEADER);
bmp_inf1 = *((BITMAPINFO*)man);
bmp_inf2 = *((BITMAPINFO*)background);
man = man + sizeof(BITMAPINFO);
background = background + sizeof(BITMAPINFO);
mmx(man,background, bmp_inf1.bmiHeader.biSizeImage);
_write(h_bmp3,buf_bmp1/*man*/, len_bmp1);

_close(h_bmp1);
_close(h_bmp2);
_close(h_bmp3);

return 0;
}
