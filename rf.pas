{$A+,B+,D+,E-,F-,G+,I-,L+,N+,P-,Q-,R-,S-,T-,V+,X+,Y+ Final}
{ $A+,B+,D+,E-,F+,G+,I+,L+,N+,O+,P+,Q+,R+,S+,T+,V+,X+,Y+ Debug}
{$M $fff0,0,655360}
program RF; {First verion: 27.2.2001}
uses crt,mycrt,api,mouse,wads,F32MA,dos,grafx,grx;
{$ifndef dpmi} Real mode not supported {$endif}
const
  accel:integer=-1;
  ppm=14; {pixel per meter (from plays.bmp)}
  ms=ppm/30; { meter/sec}
  ms2=ms/30; { meter/sec2}
  botdir='bots\';
  wadfile='513.wad';
  levext='.lev';
  mousepl=4;
  playdefitem=2;
  freeitem=1;
  oxysec=10;
  bombfire=4;
  reswapbomb=2;
  barrelbomb=5;
  maxlose=11;
  maxwin=6;
  maxstart=4;
  maxpmaxx=300;
  maxpmaxy=300;
  cwall = 1 shl 0;  cstand= 1 shl 1;  cwater= 1 shl 2;  clava = 1 shl 3; cshl= 1 shl 4; cshr= 1 shl 5;
     cFunc= 1 shl 6;
  cjump = 1 shl 0;
  cimp = 1 shl 1; cgoal = 1 shl 0;
  maxmon=196;
  maxitem=128;
  maxf=32;  maxpix=512;  maxpul=512;  maxexpl=32;  maxmontip=32;
  maxweapon=32;  maxbomb=16;  maxnode=300;
  maxlink=3; {0..3  (4)}
  maxbul=16;
  maxit=96;
  maxfname=16;
  scry:integer=19*8;  scrx:integer=260;
  maxt=1600 div 8;
  maxedmenu=12;       maxmust=128;
  defx=200; defy=200; defname='';
  maxmonframe=10;
  maxkey=7;
  {esc Left Right Fire Jump}
  ckey:array[1..3,1..maxkey]of byte=(
  (1,$4b,$4d,$1d,72,54,80),
  (1,30,32,15,17,16,31),
  (1,79,81,28,76,78,80));
  scroolspeed=12;
  truptime=30;
  reswaptime:integer=60;  monswaptime:integer=30;
  botsee:array[1..5]of integer=(800,600,400,200,0);
  edwallstr:array[1..8]of string[16]=
  (  'Стена',  'Ступень',  'Вода',  'Лава',  '<-',  '->',  'Function',  '' );
{  ednodestr:array[1..4]of string[16]=
  ( 'Цель-Выход',  'Важный',  'Предмет',  '-'  );}
  edmenustr:array[1..maxedmenu]of string[16]=
  (  'Выход',  'Сохран',  'Загруз',  'Новая',  'Текстур',  'Стены',
   'Монстры',  'Предметы',  'Функции',  'Скрытые',  'Пути',  '(C)'  );
type
  real=single;
  tcapt=array[1..4]of char;
  tcolor=record
    m,r:byte;
    del:real;
  end;
  tkeys=array[1..maxkey]of boolean;
  tbot=record
     tip,bot:integer;
     scr:(up,down,all,none,ul,ur,dl,dr);
     name:string[32];
  end;
const
  origlev:tcapt='FL02'; lever00:tcapt='FLEV';
  bot:array[1..4]of tbot=(
  (tip:10; bot:0; scr:up; name:'Player1'),
  (tip:9;  bot:1; scr:down;name:'bot2'),
  (tip:12; bot:1; scr:none;name:'bot3'),
  (tip:12; bot:1; scr:none;name:'bot4')
  );
  maxallpl:integer=4;
  blood:tcolor=(m:180; r:12; del: 6{3.5});
  water:tcolor=(m:200; r:8; del:2.5);
  blow:tcolor=(m:160; r:8; del:2);
  kexit=1;
  kleft=2;
  kright=3;
  katack=4;
  kjump=5;
  knext=6;
  kdown=7;
type
   tdest=(left,right);
{   tnpat=0..maxpat;}
   tmaxmontip=0..maxmontip;
   tmaxweapon=0..maxweapon;
   tmaxbomb=0..maxbomb;
   tmaxbul=0..maxbul;
   tmaxnode=0..maxnode;
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
  larray=array[0..$fffa]of byte;
  tmapelement=record
    land,vis:byte;
  end;
  tmapar=array[0..maxpmaxx]of tmapelement;
  tland=array[0..maxpmaxy]of ^tmapar;
  tobj=object
    enable,standing,first,down,elevator:boolean;
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
    function inwall(c:byte):boolean; virtual;
  end;
  tnode=object(tobj)
    c: byte;
    maxl: shortint;
    wave,from,index,level: longint;
    l:array[0..maxlink]of
      record
        n: tmaxnode;
        d: longint;
        c: byte;
      end;
    procedure init(ax,ay:real; ac:byte; ai:integer);
    procedure addlink(an,ac:integer);
    procedure dellink(an:integer);
    procedure xorlink(an,ac:integer);
    procedure draw(ax,ay:integer);
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
     life,ai,know,see,barrel: boolean;
     target: record x,y:integer end;
     who,lastwho: 0..maxmon;
     dest:tdest;
     tip: tmaxmontip;
     delay,deldam,statedel,vis,savedel,hero,god:longint;
     state,curstate:tstate;
     health,armor,fired,buhalo,vempire,oxy,oxylife:real;
     weap: tmaxweapon;
     w:set of tmaxweapon;
     key:set of 1..maxkey;
     bul:array[tmaxbul]of integer;
     procedure takebest(mode:integer);
     procedure init(ax,ay,adx,ady:real; at:tmaxmontip; ad:tdest; aw:longint; aai,af:boolean; ah:longint);
     function takegod(n:longint):boolean;
     function takeweap(n:tmaxweapon):boolean;
     function takebul(n:tmaxbul; m:integer):boolean;
     function takeitem(n:integer):boolean;
     function takearmor(n:real):boolean;
     function takehealth(n:real):boolean;
     function takemegahealth(n:real):boolean;
     procedure dier;
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
     procedure damage(ax,ay:integer; hit,bomb,coxy:real; dwho:integer);
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
    function getftr:real; virtual;
    procedure init(ax,ay,adx,ady:real; at:integer; af:boolean);
    procedure draw(ax,ay:integer);
    procedure done; virtual;
  end;
  tF=object(tobj)
    tip,sx,sy: integer;
    dest: tdest;
    procedure init(ax,ay,asx,asy,at:integer);
    procedure move; virtual;
    procedure draw(ax,ay,id:integer);
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
  arrayofnode=array[0..maxnode]of tnode;
  tmap=object
    name:string[8];
    copy,com:string;
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
    n:^arrayofnode;
    procedure new;
    function  getnode(mx,my:longint):integer;
    procedure deltanode;
    procedure clearnode;
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
    procedure drawnodes;
    procedure move;
    procedure clear;
    function initmon(ax,ay:real; at:longint; ad:tdest; ai,af:boolean; ah:longint):integer;
    function initbomb(ax,ay:integer; at:longint; who:integer):integer;
    function initnode(ax,ay:integer; ac:byte):integer;
    function initbul(ax,ay,adx,ady:real; at,who:integer):integer;
    function initpix(ax,ay,adx,ady:real; ac:longint; al:real):integer;
    function initf(ax,ay,asx,asy,atip:integer):integer;
    function inititem(ax,ay,adx,ady:real; at:integer; af:boolean):integer;
    procedure randompix(ax,ay,adx,ady,rdx,rdy:real; ac:tcolor);
  end;
  ted=object
    what: (face,wall,mons,items,func,node);
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
        b:tnpat;
       end;
    end;
    nodes:record
      cur,push: integer;
      mask: byte;
      sx,sy:integer;
    end;
    procedure draw;
    procedure move;
    procedure reload;
  end;
  tplayer=object
    enable,win,lose,god,see,lastsee,downed,reset,drowed:boolean;
    name:string[40];
    bot,curn,lastn,goal,nextn,mx,my,seex,seey,wmode:longint;
    startx,starty,deftip,n,frag,die,kill:integer;
    startdest:tdest;
    health,maxhealth,armor,oxy:real;
    weap: tmaxweapon;
    tip,ammo:integer;
    x1,y1,x2,y2:integer;
    hero: integer;
    key:tkeys;
    save:tmon;
    function seeany:boolean;
    procedure init(ax1,ay1,ax2,ay2,ax,ay,at:integer;ad:tdest; aname:string; an,ab:integer);
    procedure reinit(ax,ay,atip:integer;adest:tdest);
    procedure settip(at:integer);
    procedure initmulti;
    procedure draw;
    procedure move;
    function getherotip:integer;
    procedure done;
  end;
  tlevel=object
    max,cur:integer;
    name:array[0..30]of string[8];
    savefirst:string[8];
    procedure loadini;
    procedure load;
    procedure loadfirst;
    procedure next;
  end;
(******************************** Variables *********************************)
var
  pkey:array[byte]of boolean;
  keybuf:string;
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
    health,armor,megahealth,god:real;
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
    bul,pul: tmaxbul;
    mg,prise:real;
    shot,hit,reload,speed,per,damages,bomb:real; {shot time}
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
  en:array[1..7]of tnpat;
  pnode,pnodei,pnodeg: tnpat;
  time,rtimer:ttimer;
  map:tmap;
  speed:real;
  ed:ted;
  d:array[0..9]of tnpat;
  dminus,dpercent:tnpat;
{  p:array[0..maxpat]of tbmp;}
  names:array[byte]of string[8];
  allwall:^arrayofstring8;
  mx,my,lastx,lasty,add:longint;push,push2,push3:boolean;
  mfps,skill,maxallwall:longint;
  editor,endgame,multi,death,first,rail,look,sniper,reswap:boolean;
  cur,skull1,skull2,intro:tnpat;
  vec:procedure;
  maxpl:integer;
  player:array[1..4]of tplayer;
  level:tlevel;
  heiskin: array[tdest]of tnpat;
