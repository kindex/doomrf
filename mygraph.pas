unit mygraph; { Copyright Ivanov Andrey 15.4.2k  IVA vision 2000 }
interface
const mx=320;
      my=200;
      white:byte=255;
type long=array[0..65320]of byte;
      tfnt=array[0..255,1..8]of byte;
      color=byte;
var scr,savescr:^long;
    fnt:^tfnt;
type tar=array[0..256*4]of byte;
var pal,bufe:^tar;
    graph:boolean;
    maxx,maxy,minx,miny,maxl,curl:longint;
procedure circle(x,y,r,c:integer);
procedure cool(x,y,r,a,c:integer);
procedure cooldx(x,y,r,c:integer; dx,dy:real);
procedure smartprint(x,y,c:integer; s:string);
procedure setreg(x1,y1,x2,y2:integer);
procedure init320x200;
procedure closegraph;
procedure putpixel(x,y:longint; c:color);
procedure putpixel2screen(x,y:longint; c:color);
procedure putnotpixel(x,y:longint);
procedure print(x,y,c:integer; s:string);
procedure loadfont(name:string);
procedure screen;
procedure clear;
procedure linex(x,y,y2:integer; c:color);
procedure line(x1,y1,x2,y2:integer; c:byte);
procedure liney(y,x,x2,c:integer);
procedure retrace;
procedure rectangle(x1,y1,x2,y2,c:integer);
Procedure loadpal(name:string);
procedure box(x1,y1,x2,y2:word);
procedure setpal;
procedure setfullpal;
Procedure loadpalete(name:string);
procedure bar(x1,y1,x2,y2,c:integer);
procedure outtext(x,y,c:integer; s:string);
procedure treg(x1,y1,x2,y2,x3,y3:integer; col:byte);
procedure kvadr(x1,y1,x2,y2,x3,y3,x4,y4:integer; c:byte);
procedure setgraypal;
procedure loadplus;
procedure energyprint(x,y,c,l:integer; s:string);
procedure readline(x,y:integer; var str:string; last:string; col:byte; fl:integer);
implementation
uses api,F32MA,mycrt;
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
procedure circle(x,y,r,c:integer);
var
  i,j,d:integer;
begin
  d:=round(sqrt(2)/2*r);
  for i:=0 to d*2 do
  begin
    j:=r-trunc(sqrt(sqr(r)+sqr(i)));

    putpixel(x+i,y++r-j, c);
    putpixel(x+-i,y++r-j,c);
    putpixel(x++i,y+-r+j,c);
    putpixel(x+-i,y+-r+j,c);
    putpixel(x++r-j,y++i,c);
    putpixel(x++r-j,y+-i,c);
    putpixel(x+-r+j,y++i,c);
    putpixel(x+-r+j,y+-i,c);

  end;
end;
procedure cool(x,y,r,a,c:integer);
procedure putpixel(x1,x,y1,y,a,c:integer);
var
  co,si:real;
  tx,ty:integer;
begin
  co:=cos(a/100);
  si:=sin(a/100);
  tx:=round(co*y-si*x);
  ty:=round(co*x+si*y);
  mygraph.putpixel(x1+tx,y1+ty,byte(c));
end;
var
  i,j,d:integer;
begin
  d:=round(sqrt(2)/2*r);
  for i:=0 to d*2 do
  begin
{    j:=r-trunc(sqrt(sqr(r)+sqr(i)));}
    j:=d+round(sqrt(sqr(r)+sqr(i)));

    putpixel(x,i,y,+r-j, 3*i+a,c);
    putpixel(x,-i,y,+r-j,3*i+a,c);
    putpixel(x,+i,y,-r+j,3*i+a,c);
    putpixel(x,-i,y,-r+j,3*i+a,c);
    putpixel(x,+r-j,y,+i,3*i+a,c);
    putpixel(x,+r-j,y,-i,3*i+a,c);
    putpixel(x,-r+j,y,+i,3*i+a,c);
    putpixel(x,-r+j,y,-i,3*i+a,c);

  end;
end;
procedure cooldx(x,y,r,c:integer; dx,dy:real);
procedure putpixel(x1,x,y1,y,c:integer; co,si:real);
var
  tx,ty:integer;
begin
  tx:=round(co*y-si*x);
  ty:=round(co*x+si*y);
  mygraph.putpixel(x1+tx,y1+ty,byte(c));
