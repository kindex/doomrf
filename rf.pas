{$A+,B-,D+,E-,F-,G+,I+,L+,N+,O-,P-,Q-,R-,S-,T-,V+,X+,Y+ Filan}
{ $A+,B+,D+,E-,F+,G+,I+,L+,N+,O+,P+,Q+,R+,S+,T+,V+,X+,Y+ Debug}
{$M $fff0,0,655360}
program RF; {First verion: 27.2.2001}
uses mygraph,mycrt,api,mouse,wads,F32MA;
const
  wadfile='doom2d.wad';
  game='DooM RF';
  version='0.03';
  data='1.3.2001';
  company='IVA vision <-=[■]=->';
  autor='Andrey Ivanov [kIndeX Navigator]';
  comment='Special for Puh!';
  maxx=300;
  maxy=300;
  maxpat=300;
  cwall = 1 shl 0;
  cstand= 1 shl 1;
  cwater= 1 shl 2;
  clava = 1 shl 3;
  maxmon=100;
  maxitem=100;
  maxf=100;
  maxpix=200;
  maxpul=100;
  maxmontip=32;
  scry=19*8;
  scrx=260;
  maxt=320 div 8;
  maxedmenu=10;
  fupr=0.5;
  fupr2=0.9;
  edwallstr:array[1..8]of string[16]=
  (
  'Стена',
  'Ступень',
  'Вода',
  'Лава',
  '5',
  '6',
  '7',
  '8'
  );
  edmenustr:array[1..maxedmenu]of string[16]=
  (
  'Выход',
  'Сохран',
  'Загруз',
  'Новая',
  'Текстур',
  'Стены',
  'Монстры',
  'Предметы',
  'Функции',
  '-'
  );
  defx=128; defy=128; defname='temp';
type
  tcapt=array[1..4]of char;
const
  origlev:tcapt='FLEV';
type
   real=single;
   tnpat=0..maxpat;
   tmaxmontip=0..maxmontip;
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
      procedure putabs(tx,ty:longint);
      procedure putblack(tx,ty:longint);
      procedure done;
  end;
  tmapelement=record
    land,vis:byte;
  end;
  tmapar=array[0..maxx]of tmapelement;
  tland=array[0..maxy]of ^tmapar;
  tobj=object
    enable:boolean;
    lx,ly,mx,my:integer; {map}
    x,y,dx,dy:real;
    constructor new;
    procedure init(ax,ay,adx,ady:real);
    function getsx:integer; virtual;
    function getsy:integer; virtual;
    procedure move;   virtual;
    procedure draw(ax,ay:integer);
    procedure done;   virtual;
    function inwall:boolean;
  end;
  tpix=object(tobj)
    color:byte;
    life:longint;
    procedure init(ax,ay,adx,ady:real; ac,al:longint);
    procedure move; virtual;
    procedure draw(ax,ay:integer);
  end;
  tmon=object(tobj)
     tip: tmaxmontip;
     procedure init(ax,ay,adx,ady:real; at:tmaxmontip);
     function getsx:integer; virtual;
     function getsy:integer; virtual;
  end;
  tpul=object(tobj)

  end;
  titem=object(tobj)

  end;
  tF=object(tobj)

  end;
  arrayofstring8=array[0..7000]of string[8];
  arrayofmon=array[0..maxmon]of tmon;
  arrayofitem=array[0..maxitem]of titem;
  arrayoff=array[0..maxf]of tf;
  arrayofpix=array[0..maxpix]of tpix;
  arrayofpul=array[0..maxpul]of tpul;
  tmap=object
    name:string[8];
    land:tland;
    x,y,dx,dy:longint;
    g:real;
    pat:array[byte]of 0..maxpat;
    patname:^arrayofstring8;
    m:^arrayofmon;
    item:^arrayofitem;
    f:^arrayoff;
    pix:^arrayofpix;
    pul:^arrayofpul;
    procedure new;
    procedure create(ax,ay,adx,ady:longint; aname:string);
    procedure reloadpat;
    procedure deletepat;
    function addpat(s:string):longint;
    procedure putpat(ax,ay,a,b:longint);
    procedure putwall(ax,ay,b:longint);
    procedure deputpat(ax,ay:longint);
    procedure pset(ax,ay,a,b:longint);
    procedure load(s:string);
    procedure save;
    procedure done;
    procedure draw;
    procedure drawhidden;
    procedure move;
    procedure initmon(ax,ay:real; at:longint);
    procedure initpix(ax,ay,adx,ady:real; ac,al:longint);
  end;
  ted=object
    what: (face,wall,mons,items,func);
    cured:longint;
    land:record
      curname:string[8];
      cur,ch:longint;
      mask:byte;
      maxtt:longint;
      t:array[1..maxt]of
      record
        x,y:integer;
        b:tbmp;
       end;
    end;
    procedure draw;
    procedure move;
  end;
