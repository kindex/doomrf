unit fpgraph; // Graph unit for FPC, Based on standart graph.ppu + mygraph.tpu
// Resolutions: 640x480x256 - 1024x768x64K
// ~70 fps (clear&screen) on 300 Mhz [640x480x64K-base resolution]
// Andrey Ivanov kindex@mail.lv / DiVision / 9.2001
interface
  { $Define high} {High color}
const
  bit:array[1..3]of longint=(256,65536,256*256*256 {Not supported by FPC});
  maximumx=800; // When realise -> 1024x768
  maximumy=600;
  block=65536;
type
  xy=longint;
  tpoint=record
    x,y: xy;
  end;
  {$ifdef high}
  color=word; const bpp=2; {16 bit}
  {$else}
  color=byte; const bpp=1; {8 bit}
  {$endif}
  {Colors}
  white:color=15;
  grey:color=7;
  dark:color=8;
  black:color=0;
  red:color=4;
  blue:color=1;
  green:color=2;
  yellow:color=14; {green+blue}
  fon:color=0;
type
  tfont8x8=array[byte,0..7]of byte;
var
  scr:array[0..maximumy-1,0..maximumx-1]of color;
  min,max{draw view port},d,omin,omax,od{out to screen view port}: tpoint;
  bpl,mx,my:xy; {Bytes per line}
  fonth: integer;
  font8x8:tfont8x8;
  font8x14:array[byte,0..13]of byte;
  font8x16:array[byte,0..15]of byte;
  font8x19:array[byte,0..18]of byte;
  pal:array[0..256*4]of byte;

procedure setmode(const ax,ay:xy); // Setting up scree by calling InitGraph
procedure res2Mode(x, y, maxColor: longint; var driver,mode: smallInt); // Calculates mode
procedure closegraph; // Calls graph.closegraph
procedure retrace; // Wait for retrace
procedure screen;  // Move temporery buffer to screen
procedure screen(n,k: integer); // Moves buffer to screen
procedure screen(n: integer); // Moves buffer to screen
procedure screenr;  // Move temporery buffer to screen (reverse)

procedure clear;   overload;        // Clears buffer [Clip]
procedure clear(a:color); overload; // Fill buffer with color a [Clip]
procedure bar(ax,ay,bx,by:xy; c:color); // Fill box [Clip]

procedure setviewport(ax,ay,bx,by:integer); // Set view port (only clip when drawing and clearing)
procedure fullscreen; // View&Scree=FullScreen (mx,my)
procedure setscreenport(ax,ay,bx,by:integer); // Set region to draw to screen only from it from buffer
procedure screen_view; // Screen port := view port (only coords)

procedure putpixel(const ax,ay:xy; c:color); // Put pixel to buffer [Clip]
function  rgb(r,g,b : byte) : longint; // 24->16   or 24->8
procedure dergb_16(l : longint;var r,g,b : byte); // 16->24

procedure linex(x,y,y2:xy; c:color); // Vertical line(x,y,x,y2)
procedure line(x1,y1,x2,y2:xy; c:color); // User line
procedure liney(y,x,x2:xy; c:color); // Horizontal line(x,y,x2,y)
procedure rectangle(x1,y1,x2,y2,c:integer);

procedure print(x,y:xy; c:color; s:string); // Print using current font [Clip]
procedure setfont(h:integer);  // Setting current of font (8,14,16,19)-Height
procedure loadfont(a:string;h:integer); // Load For russian language - 8xh.fnt

Procedure loadpal(name:string);
Procedure setpal;
Procedure loadpal2(name:string);
{$ifndef high}

function getcolor(r,g,b:longint):byte; {$endif}

procedure sprite(var a; x,y,l:xy); // Move line to buffer

implementation
uses graph,go32,api,ports;

function getcolor(r,g,b:longint):byte;
var i,last:byte;
    min,cur:longint;
begin
   min:=maxlongint;
   last:=0;
   for i:=0 to 255 do
   begin
     cur:=sqr(r-pal[i*4+2])+sqr(g-pal[i*4+1])+sqr(b-pal[i*4+0]);
     if cur<min then begin min:=cur; last:=i; end;
   end;
   getcolor:=last;
