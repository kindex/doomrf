{$A+,B+,D+,E-,F-,G+,I+,L+,N+,O-,P-,Q-,R-,S-,T-,V+,X+,Y+ Filan}
{ $A+,B+,D+,E-,F+,G+,I+,L+,N+,O+,P+,Q+,R+,S+,T+,V+,X+,Y+ Debug}
{$M $fff0,0,655360}
program RF; {First verion: 27.2.2001}
uses crt,mycrt,api,mouse,wads,F32MA,dos,graphics,grafx;
{$ifndef dpmi} Real mode not supported {$endif}
const
  res:integer=0;
  accel:integer=-1;
  ppm=14; {pixel per meter (from plays.bmp)}
  ms=ppm/30; { meter/sec}
  ms2=ms/30; { meter/sec2}
  wadfile='513.wad';
  game='Doom RF';
  version='0.1.9';
  data='6.4.2001';
  company='IVA vision <-=[■]=->';
  autor='Andrey Ivanov [kIndeX Navigator]';
  levels='Pavel Burakov [ICE] & kindeX';
  comment='Beta 2 *** Freeware **** Special for PROGMEISTARS !';
  playdefitem=1;
  oxysec=10;
  play1=7;
  play2=1;
  bombfire=4;
  maxlose=11;
  maxwin=5;
  maxstart=7;
  maxpmaxx=300;
  maxpmaxy=300;
  cwall = 1 shl 0;
  cstand= 1 shl 1;
  cwater= 1 shl 2;
  clava = 1 shl 3;
  maxmon=96;
  maxitem=128;
  maxf=32;
  maxpix=1500;
  maxpul=512;
  maxexpl=32;
  maxmontip=32;
  maxweapon=32;
  maxbomb=16;
  maxbul=16;
  maxit=64;
  maxfname=16;
  scry:integer=19*8;
  scrx:integer=260;
  maxt=320 div 8;
  maxedmenu=10;
  maxmust=64;
  defx=200; defy=200; defname='map01';
  maxmonframe=10;
  maxkey=6;
  scroolspeed=2;
  truptime=30;
  reswaptime=60;
  monswaptime=30;
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
  'Скрытые'
  );
type
  real=single;
  tcapt=array[1..4]of char;
  tcolor=record
    m,r:byte;
    del:real;
  end;
  tkeys=array[1..maxkey]of boolean;
const
  origlev:tcapt='FLEV';
  blood:tcolor=(m:180; r:12; del: 6{3.5});
  water:tcolor=(m:200; r:8; del:2.5);
  {esc Left Right Fire Jump}
  ckey:array[1..2,1..maxkey]of byte=(
  (1,$4b,$4d,$1d,57,28),
  (1,30,32,15,17,16));
{ 1-Exit
  2runleft
  3-runright
  4-atack
  5-Jump
  6-NextWeapon }
