{$A+,B+,D+,E-,F-,G+,I+,L+,N+,O-,P-,Q-,R-,S-,T-,V+,X+,Y+ Filan}
{ $A+,B+,D+,E-,F+,G+,I+,L+,N+,O+,P+,Q+,R+,S+,T+,V+,X+,Y+ Debug}
{Patch for Grafx 1.3c by IVA vision 30.03.2001 [Andrey Ivanov kindeX]
Bugs:
!!! convert2spr: freemem(last,x*y) - error 204 - Stupid Pascal!
  Many procedures don't work (save)
  max sprite size = 64K
  Real mode max resolution = 640x400
  Protected mode don't run in Win (max res=640x400)
Fix:
  Buffer -> screen with 1 visual page
Overload
  Putpixel
  screen       <- SetVisualPage / You may wtite waitretrace before screen
  initgraph    <- set256mode
  closegraph
  loadpal
  putimage
  putline
  putsprite
  box          <- SetViewPort
  clear        <- cleardevice
+
 tBMP tSPR LoadBMP
 getfilename:string[8]
}
{$G+}
{Must be used after graphich (best - last)}
unit grafx;
interface
Uses graphics,gr_vars,crt,wads;
type
  tname=string[16];
const
  dbmp:tname='BMP\';
  maxpat=1500;
  white:byte=15;
type
  tfnt=array[0..255,1..8]of byte;
  tcaption=array[1..4]of char;
  tnpat=0..maxpat;
  tarray=array[0..64000]of byte;
  tbitmap=record
     caption:array[1..2]of char; {'BM'}
     Size  : longint;   {X*Y+FMT}
     Reserved1,Reserved2 : word;
     fmtsize     : longint;   {FMT}
     USize       : longint;   {40 ?}
     X,Y         : longint;
     pages      : word; {1}
     Bits    : word; {8}
     Compression   : longint;{0}
     ImageSize     : longint;{x*y}
     XPPM,YPPM : longint; {0}
     ClrUsed, ClrImportant  : longint  {?}
   end;
  tbmp=object
    x,y:longint;
    name:string[8];
    bmp: ^tArray;
{    function load(s:string):boolean;}
    procedure save8(s:string);
    procedure save24(s:string);
    procedure put(ax,ay:longint);
    procedure sprite(ax,ay:longint);
    procedure reverse;
    procedure done;
    function loadfile(s:string):boolean;
    function loadwad(s:string):boolean;
  end;
  tsprdata=
  record
    x,y:integer;
    w,l:word;
  end;
  arrayofspr=array[0..8000]of tsprdata;
  tspr=object(tbmp)
    spr:boolean;
    maxdata,maxbmp: longint;
    data:^arrayofspr;
    function load(s:string):boolean;
    function loadr(s:string):boolean;
    function loadfile(s:string):boolean;
    function loadwad(s:string):boolean;
    procedure convert2spr;
    procedure sprite(ax,ay:longint);
    procedure put(ax,ay:longint);
    procedure putrot(ax,ay:longint; r1,r2,r3,r4:real);
    procedure spritec(ax,ay:longint);
    procedure spritesp(ax,ay:longint);
    procedure save8(s:string);
    procedure done;
  end;
  tpat=tspr;
  arrayoftpat=array[tnpat]of tpat; {текстуры}
  tscreen=array[0..1200]of ^tarray;
var
  scr: tscreen;
  maxx,maxy,minx,miny:integer;
  getmaxx,getmaxy:integer;
  p: ^arrayoftpat;
  fnt:^tfnt;
  cbmp:^tarray;
  tempdata: ^arrayofspr;
  tempbmp:  ^tarray;
