{$A+,B-,D+,E-,F-,G+,I+,L+,N+,O-,P-,Q-,R-,S-,T-,V+,X+,Y+ Filan}
{ $A+,B+,D+,E-,F+,G+,I+,L+,N+,O+,P+,Q+,R+,S+,T+,V+,X+,Y+ Debug}
{$M $fff0,0,655360}
program RF; {First verion: 27.2.2001}
uses mygraph,mycrt,api,mouse,wads,F32MA,dos;
const
  ppm=14; {pixel per meter (from plays.bmp)}
  ms=ppm/30; { meter/sec}
  ms2=ms/30; { meter/sec2}
  wadfile='513.wad';
  game='DooM 513: Doom RF';
  version='0.08';
  data='6.3.2001';
  company='IVA vision <-=[■]=->';
  autor='Andrey Ivanov [kIndeX Navigator]';
  comment='Special for Puh! Beta -1';
  dbmp='BMP\';
  maxx=300;
  maxy=300;
  maxpat=600;
  cwall = 1 shl 0;
  cstand= 1 shl 1;
  cwater= 1 shl 2;
  clava = 1 shl 3;
  maxmon=32;
  maxitem=64;
  maxf=32;
  maxpix=512;
  maxpul=128;
  maxexpl=16;
  maxmontip=32;
  maxweapon=32;
  maxbomb=32;
  maxbul=32;
  maxit=64;
  scry:integer=19*8;
  scrx:integer=260;
  maxt=320 div 8;
  maxedmenu=10;
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
  maxmonframe=10;
  maxkey=5;
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
  blood:tcolor=(m:180; r:12; del:1.5);
  water:tcolor=(m:200; r:8; del:1.5);
  {esc Left Right Fire Jump}
  ckey:array[1..maxkey]of byte=(1,$4b,$4d,$1d,57);
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
  tbmp=object
      n:^larray{pointer};
      x,y,dx,dy:integer;
      color:byte;
      name:string[8];
      procedure save;
      procedure reverse;
      procedure load(ss:string);
      procedure loadfile(ss:string);
      procedure loadwad(ss:string);
      procedure put(tx,ty:longint);
      procedure putspr(tx,ty:longint);
      procedure putabs(tx,ty:longint);
      procedure putblack(tx,ty:longint);
      procedure putblackc(tx,ty:longint);
      procedure putrot(tx,ty:longint; adx,ady,akx,aky:extended);
      procedure done;
  end;
  tmapelement=record
    land,vis:byte;
  end;
  tmapar=array[0..maxx]of tmapelement;
  tland=array[0..maxy]of ^tmapar;
  tobj=object
    enable,standing:boolean;
    lx,ly,mx,my:integer; {map}
    x,y,dx,dy:real;
    constructor new;
    procedure init(ax,ay,adx,ady:real);
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
  tstate=(stand,run,fire,die,crash,hack);
  tmon=object(tobj)
     life,ai: boolean;
     who: 0..maxmon;
     dest:tdest;
     tip: tmaxmontip;
     health,armor:real;
     delay,statedel,vis,savedel:longint;
     state,curstate:tstate;
     weap: tmaxweapon;
     w:set of tmaxweapon;
     bul:array[tmaxbul]of integer;
     procedure init(ax,ay,adx,ady:real; at:tmaxmontip; ad:tdest; aw:longint; aai:boolean);
     procedure takeweap(n:tmaxweapon);
     procedure takebul(n:tmaxbul; m:integer);
     procedure atack;
     function getsx:integer; virtual;
     function getsy:integer; virtual;
     function getftr:real; virtual;
     function getupr:real; virtual;
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
  end;
  tbul=object(tobj)
     who,tip: integer;
     procedure init(ax,ay, adx,ady:real; at,aw:integer);
     procedure draw(ax,ay:integer);
     procedure move; virtual;
     procedure detonate;
  end;
  titem=object(tobj)

  end;
  tF=object(tobj)

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
    procedure setdelta(ax,ay:integer);
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
    function initmon(ax,ay:real; at:longint; ad:tdest; ai:boolean):integer;
    procedure initbomb(ax,ay:integer; at:longint; who:integer);
    procedure initbul(ax,ay,adx,ady:real; at,who:integer);
    procedure initpix(ax,ay,adx,ady:real; ac:longint; al:real);
    procedure randompix(ax,ay,adx,ady,rdx,rdy:real; ac:tcolor);
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
(******************************** Variables *********************************)
var
  it:array[tmaxit]of
  record
    name:string[40];
    vis:string[8];
    skin:array[0..maxmonframe]of tnpat;
    weapon,ammo,count,health,armor,max:longint;
    speed:real;
  end;
  bul:array[tmaxbul]of
  record
    name:string[40];
    vis:string[8];
    maxfly,delfly:byte;
    fly:array[0..maxmonframe]of tnpat;
    hit,mg,prise,rotate,g: real;
    bomb: tmaxbomb;
  end;
  bomb:array[tmaxbomb]of
  record
    name:string[40];
    vis:string[8];
    rad,maxfire: longint;
    time,hit: real;
    fire:array[0..maxmonframe]of tnpat;
  end;
  weapon:array[tmaxweapon]of
  record
    name:string[40];
    vis:string[8];
    skin: tnpat;
    bul: tmaxbul;
    mg,prise:real;
    shot,hit,reload,speed:real; {shot time}
    slot,reloadslot,cool:longint;
    sniper:boolean;
  end;
  monster:array[tmaxmontip]of
  record
    name:string[40];
    x,y:integer;
    dest:tdest;
    health,armor,h:longint;
    defweapon: tmaxweapon; {?}
    stay:boolean;
    speed,jumpx,jumpy,acsel,brakes:real;
    vis:string[8];
    stand,damage,fire:array[tdest]of tnpat;
    run,die,bomb:array[0..maxmonframe-1,tdest]of tnpat;
    runi,damagei,diei,bombi:record
       max:longint; delay:real;
    end;
  end;
  time,rtimer:ttimer;
  w:twad;
  map:tmap;
  speed:real;
  ed:ted;
  d:array[0..9]of tnpat;
  dminus,dpercent:tnpat;
  p:array[0..maxpat]of tbmp;
  names:array[byte]of string[8];
  allwall:^arrayofstring8;
  mx,my:longint;
  push,push2:boolean;
  mfps:longint;
  debug,editor,endgame,sfps:boolean;
  cur:tnpat;
  key:tkeys;
  vec:procedure;