type
   tdest=(left,right);
   tnpat=0..maxpat;
   tmaxmontip=0..maxmontip;
   tmaxweapon=0..maxweapon;
   tmaxbomb=0..maxbomb;
   tmaxbul=0..maxbul;
   tmaxit=0..maxit;
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
      procedure easymove;
      procedure gettime;
      procedure getfps;
   end;
  larray=array[0..$fffa]of byte;
  tmapelement=record
    land,vis:byte;
  end;
  tmapar=array[0..maxpmaxx]of tmapelement;
  tland=array[0..maxpmaxy]of ^tmapar;
  tobj=object
    enable,standing,first:boolean;
    lx,ly,mx,my,startx,starty:integer; {map}
    x,y,dx,dy:real;
    constructor new;
    procedure init(ax,ay,adx,ady:real; af:boolean);
    function getstand:boolean; virtual;
    function getsx:integer; virtual;
    function getsy:integer; virtual;
    function getftr:real; virtual;
    function getupr:real; virtual;
    procedure move;   virtual;
    procedure draw(ax,ay:integer);
    procedure done;   virtual;
    function inwall:boolean; virtual;
  end;
  tpix=object(tobj)
    color:byte;
    life:longint;
    procedure init(ax,ay,adx,ady:real; ac:longint; al:real);
    procedure move; virtual;
    procedure draw(ax,ay:integer);
  end;
  tstate=(stand,run,fire,die,crash,hack,hei);
  tmon=object(tobj)
     life,ai,know,see: boolean;
     target: record x,y:integer end;
     who: 0..maxmon;
     dest:tdest;
     tip: tmaxmontip;
     health,armor,fired:real;
     delay,statedel,vis,savedel:longint;
     state,curstate:tstate;
     weap: tmaxweapon;
     w:set of tmaxweapon;
     bul:array[tmaxbul]of integer;
     procedure init(ax,ay,adx,ady:real; at:tmaxmontip; ad:tdest; aw:longint; aai:boolean; af:boolean);
     function takeweap(n:tmaxweapon):boolean;
     function takebul(n:tmaxbul; m:integer):boolean;
     function takeitem(n:integer):boolean;
     function takearmor(n:real):boolean;
     function takehealth(n:real):boolean;
     function takemegahealth(n:real):boolean;
     procedure atack;
     function getsx:integer; virtual;
     function getsy:integer; virtual;
     function getftr:real; virtual;
     function getupr:real; virtual;
     procedure takenext;
     procedure draw(ax,ay:integer);
     procedure runleft;
     procedure runright;
     procedure jump;
     procedure move; virtual;
     procedure checkstep;
     procedure damage(ax,ay:integer; hit,bomb,oxy:real);
     procedure setstate(as:tstate; ad: real);
     procedure setcurstate(as:tstate; ad: real);
     procedure kill;
     procedure explode;
     procedure giveweapon;
     procedure moveai;
     procedure done; virtual;
  end;
  tbul=object(tobj)
     who,tip: integer;
     procedure init(ax,ay, adx,ady:real; at,aw:integer);
     procedure draw(ax,ay:integer);
     procedure move; virtual;
     procedure detonate;
  end;
  titem=object(tobj)
    tip: tmaxit;
    procedure init(ax,ay:real; at:integer; af:boolean);
    procedure draw(ax,ay:integer);
    procedure done; virtual;
  end;
  tF=object(tobj)
    tip,sx,sy: integer;
    dest: tdest;
    procedure init(ax,ay,asx,asy,at:integer);
    procedure move; virtual;
    procedure draw(ax,ay:integer);
    function getsx:integer; virtual;
    function getsy:integer; virtual;
  end;
  tbomb=object
     enable: boolean;
     who: integer;
     tip: tmaxbomb;
     x,y,life,maxlife: integer;
     vis: byte;
     procedure init(ax,ay,at,aw:longint);
     procedure draw(ax,ay:integer);
     procedure move;
     procedure kill;
  end;
  arrayofstring8=array[0..7000]of string[8];
  arrayofmon =array[0..maxmon ]of tmon;
  arrayofitem=array[0..maxitem]of titem;
  arrayoff   =array[0..maxf   ]of tf;
  arrayofpix =array[0..maxpix ]of tpix;
  arrayofpul =array[0..maxpul ]of tbul;
  arrayofbomb=array[0..maxexpl]of tbomb;
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
    b:^arrayofpul;
    e:^arrayofbomb;
    procedure new;
    procedure create(ax,ay,adx,ady:longint; aname:string);
    procedure reloadpat;
    procedure deletepat;
    procedure setdelta(ax,ay,ax1,ay1:integer);
    function addpat(s:string):longint;
    procedure putpat(ax,ay,a,ab:longint);
    procedure putwall(ax,ay,ab:longint);
    procedure deputpat(ax,ay:longint);
    procedure pset(ax,ay,a,ab:longint);
    procedure load(s:string);
    procedure save;
    procedure done;
    procedure draw;
    procedure drawhidden;
    procedure move;
    procedure clear;
    function initmon(ax,ay:real; at:longint; ad:tdest; ai,af:boolean):integer;
    function initbomb(ax,ay:integer; at:longint; who:integer):integer;
    function initbul(ax,ay,adx,ady:real; at,who:integer):integer;
    function initpix(ax,ay,adx,ady:real; ac:longint; al:real):integer;
    function initf(ax,ay,asx,asy,atip:integer):integer;
    function inititem(ax,ay:real; at:integer; af:boolean):integer;
    procedure randompix(ax,ay,adx,ady,rdx,rdy:real; ac:tcolor);
  end;
  ted=object
    what: (face,wall,mons,items,func);
    cured:longint;
    mon,itm:record
      cur,shift:integer;
    end;
    cool:boolean;
    fun:record
      cur,shift:longint;
      editing:boolean;
      f: integer;
    end;
    land:record
      curname:string[8];
      cur,ch:longint;
      mask:byte;
      maxtt:longint;
      t:array[1..maxt]of
      record
        x,y:integer;
        b:tspr;
       end;
    end;
    procedure draw;
    procedure move;
  end;
  tplayer=object
    enable,win,lose:boolean;
    name:string[40];
    startx,starty,deftip,n:integer;
    startdest:tdest;
    health,maxhealth,armor:real;
    weap: tmaxweapon;
    tip,ammo:integer;
    x1,y1,x2,y2:integer;
    hero: integer;
    key:tkeys;
    procedure init(ax1,ay1,ax2,ay2,ax,ay,at:integer;ad:tdest; aname:string; an:integer);
    procedure reinit(ax,ay,atip:integer;adest:tdest);
    procedure settip(at:integer);
    procedure initmulti;
    procedure draw;
    procedure move;
    function getherotip:integer;
    procedure done;
  end;
  tfont=object
     vis: string[8];
     c:array[#0..#255]of tnpat;
     d:integer;
     procedure load(av:string; ad,method:integer);
     procedure print(ax,ay:integer; s:string);
  end;
  tlevel=object
    max,cur:integer;
    name:array[0..30]of string[8];
    procedure loadini;
    procedure load;
    procedure loadfirst;
    procedure next;
  end;
(******************************** Variables *********************************)
var
  must:array[0..maxmust]of
  record
    tip: integer;
    x,y,curtip: integer;
    dest: tdest;
    delay: longint;
  end;
  it:array[tmaxit]of
  record
    name:string[40];
    vis:string[8];
    skin:array[0..maxmonframe]of tnpat;
    weapon,ammo,count,max:longint;
    health,armor,megahealth:real;
    speed:real;
    cant:boolean;
  end;
  bul:array[tmaxbul]of
  record
    name:string[40];
    vis:string[8];
    maxfly,delfly,shot:byte;
    fly:array[0..maxmonframe]of tnpat;
    hit,fire,mg,prise,rotate,g,per: real;
    bomb: tmaxbomb;
  end;
  bomb:array[tmaxbomb]of
  record
    name:string[40];
    vis:string[8];
    rad,maxfire: longint;
    time,hit,fired: real;
    fire:array[0..maxmonframe]of tnpat;
  end;
  weapon:array[tmaxweapon]of
  record
    name:string[40];
    vis:string[8];
    skin: tnpat;
    bul: tmaxbul;
    mg,prise:real;
    shot,hit,reload,speed,per:real; {shot time}
    slot,reloadslot,cool:longint;
    sniper:boolean;
  end;
  monster:array[tmaxmontip]of
  record
    name:string[40];
    x,y:integer;
    dest:tdest;
    health,armor,h:longint;
    defitem: tmaxweapon; {?}
    stay:boolean;
    speed,jumpx,jumpy,acsel,brakes:real;
    vis:string[8];
    stand,damage,fire:array[tdest]of tnpat;
    run,die,bomb:array[0..maxmonframe-1,tdest]of tnpat;
    runi,damagei,diei,bombi:record
       max:longint; delay:real;
    end;
  end;
  fname:array[0..maxfname]of record
    name:string[16];
    vis:string[8];
    skin: tnpat;
    n: integer;
  end;
  en:array[1..6]of tnpat;
  time,rtimer:ttimer;
  map:tmap;
  speed:real;
  ed:ted;
  d:array[0..9]of tnpat;
  dminus,dpercent:tnpat;
{  p:array[0..maxpat]of tbmp;}
  names:array[byte]of string[8];
  allwall:^arrayofstring8;
  mx,my:longint;push,push2:boolean;
  mfps:longint;
  debug,editor,endgame,sfps,multi,death,winall:boolean;
  cur,skull1,skull2,intro:tnpat;
  vec:procedure;
  maxpl:integer;
  player:array[1..4]of tplayer;
  level:tlevel;
  wb,rb:tfont;
  heiskin: array[tdest]of tnpat;
(******************************** IMPLEMENTATION ****************************)
function putbmpall(s:string):boolean;
var
  f:file;
  b:array[0..1600]of byte;
  x,y,dx,dy,c,i,j,x1,y1:integer;
  k,kx,ky:real;
  ost,o:longint;
begin
  putbmpall:=false;
  if w.exist(getfilename(s)) then
  begin
    putbmpall:=true;
    w.assign(getfilename(s));
    w.read(x,2); w.read(y,2);
    w.read(dx,2); w.read(dy,2);
    kx:=maxx/x;
    ky:=maxy/y;
    x1:=0; y1:=0;
    if kx<ky then begin k:=kx; y1:=(maxy-round(y*k))div 2; end
    else begin k:=ky; x1:=(maxx-round(x*k))div 2; end;
    for c:=0 to y-1 do
    begin
      w.read(b,x);
      for i:=round(k*c) to round(k*(c+1)) do
       for j:=0 to round((x-1)*k) do
         putpixel(x1+j,y1+i,b[round(j/k)]);
    end;
  end
  else
  begin
    putbmpall:=true;
    assign(f,dbmp+s+'.bmp');
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
  end;
  screen;
end;
procedure drawintro;
var t:tnpat;
begin
  clear;
  box(0,0,getmaxx,getmaxy);
  if putbmpall('start'+st(random(maxstart)+1)) then
  begin
    rb.print(getmaxx div 2-40,getmaxy-10,'В это время...');
    screen;
{  delay(1000); error}
    while keypressed do readkey;
    readkey;
  end;
end;
procedure tlevel.loadfirst;
var i:longint;
begin
  case multi of
  false:
  begin
    maxpl:=1;
    player[1].init(0,0,getmaxx,getmaxy,60,270,play1,right,'Player',1);
  end;
  true:
  begin
    maxpl:=2;
    player[1].init(0,0,getmaxx,getmaxy div 2,60,270,play1,right,'Player',1);
    player[2].init(0,getmaxy div 2+1,getmaxx,getmaxy,10,270,play2,right,'Player2',2)
  end;
  end;
  player[1].settip(play1);
  player[2].settip(play2);
  for i:=1 to maxpl do fillchar(player[i].key,sizeof(player[i].key),0);
  cur:=1; load;
end;
procedure tlevel.load;
begin
  map.done;
  map.load(name[cur]);
end;
procedure winallgame;
begin
  clear;
  putbmpall('intro');
  rb.print(50,70,'You are winner !');
  rb.print(70,90,'Ты прошел все комнаты !');
  screen;
  delay(1000);
  readkey;
  winall:=true;
end;
procedure tlevel.next;
var i:longint;
begin
  for i:=0 to maxmust do must[i].tip:=0;
  inc(cur);
  if cur=1 then loadfirst
  else
  begin
    if cur>max then begin endgame:=true; winallgame end else
    load;
  end;
end;
procedure tlevel.loadini;
var f:text;
begin
  cur:=0; max:=0;
  assign(f,'level.ini');
  reset(f);
  repeat
    inc(max);
    readln(f,name[max]);
  until eof(f) or (downcase(name[max])='end');
  close(f);
  dec(max);
end;
{function loadbmp(s:string):tnpat;
var i:longint;
begin
  s:=upcase(s);
  for i:=1 to maxpat do if p[i].name=s then begin loadbmp:=i; exit; end;
  for i:=1 to maxpat do
    if p[i].x=0 then
    begin
     p[i].load(s);
     if i mod 5=0 then write('.');
     loadbmp:=i;
     exit;
    end;
  loadbmp:=0;
end;}
procedure tfont.load;
var i:char;
begin
  vis:=av;
  d:=ad;
  case method of
  1: for i:=#0 to #255 do
         c[i]:=loadbmp(upcase(vis+i));
  2: for i:=#0 to #255 do
         c[i]:=loadbmp(upcase(vis+st0(byte(i),3)));
  end;
end;
procedure tfont.print;
var i,mx:integer;
begin
  s:=upcase(s); mx:=0;
  for i:=1 to length(s) do
  if s[i]=' ' then inc(mx,d) else
  begin
    p^[c[s[i]]].sprite(ax+mx,ay);
    inc(mx,p^[c[s[i]]].x);
  end;
end;
procedure initmust(atip,ax,ay,actip:integer; ad:tdest; del:real);
var i:integer;
begin
  for i:=0 to maxmust do
   if must[i].tip=0 then
   begin
     must[i].tip:=atip;
     must[i].x:=ax;
     must[i].y:=ay;
     must[i].curtip:=actip;
     must[i].dest:=ad;
     must[i].delay:=round(del*mfps/speed);
     exit;
   end;
end;
procedure tmon.done;
begin
  if death and ai and first then
    initmust(1,startx,starty,tip,dest,monswaptime);
  tobj.done;
end;
procedure titem.done;
begin
 if death and first then
   initmust(2,startx,starty,tip,right,reswaptime);
 tobj.done;
end;
procedure tplayer.initmulti;
var i,max,cur,w:integer;
begin
  case death of
   true:
   begin
     max:=0;
     for i:=0 to maxf do if map.f^[i].enable then if map.f^[i].tip=5{Deathmatch} then inc(max);
     w:=random(max);
     cur:=0;
     for i:=0 to maxf do if map.f^[i].enable then
      if map.f^[i].tip=5{Deathmatch} then
      begin
        if cur=w then
        begin
          reinit(round(map.f^[i].x),round(map.f^[i].y),deftip,map.f^[i].dest);
          break;
        end;
        inc(cur);
      end;
   end;
   false:
   begin
     for i:=0 to maxf do if map.f^[i].enable then
      if map.f^[i].tip=n{Coop} then
        begin
          reinit(round(map.f^[i].x),round(map.f^[i].y),deftip,map.f^[i].dest);
          break;
        end;

   end;
  end;
end;
procedure tplayer.done;
begin
  enable:=false;
end;
procedure tplayer.reinit;
begin
  init(x1,y1,x2,y2,ax,ay,atip,adest,name,n);
  hero:=map.initmon(ax,ay,deftip,adest,false{ai},false{first});
{  map.m^[hero].takeitem(monster[tip].defitem);}
  win:=false;
  lose:=false;
end;
function tplayer.getherotip:integer;
begin
  if deftip=0 then getherotip:=1 else getherotip:=deftip;
end;
procedure tf.move;
begin
 {error nothing?}
end;
function tf.getsx:integer;
begin getsx:=sx; end;
function tf.getsy:integer;
begin getsy:=sy; end;
procedure tf.init(ax,ay,asx,asy,at:integer);
begin
  tobj.init(ax,ay,0,0,false);
  sx:=asx;
  sy:=asy;
  if sx<0 then begin x:=x+sx; sx:=-sx; end;
  if sy<0 then begin y:=y+sy; sy:=-sy; end;
  tip:=at;
  mx:=round(x);
  my:=round(y);
end;
function tmon.takearmor(n:real):boolean;
begin
  armor:=armor+n;
  takearmor:=true;
end;
function tmon.takehealth(n:real):boolean;
begin
  if health>=monster[tip].health then begin takehealth:=false; exit; end;
  health:=health+n;
  fired:=0;
  if health>monster[tip].health then health:=monster[tip].health;
  takehealth:=true;
end;
function tmon.takemegahealth(n:real):boolean;
begin
  if health>=monster[tip].health*2 then begin takemegahealth:=false; exit; end;
  health:=health+n;
  if health>monster[tip].health*2 then health:=monster[tip].health*2;
  takemegahealth:=true;
end;
function tmon.takeitem(n:integer):boolean;
var ok:boolean;
begin
  ok:=false;
  if it[n].weapon<>0 then ok:=ok or takeweap(it[n].weapon);
  if it[n].ammo<>0 then ok:=ok or takebul(it[n].ammo,it[n].count);
  if it[n].armor<>0 then ok:=ok or takearmor(it[n].armor);
  if it[n].health<>0 then ok:=ok or takehealth(it[n].health);
  if it[n].megahealth<>0 then ok:=ok or takemegahealth(it[n].megahealth);
  takeitem:=ok;
end;
procedure digit(x,y:integer; l:longint; ch:char);
const dsize=14;
var
  s:string;
  i:integer;
begin
  dec(x,dsize);
  s:=st(l)+ch;
  for i:=1 to length(s) do
  case s[i] of
   '-': p^[dminus].sprite(x+i*dsize,y);
   '%': p^[dpercent].sprite(x+i*dsize,y);
   '0'..'9': p^[d[vl(s[i])]].sprite(x+i*dsize,y);
  end;
end;
procedure tplayer.settip(at:integer);
begin
  deftip:=at;
end;
procedure tplayer.init(ax1,ay1,ax2,ay2,ax,ay,at:integer; ad:tdest; aname:string; an:integer);
begin
  enable:=true;
  n:=an;
  x1:=ax1;
  x2:=ax2;
  y1:=ay1;
  y2:=ay2;
  name:=aname;
  startx:=ax;
  starty:=ay;
  startdest:=ad;
end;
procedure tplayer.draw;
begin
  if not editor then
  begin
    box(x1,y1,x2,y2);
    weap:=map.m^[hero].weap;
    health:=map.m^[hero].health;
    armor:=map.m^[hero].armor;
    tip:=map.m^[hero].tip;
    maxhealth:=monster[tip].health;
    ammo:=map.m^[hero].bul[weapon[weap].bul];
    map.setdelta(round(map.m^[hero].x),round(map.m^[hero].y-14),(x2-x1) div 2,(y2-y1) div 2);
  end;
  map.draw;
  if not editor then
  case multi of
  false:
  begin
    p^[en[norm(1,6,round(7-6*health/maxhealth))]].put(minx,maxy-40);
    digit(minx+30,maxy-35,round(health),'%');
    digit(minx+30,maxy-15,round(armor),' ');
    p^[weapon[weap].skin].sprite(minx+230,maxy-30);
    rb.print(minx+230,maxy-15,st(ammo));
  end;
  true:
  begin
{    p[en[norm(1,6,round(7-6*health/maxhealth))]].putblack(0,160);}
    digit(maxx-56,miny,round(health),'%');
    digit(maxx-56,miny+17,round(armor),' ');
    p^[weapon[weap].skin].sprite(maxx-40,miny+50);
    digit(maxx-56,miny+70,ammo,' ');
  end;
 end;
  box(0,0,getmaxx,getmaxy);
end;
procedure tmon.takenext;
begin
  if delay>0 then exit;
  repeat
    inc(weap);
  until (weap>maxweapon)or((bul[weapon[weap].bul]>0)and(weap in w));
  if weap>maxweapon then weap:=0;
  delay:=round(mfps/speed*0.25);
end;
procedure tplayer.move;
var i,mx,my:integer;
begin
  if (ammo=0)and(weapon[weap].hit=0) then map.m^[hero].takenext;
  mx:=round(map.m^[hero].x);
  my:=round(map.m^[hero].y);
  with map do
   if m^[hero].life then
   begin
    if (monster[m^[hero].tip].vis='fpuh')and(not m^[hero].ai)and(m^[hero].state=stand) then
     if random(100)=0 then m^[hero].setstate(hei,30);
    for i:=0 to maxitem do
     if item^[i].enable and not it[item^[i].tip].cant then
     if (abs(item^[i].x-mx)<8)and(abs(item^[i].y-my)<8)
      then
        if m^[hero].takeitem(item^[i].tip) then item^[i].done;

    for i:=0 to maxf do
     if f^[i].enable then
     if
     (mx>=f^[i].x)and
     (my>=f^[i].y)and
     (mx<=f^[i].x+f^[i].getsx)and
     (my<=f^[i].y+f^[i].getsy)
      then case f^[i].tip of
        10: win:=true;
        11: lose:=true;
        12: map.m^[hero].damage(round(map.m^[hero].x),round(map.m^[hero].y),0,33,0);
      end;

   end;
  if key[1] then endgame:=true;
  if key[2] then map.m^[hero].runleft;
  if key[3] then map.m^[hero].runright;
  if key[4] then map.m^[hero].atack;
  if key[5] then
  begin
    map.m^[hero].jump;
    if not map.m^[hero].life then lose:=true;
  end;
  if key[6] then map.m^[hero].takenext;
end;
procedure titem.init(ax,ay:real; at:integer; af:boolean);
begin
  tobj.init(ax,ay,0,0,af);
  tip:=at;
  mx:=round(x);
  my:=round(y);
end;
procedure titem.draw(ax,ay:integer);
begin
  if it[tip].max<=1 then
   p^[it[tip].skin[1]].spritesp(mx-ax,my-ay)
  else
   p^[it[tip].skin[norm(
   1,it[tip].max,
    round(it[tip].max*(rtimer.hod*speed*0.5)/mfps)mod it[tip].max+1
   )
   ]].spritesp(mx-ax,my-ay)
end;
{$f+}
procedure keyb; interrupt;
var i,j:integer;
begin
 for j:=1 to maxpl do
  for i:=1 to maxkey do
    if port[$60]=ckey[j,i] then player[j].key[i]:=true;

 for j:=1 to maxpl do
   for i:=1 to maxkey do
     if port[$60]=ckey[j,i]+$80 then player[j].key[i]:=false;
 inline ($60);
 vec;
end;
{$f-}
procedure tmon.atack;
var l:shortint;
  sp,per:real;
  i,s:longint;
begin
  if (delay>0)or not life then exit;
  if weapon[weap].hit>0 then
  begin
    s:=16;
  for i:=0 to maxmon do
   if (map.m^[i].enable)and(map.m^[i].life) then
    if who<>i then
    if
    (map.m^[i].x>(x-s))and
    (map.m^[i].y>(y-s))and
    (map.m^[i].x<(x+s))and
    (map.m^[i].y<(y+s))
    then
      map.m^[i].damage(round(map.m^[i].x),round(map.m^[i].y-map.m^[i].getsy*6),0,weapon[weap].hit,0);
  end;
  delay:=round(weapon[weap].shot*mfps/speed);
  if (not ai)and(bul[weapon[weap].bul]<=0) then exit;
  dec(bul[weapon[weap].bul]);
  {initbul();}
  case dest of
   left: l:=-1;
   right: l:=1;
  end;
  sp:=weapon[weap].speed*l;
  per:=(rf.bul[weapon[weap].bul].per+weapon[weap].per)/100;
 for i:=1 to rf.bul[weapon[weap].bul].shot do
  map.initbul(x,y-monster[tip].h,
  sp*(1+random*per-per/2)+dx,
  sp*(random*per-per/2){+dy}
  ,weapon[weap].bul,who);
  setstate(fire,0.1);
end;
function tmon.takeweap(n:tmaxweapon):boolean;
begin
  if not(n in w) then
    if (weapon[n].cool>=weapon[weap].cool) then weap:=n;
{  if weap=0 then weap:=n;}
  include(w,n);
  {error mg}
  takeweap:=true;
end;
function tmon.takebul(n:tmaxbul; m:integer):boolean;
begin
  {error mg}
  inc(bul[n],m);
  takebul:=true;
end;
function tobj.getftr:real;
begin
  getftr:=1;
end;
function tobj.getupr:real;
begin
  getupr:=0.2;
end;
function tmon.getftr:real;
begin
  if state in [run,hack,fire] then getftr:=1 else getftr:=0.3;
end;
function tmon.getupr:real;
begin
  getupr:=0.1;
end;
procedure tbul.init(ax,ay, adx,ady:real; at,aw:integer);
begin
  tip:=at;
  who:=aw;
  tobj.init(ax,ay,adx,ady,false);
end;
{errorprocedure tbmp.putrot(tx,ty:longint; adx,ady,akx,aky:extended);
var
  i,j,sx,sy,ii,jj,xx1,yy1,xx2,yy2:integer;
  c:byte;
  x2,y2:longint;
  co,si,s:extended;
  ico,isi:extended;
begin
  if x=0 then exit;
  s:=sqrt(sqr(adx)+sqr(ady));
  co:=adx/s;
  si:=ady/s;
  x2:=x div 2;
  y2:=y div 2;
  sx:=tx-x2;
  sy:=ty-y2;
  xx1:=-round(x2*akx); if xx1+tx<minx then xx1:=minx-tx; if xx1+tx>maxx then exit;
  xx2:=round(x2*akx);  if xx2+tx>maxx then xx2:=maxx-tx; if xx2+tx<minx then exit;
  yy1:=-round(y2*aky); if yy1+ty<miny then yy1:=miny-ty; if yy1+ty>maxy then exit;
  yy2:=round(y2*aky);  if yy2+ty>maxy then yy2:=maxy-ty; if yy2+ty<miny then exit;
  akx:=1/akx;
  aky:=1/aky;
  for i:=yy1 to yy2 do
  begin
    ico:=i*co*aky;
    isi:=i*si*aky;
    for j:=xx1 to xx2 do
    begin
      jj:=round(ico-j*si*akx)+x2;
      ii:=round(j*co*akx+isi)+y2;
      if (ii>=0)and(ii<y)and(jj>=0)and(jj<x) then
      begin
        c:=n^[jj+x*(ii)];
        if c<>0 then scr^[(ty+i)*320+(j+tx)]:=c;
     end(*  else  scr^[word((ty+i)*320+j+tx)]:=1;*)
    end;
  end;
end;}
procedure tbul.draw(ax,ay:integer);
begin
{  tobj.draw(ax,ay);}
  if bul[tip].rotate<>0 then
    p^[bul[tip].fly[1]].putrot(mx-ax,my-ay,cos(x/30),sin(x/30),0.75,0.75)
  else
   if bul[tip].maxfly=1 then
    p^[bul[tip].fly[1]].spritec(mx-ax,my-ay)
  else
    p^[bul[tip].fly[(mx div 32 mod bul[tip].maxfly)+1]].spritec(mx-ax,my-ay);
end;
procedure tbul.move;
var i,ax,ay,sx,sy:integer;
begin
  dy:=dy+bul[tip].g*speed;
  x:=x+dx*speed; mx:=round(x); lx:=mx div 8;
  y:=y+dy*speed; my:=round(y); ly:=my div 8;
  if inwall then detonate;

  for i:=0 to maxmon do
   if i<>who then
   if map.m^[i].enable then
   if not( (map.m^[i].ai)and(map.m^[who].ai)) then
   begin
     ax:=map.m^[i].mx;
     ay:=map.m^[i].my;
     sx:=map.m^[i].getsx*4;
     sy:=map.m^[i].getsy*8;
    if
    (mx>ax-sx)and
    (my<ay)and
    (mx<ax+sx)and
    (my>ay-sy)
    then
    begin
      map.m^[i].damage(mx,my,bul[tip].hit,0,bul[tip].fire/speed*mfps);
      detonate;
      exit;
    end;
  end;
end;
procedure tbul.detonate;
begin
  if bul[tip].bomb>0 then map.initbomb(mx,my,bul[tip].bomb,who);
  done;
end;
procedure tbomb.kill; begin enable:=false; end;
procedure tbomb.draw(ax,ay:integer);
begin
   if bomb[tip].fired=0 then p^[bomb[tip].fire[vis]].spritec(x-ax,y-ay)
   else p^[bomb[tip].fire[vis]].spritesp(x-ax,y-ay);
end;
procedure tbomb.move;
begin
  if life=0 then kill;
  dec(life);
  vis:=norm(1,bomb[tip].maxfire,bomb[tip].maxfire-round((life/maxlife*bomb[tip].maxfire)));
end;
procedure tbomb.init;
var
  i,s:integer;
begin
  enable:=true;
  x:=ax; y:=ay; tip:=at;
  vis:=1; who:=aw;
  life:=round(bomb[tip].time*mfps/speed);
  maxlife:=life;
  s:=bomb[tip].rad*2;
  for i:=0 to maxmon do
   if map.m^[i].enable then
    if
    (map.m^[i].x>(x-s))and
    (map.m^[i].y>(y-s))and
    (map.m^[i].x<(x+s))and
    (map.m^[i].y<(y+s))
    then
      map.m^[i].damage(round(map.m^[i].x),round(map.m^[i].y-map.m^[i].getsy*6),0,bomb[tip].hit,bomb[tip].fired);
end;
procedure tmon.setstate;
begin
  if not life then exit;
  state:=as;
  savedel:=round(ad*mfps/speed);
end;
procedure tmon.setcurstate(as:tstate; ad: real);
begin
  if not life then exit;
  curstate:=as;
  savedel:=round(ad*mfps/speed);
end;
procedure tmon.giveweapon;
var i:integer;
begin
  if ai then
  begin
    if monster[tip].stay then map.inititem(x,y,monster[tip].defitem,false)
  end
  else
  begin
    for i:=1 to maxit do
     if it[i].weapon=weap then
     begin
       map.inititem(x,y,i,false);
       break;
     end;
  end;
end;
procedure tmon.kill;
begin
  if not life then exit;
  setcurstate(die,monster[tip].diei.delay);
  giveweapon;
  life:=false;
end;
procedure tmon.explode;
begin
  if not life then exit;
  setcurstate(crash,monster[tip].bombi.delay);
  giveweapon;
  life:=false;
end;
procedure tmon.damage(ax,ay:integer; hit,bomb,oxy:real);
var
  i:integer;
begin
  know:=true;
{  if fired=0 then }
  fired:=fired+oxy;
  if armor=0 then
  health:=health-hit-bomb
  else
  begin
    health:=health-(hit+bomb)/5;
    armor:=armor-(hit+bomb)/3;
    if armor<0 then armor:=0;
  end;
  if health<0 then health:=0;
  setstate(hack,0.1);
  for i:=0 to min(256,round((hit+bomb)*15)) do
    map.randompix(ax,ay,dx,dy,5,5,blood);
  if health<=0 then
    if bomb>0 then explode
    else kill;
end;
procedure tmap.randompix;
begin
  initpix(ax,ay,
    random*rdx-rdx*0.5+adx,random*rdy-rdy*0.5+ady,
    ac.m+random(ac.r),ac.del);
end;
procedure tmon.moveai;
procedure movesee;
var tx,ty,l:integer;
begin
  case dest of
   left:  l:=-1;
   right: l:=1;
  end;
  tx:=lx;
  ty:=ly-2;
  if (ty>0)and(ty<map.y)then
  repeat
    tx:=tx+l;
    if (abs(target.x-tx*8)<32)and(abs(target.y-ty*8)<32)then begin see:=true; exit; end;
    if map.land[ty]^[tx].land>0 then begin see:=false; exit; end;
  until (tx<=0)or(tx>=map.x-1);
  see:=false;
end;
var i,tar,min,j,d:longint;
begin
  min:=(map.x+map.y)*8*10; tar:=0;
  with map do
  for i:=1 to maxpl do
  begin
    j:=player[i].hero;
    if not m^[j].life then continue;
    d:=round(abs(m^[j].x-mx)+abs(m^[j].y-my));
    if d<min then begin min:=d; tar:=j; end;
  end;
  if tar>0 then
  with map do
  begin
    target.x:=round(m^[tar].x);
    target.y:=round(m^[tar].y);
  end;
{  if rtimer.hod mod 10=0 then }movesee;
  if (know){and(tar>0)} then
  begin
    if not see then
     if abs(target.x-self.x)>10 then
     begin
      if target.x<self.x then runleft else runright
     end
     else
    if random(1000)=0 then jump;
    if weap=0 then if target.x<self.x then runleft else runright
  end;
  if see then begin atack; know:=true; end;
end;
procedure tmon.move;
begin
  if not life then begin inc(delay,2);
    if delay>truptime*mfps/speed then begin done; exit; end; end;
  if ai then moveai;
  tobj.move;
  if not life and (delay>100) then fired:=0;
 if speed>0 then
  if (fired>0)and(time.hod mod round(0.1*mfps/speed)=0) then
     map.initbomb(mx,my,bombfire,0);
  if fired>0 then damage(mx,my,0,oxysec*speed/mfps,0);
  fired:=fired-1;
  if fired<0 then fired:=0;
  if delay>0 then dec(delay);
  case curstate of
  run:begin
       state:=run;
       inc(statedel);
       vis:=round(statedel/(mfps*monster[tip].runi.delay))mod monster[tip].runi.max+1;
     end;
  crash:
  begin
     state:=crash;
     inc(statedel);
     vis:=min(round(statedel/(mfps*monster[tip].bombi.delay/speed/monster[tip].bombi.max))+1,monster[tip].bombi.max);
  end;
  die:
  begin
     state:=die;
     inc(statedel);
     vis:=min(round(statedel/(mfps*monster[tip].diei.delay/speed/monster[tip].diei.max))+1,monster[tip].diei.max);
  end;
  else if savedel>0 then begin dec(savedel); end;
  end;
  if savedel=0 then begin state:=stand; statedel:=0; vis:=1; end;
  if (state=stand)and(standing)then
  begin
    if abs(dx)<monster[tip].brakes*ms2 then dx:=0 else
    case dest of
      left: if dx<0 then dx:=dx+monster[tip].brakes*ms2 else dx:=0;
      right: if dx>0 then dx:=dx-monster[tip].brakes*ms2 else dx:=0;
    end;
  end;
  if (curstate<>crash)and(curstate<>die)then curstate:=stand;
end;
procedure tmon.runright;
begin
  if not life then exit;
{  if not standing then exit;error}
  if state<>run then setcurstate(run,0.05);
  if dest=left then dest:=right;
  if dx<0 then dx:=dx+monster[tip].brakes*ms2
  else
   dx:=dx+monster[tip].acsel*ms2;
  if dx>monster[tip].speed*ms then dx:=monster[tip].speed*ms;
  if savedel<=1 then setcurstate(run,0.05);
  checkstep
end;
procedure tmon.runleft;
begin
  if not life then exit;
{  if not standing then exit;error}
  if state<>run then setcurstate(run,0.05);
  if dest=right then dest:=left;
  if dx>0 then dx:=dx-monster[tip].brakes*ms2
  else
   dx:=dx-monster[tip].acsel*ms2;
  if dx<-monster[tip].speed*ms then dx:=-monster[tip].speed*ms;
  if savedel<=1 then setcurstate(run,0.05);
  checkstep
end;
procedure tmon.jump;
var l:shortint;
begin
  if not life then exit;
  if not standing then exit;
  case dest of
   left: l:=-1;
   right:l:=1;
  end;
  dx:=dx+l*monster[tip].jumpx;
  dy:=-monster[tip].jumpy;
  setstate(run,0.3);
end;
procedure tmon.checkstep;
var savex,savey:real;
begin
  savex:=x; savey:=y;
  x:=x+dx*speed;  mx:=round(x); lx:=mx div 8;
  if inwall then
  begin
    ly:=ly-1;
    if not inwall then begin savey:=y-8; end;
  end;
  x:=savex; mx:=round(x); lx:=mx div 8;
  y:=savey; my:=round(y); ly:=my div 8;
end;
procedure tmap.setdelta(ax,ay,ax1,ay1:integer);
begin
  dx:=ax-ax1;
  dy:=ay-ay1;
  if dx<0 then dx:=0;
  if dy<0 then dy:=0;
  if dx>x*8-(maxx-minx) then dx:=x*8-(maxx-minx);
  if dy>y*8-(maxy-miny) then dy:=y*8-(maxy-miny);
end;
function exist(s:string):boolean;
begin
  exist:=w.exist(s) or fexist(s+'.bmp')or fexist(dbmp+s+'.bmp');
end;
(*procedure tbmp.save;
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
end;*)
procedure ted.draw;
const ddd=60;
var i:longint;
begin
  map.draw;
  if cool then map.drawhidden;
  case what of
   func:
   with fun do
   begin
     for i:=0 to getmaxx div ddd-1 do
     begin
       if shift+i=cur then bar(i*ddd,scry+12,(i+1)*ddd-1,getmaxx,white);
       print(i*ddd,scry+2,not white,fname[shift+i].name);
       p^[fname[shift+i].skin].put(i*ddd,scry+12);
     end;
   end;
   mons:
   with mon do
   begin
     for i:=0 to getmaxx div ddd-1 do
     begin
       if shift+i=cur then bar(i*ddd,scry+12,(i+1)*ddd-1,getmaxx,white);
       print(i*ddd,scry+2,not white,monster[shift+i].name);
       p^[monster[shift+i].stand[right]].put(i*ddd,scry+12);
     end;
   end;
   items:
   with itm do
   begin
     for i:=0 to getmaxx div ddd-1 do
     begin
       if shift+i=cur then bar(i*ddd,scry+12,(i+1)*ddd-1,getmaxx,white);
       print(i*ddd,scry+2,not white,it[shift+i].name);
       p^[it[shift+i].skin[1]].put(i*ddd,scry+12);
     end;
   end;
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
        t[i].b.sprite(t[i].x,t[i].y);
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
  if mo(scrx,0,getmaxx,scry)then
  if push then
  begin
    cured:=my div 10+1;
    case cured of
   1:
   begin
{     s:='yes';
     readline(100,100,s,s,white,0);
     if downcase(s)='yes'then }endgame:=true;
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
    10: begin cool:=not cool; repeat until not mouse.push; end;
  end;
 end;
  if not push then
    if fun.editing then fun.editing:=false;

  if mo(0,scry,getmaxx,getmaxy)then
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
        if mx>=(getmaxx-4) then
        begin
          inc(ch);
          t[1].b.done;
          for j:=1 to maxt-1 do t[j].b:=t[j+1].b;
        end
        else
        if (mx<=4)and(ch>0) then
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
     func: with fun do
      begin
        if mx>=(getmaxx-4) then inc(shift)  else
        if (mx<=4)and(shift>0) then dec(shift)
        else  cur:=shift+mx div 60;
       repeat until not mouse.push;
      end;
     mons: with mon do
      begin
        if mx>=(getmaxx-4) then inc(shift)  else
        if (mx<=4)and(shift>0) then dec(shift)
        else  cur:=shift+mx div 60;
       repeat until not mouse.push;
      end;
     items: with itm do
      begin
        if mx>=(getmaxx-4) then inc(shift)  else
        if (mx<=4)and(shift>0) then dec(shift)
        else  cur:=shift+mx div 60;
       repeat until not mouse.push;
      end;
    end;
  end;
  if mo(0,0,scrx,scry)then
   begin
     if push then
     begin
       case what of
        mons: with mon do
        begin
          map.initmon((mx+map.dx),(my+map.dy),cur,tdest(random(2)),true,true);
          repeat until not mouse.push;
        end;
        items:with itm do
        begin
          map.inititem((mx+map.dx),(my+map.dy),cur,true);
          repeat until not mouse.push;
        end;
        func:
         with fun do
           if editing then
           begin
             map.f^[fun.f].sx:=round(mx+map.dx-map.f^[fun.f].x);
             map.f^[fun.f].sy:=round(my+map.dy-map.f^[fun.f].y);
            end
           else
           begin
             editing:=true;
             f:=map.initf((mx+map.dx),(my+map.dy),8,8,fname[cur].n);
           end;
       face:
         begin
           land.cur:=map.addpat(land.curname);
          for i:=0 to p^[map.pat[land.cur]].x div 8-1 do
           for j:=0 to p^[map.pat[land.cur]].y div 8-1 do
            map.deputpat((mx+map.dx)div 8+i,(my+map.dy)div 8+j);
           map.putpat((mx+map.dx)div 8,(my+map.dy)div 8,land.cur,land.mask);
         end;
       wall: map.putwall((mx+map.dx)div 8,(my+map.dy)div 8,land.mask);
       end;
     end;
     if push2 then
       case what of
         func: for i:=0 to maxf do
                if map.f^[i].enable then
                  begin
                     if
                     (map.f^[i].mx<=mx+map.dx+4)and
                     (map.f^[i].my<=my+map.dy+4)and
                     (map.f^[i].mx+map.f^[i].sx>=mx+map.dx-4)and
                     (map.f^[i].my+map.f^[i].sy>=my+map.dy-4)then
                         map.f^[i].done;
                  end;
         mons: for i:=0 to maxmon do
                if map.m^[i].enable then
                  begin
                     if
                     (map.m^[i].mx<=mx+map.dx+4)and
                     (map.m^[i].my-map.m^[i].getsy<=my+map.dy+4)and
                     (map.m^[i].mx+map.m^[i].getsx>=mx+map.dx-4)and
                     (map.m^[i].my>=my+map.dy-4)then
                         map.m^[i].done;
                  end;
         items: for i:=0 to maxitem do
                if map.item^[i].enable then
                  begin
                     if
                     (map.item^[i].mx<=mx+map.dx+4)and
                     (map.item^[i].my-map.item^[i].getsy<=my+map.dy+4)and
                     (map.item^[i].mx+map.item^[i].getsx>=mx+map.dx-4)and
                     (map.item^[i].my>=my+map.dy-4)then
                         map.item^[i].done;
                  end;
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
      if freex>=getmaxx then begin dec(maxtt); break; end;
   end;
end;
function loadbmpr(s:string):tnpat;
var i:longint;
begin
  s:=upcase(s);
  for i:=1 to maxpat do
    if p^[i].x=0 then
    begin
     if p^[i].loadr(dbmp+s+'.bmp') then
       loadbmpr:=i else loadbmpr:=0;
     exit;
    end;
  loadbmpr:=0;
end;
function tmap.initf(ax,ay,asx,asy,atip:integer):integer;
var i:longint;
begin
  for i:=0 to maxf do
    if not f^[i].enable then
    begin
      f^[i].init(ax,ay,asx,asy,atip);
      initf:=i;
      exit;
    end;
end;
function tmap.initbomb(ax,ay:integer; at:longint; who:integer):integer;
var i:longint;
begin
  for i:=0 to maxexpl do
    if not e^[i].enable then
    begin
      e^[i].init(ax,ay,at,who);
      initbomb:=i;
      exit;
    end;
end;
function tmap.initbul(ax,ay,adx,ady:real; at,who:integer):integer;
var i:longint;
begin
  for i:=0 to maxpul do
    if not b^[i].enable then
    begin
      b^[i].init(ax,ay,adx,ady,at,who);
      initbul:=i;
      exit;
    end;
end;
function tmap.initmon;
var i:longint;
begin
  for i:=0 to maxmon do
    if not m^[i].enable then
    begin
      m^[i].init(ax,ay,0,0,at,ad,i,ai,af);
      initmon:=i;
      exit;
    end;
end;
function tmap.initpix;
var i:longint;
begin
  for i:=0 to maxpix do
    if not pix^[i].enable then
    begin
      pix^[i].init(ax,ay,adx,ady,ac,al);
      initpix:=i;
      exit;
    end;
end;
function tmap.inititem;
var i:longint;
begin
  for i:=0 to maxitem do
    if not item^[i].enable then
    begin
      item^[i].init(ax,ay,at,af);
      inititem:=i;
      exit;
    end;
end;
procedure tpix.move;
begin
  dec(life);
  if (life=0)or((abs(dx)+abs(dy))<0.01*ms) then begin done; exit; end;
  tobj.move;
end;
procedure tobj.move;
var
  savex,savey:real;
  x1,y1,x2,y2,i,j:integer;
begin
  dy:=dy+map.g*speed;
  savex:=x;
  savey:=y;
  x:=x+dx*speed; mx:=round(x); lx:=mx div 8;
  if inwall then
  begin
    x:=savex;
    dx:=-dx*getupr;
    dy:=dy*getftr;
    mx:=round(x); lx:=mx div 8;
  end;
  y:=y+dy*speed; my:=round(y); ly:=my div 8;
  if inwall then
  begin
    y:=savey;
    dy:=-dy*getupr;
    dx:=dx*getftr;
    my:=round(y); ly:=my div 8;
  end;
  standing:=getstand;

  x1:=lx-getsx div 2; x2:=x1+getsx-1;
  y2:=norm(0,map.y,ly);
  for i:=max(0,x1) to min(map.x,x2) do
   if map.land[y2]^[i].land and cstand>0 then
   begin
     dy:=-dy*getupr;
{     if dy>0 then dy:=-dy*getupr;{ else dy:=dy-map.g*5;}
     y:=y-1;
     break;
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
procedure tmon.draw;
begin
  inc(my);
  case state of
   stand:  p^[monster[tip].stand[dest]].spritesp(mx-ax,my-ay);
   run:  p^[monster[tip].run[vis,dest]].spritesp(mx-ax,my-ay);
   fire:  p^[monster[tip].fire[dest]].spritesp(mx-ax,my-ay);
   hack:  p^[monster[tip].damage[dest]].spritesp(mx-ax,my-ay);
   die:  p^[monster[tip].die[vis,dest]].spritesp(mx-ax,my-ay);
   crash:  p^[monster[tip].bomb[vis,dest]].spritesp(mx-ax,my-ay);
   hei:  p^[heiskin[dest]].spritesp(mx-ax,my-ay);
  end;
  dec(my);
{  putpixel(mx-ax,my-ay,white);}
end;
procedure tf.draw;
var
  i,cur:integer;
begin
  rectangle(mx-ax,my-ay,mx-ax+sx,my-ay+sy,white);
  for i:=0 to maxfname do
   if fname[i].n=tip then begin cur:=i; break; end;
  p^[fname[cur].skin].spritesp(mx-ax,my-ay);
  print(mx-ax,my-ay,white,fname[cur].name);
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
  case state of
   run,stand,fire,hack: getsy:=monster[tip].y;
   die,crash: getsy:=1;
  end;
end;
procedure tmon.init;
begin
  fillchar(bul,sizeof(bul),0);
  fillchar(w,sizeof(w),0);
  tobj.init(ax,ay,adx,ady,af);
  weap:=0;
  delay:=0;
  ai:=aai;
  who:=aw;
  life:=true;
  dest:=ad;
  tip:=at;
  state:=stand;
  curstate:=stand;
  statedel:=0;
  vis:=1;
  health:=monster[tip].health;
  armor:=monster[tip].armor;
  fired:=0;
  w:=[0];
  if ai then takeitem(monster[tip].defitem)
        else takeitem(playdefitem);
  mx:=round(x); my:=round(y);
  dx:=0; dy:=0;
  know:=false; see:=false;
end;
procedure tobj.init(ax,ay,adx,ady:real; af:boolean);
begin
  enable:=true;
  x:=ax; y:=ay;
  mx:=round(x); my:=round(y);
  dx:=adx; dy:=ady;
  startx:=mx;
  starty:=my;
  first:=af;
end;
procedure tpix.init;
begin
  tobj.init(ax,ay,adx,ady,false);
  color:=ac;
  life:=round(al/speed*mfps);
end;
procedure tobj.done;
begin
  enable:=false;
end;
function tobj.getstand;
var
  i,j,sx,sy,x1,y1,x2,y2:integer;
  ok:boolean;
begin
  sx:=getsx;
  sy:=getsy;
  x1:=lx-sx div 2; x2:=x1+sx-1;
  y2:=ly+1; y1:=y2-sy-1;
  if (x1<0)or(y1<0)or(x2>=map.x)or(y2>=map.y) then begin getstand:=true; exit; end;
  for i:=x1 to x2 do
    for j:=y2 to y2 do
    if (map.land[j]^[i].land and cwall>0)
    or(map.land[j]^[i].land and cstand>0) then begin getstand:=true; exit; end;
  getstand:=false;
end;
function tobj.inwall:boolean;
var
  i,j,sx,sy,x1,y1,x2,y2:integer;
  ok:boolean;
begin
  sx:=getsx;
  sy:=getsy;
  x1:=lx-sx div 2; x2:=x1+sx-1;
  y2:=ly; y1:=y2-sy+1;
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
    land[ay]^[ax].land:=ab;
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
       if (p^[pat[w]].x div 8+i>ax)and(p^[pat[w]].y div 8+j>ay) then
        begin
          for i2:=i to i+p^[pat[w]].x div 8-1 do
            for j2:=j to j+p^[pat[w]].y div 8-1 do
               pset(i2,j2,0,0);
          break;
        end;
    end;
  pset(ax,ay,0,0);
end;
procedure tmap.putpat;
var i,j:longint;
begin
  for i:=ax to ax+p^[pat[a]].x div 8-1 do
    for j:=ay to ay+p^[pat[a]].y div 8-1 do
      pset(i,j,0,ab);
  pset(ax,ay,a,ab);
end;
procedure tmap.putwall;
var i,j:longint;
begin
  if (ax>=0)and(ay>=0)and(ax<x)and(ay<y) then
    land[ay]^[ax].land:=ab;
end;
procedure tmap.load(s:string);
var
  ff:file;
  capt:tcapt;
  mpat,mmon,mitem,mf,i:longint;
  pats:string[8];
  mon:record
    x,y,tip:integer;
    dest:tdest;
  end;
  itm:record
    x,y,tip:integer;
  end;
  func:record
    x,y,sx,sy,tip:integer;
  end;
begin
  done;
  name:=s;
  assign(ff,name+'.lev');
  reset(ff,1);
  blockread(ff,capt,sizeof(capt));
  if capt=origlev then
  begin
    done;
    for i:=1 to 4 do player[i].done;
    blockread(ff,x,4);
    blockread(ff,y,4);
    blockread(ff,dx,4);
    blockread(ff,dy,4);
    blockread(ff,mpat,4);
    blockread(ff,mmon,4);
    blockread(ff,mitem,4);
    blockread(ff,mf,4);
{    blockread(ff,maxpl,4);}
    map.clear; {delete all records}
    create(x,y,dx,dy,name);
    for i:=0 to y-1 do
      blockread(ff,land[i]^,x*2);
    deletepat;
    blockread(ff,patname^,mpat*9+9);
    for i:=0 to mmon-1 do
    begin
      blockread(ff,mon,sizeof(mon));
      initmon(mon.x,mon.y,mon.tip,mon.dest,true,true);
    end;
    for i:=0 to mitem-1 do
    begin
      blockread(ff,itm,sizeof(itm));
      inititem(itm.x,itm.y,itm.tip,true);
    end;
    for i:=0 to mf-1 do
    begin
      blockread(ff,func,sizeof(func));
      initf(func.x,func.y,func.sx,func.sy,func.tip);
    end;
    if not editor then
    for i:=0 to maxf do
     if f^[i].enable then
      case f^[i].tip of
        1,2,3,4:
         if f^[i].tip<=maxpl then player[f^[i].tip].reinit(round(f^[i].x),round(f^[i].y),player[f^[i].tip].deftip,f^[i].dest);
      end;
{    for i:=1 to maxpl do
    begin
      blockread(ff,pl,sizeof(pl));
      player[i].reinit(pl.x,pl.y,pl.dest);
    end;}
    reloadpat;
  end;
  close(ff);
end;
procedure tmap.save;
var ff:file;
  mpat,mmon,mitem,mf,i:longint;
  mon:record
    x,y,tip:integer;
    dest:tdest;
  end;
  itm:record
    x,y,tip:integer;
  end;
  func:record
    x,y,sx,sy,tip:integer;
  end;
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
  mmon:=0;
  for i:=0 to maxmon do if m^[i].enable then inc(mmon); blockwrite(ff,mmon,4);
  mitem:=0;
  for i:=0 to maxitem do if item^[i].enable then inc(mitem); blockwrite(ff,mitem,4);
  mf:=0;
  for i:=0 to maxf do if f^[i].enable then inc(mf); blockwrite(ff,mf,4);

{  blockwrite(ff,maxpl,4);}
  for i:=0 to y-1 do blockwrite(ff,land[i]^,x*2);
  blockwrite(ff,patname^,mpat*9+9);
  for i:=0 to maxmon do
  if m^[i].enable then
  begin
    mon.x:=round(m^[i].x);
    mon.y:=round(m^[i].y);
    mon.dest:=m^[i].dest;
    mon.tip:=m^[i].tip;
    blockwrite(ff,mon,sizeof(mon){6});
  end;
  for i:=0 to maxitem do
  if item^[i].enable then
  begin
    itm.x:=round(item^[i].x);
    itm.y:=round(item^[i].y);
    itm.tip:=item^[i].tip;
    blockwrite(ff,itm,sizeof(itm){6});
  end;
  for i:=0 to maxf do
  if f^[i].enable then
  begin
    func.x:=round(f^[i].x);
    func.y:=round(f^[i].y);
    func.sx:=round(f^[i].sx);
    func.sy:=round(f^[i].sy);
    func.tip:=f^[i].tip;
    blockwrite(ff,func,sizeof(func){10});
  end;
{  for i:=1 to maxpl do
  begin
    pl.x:=player[i].startx;
    pl.y:=player[i].starty;
    pl.dest:=player[i].startdest;
    blockwrite(ff,pl,sizeof(pl));
  end;}
  close(ff);
end;
procedure tmap.done;
var i:longint;
begin
  if x=0 then exit;
{  for i:=0 to y-1 do freemem(land[i],longint(x)*2);}
{  x:=0; y:=0;}
end;
procedure tmap.draw; {40x25}
var
  i,j:longint;
  x1,y1:integer;
begin
  x1:=(dx) div 8;
  y1:=(dy) div 8;
  for i:={minx div 8}-8 to (maxx-minx) div 8+1 do
    for j:={miny div 8}-8 to (maxy-miny) div 8+1 do
    if (j+y1<y)and(i+x1<x)then
    if (j+y1>=0)and(i+x1>=0)then
     if land[j+y1]^[i+x1].vis<>0 then
       p^[pat[land[j+y1]^[i+x1].vis]].put(minx+i*8-dx mod 8,miny+j*8-dy mod 8);
  for i:=0 to maxpul do  if b^[i].enable    then b^[i].   draw(-minx+dx,-miny+dy);
  for i:=0 to maxitem do if item^[i].enable then item^[i].draw(-minx+dx,-miny+dy);
  for i:=0 to maxmon do  if m^[i].enable    then m^[i].   draw(-minx+dx,-miny+dy);
  for i:=0 to maxpix do  if pix^[i].enable  then pix^[i]. draw(-minx+dx,-miny+dy);
  for i:=0 to maxexpl do if e^[i].enable    then e^[i].   draw(-minx+dx,-miny+dy);
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
    if (j+y1<y)and(i+x1<x)then
    if (j+y1>=0)and(i+x1>=0)then
     if land[j+y1]^[i+x1].land<>0 then
       rectangle(i*8+1-x2,j*8+1-y2,i*8+6-x2,j*8+6-y2,getcolor(land[j+y1]^[i+x1].land));
  for i:=0 to maxf do if f^[i].enable then f^[i].draw(dx,dy);
end;
procedure tmap.deletepat;
var i:longint;
begin
{  for i:=1 to 255 do
   if patname^[i]<>'' then
    begin
      p^[pat[i]].done;
      pat[i]:=0;
      patname^[i]:='';
    end;
    error
    }
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
  done;
  clear;
  name:=aname;
  dx:=adx; dy:=ady;
  getmem(patname,256*9);
  fillchar(patname^,256*9,0);
  fillchar(pat,sizeof(pat),0);
 if land[0]=nil then
  for i:=0 to defy-1 do
  begin
    getmem(land[i],defx*2);  fillchar(land[i]^,defx*2,0);
  end;
  x:=ax; y:=ay;
  for i:=0 to y-1 do putpat(i,0,1,1);
  for i:=0 to y-1 do putpat(i,x-1,1,1);
  for i:=0 to x-1 do putpat(0,i,1,1);
  for i:=0 to x-1 do putpat(y-1,i,1,1);
end;
procedure tmap.clear;
var i:integer;
begin
  fillchar32(m^,0,sizeof(m^),0);        for i:=0 to maxmon do m^[i].new;
  fillchar32(item^,0,sizeof(item^),0);  for i:=0 to maxitem do item^[i].new;
  fillchar32(f^,0,sizeof(f^),0);        for i:=0 to maxf do f^[i].new;
  fillchar32(pix^,0,sizeof(pix^),0);    for i:=0 to maxpix do pix^[i].new;
  fillchar32(b^,0,sizeof(b^),0);        for i:=0 to maxpul do b^[i].new;
  fillchar32(e^,0,sizeof(e^),0);
end;
procedure tmap.new;
var i:longint;
begin
  system.new(m); fillchar32(m^,0,sizeof(m^),0);        for i:=0 to maxmon do m^[i].new;
  system.new(item);fillchar32(item^,0,sizeof(item^),0);for i:=0 to maxitem do item^[i].new;
  system.new(f);  fillchar32(f^,0,sizeof(f^),0);       for i:=0 to maxf do f^[i].new;
  system.new(pix);  fillchar32(pix^,0,sizeof(pix^),0); for i:=0 to maxpix do pix^[i].new;
  system.new(b);  fillchar32(b^,0,sizeof(b^),0);       for i:=0 to maxpul do b^[i].new;
  system.new(e);  fillchar32(e^,0,sizeof(e^),0);
  x:=0;
end;
{procedure loadpal(s:string);
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
  else mygraph.loadpal(s+'.bmp');
end;}
{procedure tbmp.reverse;
var i,j:longint;
begin
    for j:=0 to y-1 do
     for i:=0 to x div 2-1 do
       swapb(n^[i+j*x],n^[(x-i-1)+j*x]);
end;}
procedure tmap.move;
var i:longint;
begin
  if not editor then
  begin
    for i:=0 to maxitem do if item^[i].enable then item^[i].move;
    for i:=0 to maxmon do if m^[i].enable then m^[i].move;
    for i:=0 to maxf do if f^[i].enable then f^[i].move;
    for i:=0 to maxpix do if pix^[i].enable then pix^[i].move;
    for i:=0 to maxpul do if b^[i].enable then b^[i].move;
    for i:=0 to maxexpl do if e^[i].enable then e^[i].move;
    for i:=0 to maxmust do
     if must[i].tip<>0 then
      if must[i].delay>0 then dec(must[i].delay) else
      with must[i] do
      begin
        case tip of
         1: initmon(x,y,curtip,dest,true,true);
         2: inititem(x,y,curtip,true);
        end;
        tip:=0;
      end;
  end
  else
  begin
    if (mo(0,0,0,scry))and(dx>0) then dec(dx,scroolspeed);
    if (my=0)and(dy>0) then dec(dy,scroolspeed);
    if (mo(getmaxx-4,0,getmaxx,scry))and(dx div 8+25<x) then inc(dx,scroolspeed);
    if (my>=(getmaxy-4))and(dy div 8+20<y) then inc(dy,scroolspeed);
  end;
end;
(*procedure tbmp.loadfile;
var
  f:file;
  i,temp,ost:longint;
begin
  name:=ss;
  dx:=0; dy:=0;
  if pos('.',name)=0 then ss:=ss+'.bmp';
  assign(f,dbmp+ss);
  {$i-}reset(f,1);{$i+}
  if ioresult<>0 then begin x:=0; y:=0; exit; end;
  seek(f,18); blockread(f,x,4);  blockread(f,y,4);
{  if maxavail<x*y then begin if debug then putline('Free memory: '+st(memavail));  n:=nil; x:=0; y:=0;close(f);exit;end;}
  getmem(n,longint(x)*longint(y));
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
end; *)
procedure ttimer.clear;
begin
  gettime;  time.start:=time.cur;  tik.start:=tik.cur;  hod:=0;
end;
procedure ttimer.move;
begin
  inc(hod);  gettime;
  case sfps of
   false: if hod=15 then begin getfps; clear;end;
   true:
   begin
     if hod>5 then getfps;
     if hod=50 then begin getfps; clear;end;
   end;
 end;
{  if (hod mod 10=0)and(hod>100)then getfps;}
{  if (hod>30)then getfps;}
{  if hod=15 then begin getfps; clear;end;}
end;
procedure ttimer.easymove;
begin
  inc(hod);  gettime;
  if hod mod 10=0 then getfps;
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
{procedure savepal(s:string);
var f:file;
  i:longint;
begin
  assign(f,s);
  reset(f,1);
  seek(f,54);
  for i:=0 to 256*4 do pal^[i]:=pal^[i]*4;
  blockwrite(f,pal^,256*4);
  close(f);
end;}
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
procedure loadmonsters;
var
  f:text;
  s,s1,s2:string;
  nm,i,j:longint;
begin
  fillchar(monster,sizeof(monster),0);
  assign(f,'monster.ini');
  reset(f);
  while not eof(f) do
  begin
    readln(f,s);
    if (s[1]=';')or(s='')or(s[1]='/')then continue;
    if s[1]='[' then begin nm:=vl(copy(s,2,length(s)-2)); continue; end;
    i:=pos('=',s);
    if i>0 then
    with monster[nm] do
    begin
      s1:=downcase(copy(s,1,i-1));
      s2:=copy(s,i+1,length(s)-i);
      if s1='name' then name:=s2;
      if s1='h' then h:=vl(s2);
      if s1='firstitem' then defitem:=vl(s2);
      if s1='sizex' then x:=vl(s2);
      if s1='sizey' then y:=vl(s2);
      if s1='health' then health:=vl(s2);
      if s1='armor' then armor:=vl(s2);
      if s1='stay' then stay:=boolean(downcase(s2)='yes');
      if s1='speed' then speed:=vlr(s2);
      if s1='acsel' then acsel:=vlr(s2);
      if s1='brakes' then brakes:=vlr(s2);
      if s1='jumpx' then jumpx:=vlr(s2);
      if s1='jumpy' then jumpy:=vlr(s2);
      if s1='vis' then vis:=s2;
      if s1='run' then runi.delay:=vlr(s2);
      if s1='die' then diei.delay:=vlr(s2);
      if s1='bomb' then bombi.delay:=vlr(s2);
    end;
  end;
  close(f);
  for i:=1 to maxmon do
  with monster[i] do
   if name<>'' then
   begin
     stand[left]:=loadbmp(vis+'s');
     stand[right]:=loadbmpr(vis+'s');
     damage[left]:=loadbmp(vis+'d');
     damage[right]:=loadbmpr(vis+'d');
     fire[left]:=loadbmp(vis+'f1');
     fire[right]:=loadbmpr(vis+'f1');
     for j:=1 to maxmonframe do
      if exist(vis+'r'+st(j))then
      begin
        run[j,left]:=loadbmp(vis+'r'+st(j));
        run[j,right]:=loadbmpr(vis+'r'+st(j));
        runi.max:=j;
      end;
     for j:=1 to maxmonframe do
      if exist(vis+'d'+st(j))then
      begin
        die[j,left]:=loadbmp(vis+'d'+st(j));
        die[j,right]:=loadbmpr(vis+'d'+st(j));
        diei.max:=j;
      end;
     for j:=1 to maxmonframe do
      if exist(vis+'b'+st(j))then
      begin
        bomb[j,left]:=loadbmp(vis+'b'+st(j));
        bomb[j,right]:=loadbmpr(vis+'b'+st(j));
        bombi.max:=j;
      end;
      if bombi.max=0 then
      begin
        bombi:=diei;
        bomb:=die;
      end;
   end;
end;
procedure loadweapons;
var
  f:text;
  s,s1,s2:string;
  nm,i,j:longint;
begin
  fillchar(weapon,sizeof(weapon),0);
  assign(f,'weapon.ini');
  reset(f);
  while not eof(f) do
  begin
    readln(f,s);
    if (s[1]=';')or(s='')or(s[1]='/')then continue;
    if s[1]='[' then begin nm:=vl(copy(s,2,length(s)-2)); continue; end;
    i:=pos('=',s);
    if i>0 then
    with weapon[nm] do
    begin
      s1:=downcase(copy(s,1,i-1));
      s2:=copy(s,i+1,length(s)-i);
      if s1='name' then name:=s2;
      if s1='cool' then cool:=vl(s2);
      if s1='bul' then bul:=vl(s2);
      if s1='vis' then vis:=s2;
      if s1='mg' then mg:=vlr(s2);
      if s1='prise' then prise:=vlr(s2);
      if s1='hit' then hit:=vlr(s2);
      if s1='shot' then shot:=vlr(s2);
      if s1='reload' then reload:=vlr(s2);
      if s1='speed' then speed:=vlr(s2);
      if s1='slot' then slot:=vl(s2);
      if s1='%' then per:=vlr(s2);
      if s1='realodslot' then reloadslot:=vl(s2);
      if s1='sniper' then sniper:=boolean(downcase(s2)='on');
    end;
  end;
  close(f);
  for i:=0 to maxweapon do
   with weapon[i] do if name<>'' then  skin:=loadbmp(vis);
end;
procedure loadbombs;
var
  f:text;
  s,s1,s2:string;
  nm,i,j:longint;
begin
  fillchar(bomb,sizeof(bomb),0);
  assign(f,'bomb.ini');
  reset(f);
  while not eof(f) do
  begin
    readln(f,s);
    if (s[1]=';')or(s='')or(s[1]='/')then continue;
    if s[1]='[' then begin nm:=vl(copy(s,2,length(s)-2)); continue; end;
    i:=pos('=',s);
    if i>0 then
    with bomb[nm] do
    begin
      s1:=downcase(copy(s,1,i-1));
      s2:=copy(s,i+1,length(s)-i);
      if s1='name' then name:=s2;
      if s1='rad' then rad:=round(vlr(s2)*ppm);
      if s1='time' then time:=vlr(s2);
      if s1='vis' then vis:=s2;
      if s1='hit' then hit:=vlr(s2);
      if s1='fire' then fired:=vlr(s2);
    end;
  end;
  close(f);
  for i:=1 to maxbomb do
   with bomb[i] do if name<>'' then
     for j:=1 to maxmonframe do
      if (exist(vis+st(j)))and(length(vis+st(j))<=8)then
      begin
        fire[j]:=loadbmp(vis+st(j));
        maxfire:=j;
      end;
end;
procedure loadbullets;
var
  f:text;
  s,s1,s2:string;
  nm,i,j:longint;
begin
  fillchar(bul,sizeof(bul),0);
  assign(f,'bullet.ini');
  reset(f);
  while not eof(f) do
  begin
    readln(f,s);
    if (s[1]=';')or(s='')or(s[1]='/')then continue;
    if s[1]='[' then begin nm:=vl(copy(s,2,length(s)-2)); continue; end;
    i:=pos('=',s);
    if i>0 then
    with bul[nm] do
    begin
      s1:=downcase(copy(s,1,i-1));
      s2:=copy(s,i+1,length(s)-i);
      if s1='name' then name:=s2;
      if s1='vis' then vis:=s2;
      if s1='prise' then prise:=vlr(s2);
      if s1='mg' then mg:=vlr(s2);
      if s1='g' then g:=vlr(s2)*ms2;
      if s1='hit' then hit:=vlr(s2);
      if s1='fire' then fire:=vlr(s2);
      if s1='bomb' then bomb:=vl(s2);
      if s1='fly' then delfly:=vl(s2);
      if s1='rotate' then rotate:=vlr(s2);
      if s1='%' then per:=vlr(s2);
      if s1='shot' then shot:=vl(s2);
    end;
  end;
  close(f);
  for i:=1 to maxbul do
   with bul[i] do if name<>'' then
      if exist(vis)then
      begin
        fly[1]:=loadbmp(vis);
        maxfly:=1;
      end
      else
     for j:=1 to maxmonframe do
      if exist(vis+st(j))then
      begin
        fly[j]:=loadbmp(vis+st(j));
        maxfly:=j;
      end;
end;
procedure loaditems;
var
  f:text;
  s,s1,s2:string;
  nm,i,j:longint;
begin
  fillchar(it,sizeof(it),0);
  assign(f,'item.ini');
  reset(f);
  while not eof(f) do
  begin
    readln(f,s);
    if (s[1]=';')or(s='')or(s[1]='/')then continue;
    if s[1]='[' then begin nm:=vl(copy(s,2,length(s)-2)); continue; end;
    i:=pos('=',s);
    if i>0 then
    with it[nm] do
    begin
      s1:=downcase(copy(s,1,i-1));
      s2:=copy(s,i+1,length(s)-i);
      if s1='name' then name:=s2;
      if s1='vis' then vis:=s2;
      if s1='speed' then speed:=vlr(s2)*ms;
      if s1='weapon' then weapon:=vl(s2);
      if s1='ammo' then ammo:=vl(s2);
      if s1='count' then count:=vl(s2);
      if s1='health' then health:=vlr(s2);
      if s1='megahealth' then megahealth:=vlr(s2);
      if s1='armor' then armor:=vlr(s2);
      if s1='cant' then cant:=boolean(downcase(s2)='true');
    end;
  end;
  close(f);
  for i:=1 to maxit do
   with it[i] do if name<>'' then
     if exist(vis)then
     begin
        skin[1]:=loadbmp(vis); max:=1;
     end
       else
     for j:=1 to maxmonframe do
      if exist(vis+st(j))then
      begin
        skin[j]:=loadbmp(vis+st(j));
        max:=j;
      end;
end;
procedure loadfuncs;
var
  f:text;
  i,cur:integer;
begin
  cur:=0;
  assign(f,'func.ini');
  reset(f);
  while not eof(f) do
  begin
    readln(f,fname[cur].n);
    readln(f,fname[cur].name);
    readln(f,fname[cur].vis);
    fname[cur].skin:=loadbmp(fname[cur].vis);
    inc(cur);
  end;
  close(f);
end;
procedure menu;
var
  ch,hod,enter:integer;
const
  x1=80;
  y1=50;
  max=5;
  d=22;
  name:array[1..max]of string[32]=
  ('ОДИН игрок',
  'вместе',
  'бой',
  'редактор',
  'выход');
procedure draw;
var i,j,sx,sy:integer;
begin
  clear;
  sx:=(getmaxx-320) div 2;
  sy:=(getmaxy-200) div 2;
  p^[intro].put(sx,sy);
  for i:=1 to max do
    wb.print(sx+x1,sy+y1+(i-1)*d,name[i]);
  if hod mod 30<15 then j:=skull1 else j:=skull2;
  p^[j].sprite(sx+x1-30,sy+y1-5+(ch-1)*d);
  rb.print(sx+5,sy+192,game+' ['+version+']');
  screen;
end;
begin
  endgame:=false;
  ch:=1;  hod:=0; enter:=0;
  repeat
    inc(hod);
    draw;
    if keypressed then
    case crt.readkey of
      #13: enter:=ch;
      #9:  ch:=(ch)mod max+1;
      #0:case crt.readkey of
        #80: if ch<max then inc(ch);
        #72: if ch>1 then dec(ch);
       end;
    end;
  until enter>0;
  case enter of
   1: begin level.cur:=0; editor:=false; multi:=false; death:=false;end;
   2: begin level.cur:=0;editor:=false; multi:=true; death:=false; end;
   3: begin level.cur:=0;editor:=false; multi:=true; death:=true; end;
   4: editor:=true;
   5: endgame:=true;
  end;
  while keypressed do readkey;
end;
procedure drawwin;
var t:tnpat;
begin
  box(0,0,getmaxx,getmaxy);
  if putbmpall('win'+st(random(maxwin)+1)) then
  begin
    delay(1000);
    while keypressed do readkey;
    readkey;
  end;
end;
procedure drawlose;
var t:tnpat;
begin
  box(0,0,getmaxx,getmaxy);
  if putbmpall('lose'+st(random(maxlose)+1)) then
  begin
    delay(1000);
    while keypressed do readkey;
    readkey;
  end;
end;
procedure gamemenu;
var
  ch,hod,enter,sx,sy:integer;
const
  x1=80;
  y1=60;
  max=2;
  d=25;
  name:array[1..max]of string[32]=
  ('продолжить',
  'выход');
procedure draw;
var i,j:integer;
begin
  clear;
  p^[intro].put(sx,sy);
  for i:=1 to max do
    wb.print(sx+x1,sy+y1+(i-1)*d,name[i]);
  if hod mod 30<15 then j:=skull1 else j:=skull2;
  p^[j].sprite(sx+x1-30,sy+y1-5+(ch-1)*d);
  rb.print(sx+5,sy+192,game+' ['+version+']');
  screen;
end;
begin
  sx:=(getmaxx-320) div 2;
  sy:=(getmaxy-200) div 2;
  endgame:=false;
  ch:=1;  hod:=0; enter:=0;
  repeat
    inc(hod);
    draw;
    if keypressed then
    case crt.readkey of
      #13: enter:=ch;
      #9:  ch:=(ch)mod max+1;
      #0:
        case crt.readkey of
         #80: if ch<max then inc(ch);
         #72: if ch>1 then dec(ch);
        end;
    end;
  until enter>0;
  case enter of
   1: endgame:=false;
   2: endgame:=true;
  end;
  while keypressed do readkey;
end;
procedure loadnextlevel;
var i:longint;
begin
  for i:=0 to maxmust do must[i].tip:=0;
  level.next;
  time.clear;
end;
procedure reloadelevel;
var i:longint;
begin
  for i:=0 to maxmust do must[i].tip:=0;
  dec(level.cur);
  level.next;
  time.clear;
end;
procedure loadres;
var f:text;
begin
  assign(f,'res.ini');
{$i-}  reset(f); {$i+}
if ioresult<>0 then exit;
  readln(f,res);
{  readln(f,accel);}
  close(f);
end;
procedure outtro;
begin
  writeln; writeln;
  writeln('The ',game,' <-> ',version,' [',data,']');
  writeln('Copyright ',company);
  writeln('PRG: ',autor);
  writeln('Levels: ',levels);
  writeln(comment);
  writeln;
  writeln('Управление : 1       2');
  writeln('Выход      : Esc     Esc');
  writeln('Вправо     : Right   D');
  writeln('Влево      : Left    A');
  writeln('Прыжок     : Space   W');
  writeln('Стрелять   : Ctrl    Tab');
  writeln('СледОружие : Enter   Q');
  writeln('Меню вниз  : Tab');
  writeln('*** Если у вас проблемы с графикой - '#13#10'замените число в первой строчке в файле res.ini на 0');
end;
(******************************** PROGRAM ***********************************)
var
  i:longint;
  adelay:longint;
begin
  randomize;
  outtro;
  writeln('Free RAM: ',memavail);
  write('Ни сместа');
{  debug:=true;}
{  editor:=true;
{  sfps:=true;}
{Main Loading}
  w.load(wadfile);
  p^[0].load('bmp\error.bmp');
  loadres;
  loadwalls;
  loadweapons;
  loadmonsters;
  loadbombs;
  loadbullets;
  loaditems;
  loadfuncs;
  level.loadini;
  wb.load('stbf_',10,1);
  rb.load('stcfn',5,2);
  skull1:=loadbmp('skull1');
  skull2:=loadbmp('skull2');
  intro:=loadbmp('intro');
  for i:=0 to 9 do d[i]:=loadbmp('d'+st(i)); dminus:=loadbmp('dminus'); dpercent:=loadbmp('dpercent');
  cur:=loadbmp('cursor'); for i:=1 to 6 do en[i]:=loadbmp('puh'+st(i));
  heiskin[left]:=loadbmp('hai');
  heiskin[right]:=loadbmpr('hai');
{Init Screen...}
  writeln('Free RAM: ',memavail);
  initgraph(res); loadfont('8x8.fnt'); clear; mfps:=30; loadpal('playpal.bmp');
  if accel<>-1 then setaccelerationmode(accel);
  ddx:=6; ddy:=6;
  mousebox(0,0,getmaxx,getmaxy);
  Sensetivity(12,12);
{Load first level}
 map.new;
 map.g:=9.8*ms2;
 repeat
  menu;
  if endgame then break;
  if not editor then begin scrx:=getmaxx+1; scry:=getmaxy-50; end
  else begin scrx:=getmaxx-90; scry:=getmaxy-50; end;

  if editor then
  begin
    map.create(defx,defy,0,0,defname);
    ed.land.curname:=allwall^[1];
    ed.land.mask:=1;
    ed.what:=face;
    ed.cool:=true;
    maxpl:=0;
  end;


  if not editor then
  begin
{    level.loadfirst;}
    level.next;
  end;

  {Start game}
  if not editor then drawintro;
  GetIntVec($9,@vec);  SetIntVec($9,Addr(keyb));
  speed:=1;
  endgame:=false;
  time.clear;rtimer.clear; time.fps:=mfps;
  winall:=false;
  repeat
    rtimer.easymove;time.move;  mx:=mouse.x;  my:=mouse.y; push:=mouse.push; push2:=mouse.push2;
    {Manual}
    while keypressed do readkey;
    for i:=1 to maxpl do player[i].move;
    {Move}
    map.move;
    if not multi then
      endgame:=endgame or player[1].lose or player[1].win
     else
      endgame:=endgame or player[1].win or player[2].win;
   if multi then
    for i:=1 to maxpl do
     if player[i].lose then
       player[i].initmulti;
    if editor then ed.move;
    {Draw}
    clear;
{    for i:=0 to 5 do map.m^[i].atack;}
{    map.draw;}
    for i:=1 to maxpl do player[i].draw;
    if editor then ed.draw;
    rb.print(getmaxx-30,getmaxy-10,st0(round(rtimer.fps),3));
    if editor then p^[cur].sprite(mx,my);

    screen;
    speed:=1;
    if time.fps<>0 then speed:=mfps/time.fps;
    if speed>5 then speed:=5;
    if (not editor)and sfps then
    begin
      speed:=1;
      adelay:=round(adelay+(time.fps-mfps)*1000);
      if adelay<0 then adelay:=0;
      if adelay>1000*100 then adelay:=1000*100;
      for i:=0 to adelay do;
    end;
    if endgame then
    begin
     case multi of
      true:
      begin
        if player[1].win or player[2].win {or player[3].win or player[4].win} then
        begin
          drawwin;
          loadnextlevel;
          endgame:=false;
        end else
        gamemenu;
      end;
      false:
      begin
        if player[1].win then
        begin
          drawwin;
          loadnextlevel;
          endgame:=false;
        end else
        if player[1].lose then
        begin
          drawlose;
          reloadelevel;
          endgame:=false;
        end else
        gamemenu;
      end;
    end;
   end;
  until endgame or winall;
  winall:=false;
  SetIntVec($9,@vec);
 until false;
  {End game}
  closegraph;
  map.done;
  outtro;
end.