var
  time:ttimer;
  w:twad;
  map:tmap;
  speed:real;
  ed:ted;
  monster:array[tmaxmontip]of
  record
    name:string[40];
    x,y:integer;
  end;
  p:array[0..maxpat]of tbmp;
  names:array[byte]of string[8];
  allwall:^arrayofstring8;
  mx,my:longint;
  push,push2:boolean;
  debug,editor,endgame,sfps:boolean;
  cur:tnpat;
(******************************** IMPLEMENTATION ****************************)
procedure ted.draw;
var i:longint;
begin
  map.drawhidden;
  case what of
   wall:
   begin
     for i:=1 to 8 do print(0+100*byte(i>4),scry+i*10-byte(i>4)*40,
     white-30*byte(0<(land.mask and (1 shl (i-1)))),edwallstr[i]);
   end;
   face: with land do
   begin
     for i:=1 to maxtt do
     begin
       if i+ch=cur then bar(t[i].x-1,t[i].y-1,t[i].x+t[i].b.x,t[i].y+t[i].b.y,white);
        t[i].b.putabs(t[i].x,t[i].y);
     end;
   end;
  end;
  for i:=1 to maxedmenu do
   if i=cured then
     print(scrx,(i-1)*10,white,edmenustr[i])
   else
     print(scrx,(i-1)*10,not white,edmenustr[i])
end;
function mo(x1,y1,x2,y2:integer):boolean;
begin
  if (mx>=x1)and(my>=y1)and(mx<=x2)and(my<=y2)then mo:=true else mo:=false;
end;
function enterfile(s:string):string;
var res:string;
begin
  readline(100,100,res,s,white,0);
  enterfile:=res;
end;
procedure ted.move;
var
  i,freex,j:longint;
  s:string;
begin
  if mo(scrx,0,319,scry)then
  if push then
  begin
    cured:=my div 10+1;
    case cured of
   1:
   begin
     s:='yes';
     readline(100,100,s,s,white,0);
     if downcase(s)='yes'then endgame:=true;
   end;
   2: begin
        s:=enterfile(map.name);
        if s<>'' then begin map.name:=s; map.save; end;
      end;
   3: begin
        s:=enterfile(map.name);
        if s<>'' then map.load(s);
      end;
    4: begin
         s:='yes';
         readline(100,100,s,s,white,0);
         if downcase(s)='yes'then
         begin
           map.done;
           map.create(defx,defx,0,0,defname);
         end;
       end;
    5: what:=face;
    6: what:=wall;
    7: what:=mons;
    8: what:=items;
    9: what:=func;
  end;
 end;
  if mo(0,scry,319,199)then
  begin
   if push then
    case what of
     wall:begin
       repeat until not mouse.push;
       i:=(my-scry)div 10;
       if mx>100 then inc(i,4);
       land.mask:=land.mask xor (1 shl (i-1));
     end;
     face: with land do
      begin
        if mx=319 then
        begin
          inc(ch);
          t[1].b.done;
          for j:=1 to maxt-1 do t[j].b:=t[j+1].b;
        end
        else
        if (mx=0)and(ch>0) then
        begin
          dec(ch);
{          t[maxt].b.done;
          for j:=maxt downto 2 do t[j].b:=t[j-1].b; error}
        end
        else
        for i:=1 to maxtt do if mo(t[i].x-1,t[i].y-1,t[i].x+t[i].b.x,t[i].y+t[i].b.y) then
        begin
          curname:=t[i].b.name;
          cur:=ch+i;
        end;
      end;
    end;
  end;
  if mo(0,0,scrx,scry)then
   begin
     if push then
     begin
       case what of
       face:
         begin
           land.cur:=map.addpat(land.curname);
          for i:=0 to p[map.pat[land.cur]].x div 8-1 do
           for j:=0 to p[map.pat[land.cur]].y div 8-1 do
            map.deputpat((mx+map.dx)div 8+i,(my+map.dy)div 8+j);
           map.putpat((mx+map.dx)div 8,(my+map.dy)div 8,land.cur,land.mask);
         end;
       wall: map.putwall((mx+map.dx)div 8,(my+map.dy)div 8,land.mask);
       end;
     end;
     if push2 then
       case what of
         face: map.deputpat((mx+map.dx)div 8,(my+map.dy)div 8);
         wall: map.putwall((mx+map.dx)div 8,(my+map.dy)div 8,0);
       end;
  end;
  freex:=0;
   for i:=1 to maxt do
    with land,t[i] do
    begin
      if b.name<>allwall^[ch+i] then
      begin
        b.load(allwall^[ch+i]);
      end;
        y:=scry+2;
        x:=freex;
      maxtt:=i;
      freex:=freex+b.x+2;
      if freex>=320 then begin dec(maxtt); break; end;
   end;
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
procedure tmap.initmon;
var i:longint;
begin
  for i:=0 to maxmon do
    if not m^[i].enable then
    begin
      m^[i].init(ax,ay,0,0,at);
      exit;
    end;