(******************************** IMPLEMENTATION ****************************)
procedure drawintro;
var t:tnpat;
begin
  clear;
  box(0,0,getmaxx,getmaxy);
  if putbmpall('start'+st(random(maxstart)+1)) then
  begin
    rb.print(getmaxx div 2-40,getmaxy-10,'В это время...');
    screen;
    delay(1);
  end;
end;
procedure tnode.dellink(an:integer);
var cur,j:integer;
begin
  cur:=0;
  for cur:=0 to maxl do
   if l[cur].n=an then
   begin
     for j:=cur to maxl-1 do
      l[j]:=l[j+1];
     dec(maxl);
     exit;
   end;
end;
procedure tmap.deltanode;
var
  i,j,t:longint;
begin
  for i:=0 to maxnode do
   if n^[i].enable then
    for j:=0 to n^[i].maxl do
    begin
      t:=n^[i].l[j].n;
      n^[i].l[j].d:=round(sqrt(sqr(n^[t].x-n^[i].x))+sqr(n^[t].y-n^[i].y));
    end;

  for i:=0 to maxnode do
    for j:=0 to maxf do
     if f^[j].enable then
     if  (n^[i].mx>=f^[j].x)and
         (n^[i].my>=f^[j].y)and
         (n^[i].mx<=f^[j].x+f^[j].getsx)and
         (n^[i].my<=f^[j].y+f^[j].getsy)
           then if f^[j].tip=10 then n^[i].c:=n^[i].c or cgoal;
end;
procedure tmap.clearnode;
var i:integer;
begin
  for i:=0 to maxnode do
   if n^[i].enable then
   begin
     n^[i].wave:=maxlongint;
     n^[i].from:=-1;
     n^[i].level:=-1;
   end;
end;
procedure tnode.addlink(an,ac:integer);
var cur:integer;
begin
  cur:=0;
  for cur:=0 to maxl do
   if l[cur].n=an then
   begin
     l[cur].c:=ac;
     exit;
   end;
   if cur<maxlink then
   begin
     if maxl<>-1 then inc(cur);
     if cur>maxlink then exit;
     l[cur].n:=an;
     l[cur].c:=ac;
     maxl:=cur;
   end;
end;
procedure tnode.xorlink(an,ac:integer);
var cur,j:integer;
begin
  cur:=0;
  for cur:=0 to maxl do
   if l[cur].n=an then
   begin
     for j:=cur to maxl-1 do
      l[j]:=l[j+1];
     dec(maxl);
     exit;
   end;
   addlink(an,ac);
end;
procedure tnode.init(ax,ay:real; ac:byte; ai:integer);
begin
  tobj.init(ax,ay,0,0,false);
  c:=ac;
  index:=ai;
  maxl:=-1;
end;
procedure tnode.draw(ax,ay:integer);
var i,col,tx,ty:integer;
begin
  if c=0 then p^[pnode].spritec(mx-ax,my-ay);
  if c and cimp>0 then p^[pnodei].spritec(mx-ax,my-ay);
  if c and cgoal>0 then p^[pnodeg].spritec(mx-ax,my-ay);
  for i:=0 to maxl do
  begin
    if (l[i].c and cjump)>0 then col:=red else col:=green;
    tx:=map.n^[l[i].n].mx;
    ty:=map.n^[l[i].n].my;
    line(mx-ax,my-ay,
    (tx+mx)div 2-ax,
    (ty+my)div 2-ay,col);
  end;
  rb.print(mx-ax,my-ay,st(index));
end;
procedure tlevel.loadfirst;
var i:longint;
  x1,y1,x2,y2:integer;
begin
  case multi of
  false:
  begin
    maxpl:=1;
    player[1].init(0,0,getmaxx,getmaxy,60,270,bot[1].tip,right,'Player',1,bot[1].bot);
    player[1].settip(bot[1].tip);
  end;
  true:
  begin
    maxpl:=maxallpl;
   for i:=1 to maxpl do {InitBots}
   begin
    case bot[i].scr of
      all: begin x1:=0; x2:=getmaxx; y1:=0; y2:=getmaxy ;end;
      up: begin  x1:=0; x2:=getmaxx; y1:=0; y2:=getmaxy div 2;end;
      down: begin x1:=0; x2:=getmaxx; y1:=1+getmaxy div 2; y2:=getmaxy ;end;
      none: begin x1:=0; x2:=0; y1:=0; y2:=0 ;end;
      ul: begin  x1:=0; x2:=getmaxx div 2; y1:=0; y2:=getmaxy div 2;end;
      dl: begin  x1:=0; x2:=getmaxx div 2; y1:=1+getmaxy div 2; y2:=getmaxy;end;
      ur: begin  x1:=1+getmaxx div 2; x2:=getmaxx; y1:=0; y2:=getmaxy div 2;end;
      dr: begin  x1:=1+getmaxx div 2; x2:=getmaxx; y1:=1+getmaxy div 2; y2:=getmaxy;end;
    end;
    player[i].init(x1,y1,x2,y2,50*i,60*i,bot[i].tip,right,bot[i].name,i,bot[i].bot);
    player[i].settip(bot[i].tip);
  end;
 end;
 end;
 for i:=1 to maxpl do
 begin
   fillchar(player[i].key,sizeof(player[i].key),0);
   player[i].settip(bot[i].tip);
 end;
  cur:=1; load;
end;
procedure tlevel.load;
var i:integer;
begin
{ if not first then}
  for i:=1 to maxpl do
  with map.m^[player[i].hero] do
  if health>0 then
  begin
    player[i].save.health:=health;
    player[i].save.armor:=armor;
{    player[i].save.fired:=fired;}
    player[i].save.buhalo:=buhalo;
    player[i].save.vempire:=vempire;
    player[i].save.weap:=weap;
    player[i].save.w:=w;
    player[i].save.bul:=bul;
  end;

  map.done;
  map.load(name[cur]);

 if not first then
  for i:=1 to maxpl do
  with map.m^[player[i].hero] do
  begin
    player[i].frag:=0;
    player[i].kill:=0;
    player[i].die:=0;
    health:=player[i].save.health;
    armor:=player[i].save.armor;
{    fired:=player[i].save.fired;}
    buhalo:=player[i].save.buhalo;
    vempire:=player[i].save.vempire;
    weap:=player[i].save.weap;
    w:=player[i].save.w;
    bul:=player[i].save.bul;
  end;
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
  savefirst:=name[1];
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
  if reswap and ai and first or barrel then
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
  init(x1,y1,x2,y2,ax,ay,atip,adest,name,n,bot);
  hero:=map.initmon(ax,ay,deftip,adest,false{ai},false{first},n);
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
var
  i,j:integer;
begin
  tobj.init(ax,ay,0,0,false);
  sx:=asx;
  sy:=asy;
  if sx<0 then begin x:=x+sx; sx:=-sx; end;
  if sy<0 then begin y:=y+sy; sy:=-sy; end;
  tip:=at;
  mx:=round(x);
  my:=round(y);

  for i:=ax div 8 to (ax+asx)div 8 do
    for j:=ay div 8 to (ay+asy)div 8 do
     map.land[j]^[i].land:=map.land[j]^[i].land or cfunc;
end;
function tmon.takegod(n:longint):boolean;
begin
  if god=0 then
  begin
    god:=n;
    takegod:=true;
  end
   else
    takegod:=false;
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
  fired:=0;
  if health>monster[tip].health*2 then health:=monster[tip].health*2;
  takemegahealth:=true;
end;
function tmon.takeitem(n:integer):boolean;
var ok:boolean;
begin
  ok:=false;
  if it[n].god<>0 then ok:=ok or takegod(round(it[n].god/speed*mfps));
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
procedure tplayer.init(ax1,ay1,ax2,ay2,ax,ay,at:integer; ad:tdest; aname:string; an,ab:integer);
begin
  if ax1=ax2 then drowed:=false else drowed:=true;
  enable:=true;
  n:=an;
  bot:=ab;
  curn:=0; lastn:=-1; nextn:=1; goal:=-1; see:=false;
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
    god:=map.m^[hero].god<>0;
    weap:=map.m^[hero].weap;
    health:=map.m^[hero].health;
    oxy:=map.m^[hero].oxy;
    armor:=map.m^[hero].armor;
    tip:=map.m^[hero].tip;
    maxhealth:=monster[tip].health;
    ammo:=map.m^[hero].bul[weapon[weap].bul];
    if not drowed then exit;
    box(x1,y1,x2,y2);
    map.setdelta(round(map.m^[hero].x),round(map.m^[hero].y-14),(x2-x1) div 2,(y2-y1) div 2);
  end;
  map.draw;
  if debug and (bot>0)then
  begin
    map.drawnodes;
    rb.print(minx,miny+5,'goal   :'+st(goal));
    rb.print(minx,miny+15,'current:'+st(curn));
    rb.print(minx,miny+25,'target :'+st(nextn));
    if see then rb.print(minx,miny+35,'see  '+st(round(seex/ppm))+' m');
  end;
  if not editor then
  case multi of
  false:
  begin
    if not god then
     p^[en[norm(1,6,round(7-6*health/maxhealth))]].put(minx,maxy-40)
    else
     p^[en[7]].put(minx,maxy-40);
    digit(minx+30,maxy-35,round(health),'%');
    digit(minx+30,maxy-15,round(armor),' ');
    p^[weapon[weap].skin].sprite(minx+230,maxy-30);
    rb.print(minx+230,maxy-15,st(ammo));
{    if oxy<100 then digit(minx+(minx++maxx)div 2-24,miny+(maxy+miny)div 2+30,round(oxy),'%');
    if god then digit(minx+(minx++maxx)div 2-24,miny+(maxy+miny)div 2+30,round(map.m^[hero].god/rtimer.fps),' ');}
  end;
  true:
  begin
{    p[en[norm(1,6,round(7-6*health/maxhealth))]].putblack(0,160);}
    digit(maxx-56,miny,round(health),'%');
    digit(maxx-56,miny+17,round(armor),' ');
    p^[weapon[weap].skin].spritec(maxx-28,miny+45);
    digit(maxx-56,miny+50,ammo,' ');
    rb.print(maxx-56,miny+66,'Frags:'+st(frag));
    rb.print(maxx-56,miny+74,'Kills:'+st(kill));
    rb.print(maxx-56,miny+82,'Die  :'+st(die));
{    if god then digit(minx+(minx++maxx)div 2-24,miny+(maxy+miny)div 2+30,round(map.m^[hero].god/rtimer.fps),' ');}
  end;
 end;
  if oxy<100 then digit(minx+(minx++maxx)div 2-24,miny+(maxy+miny)div 2+30,round(oxy),'%');
  if map.m^[hero].god>0 then
    digit(minx+(minx++maxx)div 2-24,miny+(maxy+miny)div 2+30,round(map.m^[hero].god/rtimer.fps),' ');
  box(0,0,getmaxx,getmaxy);