end;

Procedure loadpal(name:string);
var ff:file;
    i,c,max,t:integer;
begin
  assign(ff,name);
{$i-}  reset(ff,1); {$i+}
if ioresult<>0 then exit;
  seek(ff,54);
  blockread(ff,pal,256*4);
  close(ff);
  port[$3c8]:=0;
  c:=255; max:=0;
  for i:=0 to 255 do
  begin
(*r*)  port[$3c9]:=pal[(i*4)+2] div 4;
(*g*)  port[$3c9]:=pal[(i*4)+1] div 4;
(*b*)  port[$3c9]:=pal[(i*4)+0] div 4;
  end;
  white:=getcolor(255,255,255);
  red:=getcolor(255,0,0);
  green:=getcolor(0,255,0);
  blue:=getcolor(0,0,255);
  grey:=getcolor(200,200,200);
  dark:=getcolor(100,100,100);
end;
Procedure setpal;
var
  i:integer;
begin
  port[$3c8]:=0;
  for i:=0 to 255 do
  begin
(*r*)  port[$3c9]:=pal[(i*4)+2] div 4;
(*g*)  port[$3c9]:=pal[(i*4)+1] div 4;
(*b*)  port[$3c9]:=pal[(i*4)+0] div 4;
  end;
end;
Procedure loadpal2(name:string);
var ff:file;
    i,c,max,t:integer;
begin
  assign(ff,name);
{$i-}  reset(ff,1); {$i+}
if ioresult<>0 then exit;
  seek(ff,54);
  blockread(ff,pal,256*4);
  close(ff);
  c:=255; max:=0;
{  port[$3c8]:=0;
  for i:=0 to 255 do
  begin
(*r*)  port[$3c9]:=pal[(i*4)+2] div 4;
(*g*)  port[$3c9]:=pal[(i*4)+1] div 4;
(*b*)  port[$3c9]:=pal[(i*4)+0] div 4;
  end;}
  white:=getcolor(255,255,255);
  red:=getcolor(255,0,0);
  green:=getcolor(0,255,0);
  blue:=getcolor(0,0,255);
  grey:=getcolor(200,200,200);
  dark:=getcolor(100,100,100);
end;

procedure setmode(const ax,ay:xy);
const
  w=255;
var
  gd,gm:integer;
begin
  res2mode(ax,ay,bit[bpp],gd,gm);

  InitGraph(gd,gm,'');
{  if graphresut<>grOk then begin
    writeln('Can not initialize graphics mode. Halting...');
    halt;
  end;}
  mx:=ax;
  my:=ay;
  fullscreen;
  bpl:=ax*bpp;
  clear;
  if bpp=2 then begin
  black:=rgb(0,0,0);
  red  :=rgb(w,0,0);
  blue :=rgb(0,0,w);
  green:=rgb(0,w,0);

 yellow:=rgb(w,w,0);
{       :=rgb(w,0,w);
       :=rgb(w,w,0);}
  white:=rgb(w,w,w);
  end;
  fon:=black;
end;

procedure sprite(var a; x,y,l:xy);
var
  d:xy;
  b:array[0..1024]of color absolute a;
begin
  if (y>max.y)or(y<min.y)or(x+l<min.x)or(x>max.x) then exit;
  if x+l>max.x then l:=max.x-x+1;
  if x<min.x then begin
    d:=min.x-x;
    l:=l-(min.x-x);
    x:=min.x;
    move(b[d],scr[y,x],l*bpp);
  end else
  move(a,scr[y,x],l*bpp);
end;

procedure screen(n:integer); // Moves buffer to screen
var
  i,izl,bp,d,dx:xy;
begin
  bp:=od.x*bpp; d:=0; dx:=0;
  for i:=omin.y+1 to omax.y-1 do