end;
procedure tmap.initpix;
var i:longint;
begin
  for i:=0 to maxpix do
    if not pix^[i].enable then
    begin
      pix^[i].init(ax,ay,adx,ady,ac,al);
      exit;
    end;
end;
procedure tpix.move;
begin
  dec(life);
  if life=0 then begin done; exit; end;
  tobj.move;
end;
procedure tobj.move;
var savex,savey:real;
begin
  dy:=dy+map.g;
  savex:=x;
  savex:=y;
  x:=x+dx*speed; mx:=round(x); lx:=mx div 8;
  if inwall then
  begin
    x:=savex;
    dx:=-dx*fupr;
    dy:=dy*fupr2;
    mx:=round(x); lx:=mx div 8;
  end;
  y:=y+dy*speed; my:=round(y); ly:=my div 8;
  if inwall then
  begin
    y:=savey;
    dy:=-dy*fupr;
    dx:=dx*fupr2;
    my:=round(y); ly:=my div 8;
  end;
end;
constructor tobj.new; begin {nothing} end;
function tobj.getsx:integer;
begin getsx:=1; end;
function tobj.getsy:integer;
begin getsy:=1; end;
procedure tpix.draw;
begin
  putpixel(mx-ax,my-ay,color);
end;
procedure tobj.draw;
begin
  putpixel(mx-ax,my-ay,white);
end;
function tmon.getsx:integer;
begin
  getsx:=monster[tip].x;
end;
function tmon.getsy:integer;
begin
  getsy:=monster[tip].y;
end;
procedure tmon.init(ax,ay,adx,ady:real; at:tmaxmontip);
begin
  tobj.init(ax,ay,adx,ady);
  tip:=at;
end;
procedure tobj.init(ax,ay,adx,ady:real);
begin
  enable:=true;
  x:=ax; y:=ay;
  dx:=adx; dy:=ady;
end;
procedure tpix.init;
begin
  tobj.init(ax,ay,adx,ady);
  color:=ac;
  life:=al;
end;
procedure tobj.done;
begin
  enable:=false;
end;
function tobj.inwall:boolean;
var
  i,j,sx,sy,x1,y1,x2,y2:integer;
  ok:boolean;
begin
  sx:=getsx;
  sy:=getsy;
  x1:=lx-sx div 2; x2:=x1+sx-1;
  y2:=ly; y1:=y2-sy;
  if (x1<0)or(y1<0)or(x2>=map.x)or(y2>=map.y) then begin inwall:=true; exit; end;
  for i:=x1 to x2 do
    for j:=y1 to y2 do
    if map.land[j]^[i].land and cwall>0 then begin inwall:=true; exit; end;
  inwall:=false;