end;
var
  i,j,d:integer;
begin
  dx:=dx*r;
  dy:=dy*r;
  d:=round(sqrt(2)/2*r);
  for i:=0 to d*2 do
  begin
{    j:=r-trunc(sqrt(sqr(r)+sqr(i)));}
    j:=d+round(sqrt(sqr(r)+sqr(i)));

    putpixel(x,i,y,+r-j, c,dx,dy);
    putpixel(x,-i,y,+r-j,c,dx,dy);
    putpixel(x,+i,y,-r+j,c,dx,dy);
    putpixel(x,-i,y,-r+j,c,dx,dy);
    putpixel(x,+r-j,y,+i,c,dx,dy);
    putpixel(x,+r-j,y,-i,c,dx,dy);
    putpixel(x,-r+j,y,+i,c,dx,dy);
    putpixel(x,-r+j,y,-i,c,dx,dy);

  end;
end;
procedure energyprint(x,y,c,l:integer; s:string);
var
  jx,jy:integer;
begin
  jx:=x;
  jy:=y;

  bar(jx,jy,jx+l,jy+7,(c div 8)*8+4);
  line(jx,jy-1,jx+l,jy-1,c);
  line(jx,jy+8,jx+l,jy+8,c);

  line(jx-1,jy,jx-1,jy+7,c);
  line(jx+1+l,jy,jx+1+l,jy+7,c);

  print(jx-length(s)*8-4,jy-1,c,s);
end;
procedure loadplus;
var i:longint;
begin
  if not graph then write('.')
  else
  begin
    inc(curl);
    if curl>maxl then curl:=maxl;
    for i:=0 to round(curl/maxl*320)-1 do mem[sega000:i+199*320]:=white;
  end;
end;
procedure putpixel;
begin
 if {(c<>0)and}(x>=minx)and(x<=maxx)and(y>=miny)and(y<=maxy)
   then
     scr^[x+y*mx]:=c;
end;
procedure putpixel2screen;
begin
 if {(c<>0)and}(x>=minx)and(x<=maxx)and(y>=miny)and(y<=maxy)
   then
     mem[sega000:x+y*mx]:=c;
end;
procedure setreg(x1,y1,x2,y2:integer);
begin
  minx:=x1;
  maxx:=x2;
  miny:=y1;
  maxy:=y2;
end;
procedure kvadr(x1,y1,x2,y2,x3,y3,x4,y4:integer; c:byte);
begin
  treg(x1,y1,x2,y2,x3,y3,c);
  treg(x1,y1,x4,y4,x3,y3,c);
end;
procedure bar(x1,y1,x2,y2,c:integer);
var x,y,x3,y3,x4,y4:integer;
begin
  if x2>=320 then x3:=319 else x3:=x2;
  if y2>=200 then y3:=199 else y3:=y2;
  if x1<0 then x4:=0 else x4:=x1;
  if y1<0 then y4:=0 else y4:=y1;
  for x:=max(x4,minx) to min(x3,maxx) do
    for y:=max(y4,miny) to min(y3,maxy) do
     scr^[y*320+x]:=c;
end;
procedure treg(x1,y1,x2,y2,x3,y3:integer; col:byte);
var yx:array[1..2,0..199]of integer;
    minx,miny,maxx,maxy:integer;
    x,y:array[1..3]of integer;
    i:integer;
    main:byte;
procedure putpixel(x,y:integer; ar:byte);
begin
  if (x<0)then x:=0;
  if (y<0)then y:=0;
  if (x>319)then x:=319;
  if (y>199)then y:=199;
  yx[ar,y]:=x;