end;
procedure tmon.takebest(mode:integer);
var i,c:integer;
   dam:real;
begin
  dam:=0; c:=0;
  for i:=1 to maxweapon do
   if ((bul[weapon[i].bul]>0)or((weapon[i].hit>0)))and(i in w)and(weapon[i].cool>=0) then
    if dam<weapon[i].damages then
    if
    (mode=0)and(weapon[i].bomb=0)or
    (mode=1)and(weapon[i].hit=0)and(weapon[i].bomb=0)
        then
    begin
      dam:=weapon[i].damages;
      c:=i;
    end;
  if c>0 then weap:=c;
end;
procedure tmon.takenext;
begin
  if delay>0 then exit;
  repeat
    inc(weap);
  until (weap>maxweapon)or((bul[weapon[weap].bul]>0)and(weap in w));
{    or((weapon[weap].hit>0)and(weap in w));}
  if weap>maxweapon then weap:=1;
  delay:=round(mfps/speed*0.25);
end;
function tmap.getnode(mx,my:longint):integer;
var i,d,min,c:longint;
begin
  c:=-1;
  min:=maxint;
  for i:=0 to maxnode do
   if n^[i].enable then
   begin
     d:=round(sqrt(sqr(mx-n^[i].mx)+sqr(my-n^[i].my)));
     if (d<min){and(can(mx,my,n^[i].mx,n^[i].my))} then
        begin c:=i; min:=d; end;
   end;
  getnode:=c;
end;
function tplayer.seeany:boolean;
var
  cx,cy,m,min,d,f:longint;
begin
  seeany:=false;
  cx:=mx; cy:=my;
  min:=1000;
  f:=-1;
  for m:=0 to maxmon do
   if (map.m^[m].enable)and(map.m^[m].life)and not map.m^[m].barrel then
     if m<>hero then
     if death or (map.m^[m].hero=0) then
     if (abs(map.m^[m].my-my)<24) then
      if abs(map.m^[m].mx-mx)<min then
      begin
         min:=abs(map.m^[m].mx-mx);
         f:=m;
      end;
  if f=-1 then exit;
  if map.m^[f].mx<mx then d:=-1 else d:=1;
  seeany:=true;
  cx:=mx; cy:=my;
  while abs(map.m^[f].mx-cx)>6 do
  begin
    if (map.land[cy div 8-2]^[cx div 8].land and cwall)>0 then
        begin seeany:=false; exit; end;
    cx:=cx+d*4;
  end;
  seex:=map.m^[f].mx-mx;
  seey:=map.m^[f].my-my;
end;
procedure tplayer.move;
var
  i:integer;
  dest:tdest;
function getgoal:integer;
var i,j,ge:integer;
begin
  ge:=-1;
  with map do
   for i:=0 to maxnode do
    if n^[i].enable then
   begin
     n^[i].c:=n^[i].c and not cimp;
     if (n^[i].c and cgoal)>0 then begin n^[i].c:=n^[i].c or cimp; ge:=i;  end;
     for j:=0 to maxitem do
      if (not it[map.item^[j].tip].cant)and(map.item^[j].enable)and
       (abs(item^[j].mx-n^[i].mx)+abs(map.item^[j].my-n^[i].my)<16)
       then
        if not((health>=monster[map.m^[hero].tip].health)and(it[map.item^[j].tip].health>0))then
        if not((health*2>=monster[map.m^[hero].tip].health)and(it[map.item^[j].tip].megahealth>0))then
         n^[i].c:=n^[i].c or cimp;
   end;
  if death then
   for i:=1 to maxpl do
    if player[i].hero<>hero then
    begin
     if ge=-1 then ge:=map.getnode(player[i].mx,player[i].my);
     map.n^[ge].c:=map.n^[ge].c or cimp;
{     break;}
    end;
  getgoal:=ge;
end;
procedure wave(s,t:integer);
var i,j,k,c:longint;
begin
  if t=-1 then exit;
  with map do
  begin
    n^[s].wave:=0;
    n^[s].from:=-1;
    n^[s].level:=1;
    for i:=1 to maxnode do
    begin
      for j:=0 to maxnode do
       if (n^[j].level=i)and(n^[j].enable)and(n^[j].wave<maxlongint) then
         for k:=0 to n^[j].maxl do
          begin
            c:=n^[j].l[k].n;
{           if (((n^[c].my+64>n^[j].my))or(n^[c].my>n^[j].my))
           or((abs(n^[c].my-n^[j].my)<(abs(n^[c].mx-n^[j].mx)*2))
           or(n^[j].l[k].c and cjump>0))}
           {error - maybe fixed - button3 in editor - one wave links}
{           then}
            if n^[c].wave>(n^[j].l[k].d+n^[j].wave) then
            begin
               n^[c].from:=j;
               n^[c].level:=i+1;
               n^[c].wave:=n^[j].l[k].d+n^[j].wave;
            end;
          end;
         if n^[t].wave<maxlongint then break;
      end;
  end;
end;
function find(g:integer):integer;
var l,min,c,i:longint;
begin
  c:=g;
  i:=0;
  repeat
    inc(i);
    l:=c;
    if c=-1 then break;
    c:=map.n^[c].from;
    if c=-1 then break;
  until (c=curn)or(map.n^[c].wave=0)or(i>maxnode);
  find:=l;
end;
function getpath:integer;
var min,c,i:longint;
begin
  c:=-1; min:=maxlongint;
  for i:=0 to maxnode do
   if (map.n^[i].enable)and(map.n^[i].c and cimp>0)and(map.n^[i].wave<min)
   then
   begin
     min:=map.n^[i].wave;
     c:=i;
   end;
   getpath:=c;
end;
procedure gotonode(a,b:integer);
var c:integer;
begin
  if (a<0)or(b<0)then exit;
  if mx<map.n^[b].mx then include(map.m^[hero].key,kright) else include(map.m^[hero].key,kleft);
  c:=-1;
  for c:=0 to map.n^[a].maxl do
    if map.n^[a].l[c].n=b then break;
  if map.n^[a].my<map.n^[b].my-16 then downed:=true else
  begin
    downed:=false;
    if map.n^[a].l[c].c and cjump>0 then include(map.m^[hero].key,kjump);
  end;
end;
begin
  if (ammo=0)and(weapon[weap].hit=0) then map.m^[hero].takenext;
  mx:=round(map.m^[hero].x);
  my:=round(map.m^[hero].y);
  dest:=map.m^[hero].dest;

  with map do
   if m^[hero].life then
   begin
    if (monster[m^[hero].tip].vis='fpuh')and(not m^[hero].ai)and(m^[hero].state=stand) then
     if random(100)=0 then m^[hero].setstate(hei,30);
    for i:=0 to maxitem do
     if item^[i].enable and not it[item^[i].tip].cant then
     if (abs(item^[i].x-mx)<16)and(abs(item^[i].y-my)<16)
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
{        12: map.m^[hero].damage(round(map.m^[hero].x),round(map.m^[hero].y),0,33,0,hero);}
      end;

   end;
  map.m^[hero].key:=[];
  if key[1] then endgame:=true;
  case bot of
  0:
   begin
     if key[2] then include(map.m^[hero].key,kleft);
     if key[3] then include(map.m^[hero].key,kright);
     if key[4] then include(map.m^[hero].key,katack);
     if key[5] then if not map.m^[hero].life then lose:=true else include(map.m^[hero].key,kjump);
     if key[6] then include(map.m^[hero].key,knext);
     if key[7] then include(map.m^[hero].key,kdown);
   end;
 1:begin {SuperAI - bots}
    mx:=map.m^[hero].mx;   my:=map.m^[hero].my;

    lastsee:=see;
{   if ((rtimer.hod mod 2)=(hero mod 2))then }see:=seeany;
   if (((rtimer.hod+2) mod 20)=(hero mod 20))then  goal:=getgoal;
    reset:=reset or((rtimer.hod mod 50)=(hero mod 50));
    if (not see)and(nextn>=0) then
    if (reset)or lastsee or (abs(map.n^[nextn].mx-mx)<12)and(
    ((not downed)and(abs(map.n^[nextn].my-my)<48)and(map.n^[nextn].my>=my))or(abs(map.n^[nextn].my-my)<8))
   then
    begin
       map.clearnode;
       reset:=false;
{      lastn:=curn;}
      curn:=map.getnode(mx,my);
      if curn=-1 then exit;
      if goal=-1 then exit;
      goal:=getgoal;
      wave(curn,goal);
      goal:=getpath;
      nextn:=find(goal);
      if nextn=-1 then exit;
    end;

    if see  then
    begin
      curn:=map.getnode(mx,my);

      if abs(seex)<16 then wmode:=0 else
      if abs(seex)>128 then wmode:=2 else
         wmode:=1;

      if skill>3 then map.m^[hero].takebest(wmode);

      if seey<0 then include(map.m^[hero].key,kjump);
      downed:=false;

      if (seex>0)and((dest=left)or(seex>botsee[skill])) then
         begin exclude(map.m^[hero].key,kleft); include(map.m^[hero].key,kright); end
       else
      if (seex<0)and((dest=right)or(seex<-botsee[skill])) then
         begin exclude(map.m^[hero].key,kright);include(map.m^[hero].key,kleft); end;

      include(map.m^[hero].key,katack);

     end

     else
       gotonode(curn,nextn);

      if downed then include(map.m^[hero].key,kdown);

     if not map.m^[hero].life then begin reset:=true; lose:=true; end;

  end;
 end;