//  if random(n)=0 then
  begin
    dx:=round(cos((i+n)/30)*100);

    graph.putpixel(omin.x{+dx},i,0);
    if ((omin.x*bpp+i*bpl) div block)=((omax.x*bpp+i*bpl) div block) then
    dosmemput(sega000,(omin.x*bpp+i*bpl)mod block,scr[i,omin.x+dx],bp)
    else begin
      izl:=(block-((omin.x*bpp+i*bpl)mod block));
      dosmemput(sega000,(omin.x*bpp+i*bpl)mod block,scr[i,omin.x+dx],izl);
      graph.putpixel(omin.x+izl div bpp,i,0);
      dosmemput(sega000,0,scr[i,omin.x+dx+izl div bpp],bp-izl)
    end;
  end;
end;

procedure screen; // Moves buffer to screen
var
  i,izl,bp:xy;
begin
  bp:=od.x*bpp;
  for i:=omin.y to omax.y do
  begin
    graph.putpixel(omin.x,i,0);
    if ((omin.x*bpp+i*bpl) div block)=((omax.x*bpp+i*bpl) div block) then
    dosmemput(sega000,(omin.x*bpp+i*bpl)mod block,scr[i,omin.x],bp)
    else begin
      izl:=(block-((omin.x*bpp+i*bpl)mod block));
      dosmemput(sega000,(omin.x*bpp+i*bpl)mod block,scr[i,omin.x],izl);
      graph.putpixel(omin.x+izl div bpp,i,0);
      dosmemput(sega000,0,scr[i,omin.x+izl div bpp],bp-izl)
    end;
  end;
end;

procedure screen(n,k: integer); // Moves buffer to screen
var
  i,izl,bp:xy;
begin
  bp:=od.x*bpp;
  for i:=omin.y to omax.y do
  if (i+k) mod n=0 then
  begin
    graph.putpixel(omin.x,i,0);
    if ((omin.x*bpp+i*bpl) div block)=((omax.x*bpp+i*bpl) div block) then
    dosmemput(sega000,(omin.x*bpp+i*bpl)mod block,scr[i,omin.x],bp)
    else begin
      izl:=(block-((omin.x*bpp+i*bpl)mod block));
      dosmemput(sega000,(omin.x*bpp+i*bpl)mod block,scr[i,omin.x],izl);
      graph.putpixel(omin.x+izl div bpp,i,0);
      dosmemput(sega000,0,scr[i,omin.x+izl div bpp],bp-izl)
    end;
  end;
end;

procedure screenr; // Moves buffer to screen
var
  i,j,izl,bp:xy;
begin
  bp:=od.x*bpp;
  for j:=omin.y to omax.y do
  begin
    i:=max.y-j;
    graph.putpixel(omin.x,i,0);
    if ((omin.x*bpp+i*bpl) div block)=((omax.x*bpp+i*bpl) div block) then
    dosmemput(sega000,(omin.x*bpp+i*bpl)mod block,scr[j,omin.x],bp)
    else begin
      izl:=(block-((omin.x*bpp+i*bpl)mod block));
      dosmemput(sega000,(omin.x*bpp+i*bpl)mod block,scr[j,omin.x],izl);
      graph.putpixel(omin.x+izl div bpp,i,0);
      dosmemput(sega000,0,scr[j,omin.x+izl div bpp],bp-izl)
    end;
  end;
end;

procedure linex(x,y,y2:xy; c:color);
var i:integer;
begin
  if y2>y then for i:=y to y2 do putpixel(x,i,c);
  if y>y2 then for i:=y2 to y do putpixel(x,i,c);
end;
procedure liney(y,x,x2:xy; c:color);
var i:integer;
begin
{  if x2>x then for i:=x to x2 do putpixel(i,y,c);
  if x>x2 then for i:=x2 to x do putpixel(i,y,c);}
  if x2<x then begin i:=x; x:=x2; x2:=i;end;
    bar(x,y,x2,y,c);
end;
procedure line(x1,y1,x2,y2:xy; c:color);
var a,b:real;
    z,i:integer;
