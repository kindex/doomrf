{$A+,B-,D+,E-,F-,G+,I+,L+,N+,O-,P-,Q-,R-,S-,T-,V+,X+,Y+ Filan}
{ $A+,B+,D+,E-,F+,G+,I+,L+,N+,O+,P+,Q+,R+,S+,T+,V+,X+,Y+ Debug}
{$M $fff0,0,655360}
program special_for_puh; {First verion: 27.2.2001}
uses mygraph,mycrt,api,mouse,wads;
const
  wadfile='doom2d.wad';
  data='28.2.2001';
  maxx=300;
  maxy=300;
  maxpat=300;
  cwall = 1 shl 0;
  cstand= 1 shl 1
  cwater= 1 shl 2;
  clava = 1 shl 3;
type
   real=single;
   tnpat=0..maxpat;
   ttimer=object
      hod:longint;  fps:extended;
      tik:record cur,start:extended; h,m,s,s100:word; end;
      time:record cur,start:longint; end;
      procedure clear;
      procedure move;
      procedure gettime;
      procedure getfps;
   end;
  larray=array[0..$fffa]of byte;
  tbmp=object
      n:^larray{pointer};
      x,y,dx,dy:integer;
      color:byte;
      name:string[8];
      procedure load(ss:string);
      procedure loadfile(ss:string);
      procedure loadwad(ss:string);
      procedure put(tx,ty:longint);
      procedure putblack(tx,ty:longint);
      procedure done;
  end;
  tmapelement=record
    land,vis:byte;
  end;
  tmapar=array[0..maxx]of tmapelement;
  tland=array[0..maxy]of ^tmapar;
  tmap=object
    land:tland;
    x,y,dx,dy:longint;
    g:real;
    procedure init(ax,ay,adx,ady:longint);
    procedure done;
    procedure draw;
  end;
  tobj=object
    mx,my:integer;
    x,y,dx,dy:real;
    procedure move;
  end;
  tmon=object(tobj)

  end;
  tpul=object(tobj)

  end;
  titem=object(tobj)

  end;
  arrayofstring=array[1..7000]of string[8];
var
  time:ttimer;
  w:twad;
  map:tmap;
  p:array[0..maxpat]of tbmp;
  lands:array[byte]of 0..maxpat;
  names:array[byte]of string[8];
  allwall:^arrayofstring;
  maxlands:longint;
  mx,my:longint;
  debug:boolean;
  cur:tnpat;
(************************** IMPLEMENTATION **********************************)
procedure tobj.move;
begin
  dy:=dy+map.g;
  x:=x+dx;
  y:=y+dy;
end;
procedure tmap.done;
var i:longint;
begin
  for i:=0 to y-1 do freemem(land[i],x);
end;
procedure tmap.draw; {40x25}
var
  i,j:longint;
begin
  for i:=0 to 39 do
    for j:=0 to 20 do
    if land[j+dy]^[i+dx].vis<>0 then
     p[lands[land[j+dy]^[i+dx].vis]].put(i*8,j*8);
end;
procedure tmap.init;
var i:longint;
begin
  x:=ax; y:=ay;
  dx:=adx; dy:=ady;
  for i:=0 to y-1 do
  begin
    getmem(land[i],x);
    fillchar(land[i]^,x,0);
  end;
end;
procedure loadpal(s:string);
var i:longint;
begin
  if w.exist(s) then
  begin
    w.assign(s);
    new(pal);  fillchar(pal^,sizeof(pal^),0);
    for i:=0 to 255 do
    begin
      w.read(pal^[i*4+2],1);
      w.read(pal^[i*4+1],1);
      w.read(pal^[i*4+0],1);
    end;
    setfullpal;
  end
  else mygraph.loadpal(s);
end;
procedure tbmp.put(tx,ty:longint);
var i:longint;
begin
  if x=0 then exit;
  dec(tx,dx); dec(ty,dy);
  for i:=0 to y-1 do move(n^[x*i],scr^[(i+ty)*320+tx],x);
end;
procedure tbmp.putblack(tx,ty:longint);
var
  i,j:integer;
  c:byte;
begin
  if x=0 then exit;
  dec(tx,dx); dec(ty,dy);
  for i:=0 to y-1 do
   for j:=0 to x-1 do
   begin
     c:=n^[x*i+j];
     if c<>0 then putpixel(j+tx,i+ty,c);
   end;
end;
procedure tbmp.done;
begin
  freemem(n,x*y); n:=nil; x:=0; y:=0; dx:=0; dy:=0; name:='';