end;
procedure titem.init(ax,ay,adx,ady:real; at:integer; af:boolean);
begin
  tobj.init(ax,ay,adx,ady,af);
  tip:=at;
  mx:=round(x);
  my:=round(y);
end;
procedure titem.draw(ax,ay:integer);
begin
  if it[tip].cant then dec(ay);
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
  pkey[port[$60] mod $80]:=port[$60]<$80;
{ for j:=1 to min(3,maxpl) do
  for i:=1 to maxkey do
    if port[$60]=ckey[j,i] then player[j].key[i]:=true;

 for j:=1 to min(3,maxpl) do
   for i:=1 to maxkey do
     if port[$60]=ckey[j,i]+$80 then player[j].key[i]:=false;}
 inline ($60);
 vec;
end;
{$f-}
procedure tmon.atack;
var l:shortint;
  sp,per,ry,d,ty:real;
  i,s:longint;
begin
  if (delay>0)or not life then exit;
  if weapon[weap].hit>0 then
  begin
    s:=20;
  for i:=0 to maxmon do
   if (map.m^[i].enable)and(map.m^[i].life) then
    if who<>i then
    if
    (map.m^[i].x>(x-s))and
    (map.m^[i].y>(y-s))and
    (map.m^[i].x<(x+s))and
    (map.m^[i].y<(y+s))
    then
      map.m^[i].damage(round(map.m^[i].x),round(map.m^[i].y-map.m^[i].getsy*6),weapon[weap].hit,0,0,who);
  end;
  delay:=round(weapon[weap].shot*mfps/speed);
  if (not ai)and(bul[weapon[weap].bul]<=0) then exit;
  dec(bul[weapon[weap].bul]);
  case dest of
   left: l:=-1;
   right: l:=1;
  end;
  ry:=0;
  sp:=weapon[weap].speed*l;
  per:=(rf.bul[weapon[weap].bul].per+weapon[weap].per)/100;
  if ai and sniper then
  begin
    d:=sqrt(sqr(target.x-x)+sqr(target.y-y));
    ty:=-(target.y-y)/d;
{    if ty>abs(target.x-x)/d*}
    ry:=ty*sp;
  end;
 for i:=1 to rf.bul[weapon[weap].bul].shot do
  map.initbul(x,y-monster[tip].h,
  sp*(1+random*per-per/2)+dx,
  sp*(random*per-per/2)+ry
  ,weapon[weap].pul,who);
  setstate(fire,0.1);
end;
function tmon.takeweap(n:tmaxweapon):boolean;
begin
  if not(n in w) then
    if (weapon[n].cool>=weapon[weap].cool) then weap:=n;
  if weap=0 then weap:=n;
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
function titem.getftr:real;
begin
  getftr:=0.5;
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
  if state in [run,hack,fire] then getftr:=1 else getftr:=0.5;
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
procedure tbul.draw(ax,ay:integer);
begin
{  tobj.draw(ax,ay);}
{  if bul[tip].rotate<>0 then
    p^[bul[tip].fly[1]].putrot(mx-ax,my-ay,cos(x/30),sin(x/30),0.75,0.75)
  else}
   if bul[tip].maxfly=1 then begin
     if (tip=4)and(dx<0) then
      p^[rocket2].spritec(mx-ax,my-ay)
     else
      p^[bul[tip].fly[1]].spritec(mx-ax,my-ay)
   end
  else
    p^[bul[tip].fly[(mx div bul[tip].delfly mod bul[tip].maxfly)+1]].spritec(mx-ax,my-ay);
end;
procedure tbul.move;
var i,ax,ay,sx,sy:integer;
begin
  dy:=dy+bul[tip].g*speed;
  x:=x+dx*speed; mx:=round(x); lx:=mx div 8;
  y:=y+dy*speed; my:=round(y); ly:=my div 8;
  if inwall(cwall) then
  begin
    for i:=0 to random(5)+5 do
      map.randompix(x-dx,y-dy,0,0,5,5,blow);
    detonate;
  end;
  for i:=0 to maxmon do
   if i<>who then
   if map.m^[i].enable then
   if not((map.m^[i].ai)and(map.m^[who].ai))or not rail then
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
      map.m^[i].damage(mx,my,bul[tip].hit,0,bul[tip].fire/speed*mfps,who);
      map.m^[i].dx:=map.m^[i].dx+dx*0.1;
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
      map.m^[i].damage(round(map.m^[i].x),round(map.m^[i].y-map.m^[i].getsy*6),0,bomb[tip].hit,bomb[tip].fired,who);
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
  if barrel then exit;
  if ai then
  begin
    if monster[tip].stay then map.inititem(x,y,dx,dy,monster[tip].defitem,false)
  end
  else
  begin
    for i:=1 to maxit do
     if it[i].weapon=weap then
     begin
       map.inititem(x,y,dx,dy,i,false);
       break;
     end;
  end;
end;
procedure tmon.dier;
begin
  if not life then exit;
  life:=false;
  if (map.m^[who].hero=0)and(who<>lastwho) then
      inc(player[map.m^[lastwho].hero].kill);
    if (hero>0)and(lastwho>0)then
    begin
      inc(player[hero].die);
      if who=lastwho then dec(player[hero].frag);
      if (map.m^[who].hero>0)and(who<>lastwho) then
       inc(player[map.m^[lastwho].hero].frag);
    end;
end;
procedure tmon.kill;
begin
  if not life then exit;
  setcurstate(die,monster[tip].diei.delay);
  giveweapon;
  dier;
end;
procedure tmon.explode;
begin
  if not life then exit;
  setcurstate(crash,monster[tip].bombi.delay);
  giveweapon;
  dier;
end;
procedure tmon.damage(ax,ay:integer; hit,bomb,coxy:real; dwho:integer);
var
  i:integer;
begin
  know:=true;
  if barrel and not life then exit;
  if god<>0 then exit;
{  if fired=0 then }
  fired:=fired+coxy{*byte(hero>0)};
  if armor=0 then
  health:=health-hit-bomb
  else
  begin
    health:=health-(hit+bomb)/5;
    armor:=armor-(hit+bomb)/3;
    if armor<0 then armor:=0;
  end;
  if dwho>0 then lastwho:=dwho;
  if health<=0 then {Kill monster}
  begin
    health:=0;
  end;
  setstate(hack,0.1);
  if not barrel then
  for i:=1 to min(64,round((hit+bomb)*10)) do
    map.randompix(ax,ay,dx,dy,5,5,blood)
  else
  for i:=1 to min(32,round((hit+bomb)*5)) do
    map.randompix(ax,ay,dx,dy,5,5,blow);
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
procedure tmon.move;
var i:integer;
begin
  if not life then begin inc(delay,2);
    if delay>truptime*mfps/speed then begin done; exit; end; end;
  if ai then moveai;
  if kleft in key then runleft;
  if kright in key then runright;
  if katack in key then atack;
  if kjump in key then jump;
  if knext in key then takenext;
  if kdown in key then begin down:=true; if inwall(cwater) then dy:=dy+monster[tip].jumpy*0.25; end
    else down:=false;
  tobj.move;
  if deldam>0 then dec(deldam);

  if inwall(clava) and (deldam=0) then
  begin
    damage(mx,my,0,5,2,0);
    deldam:=round(mfps/speed);
  end;

  if inwall(cfunc)then
   with map do
    for i:=0 to maxf do
     if f^[i].enable then
     if (mx>=f^[i].x)and (my>=f^[i].y)and
     (mx<=f^[i].x+f^[i].getsx)and (my<=f^[i].y+f^[i].getsy) then
      if f^[i].tip=12 then damage(x,y,0,33,0,hero);

  if deldam=0 then
  begin
    if inwall(cwater) then
    begin
      fired:=0; {OXY}
      deldam:=round(0.1*mfps/speed);
      if oxy>0 then oxy:=oxy-1;
      if (oxy=0)and(hero>0) then begin health:=health-1; oxylife:=oxylife+1; damage(mx,my,0,0,0,who);end;
    end else
    begin
      if oxy=0 then oxy:=20;
      if oxy<100 then
        begin
          oxy:=oxy+1; deldam:=round(0.15*mfps/speed);
          for i:=1 to 3 do map.randompix(mx,my,dx,dy,1,1,water);
        end;
      if oxylife>0 then
      begin
        if health<monster[tip].health then health:=health+1;
        oxylife:=oxylife-1;
        deldam:=round(0.2*mfps/speed);
      end;
    end;
  end;

  if not life and (delay>100) then fired:=0;
  if barrel and not life and not ai then
   if delay>mfps/speed*0.25 then
   begin
     map.initbomb(mx,my,barrelbomb,lastwho);
     ai:=true;
   end;
 if deldam=0 then
  if (fired>0) then
  begin
    map.initbomb(mx,my,bombfire,0);
    deldam:=round(0.1*mfps/speed);
  end;
  if fired>0 then damage(mx,my,0,oxysec*speed/mfps,0,0);
  fired:=fired-1;
  if fired<0 then fired:=0;
  if delay>0 then dec(delay);
  if god>0 then dec(god);
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
  if (state=stand)and(standing)and(not elevator)then
  begin
    if abs(dx)<monster[tip].brakes*ms2 then dx:=0 else
    case dest of
      left: if dx<0 then dx:=dx+monster[tip].brakes*ms2 else dx:=0;
      right: if dx>0 then dx:=dx-monster[tip].brakes*ms2 else dx:=0;
    end;
  end;
  if (curstate<>crash)and(curstate<>die)then curstate:=stand;
