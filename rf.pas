{$A+,B-,D+,E-,F-,G+,I+,L+,N+,O-,P-,Q-,R-,S-,T-,V+,X+,Y+ Filan}
{ $A+,B+,D+,E-,F+,G+,I+,L+,N+,O+,P+,Q+,R+,S+,T+,V+,X+,Y+ Debug}
{$M $fff0,0,655360}
program special_for_puh; {First verion: 27.2.2001}
uses mygraph,mycrt,api,mouse,wads;
const
  wadfile='513.wad';
  data='28.2.2001 Extractor';
  maxx=300;
  maxy=300;
  maxpat=300;
type
   tnpat=0..maxpat;
  tbitmap=record
     caption:array[1..2]of char; {'BM'}
     Size  : longint;   {X*Y+FMT+PAL}
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
      procedure save;
  end;
  tmapelement=record
    land,vis:byte;
  end;
  tmapar=array[0..maxx]of tmapelement;
  tland=array[0..maxy]of ^tmapar;
  tmap=object
    land:tland;
    x,y,dx,dy:longint;
    procedure init(ax,ay,adx,ady:longint);
    procedure done;
    procedure draw;
  end;
var
  time:ttimer;
  w:twad;
  map:tmap;
  p:array[0..maxpat]of tbmp;
  lands:array[byte]of 0..maxpat;
(************************** IMPLEMENTATION **********************************)
procedure tbmp.save;
var f:file;
   b:tbitmap;
   t,i,j,ost:longint;
begin
  assign(f,name+'.bmp');
  rewrite(f,1);
  with b do
  begin
     X:=self.x; Y:=self.y;
    caption:='BM';
    size:=256*4+54+x*y;
    Reserved1:=0; Reserved2:=0;
    fmtsize:=54+256*4;   {FMT}
    USize:=40;   {40 ?}
    pages:=1; {1}
    Bits:=8; {8}
    Compression:=0;{0}
    ImageSize:=x*y;{x*y}
    XPPM:=0; YPPM:=0; {0}
    ClrUsed:=256; ClrImportant:=256;  {?}
  end;
  blockwrite(f,b,54);
  blockwrite(f,pal^,256*4);
  case x mod 4 of
  0: ost:=0;
  1: ost:=3;
  2: ost:=2;
  3: ost:=1;
  end;
  t:=0;
  for i:=y-1 downto 0 do
  begin
    blockwrite(f,n^[i*x],x);
    if ost<>0 then blockwrite(f,t,ost);
  end;
  close(f);
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
      pal^[i*4+2]:=pal^[i*4+2]*4;
      pal^[i*4+1]:=pal^[i*4+1]*4;
      pal^[i*4+0]:=pal^[i*4+0]*4;
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
  if pos('.',name)=0 then name:=name+'.bmp';
  assign(f,name);
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
  if hod=50 then begin getfps; clear;end;
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
  blockwrite(f,pal^,256*4);
  close(f);
end;
function loadbmp(s:string):tnpat;
var i:longint;
begin
  for i:=1 to maxpat do if p[i].name=s then begin loadbmp:=i; exit; end;
  for i:=1 to maxpat do
    if p[i].x=0 then
    begin
     p[i].load(s);
     loadbmp:=i;
     exit;
    end;
end;
(******************************** PROGRAM ***********************************)
var i,m:longint;
begin
  w.load(wadfile);
  map.init(100,100,0,0);
  init320x200; loadfont('8x8.fnt');
  loadpal('playpal.bmp');
  w.findfirst('*');
  w.findstr:='*';
{  w.findn:=680;}
  m:=loadbmp(w.cur.getname);
  while not((w.error<>0)or(p[m].x<>0)) do
  begin
    w.findnext;
    m:=loadbmp(w.cur.getname);
 end;
  time.clear;
  repeat
    time.move;
    if keypressed then
    case system.upcase(readkey) of
      ' ': begin
             p[m].done;
             repeat
               w.findnext;
               p[m].load(w.cur.getname);
             until (w.error<>0)or(p[m].x<>0)or(w.n=w.findn);
{             p[m].save;}
           end;
      'E':
      begin
             p[m].done;
             repeat
               w.findnext;
               p[m].load(w.cur.getname);
             until (w.error<>0)or(p[m].x<>0)or(w.n=w.findn);
             p[m].save;
           end;
      #27: break;
    end;
{    p.done;    p.load('puh8.bmp');}
    clear;
    map.draw;
    p[m].put(160,100);
    print(100,190,white,st(w.findn)+'/'+st(w.n));
    print(200,190,white,st(p[m].x)+'x'+st(p[m].y));
    print(290,190,white,st0(round(time.fps),3));
    print(10,190,white,w.cur.getname);
    screen;
  until (w.n=w.findn);
  savepal('doom.pal');
  closegraph;
  w.find('playpal');
end.