end;
procedure tbmp.loadwad;
begin
  name:=ss;
  w.assign(name);
  w.read(x,2); w.read(y,2);
  w.read(dx,2); w.read(dy,2);
  if (w.cur.l=longint(x)*longint(y)+8)and(longint(x)*longint(y)<$fff0) then
  begin
    getmem(n,longint(x)*longint(y));
    w.read(n^,longint(x)*longint(y));
  end else begin x:=0; y:=0; end;
end;
procedure tbmp.load;
begin
  if x<>0 then done;
  name:=ss;
  if w.exist(name) then loadwad(name) else loadfile(name);
end;
procedure tbmp.loadfile;
var
  f:file;
  i,temp,ost:longint;
begin
  name:=ss;
  dx:=0; dy:=0;
  if pos('.',name)=0 then ss:=ss+'.bmp';
  assign(f,ss);
  {$i-}reset(f,1);{$i+}
  if ioresult<>0 then begin x:=0; y:=0; exit; end;
  seek(f,18); blockread(f,x,4);  blockread(f,y,4);
{  if maxavail<x*y then begin if debug then putline('Free memory: '+st(memavail));  n:=nil; x:=0; y:=0;close(f);exit;end;}
  getmem(n,x*y);
  case x mod 4 of
  0: ost:=0;
  1: ost:=3;
  2: ost:=2;
  3: ost:=1;
  end;
  seek(f,1078);
  for i:=y-1 downto 0 do
  begin
    blockread(f,n^[i*x],x);
    if ost<>0 then blockread(f,temp,ost);
  end;
  close(f);
  color:=random(256);
end;
procedure ttimer.clear;
begin
  gettime;  time.start:=time.cur;  tik.start:=tik.cur;  hod:=0;
end;
procedure ttimer.move;
begin
  inc(hod);  gettime;
{  getfps;}
  if hod=100 then begin getfps; clear;end;
end;
procedure ttimer.gettime;
begin
{$ifndef dpmi}
  time.cur:=meml[0:$046c];
{$else}
  with tik do dos.gettime(h,m,s,s100);
  with tik do cur:=h*60*60+m*60+s+s100/100;
{$endif}
end;
procedure ttimer.getfps;
begin
{$ifndef dpmi}
  fps:=hod*18/(time.cur-time.start+1);
{$else}
  fps:=hod/(tik.cur-tik.start+0.01);
{$endif}
end;
procedure savepal(s:string);
var f:file;
  i:longint;
begin
  assign(f,s);
  reset(f,1);
  seek(f,54);
  for i:=0 to 256*4 do pal^[i]:=pal^[i]*4;
  blockwrite(f,pal^,256*4);
  close(f);
end;
function loadbmp(s:string):tnpat;
var i:longint;
begin
  s:=upcase(s);
  for i:=1 to maxpat do if p[i].name=s then begin loadbmp:=i; exit; end;
  for i:=1 to maxpat do
    if p[i].x=0 then
    begin
     p[i].load(s);
     loadbmp:=i;
     exit;
    end;
  loadbmp:=0;
end;
procedure loadwalls;
var dat:text;
  k,i:longint;
begin
  assign(dat,'wall.dat');
  reset(dat);
  readln(dat,k);
  if debug and(k>50) then k:=50;
  getmem(allwall,k*9);
  for i:=1 to k do readln(dat,allwall^[maxlands]);
  maxlands:=0;
  while not eof(dat)do
  begin
    inc(maxlands);
    readln(dat,allwall^[maxlands]);
  end;
  close(dat);
end;
(******************************** PROGRAM ***********************************)
var i:longint;
begin
{  debug:=true;}
  w.load(wadfile);
  map.init(100,100,0,0); map.g:=-0.1;
  init320x200; loadfont('8x8.fnt');     clear;
  loadpal('playpal');
{  w.findfirst('playa'); w.findstr:='*';}
  loadwalls;
  cur:=loadbmp('cursor');
  for i:=1 to 100 do
    map.land[random(100)]^[random(100)].vis:=random(198)+1;
  time.clear;
  repeat
    time.move;
    mx:=mouse.x;
    my:=mouse.y;
    if keypressed then
    case readkey of
      #27: break;
    end;
{    p.done;    p.load('puh8.bmp');}
    clear;
    map.draw;
    print(100,190,white,st(w.findn)+'/'+st(w.n));
    print(290,190,white,st0(round(time.fps),3));
    print(10,190,white,w.cur.getname);
    p[cur].putblack(mx,my);
    screen;
  until (w.n=w.findn);
  savepal('doom.pal');
  closegraph;
  map.done;
  w.find('playpal');
  writeln(memavail);
end.