end;
procedure tmon.moveai;
procedure movesee;
var tx,ty,l:integer;
    d:real;
begin
  key:=[];
  see:=false;
  case dest of
   left:  l:=-1;
   right: l:=1;
  end;
  tx:=lx;
  ty:=ly-2;
{  if sniper then
  begin
    d:=sqrt(sqr(target.x-x)+sqr(target.y-y));
    ddy:=(target.y-y)/d;
  end;}
{  if ddy>10 then exit;}
  if (ty>0)and(ty<map.y)then
  repeat
    tx:=tx+l;
{    ry:=ry+ddy;}
    {error}
{    ty:=round(ry*8);}
    if (ty<=0)or(ty>=map.y-1)or(tx<=0)or(tx>=map.x-1) then break;
    case sniper of
     false: if (abs(target.x-tx*8)<16)and(abs(target.y-ty*8)<32)then begin see:=true; break; end;
     true:  if (abs(target.x-tx*8)<32)and(abs(target.y-ty*8)<(abs(target.x-tx*8)))then begin see:=true; break; end;
    end;
    if (map.land[ty]^[tx].land and cwall)>0 then begin see:=false; break; end;
  until false;
  if ((abs(target.x-x)+abs(target.y-y))<32)and(sniper) then see:=true;
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
  if rtimer.hod mod 10=(who mod 10) then movesee;
  if (not see)and not look and (random(300)=0)then know:=false;
  if (know){and(tar>0)} then
  begin
    if sniper then
    begin
     if (dest=left)and(target.x>self.x) then include(key,kright) else
     if (dest=right)and(target.x<self.x) then include(key,kleft);
    end;
    if not see then
     if (abs(target.x-self.x)>10) then
     begin
      if target.x<self.x then include(key,kleft) else include(key,kright);
     end
     else
    if random(300)=0 then include(key,kjump);
    if (weap=1)or((fired>0)and(sniper)) then if target.x<self.x then include(key,kleft) else include(key,kright);
  end;
  if see then begin include(key,katack); know:=true; end;
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
  if inwall(cwall) then
  begin
    ly:=ly-1;
    if not inwall(cwall) then begin savey:=y-8; end;
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
procedure ted.reload;
var j:longint;
begin
  for j:=1 to maxt do land.t[j].b:=0;
  for j:=1 to land.maxtt do
   if j+land.ch<=maxallwall then
     land.t[j].b:=loadbmp(allwall^[j+land.ch]);
end;
procedure ted.draw;
const ddd=60;
var i,j:longint;
begin
  map.draw;
  if cool or (what=wall) then map.drawhidden;
  for i:=0 to maxf do if map.f^[i].enable then map.f^[i].draw(map.dx,map.dy,i);
  map.drawnodes;
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
{   node:
   begin
     for i:=1 to 4 do print(0,scry+i*10,
     white-30*byte(0<(nodes.mask and (1 shl (i-1)))),ednodestr[i]);
   end;}
   face: with land do
   begin
     for i:=1 to maxtt do
      if (i+ch<=maxallwall)and(t[i].b<>0) then
     begin
       if i+ch=cur then bar(t[i].x-1,t[i].y-1,t[i].x+p^[t[i].b].x+1,t[i].y+p^[t[i].b].y,white);
        p^[t[i].b].sprite(t[i].x,t[i].y);
     end;
   end;
  end;
  if what=node then
  with nodes do
  begin
    if push>0 then
      line(sx-map.dx,sy-map.dy,mx,my,blue);
  end;
  for i:=1 to maxedmenu do
   if i=cured then
     print(scrx,(i-1)*10,white,edmenustr[i])
   else
     print(scrx,(i-1)*10,red,edmenustr[i])
end;
function mo(x1,y1,x2,y2:integer):boolean;
begin
  if (mx>=x1)and(my>=y1)and(mx<=x2)and(my<=y2)then mo:=true else mo:=false;
end;
procedure ted.move;
var
  i,freex,j:longint;
  s:string;
  ok:boolean;
begin
  reload;
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
        wb.print(100,50,'Записать');
        s:=enterfile(map.name);
        if s<>'' then begin map.name:=s; map.save; end;
      end;
   3: begin
        wb.print(100,50,'Загрузить');
        s:=enterfile(map.name);
        if s<>'' then map.load(s);
      end;
    4: begin
         wb.print(100,50,'Новая карта');
         s:='yes';
         readline(100,100,s,s,white,0);
         if downcase(s)='yes'then
         begin
           map.done;
           map.create(defx,defx,0,0,defname);
           map.clear;
           wb.print(100,110,'Авторские права');
           s:='Создал: ';
           readline(1,160,map.copy,s,white,0);
           map.initnode(32,32,nodes.mask);
         end;
       end;
    5: begin scry:=getmaxy-50; what:=face;  end;
    6:  begin scry:=getmaxy-50; what:=wall; end;
    7:  begin scry:=getmaxy-50; what:=mons; end;
    8:  begin scry:=getmaxy-50; what:=items;end;
    9:  begin scry:=getmaxy-50; what:=func; end;
    10: begin cool:=not cool; repeat until not mouse.push; end;
    11: begin scry:=getmaxy; what:=node; end;
    12:begin
         wb.print(100,50,'Комментарии');
{         readline(1,100,map.copy,map.copy,white,0);}
         readline(1,100,map.com,map.com,white,0);
       end;
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
{     node:begin
       repeat until not mouse.push;
       i:=(my-scry)div 10;
       nodes.mask:=nodes.mask xor (1 shl (i-1));
     end;}
     face: with land do
      begin
        if mx>=(getmaxx-4) then    inc(ch)
          else
        if (mx<=4)and(ch>0) then  dec(ch)
          else
        for i:=1 to maxtt do if mo(t[i].x-1,t[i].y-1,t[i].x+p^[t[i].b].x,t[i].y+p^[t[i].b].y) then
        begin
          curname:=p^[t[i].b].name;
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
          map.initmon((mx+map.dx),(my+map.dy),cur,tdest(random(2)),true,true,0);
          repeat until not mouse.push;
        end;
        items:with itm do
        begin
          map.inititem((mx+map.dx),(my+map.dy),0,0,cur,true);
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
       node: {**********************NODE********************}
         if nodes.push=0 then
         with nodes do
         begin
           push:=1;
           sx:=mx+map.dx; sy:=my+map.dy;
           cur:=-1;
           for i:=0 to maxnode do
           if map.n^[i].enable then
             if (abs(map.n^[i].mx-sx)<=4)and(abs(map.n^[i].my-sy)<=4) then
             begin
               cur:=i;
               break;
             end;
           end;
       end;
     end;
     if push3 then
     case what of
       node: {**********************NODE********************}
         if nodes.push=0 then
         with nodes do
         begin
           push:=3;
           sx:=mx+map.dx; sy:=my+map.dy;
           cur:=-1;
           for i:=0 to maxnode do
           if map.n^[i].enable then
             if (abs(map.n^[i].mx-sx)<=4)and(abs(map.n^[i].my-sy)<=4) then
             begin
               cur:=i;
               break;
             end;
        end;
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
         node: {**********************NODE********************}
         if nodes.push=0 then
         with nodes do
         begin
           push:=2;
           sx:=mx+map.dx; sy:=my+map.dy;
           cur:=-1;
           for i:=0 to maxnode do
           if map.n^[i].enable then
             if (abs(map.n^[i].mx-sx)<=4)and(abs(map.n^[i].my-sy)<=4) then
               cur:=i;
           end;
     end;
  if what=node then
  begin
    if (not push and (nodes.push=1))
    or (not push3 and (nodes.push=3))
    then
    with nodes do
    begin
     ok:=false;
     if cur>=0 then
      for i:=0 to maxnode do
       if map.n^[i].enable then
        if cur<>i then
       if (abs(map.n^[i].mx-mx-map.dx)<=4)and(abs(map.n^[i].my-my-map.dy)<=4) then
       begin
         if nodes.push=1 then map.n^[i].xorlink(cur,0);
         map.n^[cur].xorlink(i,0);
         break;
       end;
      if cur=-1 then
         map.initnode(map.dx+mx,map.dy+my,nodes.mask);
      push:=0;
    end;

    if not push2 and (nodes.push=2)then
    with nodes do
    begin
     ok:=false;
     if cur>=0 then
      for i:=0 to maxnode do
       if map.n^[i].enable then
        if cur<>i then
       if (abs(map.n^[i].mx-mx-map.dx)<=4)and(abs(map.n^[i].my-my-map.dy)<=4) then
       begin
         map.n^[i].xorlink(cur,cjump);
         map.n^[cur].xorlink(i,cjump);
         ok:=true;
         break;
       end;
      if (cur<>-1)and(not ok) then
      begin
        if (abs(sx-mx-map.dx)>1)or(abs(sy-my-map.dy)>1)
         then
          begin
            map.n^[cur].x:=mx+map.dx;
            map.n^[cur].y:=my+map.dy;
            map.n^[cur].mx:=round(map.n^[cur].x);
            map.n^[cur].my:=round(map.n^[cur].y);
            map.n^[cur].lx:=map.n^[cur].mx div 8;
            map.n^[cur].ly:=map.n^[cur].my div 8;
          end
          else
          begin
            map.n^[cur].done;
            for i:=0 to maxnode do
             if map.n^[i].enable then
               map.n^[i].dellink(cur);
         end;
      end;
      push:=0;
    end;
  end;
  freex:=0;
   for i:=1 to maxt do
    with land,t[i] do
    begin
      y:=scry+2;
      x:=freex;
      maxtt:=i;
      freex:=freex+p^[b].x+2;
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
  initf:=0;
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
  initbomb:=0;