function loadbmp(s:string):integer;
function getfilename(s:string):string;
procedure putpixel(x,y:integer; c:byte);
procedure putline(x1,y1,sizex: integer;p : pointer);{draw a horizontal line with image of the pointer p}
procedure putimage(x,y,dx,dy: longint; var bmp: tarray);
procedure putsprite(x,y,dx,dy: longint; var bmp: tarray);
Procedure loadpal(name:string);
procedure screen;
procedure initgraph(res:integer);
procedure closegraph;
procedure box(x1,y1,x2,y2:integer);
procedure clear;
procedure bar(x1,y1,x2,y2:integer; c:byte);
procedure print(x,y,c:integer; s:string);
procedure line(x1,y1,x2,y2:integer; c:byte);
procedure loadfont(name:string);
procedure readline(x,y:integer; var str:string; last:string; col:byte; fl:integer);
procedure rectangle(x1,y1,x2,y2:integer; c:byte);
procedure swapb(var a,b:byte);
(*******************************)implementation(****************************)
procedure tspr.convert2spr;{from cbmp^}
const
  fon=0;
var
  last:^tarray;
  i,j,s,xy:longint;
begin
  if spr then exit;
  if x=0 then exit;
  xy:=x*y;
{  writeln(name);}
  maxdata:=0; maxbmp:=0;
{ if tempbmp<>nil then new(tempbmp);}
{  if tempdata<>nil then new(tempdata);}
  for i:=0 to y-1 do
  begin
    j:=0;
    repeat
      while (j<x)and(cbmp^[(i*x+j)mod xy]=fon) do inc(j);
      if j=x then continue;
      s:=j;
      while (j<x)and(cbmp^[(i*x+j)mod xy]<>fon) do inc(j);
      move(cbmp^[i*x+s],tempbmp^[maxbmp],j-s);
      tempdata^[maxdata].x:=s;
      tempdata^[maxdata].y:=i;
      tempdata^[maxdata].w:=maxbmp;
      tempdata^[maxdata].l:=j-s;
      inc(maxbmp,j-s);
      inc(maxdata);
    until (j+1)>=x;
  end;
{  writeln(name,': ',x*y);}
  bmp:=nil;
  getmem(bmp,maxbmp);
  move(tempbmp^,bmp^,maxbmp);
{  dispose(tempbmp);}
  data:=nil;
  getmem(data,maxdata*sizeof(tsprdata));
  move(tempdata^,data^,maxdata*sizeof(tsprdata));
{  dispose(tempdata);}
{  writeln(memavail);}
{  freemem(last,x*y); {ERROR}
  spr:=true;
end;
function tspr.loadfile(s:string):boolean;
var
  f:file;
  capt:tbitmap;
  i,ost,temp:longint;
begin
  x:=0; loadfile:=false; bmp:=nil;
  name:=getfilename(s);
  assign(f,s);
  {$i-}reset(f,1);{$i+}
  if ioresult<>0 then begin name:=''; exit; end;
  blockread(f,capt,sizeof(capt){54});
  if (capt.caption<>'BM')or(capt.bits<>8)or(capt.compression<>0) then begin close(f);exit; end;
  x:=capt.x;
  y:=capt.y;
{  if cbmp=nil then }
{  getmem(bmp,x*y);}
  case x mod 4 of
    0: ost:=0;
    1: ost:=3;
    2: ost:=2;
    3: ost:=1;
  end;
  seek(f,1078);
  for i:=y-1 downto 0 do
  begin
    blockread(f,cbmp^[i*x],x);
    if ost<>0 then blockread(f,temp,ost);
  end;
  close(f);
  loadfile:=true;
end;
function tspr.loadwad(s:string):boolean;
var dx,dy:integer;
begin
  if x>0 then done;
  name:=s;
  w.assign(name);
  w.read(x,2); w.read(y,2);
  w.read(dx,2); w.read(dy,2);
  if (w.cur.l=longint(x)*longint(y)+8)and(longint(x)*longint(y)<$fff0) then
  begin
    if cbmp=nil then new(cbmp);
{    getmem(bmp,x*y);}
    w.read(cbmp^,x*y);
    loadwad:=true;
  end else begin x:=0; y:=0; loadwad:=false; end;
end;
function tbmp.loadwad;
var dx,dy:integer;
begin
  if x>0 then done;
  name:=s;
  w.assign(name);
  w.read(x,2); w.read(y,2);
  w.read(dx,2); w.read(dy,2);
  if (w.cur.l=longint(x)*longint(y)+8)and(longint(x)*longint(y)<$fff0) then
  begin
    getmem(bmp,x*y);
    w.read(bmp^,x*y);
    loadwad:=true;
  end else begin x:=0; y:=0; loadwad:=false; end;
end;
{function tbmp.load;
begin
  if x<>0 then done;
  name:=s;
  if w.exist(name) then load:=loadwad(name) else
  begin
    load:=tbmp.loadfile(name);
    write('>');
  end;
end;}
function tspr.load;
begin
  if w.exist(s) then
  begin
    load:=tspr.loadwad(getfilename(s));
    if x<>0 then
     begin
       convert2spr;
       write(':');
     end;
  end
  else
  begin
    load:=tspr.loadfile(s);
    if x<>0 then
    begin
      convert2spr;
      write('.');
    end;
  end;
end;
procedure swapb(var a,b:byte);
var t:byte;
begin
  t:=a; a:=b; b:=t;
end;
procedure tbmp.reverse;
var i,j:longint;
begin
  for j:=0 to y-1 do
   for i:=0 to x div 2-1 do
     swapb(cbmp^[i+j*x],cbmp^[(x-i-1)+j*x]);
end;
function tspr.loadr(s:string):boolean;
begin
  if w.exist(s) then
  begin
    loadr:=tspr.loadwad(getfilename(s));
    if x<>0 then
     begin
       tbmp.reverse;
       convert2spr;
       write(':');
     end;
  end
  else
  begin
    loadr:=tspr.loadfile(s);
    if x<>0 then
    begin
      tbmp.reverse;
      convert2spr;
      write('.');
    end;
  end;
{  if tspr.load(s) then
  begin
    tbmp.reverse;
    convert2spr;
  end else
   loadr:=false;}
end;
procedure rectangle(x1,y1,x2,y2:integer; c:byte);
var
  i:integer;
begin
  for i:=x1 to x2 do putpixel(i,y1,c);
  for i:=x1 to x2 do putpixel(i,y2,c);
  for i:=y1 to y2 do putpixel(x1,i,c);
  for i:=y1 to y2 do putpixel(x2,i,c);
end;
procedure loadfont(name:string);
var f:file;
begin
  if fnt=nil then new(fnt);
  assign(f,name);
{$i-}  reset(f,1);{$i+}
  if ioresult<>0 then exit;
  blockread(f,fnt^,sizeof(fnt^));
  close(f);
end;
procedure line(x1,y1,x2,y2:integer; c:byte);
begin
   {error}
end;
procedure readline(x,y:integer; var str:string; last:string; col:byte; fl:integer);
const maxen=16;
var c:char;
    s:string;
    i,j,cur:longint;
begin
  s:=last;
  i:=0;
  cur:=length(s)+1;
  repeat
{    for j:=y to y+8 do system.move(scr^[j*320],mem[sega000:j*320],320);}
    repeat
      inc(i); {delay(1);error}
      bar(x,y,x+maxen*8,y+8,0);
      print(x,y,col,s);
      if i mod 100<50 then
       line(x+cur*8-8,y,x+cur*8-8,y+8,col)
       else
       line(x+cur*8-8,y,x+cur*8-8,y+8,not col);
       screen;
    until keypressed;
    c:=readkey;
    case c of
     #0:case readkey of
       #75: if cur>1 then dec(cur);
       #77: if cur<=length(s) then inc(cur);
       #83: begin s:=copy(s,1,cur-1)+copy(s,cur+1,length(s)-cur); end;
     end;
     #8:  if cur>1 then begin s:=copy(s,1,cur-2)+copy(s,cur,length(s)-cur+1); dec(cur); end;
     #13: break;
     #27: s:='';
    else
    begin
     case fl of
     0:begin s:=copy(s,1,cur-1)+c+copy(s,cur,length(s)-cur+1); inc(cur); end;
     1:if c in ['0'..'9','-','.']then begin s:=copy(s,1,cur-1)+c+copy(s,cur,length(s)-cur+1); inc(cur); end
     end;
    end;
    end;
{    screen;
    print(x,y,15,'->'+s);}
  until c in [#13,#27];
  str:=s;
  while keypressed do readkey;
end;
procedure print(x,y,c:integer; s:string);
var i,j,k,l:integer;
begin
 if (y>=miny-8)and(x<maxx)and(y<maxy) then
 begin
   for k:=1 to length(s) do
    for i:=1 to 8 do
     for j:=1 to 8 do
     if (fnt^[ord(s[k]),j] shr (8-i))and 1=1 then
       putpixel((x+(k-1)*8+i),(y+j),c);
  end;
end;
procedure bar(x1,y1,x2,y2:integer; c:byte);
var i,d:integer;
begin
  if x1<minx then x1:=minx;
  if y1<miny then y1:=miny;
  if x2>maxx then x2:=maxx;
  if y2>maxy then y2:=maxy;
  if (x2<x1)or(y2<y1)then exit;
  d:=x2-x1;
  for i:=y1 to y2 do
    fillchar(scr[i]^[x1],d,c);
end;
procedure tspr.putrot(ax,ay:longint; r1,r2,r3,r4:real);
begin
  spritec(ax,ay);{error}
end;
procedure tspr.spritec(ax,ay:longint);
begin
  sprite(ax-x div 2,ay-y div 2);
end;
procedure tspr.spritesp(ax,ay:longint);
begin
  sprite(ax-x div 2,ay-y);
end;
procedure clear;
var
  i:integer;
begin
  for i:=0 to getmaxy do
    fillchar(scr[i]^,getmaxx+1,0);
end;
procedure box(x1,y1,x2,y2:integer);
begin
  if x1<0 then x1:=0;
  if y1<0 then y1:=0;
  if x2>getmaxx then x2:=getmaxx;
  if y2>getmaxy then x2:=getmaxy;
  minx:=x1; miny:=y1; maxx:=x2; maxy:=y2;
  setviewport(x1,y1,x2,y2,clipon);
end;
procedure closegraph;
var
  i:integer;
begin
  for i:=0 to getmaxy do freemem(scr[i],getmaxx+1);
  graphics.closegraph;
end;
procedure initgraph(res:integer);
var
  i:integer;
begin
  set256mode(res);
  getmaxx:=gr_vars.getmaxx;
  getmaxy:=gr_vars.getmaxy;
  minx:=0;
  miny:=0;
  maxx:=getmaxx;
  maxy:=getmaxy;
  for i:=0 to getmaxy do
  begin
    getmem(scr[i],getmaxx+1);
    fillchar(scr[i]^,getmaxx+1,0);
  end;
end;
function getfilename(s:string):string;
var
  i:integer;
begin
  repeat
    i:=pos('\',s);
    if i=0 then break;
    s:=copy(s,i+1,length(s)-i);
  until false;
  if pos('.',s)>0 then s:=copy(s,1,pos('.',s)-1);
  getfilename:=s;
end;
procedure putpixel(x,y:integer; c:byte);
begin
  if (x>=minx)and(y>=miny)and(x<=maxx)and(y<=maxy) then
     scr[y]^[x]:=c;
end;
procedure putline(x1,y1,sizex: integer;p : pointer);{draw a horizontal line with image of the pointer p}
var
  i2,i3,mempos : word;
  olx1         : integer;
label
  endofproc;
begin
  asm
    mov   cx,sizex
    mov   ax,x1
    or    cx,cx
    jz    endofproc
    jns   @next
      neg   cx
      sub   ax,cx
    @next:
    add   ax,actviewport.x1
    mov   olx1,ax
    mov   bx,ax
    add   bx,cx
    mov   di,y1
    add   di,actviewport.y1
    cmp   di,fillviewport.y1
    jl    endofproc
    cmp   di,fillviewport.y2
    jg    endofproc
    mov   cx,fillviewport.x1
    mov   dx,fillviewport.x2
    cmp   ax,dx
    jge   endofproc
    cmp   bx,cx
    jle   endofproc
    cmp   ax,cx
    jnl   @next1
      mov   ax,cx
    @next1:
    inc   dx
    cmp   bx,dx
    jng   @next2
      mov   bx,dx
    @next2:
    sub   bx,ax
    mov   sizex,bx
    sub   ax,actviewport.x1
    sub   di,actviewport.y1
    add   di,pageadd
    mov   bx,ax
    sub   bx,olx1
    mov   mempos,bx
    push  ax
    push  di
    call  calcbank
    mov   i2,ax
  end;
    if i2 < i2+word(sizex) then
   {move2screen(ptr(seg(p^),ofs(p^)+mempos)^,ptr(writeptr,i2)^,putmaxx)}
  asm
    mov   ax,mempos
    mov   di,i2
    mov   cx,sizex
    mov   bx,writeptr
    mov   dx,ds
    lds   si,p
    add   si,ax
    mov   es,bx
    mov   ax,cx
    cmp   cx,8
    jb    @start
    mov   cx,di
    and   cx,11b
    jz    @iszero
    mov   bx,4
    sub   bx,cx
    mov   cx,bx
    rep   movsb
    sub   ax,bx
    @iszero:
    mov   cx,ax
    @start:
      shr   cx,2
      db    0F3h,66h,0A5h{rep movsd}
      mov   cx,ax
      and   cx,11b
      jz    @end
      rep   movsb
      @end:
    mov   ds,dx
  end
  else begin
    i3 := 0-i2;
    move2screen(ptr(seg(p^),ofs(p^)+mempos)^,ptr(writeptr,i2)^,i3);
    incbank;
    move2(ptr(seg(p^),ofs(p^)+i3+mempos)^,ptr(writeptr,0)^,sizex-i3);
  end;
  endofproc:
end;
procedure putimage(x,y,dx,dy: longint; var bmp: tarray);
var
  sizex,sizey,i,i2,i3,i4,oli2,putmaxx : word;
  x2,y2                               : integer;
  switched                            : boolean;
begin
  sizex := dx;          sizey := dy;
  inc(x,actviewport.x1); inc(y,actviewport.y1);
  x2 := x+sizex;        y2 := y+sizey-1;
  i4      := 0;
  if (y > fillviewport.y2) or (y2 < fillviewport.y1) then exit;
  if (x >= fillviewport.x2) or (x2 < fillviewport.x1) then exit;
  if x  < fillviewport.x1 then begin
    inc(i4,fillviewport.x1-x);
    x       := fillviewport.x1;
  end;
  if x2 > fillviewport.x2 then x2 := fillviewport.x2;
  if y  < fillviewport.y1 then begin
    inc(i4,sizex*(fillviewport.y1-y));
    y  := fillviewport.y1;
  end;
  if y2 > fillviewport.y2 then y2 := fillviewport.y2;
  putmaxx := abs(x2-x);  sizey := abs(y2-y);
  inc(y,pageadd);
  i2 := calcbank(x-actviewport.x1,y-actviewport.y1);
  oli2 := i2;
  switched := false;

   for i := y to y+sizey do begin
     if i2 < i2+putmaxx then begin
       if (oli2 > i2)and(not switched) then incbank;
       move2screen(bmp[i4],ptr(writeptr,i2)^,putmaxx);
       switched := false;
     end else begin
       i3 := 0-i2;
       move2screen(bmp[i4],ptr(writeptr,i2)^,i3);
       incbank;
       switched := true;
       move2screen(bmp[i4+i3],ptr(writeptr,0)^,putmaxx-i3);
     end;
     inc(i4,sizex);
     oli2 := i2;
     inc(i2,bytesperscanline);
   end;
end;
procedure putsprite(x,y,dx,dy: longint; var bmp: tarray);
const fon=0;
var
  sizex,sizey,i,i2,i3,i4,oli2,putmaxx : word;
  x2,y2                               : integer;
  switched                            : boolean;
begin
  sizex := dx;          sizey := dy;
  inc(x,actviewport.x1); inc(y,actviewport.y1);
  x2 := x+sizex;        y2 := y+sizey-1;
  i4      := 0;
  if (y > fillviewport.y2) or (y2 < fillviewport.y1) then exit;
  if (x >= fillviewport.x2) or (x2 < fillviewport.x1) then exit;
  if x  < fillviewport.x1 then begin
    inc(i4,fillviewport.x1-x);
    x       := fillviewport.x1;
  end;
  if x2 > fillviewport.x2 then x2 := fillviewport.x2;
  if y  < fillviewport.y1 then begin
    inc(i4,sizex*(fillviewport.y1-y));
    y  := fillviewport.y1;
  end;
  if y2 > fillviewport.y2 then y2 := fillviewport.y2;
  putmaxx := abs(x2-x);  sizey := abs(y2-y);
  inc(y,pageadd);
  i2 := calcbank(x-actviewport.x1,y-actviewport.y1);
  oli2 := i2;
  switched := false;

   for i := y to y+sizey do begin
     if i2 < i2+putmaxx then begin
       if (oli2 > i2)and(not switched) then incbank;
       sprite2mem(bmp[i4],ptr(writeptr,i2)^,putmaxx,fon);
       switched := false;
     end else begin
       i3 := 0-i2;
       sprite2mem(bmp[i4],ptr(writeptr,i2)^,i3,fon);
       incbank;
       switched := true;
       sprite2mem(bmp[i4+i3],ptr(writeptr,0)^,putmaxx-i3,fon);
     end;
     inc(i4,sizex);
     oli2 := i2;
     inc(i2,bytesperscanline);
   end;
end;
Procedure loadpal(name:string);
var ff:file;
    buf:array[0..256*4]of byte;
    i,c,max,t:integer;
begin
  assign(ff,name);
{$i-}  reset(ff,1); {$i+}
if ioresult<>0 then exit;
  seek(ff,54);
  blockread(ff,buf,256*4);
  close(ff);
  port[$3c8]:=0;
  c:=255; max:=0;
  for i:=0 to 255 do
  begin
(*r*)  port[$3c9]:=buf[(i*4)+2] div 4;
(*g*)  port[$3c9]:=buf[(i*4)+1] div 4;
(*b*)  port[$3c9]:=buf[(i*4)+0] div 4;
     t:=buf[(i*4)+2]+buf[(i*4)+1]+buf[(i*4)+0];
     if t>max then begin max:=t; c:=i; white:=i; end;
  end;
end;
(*function tspr.loadfile(s:string):boolean;
const
  cspr:tcaption='SPR@';
var
  f:file;
  capt:record
    c:tcaption;
    x,y,maxdata,maxbmp:longint;
  end;
begin
  x:=0; loadfile:=false; spr:=false;
  name:=getfilename(s);
  assign(f,s);
  {$i-}reset(f,1);{$i+}
  if ioresult<>0 then begin name:=''; exit; end;
  blockread(f,capt,sizeof(capt));
  if capt.c<>cspr then
  begin
    close(f);
    if (capt.c[1]='B')and(capt.c[2]='M')then
    begin
      loadfile:=tbmp.loadfile(s);
      if x<>0 then begin convert2spr; write('.');end;
    end;
    exit;
  end;
  x:=capt.x; y:=capt.y;
  maxdata:=capt.maxdata;
  maxbmp:=capt.maxbmp;
  getmem(data,maxdata*sizeof(tsprdata));
  getmem(bmp,maxbmp);
  blockread(f,data^,maxdata*sizeof(tsprdata));
  blockread(f,bmp^,maxbmp);
  close(f);
  loadfile:=true;
  spr:=true;
end; *)
procedure tspr.sprite(ax,ay:longint);
var
  i,j,tx,ty,l,w:longint;
begin
  if not spr then tbmp.put(ax,ay)
  else
  begin
    for i:=0 to maxdata-1 do
    begin
      ty:=ay+data^[i].y;
      if ty>maxy then break;
      if ty<miny then continue;
      tx:=ax+data^[i].x;
      l:=data^[i].l;
      w:=data^[i].w;
      if (tx+l<minx)or(tx>maxx)then continue;
      if (tx>=minx)and(tx+l<=maxx)then
        move(bmp^[w],scr[ty]^[tx],l)
        else
      if (tx>=minx)and(tx+l>maxx)then
        move(bmp^[w],scr[ty]^[tx],maxx-tx+1)
        else
      if (tx<minx){and(tx+l>=minx)}then
        move(bmp^[w+minx-tx],scr[ty]^[minx],l-minx+tx);
      {error}
    end;
  end;
end;
procedure tspr.put(ax,ay:longint);
begin
  sprite(ax,ay);
end;
procedure tspr.save8(s:string);
begin
end;
procedure tspr.done;
begin
  if x=0 then exit;
  if not spr then begin tbmp.done; exit; end;
  x:=0; name:='';
  freemem(bmp,maxbmp);
  freemem(data,maxdata*sizeof(tsprdata));
  bmp:=nil;
  data:=nil;
end;
function tbmp.loadfile(s:string):boolean;
var
  f:file;
  capt:tbitmap;
  i,ost,temp:longint;
begin
  x:=0; loadfile:=false; bmp:=nil;
  name:=getfilename(s);
  assign(f,s);
  {$i-}reset(f,1);{$i+}
  if ioresult<>0 then begin name:=''; exit; end;
  blockread(f,capt,sizeof(capt){54});
  if (capt.caption<>'BM')or(capt.bits<>8)or(capt.compression<>0) then begin close(f);exit; end;
  x:=capt.x;
  y:=capt.y;
{  writeln(name,': ',x*y);}
  getmem(bmp,x*y);
  case x mod 4 of
    0: ost:=0;
    1: ost:=3;
    2: ost:=2;
    3: ost:=1;
  end;
{  seek(f,capt.fmtsize);}
  seek(f,1078);
  for i:=y-1 downto 0 do
  begin
    blockread(f,bmp^[i*x],x);
    if ost<>0 then blockread(f,temp,ost);
  end;
  close(f);
  loadfile:=true;
end;
procedure tbmp.save8(s:string);
begin
end;
procedure tbmp.save24(s:string);
begin
end;
procedure tbmp.put(ax,ay:longint);
begin
{  if x<>0 then putimage(ax,ay,x,y,bmp^);}
  sprite(ax,ay);
end;
procedure tbmp.sprite(ax,ay:longint);
var
  i,j,tx,ty,l,w:longint;
begin
  if x<>0 then
  begin
    for i:=0 to y-1 do
    begin
      ty:=ay+i;
      if ty>maxy then break;
      if ty<miny then continue;
      tx:=ax;
      l:=x;
      w:=i*x;
      if (tx+l<minx)or(tx>maxx)then continue;
      if (tx>=minx)and(tx+l<=maxx)then
        sprite2mem(bmp^[w],scr[ty]^[tx],l,0)
        else
      if (tx>=minx)and(tx+l>maxx)then
        sprite2mem(bmp^[w],scr[ty]^[tx],maxx-tx+1,0)
        else
      if (tx<minx){and(tx+l>=minx)}then
        sprite2mem(bmp^[w+minx-tx],scr[ty]^[minx],l-minx+tx,0);
   { putsprite(ax,ay,x,y,bmp^);}
  end; end;
end;
procedure tbmp.done;
begin
  if x=0 then exit;
  freemem(bmp,x*y);
  name:='';
  x:=0;
end;
procedure screen;
var i:integer;
begin
   for i:=0 to getmaxy do putline(0,i,getmaxx+1,scr[i]);
end;
function loadbmp(s:string):integer;
var
  i:integer;
  name:string;
begin
  name:=getfilename(s);
  for i:=0 to maxpat do
    if (p^[i].x>0)and(p^[i].name=name)then
    begin
      loadbmp:=i;
      exit;
    end;
  for i:=0 to maxpat do
    if (p^[i].x=0)then
    begin
      if p^[i].load(dbmp+s+'.bmp') then
        loadbmp:=i else
        loadbmp:=0;
      exit;
    end;
  loadbmp:=0;
end;
begin
  new(p); fillchar(p^,sizeof(p^),0);
  new(tempbmp); new(tempdata); new(cbmp);
end.