(******************************** IMPLEMENTATION ****************************)
{$f+}
procedure keyb; interrupt;
var i,j:integer;
begin
  for i:=1 to maxkey do
    if port[$60]=ckey[i] then key[i]:=true;

   for i:=1 to maxkey do
     if port[$60]=ckey[i]+$80 then key[i]:=false;
 inline ($60);
 vec;
end;
{$f-}
procedure tmon.atack;
var l:shortint;
begin
  if (delay>0)or not life  then exit;
  if (not ai)and(bul[weapon[weap].bul]<=0) then exit;
  delay:=round(weapon[weap].shot*mfps/speed);
  dec(bul[weapon[weap].bul]);
  {initbul();}
  case dest of
   left: l:=-1;
   right: l:=1;
  end;
  map.initbul(x,y-monster[tip].h,weapon[weap].speed*l,0,weapon[weap].bul,who);
  setstate(fire,0.1);
end;
procedure tmon.takeweap(n:tmaxweapon);
begin
  include(w,n);
  if weapon[n].cool>weapon[weap].cool then weap:=n;
end;
procedure tmon.takebul(n:tmaxbul; m:integer);
begin
  inc(bul[n],m);
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
  tobj.init(ax,ay,adx,ady);
end;
procedure tbmp.putrot(tx,ty:longint; adx,ady,akx,aky:extended);
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
  xx1:=-round(x2*akx); if xx1+tx<0 then xx1:=-tx; if xx1+tx>319 then exit;
  xx2:=round(x2*akx);  if xx2+tx>319 then xx2:=319-tx; if xx2+tx<0 then exit;
  yy1:=-round(y2*aky); if yy1+ty<0 then yy1:=-ty; if yy1+ty>319 then exit;
  yy2:=round(y2*aky);  if yy2+ty>199 then yy2:=199-ty; if yy2+ty<0 then exit;
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
     end{  else  scr^[word((ty+i)*320+j+tx)]:=1;}
    end;
  end;