end;
procedure tmap.pset;
begin
  if (ax>=0)and(ay>=0)and(ax<x)and(ay<y) then
  begin
    land[ay]^[ax].vis:=a;
    land[ay]^[ax].land:=b;
  end;
end;
procedure tmap.deputpat;
var
  i,j,w,i2,j2:longint;
begin
{  pset(ax,ay,0,0);}
  for i:=ax downto 0 do
    for j:=ay downto 0 do
    begin
      w:=land[j]^[i].vis;
      if w<>0 then
       if (p[pat[w]].x div 8+i>ax)and(p[pat[w]].y div 8+j>ay) then
        begin
          for i2:=i to i+p[pat[w]].x div 8-1 do
            for j2:=j to j+p[pat[w]].y div 8-1 do
               pset(i2,j2,0,0);
          break;
        end;
    end;
  pset(ax,ay,0,0);
end;
procedure tmap.putpat;
var i,j:longint;
begin
  for i:=ax to ax+p[pat[a]].x div 8-1 do
    for j:=ay to ay+p[pat[a]].y div 8-1 do
      pset(i,j,0,b);
  pset(ax,ay,a,b);
end;
procedure tmap.putwall;
var i,j:longint;
begin
  if (ax>=0)and(ay>=0)and(ax<x)and(ay<y) then
    land[ay]^[ax].land:=b;
end;
procedure tmap.load(s:string);
var
  ff:file;
  capt:tcapt;
  mpat,mmon,mitem,mf,i:longint;
  pats:string[8];
begin
  name:=s;
  assign(ff,name+'.lev');
  reset(ff,1);
  blockread(ff,capt,sizeof(capt));
  if capt=origlev then
  begin
    done;
    blockread(ff,x,4);
    blockread(ff,y,4);
    blockread(ff,dx,4);
    blockread(ff,dy,4);
    blockread(ff,mpat,4);
    blockread(ff,mmon,4);
    blockread(ff,mitem,4);
    blockread(ff,mf,4);
    create(x,y,dx,dy,name);
    for i:=0 to y-1 do
      blockread(ff,land[i]^,x*2);
    deletepat;
    blockread(ff,patname^,mpat*9+9);
    fillchar(m^,sizeof(m^),0);      if mmon<>0 then blockread(ff,m^,sizeof(tmon)*(mmon+1));
    for i:=0 to maxmon do m^[i].new;
    fillchar(item^,sizeof(item^),0);if mitem<>0 then blockread(ff,item^,sizeof(titem)*(mitem+1));
    for i:=0 to maxitem do item^[i].new;
    fillchar(f^,sizeof(f^),0);      if mf<>0 then blockread(ff,f^,sizeof(tf)*(mf+1));          for i:=0 to maxf do f^[i].new;
    reloadpat;
  end;
  close(ff);
end;
procedure tmap.save;
var ff:file;
  mpat,mmon,mitem,mf,i:longint;
begin
  assign(ff,name+'.lev');
  rewrite(ff,1);
  blockwrite(ff,origlev,sizeof(origlev));
  blockwrite(ff,x,4);
  blockwrite(ff,y,4);
  blockwrite(ff,dx,4);
  blockwrite(ff,dy,4);
  for mpat:=1 to 255 do if patname^[mpat]='' then break;
  blockwrite(ff,mpat,4);
  mmon:=maxmon;
  while (not m^[mmon].enable)and(mmon>0) do dec(mmon); blockwrite(ff,mmon,4);
  mitem:=maxitem; while (not item^[mitem].enable)and(mitem>0) do dec(mitem); blockwrite(ff,mitem,4);
  mf:=maxf; while (not f^[mf].enable)and(mf>0) do dec(mf); blockwrite(ff,mf,4);
  for i:=0 to y-1 do blockwrite(ff,land[i]^,x*2);
  blockwrite(ff,patname^,mpat*9+9);
  blockwrite(ff,m^,sizeof(tmon)*mmon);
  blockwrite(ff,item^,sizeof(titem)*mitem);
  blockwrite(ff,f^,sizeof(tf)*mf);
  close(ff);