end;
procedure line(x1,y1,x2,y2:integer; c:byte);
var dx,dy,a,b,i,j:longint;
begin
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
end;
function min(a,b:integer):integer;
begin if a<b then min:=a else min:=b; end;
begin
  x[1]:=x1; y[1]:=y1; {1 = 1 to 2}
  x[2]:=x2; y[2]:=y2; {2 = 2 to 3}
  x[3]:=x3; y[3]:=y3; {3 = 1 to 3}
  minx:=320; for i:=1 to 3 do if x[i]<minx then minx:=x[i]; if minx=320 then exit;
  miny:=200; for i:=1 to 3 do if y[i]<miny then miny:=y[i]; if miny=200 then exit;
  maxx:=0;   for i:=1 to 3 do if x[i]>maxx then maxx:=y[i]; if maxx=0 then exit;
  maxy:=0;   for i:=1 to 3 do if y[i]>maxy then maxy:=y[i]; if maxy=0 then exit;
  main:=0;
  for i:=1 to 3 do
   if ((y[i]=miny)and(y[i mod 3+1]=maxy))or((y[i]=maxy)and(y[i mod 3+1]=miny))then begin main:=i; break;end;
  if main<>0 then
  begin
   line(x[main]        ,y[main]        ,x[main mod 3+1],y[main mod 3+1],1);
   line(x[main mod 3+1],y[main mod 3+1],x[(main+1) mod 3+1],y[(main+1) mod 3+1],2);
   line(x[(main+1)mod 3+1],y[(main+1)mod 3+1],x[(main+2) mod 3+1],y[(main+2) mod 3+1],2);
  end;
  if minx<0 then minx:=0;
  if miny<0 then miny:=0;
  if maxx>319 then maxx:=319;
  if maxy>198 then maxy:=198;

   for i:=miny to maxy do
     fillchar32(scr^,i*320+min(yx[1,i],yx[2,i]),abs(abs(yx[1,i])-abs(yx[2,i]))mod 320,col);
end;
procedure smartprint(x,y,c:integer; s:string);
var jx,jy:longint;
begin
  jx:=x-length(s)*4;
  jy:=y-4;
  bar(jx,jy,jx+length(s)*8,jy+8,(c div 8)*8+2);
  line(jx,jy-1,jx+length(s)*8,jy-1,c);
  line(jx,jy+9,jx+length(s)*8,jy+9,c);
  line(jx-1,jy,jx-1,jy+8,c);
  line(jx+1+length(s)*8,jy,jx+1+length(s)*8,jy+8,c);
  print(jx,jy,c,s);
end;
procedure print(x,y,c:integer; s:string);
var i,j,k,l:integer;
begin
 if (y>=-8)and(x<mx)and(y<my) then
 begin
   for k:=1 to length(s) do
    for i:=1 to 8 do
     for j:=1 to 8 do
     if (fnt^[ord(s[k]),j] shr (8-i))and 1=1 then
       putpixel((x+(k-1)*8+i),(y+j),c);
  end;
end;
procedure outtext(x,y,c:integer; s:string);
var i,j,k,l:integer;
begin
  if s='' then exit;
  if x+length(s)*8>mx then x:=mx-length(s)*8;
  if x<0 then x:=0;
  bar(x,y,x+length(s)*8,y+8,43);
  line(x,y-1,x+length(s)*8,y-1,c+1);
  line(x,y+9,x+length(s)*8,y+9,c+1);
  line(x-1,y,x-1,y+8,c+1);
  line(x+length(s)*8+1,y,x+length(s)*8+1,y+8,c+1);
  for k:=1 to length(s) do
    for i:=1 to 8 do
     for j:=1 to 8 do
     if odd(fnt^[ord(s[k]),j] shr (8-i)) then putnotpixel((x+(k-1)*8+i),(y+j))
end;

Procedure loadpalete(name:string);
var ff:file;
begin
  if pal=nil then new(pal);
  if bufe=nil then new(bufe);
  assign(ff,name);
  reset(ff,1);
  seek(ff,54);
  blockread(ff,pal^,256*4);
  close(ff);
  setpal;
  bufe^:=pal^;
end;
procedure setpal;
var i:integer;
begin
  port[$3c8]:=0;
  for i:=0 to 255 do
  begin
(*r*)  port[$3c9]:=pal^[(i*4)+2] div 4;
(*g*)  port[$3c9]:=pal^[(i*4)+1] div 4;
(*b*)  port[$3c9]:=pal^[(i*4)+0] div 4;
  end;
end;
procedure setfullpal;
var i,temp:integer;
begin
  temp:=0;
  port[$3c8]:=0;
  for i:=0 to 255 do
  begin
(*r*)  port[$3c9]:=pal^[(i*4)+2] div 4;
(*g*)  port[$3c9]:=pal^[(i*4)+1] div 4;
(*b*)  port[$3c9]:=pal^[(i*4)+0] div 4;
     if pal^[(i*4)+0]+pal^[(i*4)+1]+pal^[(i*4)+2]>temp then
     begin
       temp:=pal^[(i*4)+0]+pal^[(i*4)+1]+pal^[(i*4)+2];
       white:=i;
     end;
  end;