end;
procedure tbul.draw(ax,ay:integer);
begin
{  tobj.draw(ax,ay);}
  if bul[tip].rotate<>0 then
    p[bul[tip].fly[1]].putrot(mx-ax,my-ay,cos(x/30),sin(x/30),0.75,0.75)
  else
    p[bul[tip].fly[1]].putblackc(mx-ax,my-ay);
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
      map.m^[i].damage(mx,my,bul[tip].hit,0,0);
      detonate;
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
   p[bomb[tip].fire[vis]].putblackc(x-ax,y-ay);
end;
procedure tbomb.move;
begin
  if life=0 then kill;
  dec(life);
  vis:=bomb[tip].maxfire-round(int(life/maxlife*bomb[tip].maxfire));
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
      map.m^[i].damage(round(map.m^[i].x),round(map.m^[i].y-map.m^[i].getsy*6),0,bomb[tip].hit,0);
end;
procedure tmon.setstate;
begin
  if not life then exit;
  state:=as;
  savedel:=round(ad*mfps/speed);
end;
procedure tmon.setcurstate;
begin
  if not life then exit;
  curstate:=as;
  savedel:=round(ad*mfps/speed);
end;
procedure tmon.kill;
begin
  setcurstate(die,100);
  life:=false;
end;
procedure tmon.explode;
begin
  setcurstate(crash,100);
  life:=false;
end;
procedure tmon.damage(ax,ay:integer; hit,bomb,oxy:real);
var
  i:integer;
begin
  if armor=0 then
  health:=health-hit-bomb-oxy
  else
  begin
    health:=health-(hit+bomb+oxy)/5;
    armor:=armor-(hit+bomb+oxy)/3;
    if armor<0 then armor:=0;
  end;
{  if health<0 then health:=0;}
  setstate(hack,0.1);
  for i:=0 to round((hit+bomb+oxy)*10) do
    map.randompix(ax,ay,dx,dy,5,5,blood);
  if health<0 then
    if bomb>0 then explode
    else kill;
end;
procedure tmap.randompix;
begin
  initpix(ax,ay,
    random*rdx-rdx*0.5+adx,random*rdy-rdy*0.5+ady,
    ac.m+random(ac.r),ac.del);
end;
procedure tmon.move;
begin
  tobj.move;
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
     vis:=min(round(statedel/(mfps*monster[tip].bombi.delay))+1,monster[tip].bombi.max);
  end;
  die:
  begin
     state:=die;
     inc(statedel);
     vis:=min(round(statedel/(mfps*monster[tip].diei.delay))+1,monster[tip].diei.max);
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
procedure tmap.setdelta(ax,ay:integer);
begin
  dx:=ax-160;
  dy:=ay-100;
  if dx<0 then dx:=0;
  if dy<0 then dy:=0;
  if dx>x+320 then dx:=x-320;
  if dy>y+200 then dy:=y-200;
end;
procedure swapb(var a,b:byte);
var t:byte;
begin
  t:=a; a:=b; b:=t;
end;
function exist(s:string):boolean;
begin
  exist:=fexist(s+'.bmp')or fexist(dbmp+s+'.bmp') or w.exist(s);
end;
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
  write('.');
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
function loadbmpr(s:string):tnpat;
var i:longint;
begin
  s:=upcase(s);
{  for i:=1 to maxpat do if p[i].name=s then begin loadbmpr:=i; exit; end; error}
  for i:=1 to maxpat do
    if p[i].x=0 then
    begin
     p[i].load(s);
     p[i].reverse;
     loadbmpr:=i;
     exit;
    end;
  loadbmpr:=0;
end;
procedure tmap.initbomb(ax,ay:integer; at:longint; who:integer);
var i:longint;
begin
  for i:=0 to maxexpl do
    if not e^[i].enable then
    begin
      e^[i].init(ax,ay,at,who);
      exit;
    end;
end;
procedure tmap.initbul(ax,ay,adx,ady:real; at,who:integer);
var i:longint;
begin
  for i:=0 to maxbul do
    if not b^[i].enable then
    begin
      b^[i].init(ax,ay,adx,ady,at,who);
      exit;
    end;