end;
procedure tmap.done;
var i:longint;
begin
  for i:=0 to y-1 do freemem(land[i],x*2);
  x:=0; y:=0;
end;
procedure tmap.draw; {40x25}
var
  i,j:longint;
  x1,y1,x2,y2:integer;
begin
  x1:=dx div 8;
  y1:=dy div 8;
  x2:=dx mod 8;
  y2:=dy mod 8;
  for i:=0 to scrx div 8 do
    for j:=0 to scry div 8 do
     if land[j+y1]^[i+x1].vis<>0 then
       p[pat[land[j+y1]^[i+x1].vis]].put(i*8-x2,j*8-y2);
  for i:=0 to maxmon do if m^[i].enable then m^[i].draw(dx,dy);
  for i:=0 to maxitem do if item^[i].enable then item^[i].draw(dx,dy);
  for i:=0 to maxf do if f^[i].enable then f^[i].draw(dx,dy);
  for i:=0 to maxpix do if pix^[i].enable then pix^[i].draw(dx,dy);
  for i:=0 to maxpul do if pul^[i].enable then pul^[i].draw(dx,dy);
end;
procedure tmap.drawhidden; {40x25}
var i,j:longint;
    x1,y1,x2,y2:integer;
function getcolor(a:byte):byte;
begin
  case a of
  0: getcolor:=0;
  1: getcolor:=white;
  2..3: getcolor:=30;
  4..7: getcolor:=60;
  8..15: getcolor:=20;
  end;
end;
begin
  x1:=dx div 8;
  y1:=dy div 8;
  x2:=dx mod 8;
  y2:=dy mod 8;
  for i:=0 to scrx div 8 do
    for j:=0 to scry div 8 do
     if land[j+y1]^[i+x1].land<>0 then
       rectangle(i*8+1-x2,j*8+1-y2,i*8+6-x2,j*8+6-y2,getcolor(land[j+y1]^[i+x1].land));
end;
procedure tmap.deletepat;
var i:longint;
begin
  for i:=1 to 255 do
   if patname^[i]<>'' then
    begin
      p[pat[i]].done;
      pat[i]:=0;
      patname^[i]:='';
    end;
end;
procedure tmap.reloadpat;
var i:longint;
begin
  for i:=1 to 255 do
   if patname^[i]<>'' then
    begin
      pat[i]:=loadbmp(patname^[i]);
    end;
end;
function tmap.addpat;
var i:longint;
begin
  for i:=1 to 255 do
   if patname^[i]=s then begin addpat:=i; exit;end;
  for i:=1 to 255 do
   if patname^[i]='' then
   begin
     patname^[i]:=s;
     pat[i]:=loadbmp(patname^[i]);
     addpat:=i;
     exit;
   end;
end;
procedure tmap.create;
var i:longint;
begin
  name:=aname;
  x:=ax; y:=ay;
  dx:=adx; dy:=ady;
  getmem(patname,256*9);
  fillchar(patname^,256*9,0);
  fillchar(pat,sizeof(pat),0);
  for i:=0 to y-1 do
  begin
    getmem(land[i],x*2);
    fillchar(land[i]^,x*2,0);
  end;
end;
procedure tmap.new;
var i:longint;
begin
  system.new(m); fillchar32(m^,0,sizeof(m^),0);        for i:=0 to maxmon do m^[i].new;
  system.new(item);fillchar32(item^,0,sizeof(item^),0);for i:=0 to maxitem do item^[i].new;
  system.new(f);  fillchar32(f^,0,sizeof(f^),0);       for i:=0 to maxf do f^[i].new;
  system.new(pix);  fillchar32(pix^,0,sizeof(pix^),0); for i:=0 to maxpix do pix^[i].new;
  system.new(pul);  fillchar32(pul^,0,sizeof(pul^),0);       for i:=0 to maxpul do pul^[i].new;
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
procedure tbmp.put(tx,ty:longint); {error}
var i:longint;
begin
  if x=0 then exit;
  dec(tx,dx); dec(ty,dy);
{  for i:=0 to y-1 do move32(n^,x*i,scr^,(i+ty)*320+tx,x); ?}
  for i:=0 to y-1 do
   if (i+ty<200)and(i+ty>=0) then
     move(n^[x*i],scr^[(i+ty)*320+tx],x);
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
procedure tbmp.putabs(tx,ty:longint);
var
  i,j:integer;
  c:byte;