begin
 if ((x1<min.x)and(x2<min.x))or
    ((x1>max.x)and(x2>max.x))or
    ((y1<min.y)and(y2<min.y))or
    ((y1>max.y)and(y2>max.y))then exit;
 if (x2<x1)and(y2<y1)then begin   z:=x2;  x2:=x1;  x1:=z; z:=y2;  y2:=y1;  y1:=z;end;
 if x1=x2 then linex(x1,y1,y2,c);
 if y1=y2 then liney(y1,x1,x2,c);
 if not((x1=x2)or(y1=y2)or((x2-x1)=0)or((y2-y1)=0))
 then
 begin
  a:=(x2-x1)/(y2-y1);
  b:=(y2-y1)/(x2-x1);
  if (a>1)or(a<-1) then
    if (x2-x1)>0 then   for i:=0 to x2-x1 do  putpixel(i+x1,round(i*b)+y1,c)
    else    for i:=0 to abs(x2-x1) do  putpixel(x1-i,y1-round(i*b),c)
  else
   if (y2-y1)>0 then  for i:=0 to (y2-y1) do  putpixel(round(i*a)+x1,i+y1,c)
   else  for i:=0 to abs(y2-y1) do  putpixel(x1-round(i*a),y1-i,c);
end;
end;
procedure rectangle(x1,y1,x2,y2,c:integer);
begin
  line(x1,y1,x2,y1,c);
  line(x1,y1,x1,y2,c);
  line(x2,y1,x2,y2,c);
  line(x1,y2,x2,y2,c);
end;

function rgb(r,g,b : byte) : longint;
{$ifdef high}
assembler;
asm
  mov   al,b
  mov   ah,g
  shr   ah,2
  mov   bl,r
  shr   ax,3
  and   bl,11111000b
  or    ah,bl
  xor   dx,dx
end;
{$else high}
begin
 rgb:=getcolor(r,g,b);
end;
{$endif}
procedure dergb_16(l : longint;var r,g,b : byte);assembler;
asm
  mov   ax,word ptr l
  mov   bx,ax
  and   ax,1111100000011111b
  shl   al,3
  les   edi,b
  mov   es:[edi],al
  les   edi,r
  mov   es:[edi],ah
  and   bx,11111100000b
  shr   bx,3
  les   edi,g
  mov   es:[edi],bl
end;

procedure retrace; assembler;
asm
        mov  dx,3dah;
@vert1: in   al,dx;
        test al,8;
        jz   @vert1
@vert2: in   al,dx;
        test al,8;
        jnz  @vert2;
end;
procedure setscreenport(ax,ay,bx,by:integer);
begin
  omin.x:=ax;
  omin.y:=ay;
  omax.x:=bx;
  omax.y:=by;
  od.x:=bx-ax+1;
  od.y:=by-ay+1;
end;
procedure setviewport(ax,ay,bx,by:integer);
begin
  min.x:=ax;
  min.y:=ay;
  max.x:=bx;
  max.y:=by;
  d.x:=bx-ax+1;
  d.y:=by-ay+1;
end;

procedure fullscreen;
begin
  setviewport(0,0,mx-1,my-1);
  setscreenport(0,0,mx-1,my-1);
end;

procedure res2Mode(x, y, maxColor: longint; var driver,mode: smallInt); // Original - FPC
var l: longint;
begin
   case maxColor of
     2: driver := D1bit;
     4: driver := D2bit;
     16: driver := D4bit;
     64: driver := D6bit;
     256: driver := D8bit;
     4096: driver := D12bit;
     32768: driver := D15bit;
     65536: driver := D16bit;
{     65536*256: driver := D24bit;
     65536*65536: driver := D32bit; not supported}
     else begin
       driver := maxsmallint;
       exit;
     end;
   end;
   { Check whether this is known/predefined mode }
   for l := lowNewMode to highNewMode do
     if (resolutions[l].x = x) and
        (resolutions[l].y = y) then begin
         { Found! }
         mode := l;
         exit;
       end;
   { Not Found }
   mode := maxsmallint;
end;

procedure clear; // Clears buffer [clip]
begin
  bar(0,0,mx-1,my-1,fon);
end;
procedure clear(a:color); // Clears buffer [clip]
begin
  bar(0,0,mx-1,my-1,a);
