{ $mode tp}
unit grx;
interface
Uses crt,wads, timer, ports, fpgraph,api,sprites;
type
  tname=string[16];

const
  res:integer=0;
  bpp=8;
//  maxpat=2000;
{  red: byte = 4;
  green: byte = 2;
  blue: byte = 1;
  white: byte = 15;
  grey: byte = 7;
  dark: byte = 8;}
{  resolution:array[0..4]of
   record x,y:longint end=
   (
   (x:320; y:200),
   (x:320; y:240),
   (x:640; y:400),
   (x:640; y:480),
   (x:800; y:600)
   );}
  load:array[1..8]of string[40]=
  (
  #13#10'Боты (bot.ini) ...',
  #13#10'Стены (wall.dat)'  ,
  #13#10'Взрывы (bomb.ini)' ,
  #13#10'Пули (bullet.ini)' ,
  #13#10'Оружие (weapon.ini)',
  #13#10'Предметы (item.ini)',
  #13#10'Монстры (monster.ini)',
#13#10'Остальное (func.ini, bitmaps)'
  );
type
  tcaption=array[1..4]of char;
//  tnpat=0..maxpat;
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
{  tbmp=object
    x,y:longint;
    name:string[8];
    bmp: ^tArray;
//    function load(s:string):boolean;
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
    procedure spriteo(ax,ay:longint; c:longint);
    procedure save8(s:string);
    procedure done;
  end;}