end;
function tmap.initnode;
var i:longint;
begin
  for i:=0 to maxnode do
    if not n^[i].enable then
    begin
      n^[i].init(ax,ay,ac,i);
      initnode:=i;
      exit;
    end;
  initnode:=0;
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
  initbul:=0;
end;
function tmap.initmon;
var i:longint;
begin
  for i:=0 to maxmon do
    if not m^[i].enable then
    begin
      m^[i].init(ax,ay,0,0,at,ad,i,ai,af,ah);
      initmon:=i;
      exit;
    end;
  initmon:=0;
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
  initpix:=0;
end;
function tmap.inititem;
var i:longint;
begin
  for i:=0 to maxitem do
    if not item^[i].enable then
    begin
      item^[i].init(ax,ay,adx,ady,at,af);
      inititem:=i;
      exit;
    end;
  inititem:=0;
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
  x1,y1,x2,y2,i,j,ti,tj:longint;
  br:boolean;
begin
  dy:=dy+map.g*speed;
  savex:=x;
  savey:=y;
  x:=x+dx*speed; mx:=round(x); lx:=mx div 8;

  if (inwall(cFunc)){or(inwall(cButton))} then begin
   with map do
    for i:=0 to maxf do
     if f^[i].enable then
     if
     (mx>=f^[i].x)and
     (my>=f^[i].y)and
     (mx<=f^[i].x+f^[i].getsx)and
     (my<=f^[i].y+f^[i].getsy)
      then case f^[i].tip of
{        10: win:=true;
        11: lose:=true;
        12: map.m^[hero].damage(round(map.m^[hero].x),round(map.m^[hero].y),0,33,0,hero);}
        13{Teleport}: begin
          self.x:=self.x+(f^[i+1].x-f^[i].x);
          self.y:=self.y+(f^[i+1].y-f^[i].y);
        end;
        15,16{Open Door}: begin
          j:=i+1;
          for ti:=(round(f^[j].x) div 8) to  round(f^[j].x+f^[j].sx) div 8 do
            for tj:=(round(f^[j].y) div 8) to  round(f^[j].y+f^[j].sy) div 8 do begin
              land[tj]^[ti].vis:=byte(f^[i].tip=16);
              land[tj]^[ti].land:=byte(f^[i].tip=16);
            end;
        end;
      end;
  end;

  if inwall(cwall) then
  begin
    x:=savex;
    dx:=-dx*getupr;
    dy:=dy*getftr;
    mx:=round(x); lx:=mx div 8;
  end;
  y:=y+dy*speed; my:=round(y); ly:=my div 8;
  if inwall(cwall) then
  begin
    y:=savey;
    dy:=-dy*getupr;
    dx:=dx*getftr;
    my:=round(y); ly:=my div 8;
  end;
  elevator:=false;
  standing:=getstand;


  x1:=lx-getsx div 2; x2:=x1+getsx-1;  y2:=norm(0,map.y,ly);
  if not down then
  for i:=max(0,x1) to min(map.x,x2) do
  begin
   br:=false;
   if map.land[y2]^[i].land and cwater>0 then
   begin
     standing:=true;
     dx:=dx*0.95;
     dy:=dy*0.97;
     br:=true;
   end;
   if map.land[y2]^[i].land and cstand>0 then
   begin
     standing:=true;
     elevator:=true;
     dy:=-dy*getupr;
     y:=y-1;  my:=round(y); ly:=my div 8;
     br:=true;
   end;
   if map.land[y2]^[i].land and cshl>0 then
   begin
     standing:=true;
     elevator:=true;
     dy:=-dy*getupr;
     y:=y-1; x:=x-1; dx:=-1; my:=round(y); ly:=my div 8;
     br:=true;
   end;
   if map.land[y2]^[i].land and cshr>0 then
   begin
     standing:=true;
     elevator:=true;
     dy:=-dy*getupr;
     y:=y-1; x:=x+1; dx:=1; my:=round(y); ly:=my div 8;
     br:=true;
   end;
   if br then break;
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
  print(mx-ax,my-ay,white,fname[cur].name+' - '+st(id));
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
procedure tmon.init(ax,ay,adx,ady:real; at:tmaxmontip; ad:tdest; aw:longint; aai,af:boolean; ah:longint);
begin
  fillchar(bul,sizeof(bul),0);
  fillchar(w,sizeof(w),0);
  tobj.init(ax,ay,adx,ady,af);
  hero:=ah;
  w:=[]; weap:=0;
  delay:=0; deldam:=0; oxy:=100; oxylife:=0;
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
  takeitem(freeitem);
  if ai then takeitem(monster[tip].defitem)
        else
  begin
    takeitem(playdefitem);
    weap:=it[playdefitem].weapon;
  end;
  mx:=round(x); my:=round(y);
  dx:=0; dy:=0;
  know:=false; see:=false;
  barrel:=monster[tip].h=0;
  if barrel then begin ai:=false; dest:=left;end;
  key:=[];
end;
procedure tobj.init(ax,ay,adx,ady:real; af:boolean);
begin
  enable:=true;
  down:=false;
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
function tobj.inwall(c:byte):boolean;
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
    if map.land[j]^[i].land and c>0 then begin inwall:=true; exit; end;
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
procedure tmap.deputpat(ax,ay:longint);
var
  i,j,w,i2,j2:longint;
begin
{  pset(ax,ay,0,0);}
  if ax>=x then ax:=x-1;
  if ay>=y then ay:=y-1;
  for i:=ax downto max(0,ax-32) do
    for j:=ay downto max(0,ay-32) do
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
{FOR save and load}
var
  nodes:record
    x,y: integer;
    c: byte;
    maxl:shortint;
    l:array[0..maxlink]of
    record
      n:tmaxnode;
      c:byte;
    end;
    index:integer;
  end;
  reserved: array[0..16]of byte;
procedure tmap.load(s:string);
var
  ff:file;
  capt:tcapt;
  mpat,mmon,mitem,mf,mnode,i,j,cn:longint;
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
  ver: integer;
begin
  done;
  name:=s;
  assign(ff,name+levext);
  reset(ff,1);
  ver:=-1;
  blockread(ff,capt,sizeof(capt));
  if capt=lever00 then ver:=0 else
  if (capt[1]=origlev[1])and(capt[2]=origlev[2]) then
  begin
    ver:=vl(system.copy(capt,3,2));
  end;
  if ver=-1 then begin close(ff); exit; end;
  begin
    done;
{    if first then for i:=1 to 4 do player[i].done;}
    blockread(ff,x,4);
    blockread(ff,y,4);
    blockread(ff,dx,4);
    blockread(ff,dy,4);
    blockread(ff,mpat,4);
    blockread(ff,mmon,4);
    blockread(ff,mitem,4);
    blockread(ff,mf,4);
  if ver>0 then
  begin
    blockread(ff,mnode,4);
    blockread(ff,reserved,16);
  end;
  copy:='';
  com:='';
  if ver>1 then
  begin
    blockread(ff,copy,256);
    blockread(ff,com,256);
  end;
    map.clear; {delete all records}
    create(x,y,dx,dy,name);
    for i:=0 to y-1 do
      blockread(ff,land[i]^,x*2);
    deletepat;
    blockread(ff,patname^,mpat*9+9);
    for i:=0 to mmon-1 do
    begin
      blockread(ff,mon,sizeof(mon));
      initmon(mon.x,mon.y,mon.tip,mon.dest,true,true,0);
    end;
    for i:=0 to mitem-1 do
    begin
      blockread(ff,itm,sizeof(itm));
      inititem(itm.x,itm.y,0,0,itm.tip,true);
    end;
    for i:=0 to mf-1 do
    begin
      blockread(ff,func,sizeof(func));
      initf(func.x,func.y,func.sx,func.sy,func.tip);
    end;
    if not editor then
    if not death then
    for i:=0 to maxf-1 do
     if f^[i].enable then
      case f^[i].tip of
        1,2,3,4:
         if f^[i].tip<=maxpl then player[f^[i].tip].reinit(round(f^[i].x),round(f^[i].y),player[f^[i].tip].deftip,f^[i].dest);
      end;

  if not editor then
  if death then
   for j:=1 to maxpl do
   repeat
    with f^[random(maxf)] do
    if enable and(tip=5)then
       begin
         player[j].reinit(round(x),round(y),player[j].deftip,dest);
         break;
        end;
    until false;

 if ver>0 then
   for i:=0 to mnode-1 do
   begin
     blockread(ff,nodes,sizeof(nodes));
     cn:=nodes.index;
     n^[cn].init(nodes.x,nodes.y,nodes.c,cn);
     for j:=0 to nodes.maxl do
      if nodes.l[j].n<>cn then
       map.n^[cn].addlink(nodes.l[j].n,nodes.l[j].c);
    end;
    reloadpat;
  end;
  close(ff);
  deltanode;