begin
  if x=0 then exit;
  for i:=0 to y-1 do
   for j:=0 to x-1 do
   begin
     c:=n^[x*i+j];
     if c<>0 then putpixel(j+tx,i+ty,c);
   end;
end;
procedure tbmp.done;
begin
  if x=0 then exit;
  if n<>nil then freemem(n,x*y); n:=nil; x:=0; y:=0; dx:=0; dy:=0; name:='';
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
procedure tmap.move;
var i:longint;
begin
  if not editor then
  begin
    for i:=0 to maxitem do if item^[i].enable then item^[i].move;
    for i:=0 to maxmon do if m^[i].enable then m^[i].move;
    for i:=0 to maxf do if f^[i].enable then f^[i].move;
    for i:=0 to maxpix do if pix^[i].enable then pix^[i].move;
    for i:=0 to maxpul do if pul^[i].enable then pul^[i].move;
  end
  else
  begin
    if (mo(0,0,0,scry))and(dx>0) then dec(dx);
    if (my=0)and(dy>0) then dec(dy);
    if (mo(319,0,319,scry))and(dx div 8+40<x) then inc(dx);
    if (my=199)and(dy div 8+21<y) then inc(dy);
  end;
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
{  if (hod mod 10=0)and(hod>100)then getfps;}
  if (hod>5)then getfps;
  if hod=1000 then begin getfps; clear;end;
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
procedure loadwalls;
var dat:text;
  k,i:longint;
begin
  assign(dat,'wall.dat');
  reset(dat);
  readln(dat,k);
  if debug and(k>50) then k:=50;
  getmem(allwall,(k+1)*9);
  for i:=1 to k do readln(dat,allwall^[i]);
  close(dat);
end;
(******************************** PROGRAM ***********************************)
var
  i:longint;
  adelay,mfps:longint;
begin
{  debug:=true;}
{  editor:=true;}
  sfps:=true;
  monster[1].x:=1;
  monster[1].y:=1;
  w.load(wadfile);
  loadwalls;
  map.new;
{  map.create(defx,defy,0,0,defname); }map.g:=0.05;
  map.load('temp');
  init320x200; loadfont('8x8.fnt'); clear; mfps:=30;
  loadpal('playpal');
{  w.findfirst('playa'); w.findstr:='*';}
  cur:=loadbmp('cursor');
  ed.land.curname:=allwall^[1];
  ed.land.mask:=1;
  ed.what:=face;
{  for i:=1 to 10000 do
    map.land[random(100)]^[random(100)].vis:=random(50)+1;}
{  map.save;}
  endgame:=false;
  time.clear;
  repeat
    map.initpix(230,30,random*5-2.5,random*5-2.5,time.hod div 4,200);
    time.move;
    mx:=mouse.x;
    my:=mouse.y;
    push:=mouse.push;
    push2:=mouse.push2;
    if keypressed then
    case readkey of
      #27: endgame:=true;
    end;
{    p.done;    p.load('puh8.bmp');}
    map.move;
    if editor then ed.move;
    clear;
    map.draw;
    if editor then ed.draw;
    print(290,190,white,st0(round(time.fps),3));
    print(200,190,white,st0(round(speed*100),4));
    if editor then p[cur].putblack(mx,my);
    screen;
    if time.fps<>0 then speed:=mfps/time.fps;
    if (not editor)and sfps then
    begin
      adelay:=round(adelay+(time.fps-mfps)*1000);
      if adelay<0 then adelay:=0;
      for i:=0 to adelay do;
    end;
  until endgame;
  savepal('doom.pal');
  closegraph;
  map.done;
  writeln;
  writeln('The ',game,' <-> ',version,' [',data,']');
  writeln('Copyright ',company);
  writeln('PRG: ',autor);
  writeln(comment);
end.