//  tpat=tspr;
//  arrayoftpat=array[tnpat]of tpat; {текстуры}
//  tscreen=array[0..1200]of ^tarray;
  tfont=object
     vis: string[8];
     c:array[#0..#255]of tnpat;
     d:integer;
     procedure load(av:string; ad,method:integer);
     procedure print(ax,ay:integer; s:string);
     function width(s:string):integer;
  end;
var
//  scr: tscreen;
  maxx,maxy,minx,miny:integer;
  getmaxx,getmaxy:integer;
//  p: ^arrayoftpat;
//  cbmp:^tarray;
//  tempdata: ^arrayofspr;
//  tempbmp:  ^tarray;
  sfps,winall:boolean;
  wb,rb:tfont;

  inx,iny: integer;


//function loadbmp(s:string):integer;
function getfilename(s:string):string;
Procedure loadpal(name:string);
//procedure initgraph(res:integer);
procedure box(x1,y1,x2,y2:integer);

//procedure line(x1,y1,x2,y2:integer; c:byte);
procedure readline(x,y:integer; var str:string; last:string; col:byte; fl:integer);
procedure rectangle(x1,y1,x2,y2:integer; c:byte);
procedure rectangle2(x1,y1,x2,y2:integer; c:byte);
//procedure swapb(var a,b:byte);
function getcolor(r,g,b:longint):byte;
procedure delay(n:real);
function putbmpall(s:string):boolean;
function enterwall(s:string):string;
function enterfile(s:string):string;
procedure log(b:string; a:longint);
function exist(s:string):boolean;
procedure readlinebmp(x,y:integer; var str:string; last:string; col:byte; fl:integer);
//function loadbmpr(s:string):tnpat;
(*******************************)implementation(****************************)
uses rfunit;

{function loadbmpr(s:string):tnpat;
var
  i:integer;
begin
  s:=upcase(s);
  for i:=1 to maxpat do
    if p^[i].x=0 then
    begin
     if p^[i].loadr(dbmp+s+'.bmp') then
       loadbmpr:=i
     else loadbmpr:=0;
     exit;
    end;
  loadbmpr:=0;
end;}
function exist(s:string):boolean;
begin
  exist:=aw.exist(s) or bmpexist(s);
end;

procedure log(b:string; a:longint);
var f:text;
begin
  assign(f,'log.log');
{  rewrite(f);} append(f);
  writeln(f,b,': ',a);
  close(f);
end;

function enterfile(s:string):string;
var res:string;
begin
  readline(100,100,res,s,white,0);
  enterfile:=res;
end;

function enterwall(s:string):string;
var res:string;
begin
  readlinebmp(100,100,res,s,white,0);
  enterwall:=res;
end;

procedure delay(n:real);
var
  t:ttimer;
begin
  while keypressed do readkey;
  t.init(average,0);
  repeat
    t.move;
  until keypressed or (abs(t.tik-t.start)>n*18);
  while keypressed do readkey;
end;

function putbmpall(s:string):boolean;
var
  f:file;
//  b:array[0..1600]of byte;
  x,y,dx,dy,c,i,j,x1,y1:integer;
  k,kx,ky:real;
  ost,o:longint;
  t: tnpat;
begin
  t:=loadasbmp(s);
{  putbmpall:=false;
  if aw.exist(getfilename(s)) then
  begin
    putbmpall:=true;}
{    aw.assign(getfilename(s));
    aw.read(x,2); aw.read(y,2);
    aw.read(dx,2); aw.read(dy,2);}
  x:=p[t].x;
  y:=p[t].y;

   kx:=maxx/x; if kx>2 then kx:=2;
   ky:=maxy/y; if ky>2 then ky:=2;
    x1:=0; y1:=0;

    if kx<ky then begin k:=kx;  end
    else begin k:=ky;  end;

    y1:=(maxy-round(y*k))div 2;
    x1:=(maxx-round(x*k))div 2;

    for c:=0 to y-1 do
    begin
//      aw.read(b,x);
      for i:=round(k*c) to round(k*(c+1)) do
       for j:=0 to round((x-1)*k) do
         putpixel(x1+j,y1+i,p[t].bmp^[c*x+round(j/k)]);
    end;
(*  end
  else
  begin
    putbmpall:=true;
    assign(f,s+'.bmp');
    {$i-}reset(f,1); {$i-}
    if ioresult<>0 then
      putbmpall:=false
    else
    begin
      seek(f,18);
      blockread(f,x,2);
      seek(f,22);
      blockread(f,y,2);
      seek(f,1078);
    kx:=maxx/x;
    ky:=maxy/y;
    case x mod 4 of
     0: ost:=0;
     1: ost:=3;
     2: ost:=2;
     3: ost:=1;
    end;
    x1:=0; y1:=0;
    if kx<ky then begin k:=kx; y1:=(maxy-round(y*k))div 2; end
    else begin k:=ky; x1:=(maxx-round(x*k))div 2; end;
    for c:=y-1 downto 0 do
    begin
      blockread(f,b,x);
      if ost>0 then blockread(f,o,ost);
{      w.read(b,x);}
      for i:=round(k*c) to round(k*(c+1)) do
       for j:=0 to round((x-1)*k) do
         putpixel(x1+j,y1+i,b[round(j/k)]);
    end;
{    for c:=y-1 downto 0 do
    begin
      blockread(f,b,x);
      for i:=round(c*(maxy-miny)/y) to round((c+1)*(maxy-miny)/y) do
       for j:=0 to maxx-minx do
         putpixel(minx+j,miny+i,b[round(x*j/(maxx-minx))]);
    end;}
      close(f);
    end;
  end;*)
  screen;
end;

function getcolor(r,g,b:longint):byte;
var i,last:byte;
    min,cur:longint;
begin
   min:=maxlongint;
   last:=0;
   for i:=0 to 255 do
   begin
     cur:=sqr(r-pal[i*4+2])+sqr(g-pal[i*4+1])+sqr(b-pal[i*4+0]);
     if cur<=min then begin min:=cur; last:=i; end;
   end;
   getcolor:=last;
end;
(*procedure tspr.convert2spr;
const
  fon=0;
var
  last:^tarray;
  i,j,s,xy:longint;
begin
  if spr then exit;
  if x=0 then exit;
  xy:=x*y;
  maxdata:=0; maxbmp:=0;
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
  bmp:=nil;
  getmem(bmp,maxbmp);
  move(tempbmp^,bmp^,maxbmp);
  data:=nil;
  getmem(data,maxdata*sizeof(tsprdata));
  move(tempdata^,data^,maxdata*sizeof(tsprdata));
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
function tbmp.loadwad(s:string):boolean;
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
function tspr.load(s:string):boolean;
begin
  done;
{  writeln(s);}
  if diskload and fexist(s{+'.bmp'}) then
  begin
    load:=tspr.loadfile(s);
    if x<>0 then
    begin
      convert2spr;
      out(':');
    end;
  end;
  if x=0 then
  if w.exist(s) then
  begin
    load:=tspr.loadwad(getfilename(s));
    if x<>0 then
     begin
       convert2spr;
       out('.');
     end;
  end;
  if x=0 then load:=false;
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
  done;
  if diskload and fexist(s) then
  begin
    loadr:=tspr.loadfile(s);
    if x<>0 then
    begin
      tbmp.reverse;
      convert2spr;
      out(':');
    end;
  end;
  if x=0 then
  if w.exist(s) then
  begin
    loadr:=tspr.loadwad(getfilename(s));
    if x<>0 then
     begin
       tbmp.reverse;
       convert2spr;
       out('.');
     end;
  end;
  if x=0 then loadr:=false;
{  if tspr.load(s) then
  begin
    tbmp.reverse;
    convert2spr;
  end else
   loadr:=false;}
end;*)
procedure rectangle(x1,y1,x2,y2:integer; c:byte);
var
  i:integer;
begin
  for i:=x1 to x2 do putpixel(i,y1,c);
  for i:=x1 to x2 do putpixel(i,y2,c);
  for i:=y1 to y2 do putpixel(x1,i,c);
  for i:=y1 to y2 do putpixel(x2,i,c);
end;
procedure rectangle2(x1,y1,x2,y2:integer; c:byte);
var
  i:integer;
begin
  for i:=x1 to x2 do putpixel(i,y1,c);
{  for i:=x1 to x2 do putpixel(i,y2,c);}
  for i:=y1 to y2 do putpixel(x1,i,c);
{  for i:=y1 to y2 do putpixel(x2,i,c);}
end;
{procedure line(x1,y1,x2,y2:integer; c:byte);
var dx,dy,a,b,i,j:longint;
begin
  if
  ((x1<minx)and(x2<minx))or
  ((x1>maxx)and(x2>maxx))or
  ((y1<miny)and(y2<miny))or
  ((y1>maxy)and(y2>maxy))
  then exit;
  if (x2<x1) then
  begin
    i:=x2; x2:=x1; x1:=i;
    i:=y2; y2:=y1; y1:=i;
  end;
  dx:=x2-x1;
  dy:=y2-y1;
  j:=0;
  if abs(dx)>abs(dy) then
  for i:=0 to dx do
  begin
    j:=i*dy div dx;
    putpixel(x1+i,y1+j,c);
  end
  else
  if abs(dx)<abs(dy) then
  begin
   if dy>0 then
    for i:=0 to dy do
    begin
      j:=i*dx div dy;
      putpixel(x1+j,y1+i,c);
    end
    else
    for i:=dy to 0 do
    begin
      j:=i*dx div dy;
      putpixel(x1+j,y1+i,c);
    end
  end
  else
  if dx=dy then
  for i:=0 to dx do  putpixel(x1+i,y1+i,c)
  else
  if dx=-dy then
  for i:=0 to dx do  putpixel(x1+i,y1-i,c);
end;}
{procedure line(x1,y1,x2,y2:integer; c:byte);
var i:integer;
begin
  if x1=x2 then for i:=y1 to y2 do putpixel(x1,i,c);
  if y1=y2 then for i:=x1 to x2 do putpixel(i,y1,c);
end;}

procedure readline(x,y:integer; var str:string; last:string; col:byte; fl:integer);
const maxen=255;
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

      bar(x,y,x+maxen*8,y+8,black);

      print(x,y,col,s);
      if i mod 100<50 then
       line(x+cur*8-8,y,x+cur*8-8,y+8,col)
       else
       line(x+cur*8-8,y,x+cur*8-8,y+8,black);
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

procedure readlinebmp(x,y:integer; var str:string; last:string; col:byte; fl:integer);
const maxen=255;
var c:char;
    s:string;
    i,j,cur,t:longint;
begin
  s:=last;
  i:=0;
  cur:=length(s)+1;
  repeat
{    for j:=y to y+8 do system.move(scr^[j*320],mem[sega000:j*320],320);}
    repeat
      inc(i); {delay(1);error}
      bar(x,y,x+maxen*8,y+8,black);
      print(x,y,col,s);
      if i mod 100<50 then
       line(x+cur*8-8,y,x+cur*8-8,y+8,col)
       else
       line(x+cur*8-8,y,x+cur*8-8,y+8,black);

       t:=loadasbmp(s);

       p[t].sprite(x,y+32);

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
(*procedure tspr.putrot(ax,ay:longint; r1,r2,r3,r4:real);
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
end;*)
procedure box(x1,y1,x2,y2:integer);
begin
  if x1<0 then x1:=0;
  if y1<0 then y1:=0;
  if x2>getmaxx then x2:=getmaxx;
  if y2>getmaxy then x2:=getmaxy;
  minx:=x1; miny:=y1; maxx:=x2; maxy:=y2;

  setviewport(x1,y1,x2,y2{,clipon});

end;

{procedure initgraph(res:integer);
var
  i:integer;
begin
  setmode(resolution[res].x,resolution[res].y{,bpp});

  getmaxx:=mx;
  getmaxy:=my;

  minx:=0;
  miny:=0;
  maxx:=getmaxx;
  maxy:=getmaxy;
end;
}
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
end;*)
(*procedure tspr.spriteo(ax,ay:longint; c:longint);
var
  i,j,tx,ty,l,w:longint;
begin
  if c=0 then begin spritesp(ax,ay);exit; end;
  ax:=ax-x div 2; ay:=ay-y;
if x=0 then exit;
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
      if (tx>=minx)and(tx+l<=maxx)then begin
        putpixel(tx-1,ty,c);
        move(bmp^[w],scr[ty,tx],l);
        putpixel(tx+l+1,ty,c);
      end
        else
      if (tx>=minx)and(tx+l>maxx)then
        move(bmp^[w],scr[ty,tx],maxx-tx+1)
        else
      if (tx<minx){and(tx+l>=minx)}then
        move(bmp^[w+minx-tx],scr[ty,minx],l-minx+tx);
      {error}
    end;
  end;
end;
procedure tspr.sprite(ax,ay:longint);
var
  i,j,tx,ty,l,w:longint;
begin
  if x=0 then exit;
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
        move(bmp^[w],scr[ty,tx],l)
        else
      if (tx>=minx)and(tx+l>maxx)then
        move(bmp^[w],scr[ty,tx],maxx-tx+1)
        else
      if (tx<minx){and(tx+l>=minx)}then
        move(bmp^[w+minx-tx],scr[ty,minx],l-minx+tx);
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
  getmem(bmp,x*y);
  case x mod 4 of
    0: ost:=0;
    1: ost:=3;
    2: ost:=2;
    3: ost:=1;
  end;
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
  sprite(ax,ay);
end;
procedure tbmp.sprite(ax,ay:longint);
var
  i,j,tx,ty,l,w:longint;
begin
{  if x<>0 then
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
      if (tx<minx)then
        sprite2mem(bmp^[w+minx-tx],scr[ty]^[minx],l-minx+tx,0);
  end; end;}
end;
procedure tbmp.done;
begin
  if x=0 then exit;
  freemem(bmp,x*y);
  name:='';
  x:=0;
end;*)
{procedure screen;
var i:integer;
begin
   for i:=0 to getmaxy do putline(0,i,getmaxx+1,scr[i]);
end;}
{function loadbmp(s:string):integer;
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
end;}
procedure tfont.load(av:string; ad,method:integer);
var i:char;
   j:integer;
begin
  vis:=av;
  d:=ad;
  case method of
  1:
   begin
   for i:=#0 to #255 do
         c[i]:=loadbmp(upcase(vis+i));
    for j:=0 to 9 do
      c[char(j+48)]:=loadbmp('d'+st(j));
     c['-']:=loadbmp('dminus');
     c['.']:=loadbmp('-');
   end;
  2:
    for i:=#0 to #255 do
         c[i]:=loadbmp(upcase(vis+st0(byte(i),3)));
  end;
end;
procedure tfont.print(ax,ay:integer; s:string);
var
  i,mx:integer;
begin
  s:=upcase(s);

  mx:=0;
  for i:=1 to length(s) do
  if s[i]=' ' then inc(mx,d) else
  begin
    p[c[s[i]]].sprite(ax+mx,ay);
    inc(mx,p[c[s[i]]].x);
  end;
end;
function tfont.width(s:string):integer;
var
  i,mx:integer;
begin
  s:=upcase(s);

  mx:=0;
  for i:=1 to length(s) do
  if s[i]=' ' then inc(mx,d) else
  begin
//    p^[c[s[i]]].sprite(ax+mx,ay);
    inc(mx,p[c[s[i]]].x);
  end;
  width:=mx;
end;

end.