end;
procedure tmap.save;
var
  ff:file;
  mpat,mmon,mitem,mf,i,j,mnode:longint;
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
  assign(ff,name+levext);
  rewrite(ff,1);
  blockwrite(ff,origlev,sizeof(origlev));
  blockwrite(ff,x,4);
  blockwrite(ff,y,4);
  blockwrite(ff,dx,4);
  blockwrite(ff,dy,4);
  for mpat:=1 to 255 do if patname^[mpat]='' then break;
  blockwrite(ff,mpat,4);
  mmon:=0;
  for i:=0 to maxmon do if m^[i].enable then inc(mmon);      blockwrite(ff,mmon,4);
  mitem:=0;
  for i:=0 to maxitem do if item^[i].enable then inc(mitem); blockwrite(ff,mitem,4);
  mf:=0;
  for i:=0 to maxf do if f^[i].enable then inc(mf);          blockwrite(ff,mf,4);
  mnode:=0;
  for i:=0 to maxnode do if n^[i].enable then inc(mnode);    blockwrite(ff,mnode,4);
  blockwrite(ff,reserved,16);
  blockwrite(ff,copy,256);
  blockwrite(ff,com,256);

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
  for i:=0 to maxnode do
    if n^[i].enable then
    begin
       nodes.index:=i;
       nodes.x:=n^[i].mx;
       nodes.y:=n^[i].my;
       nodes.maxl:=n^[i].maxl;
       nodes.c:=n^[i].c;
       for j:=0 to nodes.maxl do
        begin
          nodes.l[j].n:=n^[i].l[j].n;
          nodes.l[j].c:=n^[i].l[j].c;
        end;
       blockwrite(ff,nodes,sizeof(nodes));
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
  for i:=0 to maxpix do  if pix^[i].enable  then pix^[i]. draw(-minx+dx,-miny+dy);
  for i:=0 to maxitem do if item^[i].enable then item^[i].draw(-minx+dx,-miny+dy);
  for i:=0 to maxmon do  if m^[i].enable    then m^[i].   draw(-minx+dx,-miny+dy);
  for i:=0 to maxexpl do if e^[i].enable    then e^[i].   draw(-minx+dx,-miny+dy);
  for i:=0 to maxpul do  if b^[i].enable    then b^[i].   draw(-minx+dx,-miny+dy);
end;
procedure tmap.drawhidden; {40x25}
var i,j:longint;
    x1,y1,x2,y2:integer;
function getcol(a:byte):byte;
begin
  getcol:=0;
  if a and cwall>0 then getcol:=white;
  if a and cstand>0 then getcol:=green;
  if a and clava>0 then getcol:=red;
  if a and cwater>0 then getcol:=blue;
  if a and cshl>0 then getcol:=grey;
  if a and cshr>0 then getcol:=dark;
  if a and cFunc>0 then getcol:=blue;
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
       rectangle2(i*8+1-x2,j*8+1-y2,i*8+6-x2,j*8+6-y2,getcol(land[j+y1]^[i+x1].land));
end;
procedure tmap.drawnodes;
var i:integer;
begin
  for i:=0 to maxnode do if n^[i].enable then n^[i].draw(-minx+dx,-miny+dy);
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
  fillchar32(n^,0,sizeof(n^),0);        for i:=0 to maxnode do n^[i].new;
  fillchar32(e^,0,sizeof(e^),0);
  if (x<>0)and(land[1]<>nil) then
  begin
  for i:=0 to defy-1 do
    begin
      fillchar(land[i]^,defx*2,0);
    end;
    for i:=0 to y-1 do putpat(i,0,1,1);
    for i:=0 to y-1 do putpat(i,x-1,1,1);
    for i:=0 to x-1 do putpat(0,i,1,1);
    for i:=0 to x-1 do putpat(y-1,i,1,1);
  end;
end;
procedure tmap.new;
var i:longint;
begin
  system.new(m);
  system.new(item);
  system.new(f);
  system.new(pix);
  system.new(b);
  system.new(n);
  system.new(e);
  x:=0;
  clear;
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
    for i:=0 to maxmust do
     if must[i].tip<>0 then
      if must[i].delay>0 then dec(must[i].delay) else
      with must[i] do
      begin
        case tip of
         1: initmon(x,y,curtip,dest,true,true,0);
         2: inititem(x,y,0,0,curtip,true);
        end;
        tip:=0;
        initbomb(x,y-16,reswapbomb,0);
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
procedure loadwalls;
var dat:text;
  k,i:longint;
begin
  assign(dat,'wall.dat');
  reset(dat);
  k:=0;
  while not seekeof(dat) do begin readln(dat); inc(k);end;
  close(dat);

  assign(dat,'wall.dat');
  reset(dat);
{  readln(dat,k);}
{  if debug and(k>10) then k:=10;}
  getmem(allwall,(k+1)*9);
  for i:=1 to k do
  begin
    readln(dat,allwall^[i]);
{    loadbmp(allwall^[i]);}
  end;
  maxallwall:=k;
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
  for i:=1 to maxmontip do
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
      if s1='pul' then pul:=vl(s2);
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
   with weapon[i] do
   if name<>'' then
   begin
     skin:=loadbmp(vis);
     damages:=0; bomb:=0;
     if hit>0 then damages:=damages+hit/shot;
     damages:=damages+rf.bul[pul].shot*rf.bul[pul].hit/shot;
     damages:=damages+rf.bomb[rf.bul[pul].bomb].hit/shot;
     if rf.bul[bul].bomb>0 then bomb:=rf.bomb[rf.bul[pul].bomb].hit;
   end;
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
   begin
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
      if s1='god' then god:=vlr(s2);
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
var
  men:array[0..100]of string[40];
procedure loadbots(name:string);
var
  f:text;
  s,s1,s2:string;
  nm,i,j:longint;
begin
  assign(f,botdir+name);
  reset(f);
  while not eof(f) do
  begin
    readln(f,s);
    if (s[1]=';')or(s='')or(s[1]='/')or
    ((pos('=',s)=0)and(s[1]<>'['))then continue;
    if s[1]='[' then begin nm:=vl(copy(s,2,length(s)-2)); continue; end;
    i:=pos('=',s);
    if i>0 then
    with bot[nm] do
    begin
      s1:=downcase(copy(s,1,i-1));
      s2:=copy(s,i+1,length(s)-i);
      if s1='players' then maxallpl:=vl(s2);
      if s1='debug' then if s2='on' then debug:=true;

      if s1='name' then name:=s2;
      if s1='bot' then bot:=vl(s2);
      if s1='tip' then tip:=vl(s2);
      if s1='screen' then
      begin
       if s2='all' then scr:=all;
       if s2='up' then scr:=up;
       if s2='down' then scr:=down;
       if s2='none' then scr:=none;
       if s2='up-left' then scr:=ul;
       if s2='up-right' then scr:=ur;
       if s2='down-left' then scr:=dl;
       if s2='down-right' then scr:=dr;
      end;
    end;
  end;
  close(f);
end;
function menu(max:integer):integer;
var
  ch,hod,enter,i,maxl:integer;
const
  x1:integer=80;
  y1:integer=50;
  d=22;
procedure draw;
var i,j,sx,sy:integer;
begin
  clear;
{  putintro('intro'); Update - }
  sx:=(getmaxx-p^[intro].x) div 2;
  sy:=(getmaxy-p^[intro].y) div 2;

  p^[intro].put(sx,sy);

  rb.print(getmaxx div 2-152,getmaxy-10,shortintro);

  for i:=1 to max do
    wb.print(x1,y1+(i-1)*d,men[i]);
  if hod mod 90<45 then j:=skull1 else j:=skull2;
  p^[j].sprite(x1-30,y1-5+(ch-1)*d);

  screen;
end;
begin
  maxl:=10;
  for i:=1 to max do
    if length(men[i])>maxl then maxl:=length(men[i]);
  x1:=(getmaxx-maxl*15)div 2;
  if x1<30 then x1:=30;
  endgame:=false;
  ch:=1;  hod:=0; enter:=0;
  repeat
    inc(hod);
    y1:=(getmaxy-max*d)div 2;
    if y1<30 then y1:=30;
    if (y1+(ch-1)*d>getmaxy-30)then y1:=-(ch-1)*d+getmaxy-30;
    draw;
    if keypressed then
    case crt.readkey of
      #13: enter:=ch;
      #27: break;
      #9:  ch:=(ch)mod max+1;
      #0:case crt.readkey of
        #80: if ch<max then inc(ch);
        #72: if ch>1 then dec(ch);
       end;
    end;
  until enter>0;
  menu:=enter;
  while keypressed do readkey;
end;
procedure botmenu;
const
  max=32;
var
  c:array[1..max] of string[32];
{  (
  (name:'Бот x Игрок';     bot:'bot1x1'),
  (name:'2 Игрока';        bot:'bot2x0'),
  (name:'3 Игрока';        bot:'bot3x0'),
  (name:'4 Игрока';        bot:'bot4x0'),
  (name:'Бот x 2 Игрока';    bot:'bot2x1'),
  (name:'2 Бота x 2 Игрока'; bot:'bot2x2'),
  (name:'2 Бота x 1 игрок';  bot:'bot1x2'),
  (name:'3 Бота x 1 игрок';  bot:'bot1x3'),
  (name:'4 Бота';          bot:'bot0x4')
  );}
var
  s:integer;
  g:searchrec;
  f:text;
begin
  findfirst(botdir+'bot*.ini',anyfile,g);
  s:=0;
  while doserror=0 do
  begin
    inc(s);
    c[s]:=g.name;
    assign(f,g.name);
    reset(f);
    readln(f,men[s]);
    close(f);
    findnext(g);
  end;
  s:=menu(s);
  if s<>0 then
   loadbots(c[s]);