end;
procedure setgraypal;
var i:integer;
begin
  port[$3c8]:=0;
  for i:=0 to 255 do
  begin
(*r*)  port[$3c9]:=i div 4;
(*g*)  port[$3c9]:=i div 4;
(*b*)  port[$3c9]:=i div 4;
  end;
end;
procedure box(x1,y1,x2,y2:word);
begin
  bar(x1+1,y1+1,x2-1,y2-1,7);
  line(x1,y1,x2,y1,15);
  line(x1,y1,x1,y2,15);
  line(x2,y1,x2,y2,8);
  line(x1,y2,x2,y2,8);
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
procedure linex;
var i:integer;
begin
  if y2>y then for i:=y to y2 do putpixel(x,i,c);
  if y>y2 then for i:=y2 to y do putpixel(x,i,c);
end;
procedure liney;
var i:integer;
begin
  if x2>x then for i:=x to x2 do putpixel(i,y,c);
  if x>x2 then for i:=x2 to x do putpixel(i,y,c);
end;
procedure line(x1,y1,x2,y2:integer; c:byte);
var dx,dy,a,b,i,j:longint;
begin
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
end;
procedure rectangle(x1,y1,x2,y2,c:integer);
begin
  line(x1,y1,x2,y1,c);
  line(x1,y1,x1,y2,c);
  line(x2,y1,x2,y2,c);
  line(x1,y2,x2,y2,c);
end;

procedure loadfont;
var f:file;
begin
  if fnt=nil then new(fnt);
  assign(f,name);
{$i-}  reset(f,1);{$i+}
  if ioresult<>0 then exit;
  blockread(f,fnt^,sizeof(fnt^));
  close(f);
end;

procedure putnotpixel(x,y:longint);
var k:longint;
begin
 k:=x+y*mx;
 if (x>=0)and(x<mx)and(y>=0)and(y<my)
   then scr^[k]:=not scr^[k];
end;
{procedure print(x,y,c:integer; s:string);
var i,j,k,l:integer;
begin
 if (x>=0)and(y>=0)and(x<mx)and(y<my) then
 begin
 if c=0 then
 begin
  for k:=1 to length(s) do
    for i:=1 to 8 do
     for j:=1 to 8 do
     if odd(fnt^[ord(s[k]),j] shr (8-i)) then putnotpixel((x+(k-1)*8+i),(y+j))
   end
  else
   for k:=1 to length(s) do
     for i:=1 to 8 do
     for j:=1 to 8 do
     if odd(fnt^[ord(s[k]),j] shr (8-i)) then
       putpixel((x+(k-1)*8+i),(y+j),c);
  end;
end;}
Procedure loadpal(name:string);
var ff:file;
    buf:array[0..256*4]of byte;
    i,c,max,t:integer;
begin
    new(pal);  fillchar(pal^,sizeof(pal^),0);
  assign(ff,name);
{$i-}  reset(ff,1); {$i+}
if ioresult<>0 then exit;
  seek(ff,54);
  blockread(ff,pal^,256*4);
  close(ff);
  port[$3c8]:=0;
  c:=255; max:=0;
  setfullpal;
  white:=c;
end;
procedure init320x200;
begin
   if maxavail<68000 then begin writeln('Fatal error: Free Memory: ',maxavail); halt; end;
   asm xor ax,ax; mov al,$13; int $10; end;
   new(scr);
   graph:=true;
   setreg(0,0,319,199);
end;
procedure closegraph;
begin
   asm xor ax,ax; mov al,$3; int $10; end;
   if scr<>nil then dispose(scr);
   if fnt<>nil then dispose(fnt);
   if pal<>nil then dispose(pal);
   if bufe<>nil then dispose(bufe);
   scr:=nil; fnt:=nil; pal:=nil; bufe:=nil;
   graph:=false;
end;
procedure screen;
begin
{  retrace;}
  move32(scr^,0,mem[sega000:0],0,64000);
end;
procedure clear;
begin
  fillchar32(scr^,0,64000,0);
end;
begin
  fnt:=nil; scr:=nil; pal:=nil; bufe:=nil;
  graph:=false;
  maxl:=320; curl:=0;
end.