end;
procedure putpixel(const ax,ay: xy; c:color);
begin
  if (ax>=min.x)and(ax<=max.x)and(ay>=min.y)and(ay<=max.y)then
    scr[ay,ax]:=c;
end;
procedure bar(ax,ay,bx,by:xy; c:color);
var
  i,d:xy;
begin
  if ax<min.x then ax:=min.x;
  if ay<min.y then ay:=min.y;
  if bx>max.x then bx:=max.x;
  if by>max.y then by:=max.y;
  d:=(bx-ax+1);
  for i:=ay to by do
  {$ifdef high}
    fillword(scr[i,ax],d,c); {x2 bytes}
  {$else}
    fillchar(scr[i,ax],d,c);
  {$endif}
end;
procedure closegraph; // Calls graph.closegraph
begin
  graph.closegraph;
  mx:=0; my:=0; setviewport(0,0,-1,-1);
end;
procedure print8(x,y:xy; c:color; s:string);
var
  i,j,k:integer;
begin
 if (x+length(s)*8>=min.x)and(y+fonth>=min.y)and(x<=max.x)and(y<=max.y) then
 begin
   for k:=1 to length(s) do
    for i:=0 to fonth-1 do
     for j:=0 to 7 do
     if odd(font8x8[ord(s[k]),i] shr j) then
       putpixel((x+(k-1)*8+7-j),y+i,c);
  end;
end;
procedure print14(x,y:xy; c:color; s:string);
var
  i,j,k:integer;
begin
 if (x+length(s)*8>=min.x)and(y+fonth>=min.y)and(x<=max.x)and(y<=max.y) then
 begin
   for k:=1 to length(s) do
    for i:=0 to fonth-1 do
     for j:=0 to 7 do
     if odd(font8x14[ord(s[k]),i] shr j) then
       putpixel((x+k*8+7-j),y+i,c);
  end;
end;
procedure print16(x,y:xy; c:color; s:string);
var
  i,j,k:integer;
begin
 if (x+length(s)*8>=min.x)and(y+fonth>=min.y)and(x<=max.x)and(y<=max.y) then
 begin
   for k:=1 to length(s) do
    for i:=0 to fonth-1 do
     for j:=0 to 7 do
     if odd(font8x16[ord(s[k]),i] shr j) then
       putpixel((x+k*8+7-j),y+i,c);
  end;
end;
procedure print19(x,y:xy; c:color; s:string);
var
  i,j,k:integer;
begin
 if (x+length(s)*8>=min.x)and(y+fonth>=min.y)and(x<=max.x)and(y<=max.y) then
 begin
   for k:=1 to length(s) do
    for i:=0 to fonth-1 do
     for j:=0 to 7 do
     if odd(font8x19[ord(s[k]),i] shr j) then
       putpixel((x+k*8+7-j),y+i,c);
  end;
end;
procedure print(x,y:xy; c:color; s:string);// Default - 8x8 English font from ROM
begin
  case fonth of
   8: print8(x,y,c,s);
   14: print14(x,y,c,s);
   16: print16(x,y,c,s);
   19: print19(x,y,c,s);
   else print8(x,y,c,s);
  end;
end;
procedure setfont(h:integer);// Height of font (8,14,16,19)
begin
  fonth:=h;
end;
procedure loadfont(a:string; h:integer); // Load For russian language - 8x8.fnt
var
  f:file;
begin
{$i-}  assign(f,a+'8x'+st(h)+'.fnt');
  reset(f,1);{$i+}
  if ioresult<>0 then exit;
  case h of
   8: blockread(f,font8x8,256*h);
   14: blockread(f,font8x14,256*h);
   16: blockread(f,font8x16,256*h);
   19: blockread(f,font8x19,256*h);
  end;
  close(f);
  setfont(h);
end;
procedure screen_view; // Screen port := view port (only coords)
begin
  omin:=min;
  omax:=max;
  od:=d;
end;
begin
  dosmemget($F0A0,$F06E,font8x8,256*8);// Load system font 8x8 (Only English)
  setfont(8);
end.