end;
function skillmenu:integer;
var s:integer;
begin
  men[1]:='Проще пареной репы';
  men[2]:='Для сельской местности';
  men[3]:='Норма';
  men[4]:='Жизнь';
  men[5]:='Кошмар';
  s:=menu(5);
  skillmenu:=s;
  case s of
   1: begin reswap:=false;reswaptime:=30; monswaptime:=240; rail:=false; look:=false;sniper:=false; end;
   2: begin reswap:=false;reswaptime:=60; monswaptime:=180; rail:=false; look:=true; sniper:=false; end;
   3: begin reswap:=false;reswaptime:=90; monswaptime:=120; rail:=true;  look:=true; sniper:=false; end;
   4: begin reswap:=false;reswaptime:=120;monswaptime:=60;  rail:=true;  look:=true; sniper:=true; end;
   5: begin reswap:=true; reswaptime:=300;monswaptime:=30;  rail:=true;  look:=true; sniper:=true; end;
  end;
end;
procedure gamemenu;
begin
  endgame:=false;
  men[1]:='продолжить';
  men[2]:='выход';
  case menu(2) of
   0,1: endgame:=false;
   2: endgame:=true;
  end;
end;
function getlevel:string;
var
  s:searchrec;
  max:integer;
begin
  findfirst('*'+levext,anyfile,s);
  max:=0;  men[max]:='';
  while doserror=0 do
  begin
    inc(max);
    men[max]:=getfilename(s.name);
    findnext(s);
  end;
  getlevel:=men[menu(max)];
end;
procedure mainmenu;
var s:string;
begin
 repeat
   first:=false;
   men[1]:='ОДИН игрок';
   men[2]:='вместе';
   men[3]:='бой';
   men[4]:='редактор';
   men[5]:='выход';
   case menu(5) of
    1: begin
         level.name[1]:=level.savefirst;
         skill:=skillmenu;
         first:=skill<>0;
         level.cur:=0;
         editor:=false;
         multi:=false;
         death:=false;
       end;
    2: begin
         botmenu;
         level.name[1]:=level.savefirst;
         skill:=skillmenu;
         first:=skill<>0;
         level.cur:=0;editor:=false; multi:=true; death:=false;
       end;
    3: begin
         botmenu;
         level.name[1]:=level.savefirst;
         skill:=skillmenu;
         first:=skill<>0;
         if first then
         begin
           s:=getlevel;
           if s<>'' then
              level.name[1]:=s;
         end;
         level.cur:=0;
         editor:=false; multi:=true; death:=true;
         reswap:=true;
       end;
    4: begin debug:=true; editor:=true;first:=true;end;
    0,5: begin endgame:=true; first:=true;end;
   end;
 until first;
end;
procedure drawwin;
var t:tnpat;
begin
  box(0,0,getmaxx,getmaxy);
  if putbmpall('win'+st(random(maxwin)+1)) then
    delay(1);
end;
procedure drawlose;
var t:tnpat;
begin
  box(0,0,getmaxx,getmaxy);
  if putbmpall('lose'+st(random(maxlose)+1)) then
    delay(1);
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
{procedure weaponinfo;
var i:integer;
begin
  writeln;
  for i:=0 to maxweapon do
   with weapon[i] do
   if name<>'' then
   begin
     write(name:16,' - ',damages:6:2);
     if bomb>0 then write(' / BOMB ',bomb:6:2);
     writeln;
   end;
 end;}
(******************************** PROGRAM ***********************************)
var
  i,j:longint;
  adelay:longint;
  lev:string;
begin
{Main Loading}
  w.load(wadfile);
  p^[0].load('bmp\error.bmp');
  loadres;
  write(load[1]);  loadbots('bot.ini');
  write(load[2]);  loadwalls;
  write(load[3]);  loadbombs;
  write(load[4]);  loadbullets;
  write(load[5]);  loadweapons;
  write(load[6]);  loaditems;
  write(load[7]);  loadmonsters;
  write(load[8]);  loadfuncs;
  level.loadini;
  wb.load('stbf_',10,1); rb.load('stcfn',5,2);
  skull1:=loadbmp('skull1'); skull2:=loadbmp('skull2');
  intro:=loadbmp('intro');
  rocket2:=loadbmp('rocketl');
  pnode:=loadbmp('node');  pnodei:=loadbmp('nodei');  pnodeg:=loadbmp('nodeg');
  for i:=0 to 9 do d[i]:=loadbmp('d'+st(i)); dminus:=loadbmp('dminus'); dpercent:=loadbmp('dpercent');
  cur:=loadbmp('cursor'); for i:=1 to 7 do en[i]:=loadbmp('puh'+st(i));
  heiskin[left]:=loadbmp('hai');  heiskin[right]:=loadbmpr('hai');
{Init Screen...}
  writeln('Free RAM: ',memavail);
  initgraph(res); loadfont('8x8.fnt'); clear; mfps:=30; loadpal('playpal.bmp');
  if accel<>-1 then setaccelerationmode(accel);
{Load first level}
  first:=true;
  map.new;
  map.g:=9.8*ms2;
 repeat
  mainmenu;
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
    map.addpat(allwall^[1]);
  end;


  if not editor then
  begin
{    level.loadfirst;}
    level.next;
  end;

  {Start game}
  keybuf:='';
  if not editor then drawintro;
  GetIntVec($9,@vec);  SetIntVec($9,Addr(keyb));
  speed:=1;
  endgame:=false;
  time.clear;rtimer.clear; time.fps:=mfps;
  winall:=false;
  if not editor then
  begin
    ddx:=1; ddy:=1;  Sensetivity(1,1);
  end
  else
  begin
    ddx:=6; ddy:=6;    Sensetivity(12,12);
  end;
  mousebox(0,0,getmaxx,getmaxy);
  repeat
    rtimer.easymove;time.move;  mx:=mouse.x;  my:=mouse.y; push:=mouse.push; push2:=mouse.push2;push3:=mouse.push3;
    case res of
     0,1: add:=1;
     2: add:=7;
    end;
    lastx:=mx-getmaxx div 2+add;
    lasty:=my-getmaxy div 2;
    if not editor {and(rtimer.hod mod 10=0)}then
    begin
      setMouseCursor(getmaxx div 2,getmaxy div 2);
    end;

   if player[mousepl].bot=0 then
   with player[mousepl] do
   begin
     key[kright]:=lastx>0;
     key[kleft]:=lastx<0;
     key[kdown]:=lasty>0;
     key[kjump]:=lasty<-36;
     key[katack]:=push;
     key[knext]:=push2;
   end;
    {Manual}
    while keypressed do
    begin
      if length(keybuf)=255 then keybuf:=copy(keybuf,2,254);
      keybuf:=keybuf+downcase(readkey);

     if pos('debug',keybuf)>0 then begin debug:=not debug;  keybuf:='';end;
     if pos('lev',keybuf)>0 then
         begin
           j:=pos('lev',keybuf)+3;
           lev:=copy(keybuf,j,length(keybuf));
           if pos('lev',lev)>0 then
             keybuf:=copy(keybuf,j,length(keybuf));
          with level do
           for i:=1 to max do
            if lev=downcase(name[i]) then begin cur:=i-1; j:=0; break; end;
          if j=0 then
          begin
           for i:=1 to maxpl do
              player[i].win:=true;
            keybuf:='';
          end;
        end;

{      if not reswap then
        if not death then
      begin}
       if pos('god',keybuf)>0 then
         begin
           for i:=1 to maxpl do
            if map.m^[player[i].hero].god=0 then map.m^[player[i].hero].god:=-1
            else map.m^[player[i].hero].god:=0;
           keybuf:='';
          end;
       if pos('kill',keybuf)>0 then
         begin
           for i:=1 to maxpl do
              map.m^[player[i].hero].damage(map.m^[player[i].hero].mx,map.m^[player[i].hero].my,0,10000,100,0);
           keybuf:='';
          end;
       if pos('all',keybuf)>0 then
         begin
           for i:=1 to maxpl do
            for j:=1 to 39 do
              map.m^[player[i].hero].takeitem(j);
           keybuf:='';
          end;
       if pos('tank',keybuf)>0 then
         begin
           for i:=1 to maxpl do
            for j:=41 to 60 do
              map.m^[player[i].hero].takeitem(j);
           keybuf:='';
        end;
      end;
{      end;}
    for i:=1 to maxpl do player[i].move;
    {Move}
    map.move;
    if not multi then
      endgame:=endgame or player[1].lose or player[1].win
     else
     for i:=1 to maxpl do
       endgame:=endgame or player[i].win;
   if multi then
    for i:=1 to maxpl do
     if player[i].lose then
       player[i].initmulti;
    if editor then ed.move;
    {Draw}
    clear;
    for i:=1 to maxpl do player[i].draw;
    if editor then ed.draw;
    rb.print(getmaxx-24,getmaxy-8,st0(round(rtimer.fps),3));
    if editor then p^[cur].sprite(mx,my);

    screen;
{    speed:=1;}
    if time.fps<>0 then speed:=mfps/time.fps;
    if speed>5 then speed:=5;
    if (not editor)and sfps then
    begin
      speed:=1;
      adelay:=round(adelay+(time.fps-mfps)*1000);
      if adelay<0 then adelay:=0;
      for i:=0 to adelay do;
    end;
    if endgame then
    begin
     case multi of
      true:
      begin
        if player[1].win or player[2].win or player[3].win or player[4].win then
        begin
          first:=false;
          drawwin;
          loadnextlevel;
          endgame:=false;
          time.clear;
          rtimer.clear;
        end else
        begin
          gamemenu;
          time.clear;
          rtimer.clear;
        end;
      end;
      false:
      begin
        if player[1].win then
        begin
          first:=false;
          drawwin;
          loadnextlevel;
          endgame:=false;
          time.clear;
          rtimer.clear;
        end else
        if player[1].lose then
        begin
          drawlose;
          reloadelevel;
          endgame:=false;
          time.clear;
          rtimer.clear;
        end else
        begin
          gamemenu;
          time.clear;
          rtimer.clear;
        end;
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
{  weaponinfo;}
end.