end;
function tmap.initmon;
var i:longint;
begin
  for i:=0 to maxmon do
    if not m^[i].enable then
    begin
      m^[i].init(ax,ay,0,0,at,ad,i,ai);
      initmon:=i;
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
  y2:=ly;
  for i:=x1 to x2 do
   if map.land[y2]^[i].land and cstand>0 then
   begin
     dy:=-dy*getupr; y:=y-1;
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
  my:=my+2;
  case state of
   stand:  p[monster[tip].stand[dest]].putspr(mx-ax,my-ay);
   run:  p[monster[tip].run[vis,dest]].putspr(mx-ax,my-ay);
   fire:  p[monster[tip].fire[dest]].putspr(mx-ax,my-ay);
   hack:  p[monster[tip].damage[dest]].putspr(mx-ax,my-ay);
   die:  p[monster[tip].die[vis,dest]].putspr(mx-ax,my-ay);
   crash:  p[monster[tip].bomb[vis,dest]].putspr(mx-ax,my-ay);
  end;
{  putpixel(mx-ax,my-ay,white);}
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
  tobj.init(ax,ay,adx,ady);
  ai:=aai;
  who:=aw;
  life:=true;
  dest:=ad;
  tip:=at;
  state:=stand;
  statedel:=0;
  vis:=1;
  health:=monster[tip].health;
  armor:=monster[tip].armor;
  takeweap(monster[tip].defweapon);
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
  for i:=0 to maxf do if f^[i].enable then f^[i].draw(dx,dy);
  for i:=0 to maxpul do if b^[i].enable then b^[i].draw(dx,dy);
  for i:=0 to maxitem do if item^[i].enable then item^[i].draw(dx,dy);
  for i:=0 to maxmon do if m^[i].enable then m^[i].draw(dx,dy);
  for i:=0 to maxpix do if pix^[i].enable then pix^[i].draw(dx,dy);
  for i:=0 to maxexpl do if e^[i].enable then e^[i].draw(dx,dy);
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
  system.new(b);  fillchar32(b^,0,sizeof(b^),0);       for i:=0 to maxpul do b^[i].new;
  system.new(e);  fillchar32(e^,0,sizeof(e^),0);
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
  else mygraph.loadpal(s+'.bmp');
end;
procedure tbmp.put(tx,ty:longint); {error}
var i:longint;
begin
  if x=0 then exit;
  {dec(tx,dx); dec(ty,dy);}
  if (tx>0)and(tx+x<320)then
  for i:=max(0,-ty) to min(y-1,320-y-ty) do
    move32(n^,x*i,scr^,(i+ty)*320+tx,x)
{    move(n^[x*i],scr^[(i+ty)*320+tx],x) ?}
  else
    putblack(tx,ty);
{  for i:=0 to y-1 do
   if (i+ty<200)and(i+ty>=0) then
     move(n^[x*i],scr^[(i+ty)*320+tx],x);}
end;
procedure tbmp.putblackc(tx,ty:longint);
begin
  putblack(tx-x div 2,ty-y div 2);
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
procedure tbmp.putspr(tx,ty:longint);
var
  i,j:integer;
  c:byte;
begin
  if x=0 then exit;
{  dec(tx,dx); dec(ty,dy);}
  dec(tx,x div 2);
  dec(ty,y);
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
procedure tbmp.reverse;
var i,j:longint;
begin
    for j:=0 to y-1 do
     for i:=0 to x div 2-1 do
       swapb(n^[i+j*x],n^[(x-i-1)+j*x]);
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
    for i:=0 to maxpul do if b^[i].enable then b^[i].move;
    for i:=0 to maxexpl do if e^[i].enable then e^[i].move;
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
  assign(f,dbmp+ss);
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
      if s1='weapon' then defweapon:=vl(s2);
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
      if bombi.max=0 then begin bombi:=diei; bomb:=die; end;
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
    end;
  end;
  close(f);
  for i:=1 to maxbomb do
   with bomb[i] do if name<>'' then
     for j:=1 to maxmonframe do
      if exist(vis+st(j))then
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
      if s1='bomb' then bomb:=vl(s2);
      if s1='fly' then delfly:=vl(s2);
      if s1='rotate' then rotate:=vlr(s2);
    end;
  end;
  close(f);
  for i:=1 to maxbul do
   with bul[i] do if name<>'' then
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
      if s1='health' then health:=vl(s2);
      if s1='armor' then armor:=vl(s2);
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
procedure outtro;
begin
  writeln; writeln;
  writeln('The ',game,' <-> ',version,' [',data,']');
  writeln('Copyright ',company);
  writeln('PRG: ',autor);
  writeln(comment);
  writeln;
  writeln('Управление:');
  writeln('Выход: Esc');
  writeln('Вправо:   Right');
  writeln('Влево:    Left');
  writeln('Прыжок:   Space');
  writeln('Стрелять: Ctrl');
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
   '-': p[dminus].putblack(x+i*dsize,y);
   '%': p[dpercent].putblack(x+i*dsize,y);
   '0'..'9': p[d[vl(s[i])]].putblack(x+i*dsize,y);
  end;
end;
(******************************** PROGRAM ***********************************)
var
  i:longint;
  adelay:longint;
  en:array[1..6]of tnpat;
begin
  randomize;
  outtro;
{  debug:=true;}
{  editor:=true;}
{  sfps:=true;}
  if not editor then begin scrx:=319; scry:=199; end;
{Main Loading}
  w.load(wadfile);
  loadwalls;
  map.new;
{  map.create(defx,defy,0,0,defname); }map.g:=9.8*ms2;
  loadmonsters;
  loadweapons;
  loadbombs;
  loadbullets;
  loaditems;
{Init Screen...}
  init320x200; loadfont('8x8.fnt'); clear; mfps:=30; loadpal('playpal');
  cur:=loadbmp('cursor'); for i:=1 to 6 do en[i]:=loadbmp('puh'+st(i));
  for i:=0 to 9 do d[i]:=loadbmp('d'+st(i));
  dminus:=loadbmp('dminus');
  dpercent:=loadbmp('dpercent');
{Load first level}
  map.load('temp');

  ed.land.curname:=allwall^[1];
  ed.land.mask:=1;
  ed.what:=face;

  map.initmon(30,270,7,right,false);
  for i:=1 to 6 do
    map.initmon(50+i*40,270,i,tdest(random(2)){right},true{ai});
  map.m^[0].takeweap(2);
  map.m^[0].takebul(1,100);
  map.m^[0].armor:=100;
  {Start game}
  GetIntVec($9,@vec);  SetIntVec($9,Addr(keyb));
  speed:=1;
  endgame:=false;
  time.clear;rtimer.clear; time.fps:=mfps;
  repeat
    rtimer.easymove;time.move;  mx:=mouse.x;  my:=mouse.y; push:=mouse.push; push2:=mouse.push2;
    {Manual}
    if keypressed then
    if key[1] then endgame:=true;
    if key[2] then map.m^[0].runleft;
    if key[3] then map.m^[0].runright;
    if key[4] then map.m^[0].atack;
    if key[5] then map.m^[0].jump;
    {Move}
    map.move;
    if not editor then map.setdelta(round(map.m^[0].x),round(map.m^[0].y));
    if editor then ed.move;
    {Draw}
    clear;
    for i:=1 to 6 do map.m^[i].atack;
    map.draw;
    if editor then ed.draw;
    print(290,190,white,st0(round(rtimer.fps),3));
    if editor then p[cur].putblack(mx,my);
    p[en[

    norm(1,6,
    round(7-6*map.m^[0].health/monster[map.m^[0].tip].health)

    )]].putblack(0,160);
    digit(30,168,
    round(map.m^[0].health)
    ,'%');
    digit(30,184,
    round(map.m^[0].armor)
    ,' ');
    p[weapon[map.m^[0].weap].skin].putblack(100,170);
    digit(150,170,map.m^[0].bul[weapon[map.m^[0].weap].bul],' ');
    screen;
    speed:=1;
    if time.fps<>0 then speed:=mfps/time.fps;
    if speed>5 then speed:=5;
    if (not editor)and sfps then
    begin
      speed:=1;
      adelay:=round(adelay+(time.fps-mfps)*1000);
      if adelay<0 then adelay:=0;
      for i:=0 to adelay do;
    end;
  until endgame;
  SetIntVec($9,@vec);
  {End game}
  closegraph;
  map.done;
  outtro;
end.