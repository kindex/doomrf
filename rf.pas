{$Mode Tp}
{$A+,B+,D+,E-,F-,G+,I+,L+,N+,P-,Q-,R-,S-,T-,V+,X+,Y+ Final}
{$M $fff0,0,655360}
{$ifndef dpmi} Real mode not supported {$endif}
{$Ifndef FPC} Turbo Pascal not supported. Only Free Pascal{$endif}
program RF; {First verion: 27.2.2001}
uses crt,mycrt,mouse,wads,dos{,grafx},fpgraph,grx,rfunit, timer, api,ports;
const {(C) DiVision: kIndeX (Thanks to Zonik & Dark Sirius)}
  accel:integer=-1;
  botdir='bots\';
  levdir='Levels\';
  wadfile='513.wad';
  levext='.lev';
  mousepl=4;
  kniferange=33;
  oxysec=10;
  bombfire=4;
  reswapbomb=2;
  barrelbomb=5;
  maxpmaxx=200;
  maxpmaxy=200;
  cwall = 1 shl 0;  cstand= 1 shl 1;  cwater= 1 shl 2;  clava = 1 shl 3; cshl= 1 shl 4; cshr= 1 shl 5;
     cFunc= 1 shl 6; cDeath=1 shl 7;
  cjump = 1 shl 0;
  cimp = 1 shl 1; cgoal = 1 shl 0;
  maxmon=196;
  maxitem=128;
  maxlink=3; {0..3  (4)}
  scry:integer=19*8;  scrx:integer=260;
  maxt=1600 div 8;
  defx=200; defy=200; defname='';
  maxkey=8;
  {Left Right Fire Jump Next Prev}
  ckey:array[1..3,1..maxkey]of byte=(
  (75,77,72,80,29,{43}56, 28,54),
  (30,32,17,31,15,58{?}, 41,16),
  (79,81,76,82,78,69, 74,55));
  kleft =1;
  kright=2;
  kjump =3;
  kdown =4;
  katack=5;
  katack2=6;
  knext =7;
  kprev =8;
  scroolspeed=12;
  truptime=30;
  reswaptime:integer=60;  monswaptime:integer=30;
  botsee:array[1..5]of integer=(800,600,400,200,0);
  edwallstr:array[1..8]of string[16]=
  (  'Стена',  'Ступень',  'Вода',  'Лава',  '<<',  '>>',  'Function',  'Only in Deathmatch' );
{  ednodestr:array[1..4]of string[16]=
  ( 'Цель-Выход',  'Важный',  'Предмет',  '-'  );}
  maxedmenu=12+5+4;
  edmenustr:array[1..maxedmenu]of string[16]=
  (  'Выход',  'Сохранить',  'Загрузить',  'Новая',  'Текстуры',  'Стены',
   'Монстры',  'Предметы',  'Функции',  'Скрытые',  'Пути',  '(C)',
   'Оружие','Патроны','Аптечки','Интерьер','Колонны',
   '','Пусто','Стена','Ступень');
type
  real=single;
  tcapt=array[1..4]of char;
  tcolor=record
    m,r:byte;
    del:real;
  end;
  tkeys=array[1..maxkey]of boolean;
const
  origlev:tcapt='FL02'; lever00:tcapt='FLEV';
  maxallpl:integer=4;
  blood:tcolor=(m:180; r:12; del: 4{6}{3.5});
  water:tcolor=(m:200; r:8; del:2.5);
  blow:tcolor=(m:160; r:8; del:2.5);
  ice:tcolor=(m:186; r:10; del:2.5);
type
{   tnpat=0..maxpat;}
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
    constructor newObj;
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
    procedure checkdeath;
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
  tstate=(stand,run,fire,die,crash,hack,hai);
  tmon=object(tobj)
     life,ai,know,see,barrel: boolean;
     target: record x,y:integer end;
     who,lastwho: 0..maxmon;
     dest: tdest;
     tip: tmaxmontip;
     delay,freez,fired,deldam,statedel,vis,savedel,hero,god:longint;
     state,curstate:tstate;
     health,armor,buhalo,vempire,oxy,oxylife:real;
     weap: longint{tmaxweapon};
     w:set of tmaxweapon;
     key:set of 1..maxkey;
     bul:array[tmaxbul]of integer;
     procedure clearwall(c:byte);
     procedure fillwall(c:byte);
     procedure takebest(mode:integer);
     procedure init(ax,ay,adx,ady:real; at:tmaxmontip; ad:tdest; aw:longint; aai,af:boolean; ah:longint);
     function takegod(n:longint):boolean;
     function takeweap(n:tmaxweapon):boolean;
     function takebul(n:tmaxbul; m:integer):boolean;
     function takeitem(nn:integer):boolean;
     function takearmor(n:real):boolean;
     function takehealth(n:real):boolean;
     function takemegahealth(n:real):boolean;
     procedure dier;
     procedure attack(nweap: longint);
     function getsx:integer; virtual;
     function getsy:integer; virtual;
     function getftr:real; virtual;
     function getupr:real; virtual;
     procedure takenext;
     procedure takeprev;
     procedure fastweap(n:integer);
     procedure draw(ax,ay:integer);
     procedure runleft;
     procedure runright;
     procedure jump;
     procedure move; virtual;
     procedure checkstep;
     procedure damage(ax,ay:integer; hit,bomb,coxy,afreez:real; dwho:integer; adx,ady: real);
     procedure setstate(as:tstate; ad: real);
     procedure setcurstate(as:tstate; ad: real);
     procedure kill;
     procedure explode;
     procedure giveweapon;
     procedure moveai;
     procedure done; virtual;
  end;
  tbul=object(tobj)
     who,tip,etime: integer;
     range: longint;
     procedure init(ax,ay, adx,ady:real; at,aw:integer);
     procedure draw(ax,ay:integer);
     procedure move; virtual;
     procedure detonate;
     function getftr:real; virtual;
     function getupr:real; virtual;
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
    procedure door(id: integer);
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
    procedure newObj;
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
    function space(ax,ay: integer): boolean;
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
    order:record
      kind: (no, takepos, cover, goexit);
      target: record x,y,hero: integer; end;
    end;
    bot,curn,lastn,goal,nextn,mx,my,seex,seey,wmode:longint;
    last: record x,y: longint; end;
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

    procedure takeposition(ax,ay: integer);
    procedure coverme(a:integer);
    procedure freebot;
    procedure gotoexit;
  end;
  tlevel=object
    max,cur:integer;
    name:array[0..40]of string[8];
    savefirst:string[8];
    skill: longint;
    editor,endgame,multi,death,first,rail,look,sniper,reswap:boolean;
    maxpl:integer;
    procedure setup;
    procedure loadini(a:string);
    procedure load;
    procedure loadfirst;
    procedure next;
    procedure add(a:string);
  end;
(******************************** Variables *********************************)
var
  unpush: boolean;
  keybuf,wintext1,wintext2:string;
  pnode,pnodei,pnodeg: tnpat;
  time,rtimer:ttimer;
  map:tmap;
  speed:real;
  ed:ted;
  d:array[0..9]of tnpat;
  dminus,dpercent:tnpat;
{  p:array[0..maxpat]of tbmp;}
{  names:array[byte]of string[8];}
  allwall:^arrayofstring8;
  mx,my,lastx,lasty,add:longint;
  push,push2,push3,loaded:boolean;
  mfps,maxallwall:longint;
  cur:tnpat;
  vec:procedure;
  player:array[1..maxplays]of tplayer;
  level:tlevel;
{  heiskin: array[tdest]of tnpat;}
(******************************** IMPLEMENTATION ****************************)
procedure winallgame;
begin
  clear;
  putbmpall('intro');
  wb.print((getmaxx-rb.width(wintext1))div 2,getmaxy div 2-40,wintext1);
  wb.print((getmaxx-rb.width(wintext2))div 2,getmaxy div 2,wintext2);
  screen;
  delay(10);
  winall:=true;
end;
function menu(max,def:integer; title: string):integer;
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

{  wb.print(x1,y1+(i-1)*d,men[i]);}

  wb.print(x1,y1-d*2,title);

  for i:=1 to max do
    wb.print(x1,y1+(i-1)*d,men[i]);
  if hod mod 90<45 then j:=skull1 else j:=skull2;
  p^[j].sprite(x1-30,y1-5+(ch-1)*d);

  screen;
end;

begin
  while keypressed do readkey;
  maxl:=10;
  for i:=1 to max do
    if length(men[i])>maxl then maxl:=length(men[i]);
  x1:=(getmaxx-maxl*15)div 2;
  if x1<30 then x1:=30;

  level.endgame:=false;
  if max=1 then begin menu:=def; exit; end;
  if max=0 then begin menu:=0; exit; end;

  ch:=def;  hod:=0; enter:=0;
  if (ch<1)or(ch>max)then ch:=1;
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
        #73: {PgUp} ch:=1;
        #81: {PgDn} ch:=max;
       end;
    end;
  until enter>0;
  menu:=enter;
  while keypressed do readkey;
end;
procedure weaponinfo;
var i:integer;
begin
  writeln;
  for i:=0 to maxweapon do
   with weapon[i] do
   if name<>'' then
   begin
     write(name:16,' - ',damages:6:2);
     if bomb>0 then write(' / Взрыв - ',bomb:6:2);
     if hits>0 then write(' / Холодное - ',hits:6:2);
     writeln;
   end;
 end;
procedure loadmodfile(a:string);
var
  f:text;
  s,s1,s2:string;
  nm,i,j:longint;
begin
  curmod:=a;

  assign(f,a);
  reset(f);
  while not eof(f) do
  begin
    readln(f,s);
    if (s='')or(s[1]=';')or(s[1]='/')then continue;
    if s[1]='[' then begin nm:=vl(copy(s,2,length(s)-2)); continue; end;
    i:=pos('=',s);
    if i>0 then
    begin
      s1:=downcase(copy(s,1,i-1));
      s2:=copy(s,i+1,length(s)-i);
{      if s1='intro' then p^[intro].load(s2);}
      if s1='intro' then
        intro:=loadbmp(s2);
      if s1='skull' then begin
        skull1:=loadbmp(s2+'1');
        skull2:=loadbmp(s2+'2');
      end;
      if s1='vis' then
        for i:=1 to 7 do en[i]:=loadbmp(s2+st(i));
      if s1='freeitem' then
        freeitem:=vl(s2);
      if s1='wintext1' then wintext1:=s2;
      if s1='wintext2' then wintext2:=s2;
      if s1='free death item' then
        freemultiitem:=vl(s2);
      if s1='health' then
        playdefhealth:=vl(s2);
      if s1='defitem' then
        playdefitem:=vl(s2);
      if s1='death item' then
        multiitem:=vl(s2);
      if copy(s1,1,3)='tip' then
        bot[vl(copy(s1,4,1))].tip:=vl(s2);
   {Update - Start lose, Win}
    end;
  end;
end;
procedure loadmod(a:string);
begin
  level.loadini(a);
  loadmodfile(a);
end;
function tmap.space(ax,ay: integer): boolean;
var
  l: longint;
begin
  space:=false;
  ax:=ax div 8;
  ay:=ay div 8;
  if (ax>0)and(ay>0)and(ax<x)and(ay<y) then begin
    l:=land[ay]^[ax].land;
    space:=((l and cwall)=0)or((l and cfunc)=0);
  end;
end;
procedure tplayer.takeposition(ax,ay: integer);
begin
  order.kind:=takepos;
  order.target.x:=ax;
  order.target.y:=ay;
end;
procedure tplayer.coverme(a:integer);
begin
  order.kind:=cover;
  order.target.hero:=a;
end;
procedure tplayer.freebot;
begin
  order.kind:=no;
end;
procedure tplayer.gotoexit;
begin
  order.kind:=goexit;
end;
procedure tlevel.add(a:string);
var
  i: integer;
  f: text;
begin
  for i:=1 to max do
    if upcase(name[i])=upcase(a)then exit;
  inc(max);
  name[max]:=a;
{  assign(f,levelini);
  append(f);
  writeln(f,a);
  close(f);}
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
    delay(3);
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
procedure tlevel.setup;
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
      ul: begin  x1:=0; x2:=getmaxx div 2; y1:=0; y2:=getmaxy div 2;end;
      dl: begin  x1:=0; x2:=getmaxx div 2; y1:=1+getmaxy div 2; y2:=getmaxy;end;
      ur: begin  x1:=1+getmaxx div 2; x2:=getmaxx; y1:=0; y2:=getmaxy div 2;end;
      dr: begin  x1:=1+getmaxx div 2; x2:=getmaxx; y1:=1+getmaxy div 2; y2:=getmaxy;end;
      else  {none} begin x1:=0; x2:=0; y1:=0; y2:=0 ;end;

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
end;
procedure tlevel.loadfirst;
begin
  setup;
  cur:=1; load;
end;

procedure tf.door;
var
  ti,tj,j: integer;
begin
  j:=id+1;
  with map do
  for ti:=(round(f^[j].x) div 8) to  round(f^[j].x+f^[j].sx) div 8 do
    for tj:=(round(f^[j].y) div 8) to  round(f^[j].y+f^[j].sy) div 8 do begin
      land[tj]^[ti].vis:=byte(f^[id].tip=16);
      land[tj]^[ti].land:=byte(f^[id].tip=16);
    end;
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

  if not death then with map do begin {Disable some wepons and mons in single}
    for i:=0 to maxmon do
      if (m^[i].enable)and(m^[i].ai) then m^[i].checkdeath;
    for i:=0 to maxitem do
      if item^[i].enable then item^[i].checkdeath;
  end;
  if death then begin {Open all doors in deathmatch}
    for i:=0 to maxf do
      if map.f^[i].tip=15 then map.f^[i].door(i);
  end;

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
  case death of
  false: begin
    inc(cur);
    if cur=1 then loadfirst
    else
    begin
      if cur>max then begin endgame:=true; winallgame end else
      load;
    end;
  end;
  true: begin
    i:=cur;
    setup;
    if max=1 then cur:=1 else
    begin
     repeat
       cur:=random(max)+1;
     until cur<>i;
    end;
    load;
  end;
 end;
end;
procedure tlevel.loadini(a:string);
var
  f:text;
  s: string;
begin
  cur:=0; max:=0;
  assign(f,a);
  reset(f);
  repeat
    readln(f,s);
  until (downcase(s)='[levellist]')or(eof(f));

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
  if level.reswap and ai and first or barrel then
    initmust(1,startx,starty,tip,dest,monswaptime);
  tobj.done;
end;
procedure titem.done;
begin
  if level.death and first then
    initmust(2,startx,starty,tip,right,reswaptime);
  tobj.done;
end;
procedure tplayer.initmulti;
var i,max,cur,w,mn:integer;
begin
  case level.death of
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
     {Update - orders}
     mn:=min(n,4);
     for i:=0 to maxf do if map.f^[i].enable then
      if map.f^[i].tip=mn{Coop} then
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
  map.m^[hero].health:=playdefhealth;
{  map.m^[hero].takeitem(monster[tip].defitem);}
  win:=false;
  lose:=false;

  order.kind:=no;
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

  for i:=max(0,ax div 8) to min(map.x-1,(ax+asx)div 8) do
    for j:=max(0,ay div 8) to min(map.y-1,(ay+asy)div 8) do
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
function tmon.takeitem(nn:integer):boolean;
var
  ok:boolean;
begin
  ok:=false;
  if it[nn].god<>0 then
     ok:=takegod(round(it[nn].god/speed*mfps)) or ok;

  if it[nn].weapon<>0 then
     ok:=takeweap(it[nn].weapon) or ok;
  if it[nn].ammo<>0 then
     ok:=takebul(it[nn].ammo,it[nn].count) or Ok;
  if it[nn].armor<>0 then
     ok:=takearmor(it[nn].armor)or ok;
  if it[nn].health<>0 then
     ok:=takehealth(it[nn].health)or ok;
  if it[nn].megahealth<>0 then
     ok:=takemegahealth(it[nn].megahealth) or ok;
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
  if not level.editor then
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
  if not level.editor then
  case level.multi of
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
  box(0,0,getmaxx,getmaxy);
  if oxy<100 then
    digit((x1+x2)div 2-20,(y1+y2)div 2+30,round(oxy),'%');
  if map.m^[hero].god>0 then
    digit((x1+x2)div 2-12,(y1+y2)div 2+30,round(map.m^[hero].god/rtimer.fps),' ');
  if map.m^[hero].freez>0 then
    digit((x1+x2)div 2-12,(y1+y2)div 2+30,round(map.m^[hero].freez/rtimer.fps),' ');
{  if map.m^[hero].fired>0 then
    digit((x1+x2)div 2-12,(y1+y2)div 2+30,round(map.m^[hero].fired/rtimer.fps),' ');}
end;
procedure tmon.takebest(mode:integer);
var i,c:integer;
   dam:real;
begin
  dam:=0; c:=1;
  for i:=1 to maxweapon do
   if ((bul[weapon[i].bul]>max(1,weapon[i].input))or((weapon[i].hit>0)))and(i in w)and(weapon[i].cool>=0) then
    if dam<weapon[i].damages then
    if
    (mode=0)and(weapon[i].hit>0)or
    (mode=1)and(weapon[i].hit=0)and(weapon[i].bomb=0)
        then
    begin
      dam:=weapon[i].damages;
      c:=i;
    end;
  if c>0 then weap:=c;
end;
procedure tmon.fastweap(n:integer);
var
  try,last: integer;
begin
  if delay>0 then exit; try:=0; last:=weap;
  repeat
    inc(try);
    inc(weap);
    if weap>maxweapon then weap:=1;
    if weap in w then
      if rfunit.weapon[weap].shortcut=n then
      if (bul[rfunit.weapon[weap].bul]>0)or(rfunit.weapon[weap].hit>0)then break;
  until try>maxweapon;
  if try>maxweapon then weap:=last else
  delay:=round(mfps/speed*0.25);
end;
procedure tmon.takenext;
begin
  if delay>0 then exit;
  repeat
    inc(weap);
    if weap>maxweapon then weap:=1;
    if weap in w then
      if (bul[rfunit.weapon[weap].bul]>max(1,weapon[weap].input))or(rfunit.weapon[weap].hit>0)then break;
  until false;
  delay:=round(mfps/speed*0.25);
end;
procedure tmon.takeprev;
begin
  if delay>0 then exit;
  repeat
    dec(weap);
    if weap<0 then weap:=maxweapon;
    if weap in w then
      if (bul[rfunit.weapon[weap].bul]>max(1,weapon[weap].input))or(rfunit.weapon[weap].hit>0)then break;
  until false;
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
     d:=round(sqrt(sqr(mx-n^[i].mx)+sqr(my-n^[i].my)*4));
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
     if level.death or (map.m^[m].hero=0) then begin
      if (abs(map.m^[m].mx-mx)<kniferange)and(abs(map.m^[m].my-my)<kniferange)then begin
       seex:=map.m^[m].mx-mx;
       seey:=map.m^[m].my-my;
       seeany:=true;
       exit;
      end;
      if (abs(map.m^[m].my-my)<24) then
        if abs(map.m^[m].mx-mx)<min then
        begin
           min:=abs(map.m^[m].mx-mx);
           f:=m;
      end;
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
var
  i,j,ge,findn:integer;
  mind,d: real;
begin
  ge:=-1;
  case order.kind of
  no:with map do
    for i:=0 to maxnode do if n^[i].enable then begin
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
  cover: with map do
  begin
    for i:=0 to maxnode do if n^[i].enable then
    if n^[i].c and cgoal=0 then
      n^[i].c:=0;
    i:=player[order.target.hero].hero;
    ge:=getnode(map.m^[i].mx,map.m^[i].my);
    map.n^[ge].c:=cimp{ and cgoal};
  end;
  takepos: with map do
  begin
    for i:=0 to maxnode do if n^[i].enable then
    if n^[i].c and cgoal=0 then
      n^[i].c:=0;
{    i:=player[order.target.hero].hero;}
    ge:=getnode(order.target.x,order.target.y);
    map.n^[ge].c:=cimp{ and cgoal};
  end;
  end;

  if level.death then
   for i:=1 to level.maxpl do
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
           if map.space(n^[c].mx,n^[c].my) then
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
  if (abs(mx-map.n^[b].mx)>4)or(order.kind=no) then
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
var j,ti,tj:integer;

begin
  if (ammo<max(1,weapon[weap].input))and(weapon[weap].hit=0) then
    map.m^[hero].takebest(1);

  mx:=round(map.m^[hero].x);
  my:=round(map.m^[hero].y);
  dest:=map.m^[hero].dest;

  with map do
   if m^[hero].life then
   begin
    if (monster[m^[hero].tip].hai[left]<>0)and(not m^[hero].ai)and(m^[hero].state=stand) then
     if random(100)=0 then m^[hero].setstate(hai,30);
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
        15,16{Open&Close Door}: f^[i].door(i);
        {        12: map.m^[hero].damage(round(map.m^[hero].x),round(map.m^[hero].y),0,33,0,hero);}
        17: begin map.g:=map.g*1.6; f^[i].tip:=0; end;
        18: begin map.g:=map.g/1.6; f^[i].tip:=0; end;
        19: begin map.g:=9.8*ms2; f^[i].tip:=0; end;
        20: begin usk:=usk*1.6; f^[i].tip:=0; end;
        21: begin usk:=usk/1.6; f^[i].tip:=0; end;
        22: begin usk:=ausk; f^[i].tip:=0; end;
      end;

   end;
  map.m^[hero].key:=[];
{  if key[1] then endgame:=true;}
  case bot of
  0:
   begin
     if key[kleft] then include(map.m^[hero].key,kleft);
     if key[kright] then include(map.m^[hero].key,kright);
     if key[katack] then include(map.m^[hero].key,katack);
     if key[katack2] then include(map.m^[hero].key,katack2);
     if key[kjump] then if not map.m^[hero].life then lose:=true else include(map.m^[hero].key,kjump);
     if key[knext] then include(map.m^[hero].key,knext);
     if key[kprev] then include(map.m^[hero].key,kprev);
     if key[kdown] then include(map.m^[hero].key,kdown);
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
{      if random(3)=0 then}

      curn:=map.getnode(mx,my);
      if curn=-1 then exit;
      if goal=-1 then exit;
      goal:=getgoal;
      wave(curn,goal);
      goal:=getpath;
      nextn:=find(goal);

      if
      (abs(last.x-map.m^[hero].mx)<2)and
      (abs(last.y-map.m^[hero].my)<2)then
      case random(3) of
        0: include(map.m^[hero].key,kjump);
        1: include(map.m^[hero].key,kdown);
      end;
      last.x:=map.m^[hero].mx;
      last.y:=map.m^[hero].my;

      if nextn=-1 then exit;
    end;

    if see  then
    begin
      curn:=map.getnode(mx,my);

      if abs(seex)<kniferange then
      wmode:=0
      else
      if abs(seex)>128 then wmode:=2 else
         wmode:=1;

{      if level.skill>3 then} map.m^[hero].takebest(wmode);

      if seey<0 then include(map.m^[hero].key,kjump);
      downed:=false;

      if (seex>0)and((dest=left)or(seex>botsee[level.skill])) then
         begin exclude(map.m^[hero].key,kleft); include(map.m^[hero].key,kright); end
       else
      if (seex<0)and((dest=right)or(seex<-botsee[level.skill])) then
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


procedure tmon.attack(nweap: longint);
var
  l:shortint;
  sp,per,ry,d,ty:real;
  i,s,j:longint;
begin
  if (delay>0)or not life then exit;
  if weapon[nweap].hit>0 then
  begin
    s:=kniferange;
  for i:=0 to maxmon do
   if (map.m^[i].enable)and(map.m^[i].life) then
    if who<>i then
    if
    (abs(map.m^[i].x-x)<s)and
    (abs(map.m^[i].y-y)<s)
    then
      map.m^[i].damage(round(map.m^[i].x),round(map.m^[i].y-map.m^[i].getsy*6),weapon[nweap].hit,0,0,0,who,0,0);
  end;
  delay:=round(weapon[nweap].shot*mfps/speed);
  if (not ai)and(bul[weapon[nweap].bul]<=0) then exit;
  case dest of
   left: l:=-1;
   right: l:=1;
  end;
  ry:=0;
  sp:=(weapon[nweap].speed)*l;
  per:=(rfunit.bul[weapon[nweap].bul].per+weapon[nweap].per)/100;
  if ai and level.sniper then
  begin
    d:=sqrt(sqr(target.x-x)+sqr(target.y-y));
    ty:=-(target.y-y)/d;
{    if ty>abs(target.x-x)/d*}
    ry:=ty*sp;
  end;

  for j:=1 to max(1,weapon[nweap].multi) do
  if ai or (bul[weapon[nweap].bul]>=max(1,weapon[nweap].input))then
  begin
    if not ai then dec(bul[weapon[nweap].bul],max(1,weapon[nweap].input));

    for i:=1 to rfunit.bul[weapon[nweap].bul].shot do
      map.initbul(x+l*getsx*4,y-monster[tip].h,
      sp*(1+random*per-per/2)+dx,
      sp*(random*per-per/2)+ry-weapon[nweap].speedy
      ,weapon[nweap].pul,who);
    setstate(fire,0.1);
  end;
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

function tbul.getftr:real;
begin
  getftr:=0.9;
end;
function tbul.getupr:real;
begin
  getupr:=0.6;
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
var
  l,i,sx,sy: integer;
begin
  tip:=at;
  who:=aw;
  tobj.init(ax,ay,adx,ady,false);
  etime:=round(bul[tip].time*mfps/speed);
  range:=0;
{  log(st(tip),etime);}
end;
procedure tbul.draw(ax,ay:integer);
var
  i,tx:longint;
begin
{  tobj.draw(ax,ay);}
{  if bul[tip].rotate<>0 then
    p^[bul[tip].fly[1]].putrot(mx-ax,my-ay,cos(x/30),sin(x/30),0.75,0.75)
  else}
 case bul[tip].laser of
 false: begin
   if bul[tip].maxfly=1 then begin
     if (tip=4)and(dx<0) then
      p^[rocket2].spritec(mx-ax,my-ay)
     else
      p^[bul[tip].fly[1]].spritec(mx-ax,my-ay)
   end
  else
    p^[bul[tip].fly[(mx div bul[tip].delfly mod bul[tip].maxfly)+1]].spritec(mx-ax,my-ay);
  end;
  true:begin
    tx:=p^[bul[tip].fly[1]].x;
   if range>0 then
    for i:=1 to range div tx do
      p^[bul[tip].fly[1]].spritec(mx-ax+i*tx,my-ay)
     else
   for i:=-1 downto range div tx do
      p^[bul[tip].fly[1]].spritec(mx-ax+i*tx,my-ay)
  end;
  end;
end;
procedure tbul.move;
var
  i,ax,ay,sx,sy,l:integer;
  sdy: real;
begin
  case bul[tip].laser of
  false: begin
  if (bul[tip].time=0)then begin
  dy:=dy+bul[tip].g*speed;
  ax:=mx; ay:=my;
  x:=x+dx*speed; mx:=round(x); lx:=mx div 8;
  y:=y+dy*speed; my:=round(y); ly:=my div 8;
  if inwall(cwall) then
  begin
    for i:=0 to random(5)+5 do
      map.randompix(x-dx,y-dy,0,0,5,5,blow);
    if bul[tip].staywall>0 then
      map.inititem(ax,ay,dx,dy,bul[tip].staywall,false);
    detonate;
    exit;
  end
  end
  else begin
    dy:=dy+bul[tip].g*speed;
    dy:=dy-map.g*speed;
    tObj.move;


    if etime>0 then dec(etime);
    if (etime=0)and(bul[tip].time<>0)then begin detonate; exit; end;
  end;

  for i:=0 to maxmon do
   if i<>who then
   if map.m^[i].enable and map.m^[i].life then
   if not((map.m^[i].ai)and(map.m^[who].ai))or not level.rail then
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
      map.m^[i].damage(mx,my,
      bul[tip].hit,
      0,
      bul[tip].fire/speed*mfps,
      bul[tip].freez/speed*mfps,
      who,dx*bloodu,dy*bloodu);
      map.m^[i].dx:=map.m^[i].dx+dx*0.1;
      detonate;
      exit;
    end;
  end;
  end;
  true: {laser} begin
  if bul[tip].laser and (range=0)then begin
    if dx<0 then l:=-1 else l:=1;
    repeat
      lx:=lx+l;
    until inwall(cwall);
    range:=lx*8-mx;
    lx:=mx div 8;

   for i:=0 to maxmon do
   if i<>who then
   if map.m^[i].enable and map.m^[i].life then
   if not((map.m^[i].ai)and(map.m^[who].ai))or not level.rail then
   begin
     ax:=map.m^[i].mx;
     ay:=map.m^[i].my;
     sx:=map.m^[i].getsx*4;
     sy:=map.m^[i].getsy*8;
    if (my<ay)and(my>ay-sy)then
    if
    ((ax>(range+mx-sx))and(range<0)and(ax<mx))or
    ((ax<(range+mx+sx))and(range>0)and(ax>mx))
    then
    begin
      map.m^[i].damage(ax,my,
      bul[tip].hit,
      0,
      bul[tip].fire/speed*mfps,
      bul[tip].freez/speed*mfps,
      who,dx*bloodu,dy*bloodu);
      map.m^[i].dx:=map.m^[i].dx+dx*0.1;
    end;
  end;
  end;

    if etime>0 then dec(etime);
    if (etime=0)and(bul[tip].time<>0)then begin
      x:=x+range; mx:=round(x); lx:=mx div 8;
      detonate;
      exit;
    end;

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
      map.m^[i].damage(round(map.m^[i].x),round(map.m^[i].y-map.m^[i].getsy*6),0,bomb[tip].hit,bomb[tip].fired,0,who,0,0);
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
procedure tmon.damage(ax,ay:integer; hit,bomb,coxy,afreez:real; dwho:integer; adx,ady: real);
var
  i:integer;
begin
  if ax=0 then begin
    ax:=round(x);
    ay:=round(y-getsy*6)
  end;
  if (freez>0)and(afreez=0) then begin
    hit:=hit*10;
    bomb:=bomb*10;
  end;
  if health>300 then begin
    coxy:=0;
    afreez:=0;
  end;
  know:=true;
  if barrel and not life then exit;
  if god<>0 then exit;
{  if fired=0 then }
  fired:=fired+round(coxy){*byte(hero>0)};
  freez:=freez+round(afreez);

  if afreez>0 then fired:=0;
  if coxy>0 then freez:=0;

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
    clearwall(cwall);
{    if (dwho>0)and(hero>0) then player[hero].hero:=dwho;}
  end;
  if freez=0 then
    setstate(hack,0.1);
  if not barrel then
  if freez>0 then
  for i:=1 to min(32,round((hit+bomb)*5)) do
    map.randompix(ax,ay,dx+adx,dy+ady,5,5,ice)
  else
  for i:=1 to min(64,round((hit+bomb)*10)) do
    map.randompix(ax,ay,dx+adx,dy+ady,5,5,blood)
  else
  for i:=1 to min(32,round((hit+bomb)*5)) do
    map.randompix(ax,ay,dx+adx,dy+ady,5,5,blow);

  if health<=0 then
    if (bomb>0)or(freez>0) then begin explode; freez:=0; end
    else kill;
end;
procedure tmap.randompix;
begin
  initpix(ax,ay,
    random*rdx-rdx*0.5+adx,random*rdy-rdy*0.5+ady,
    ac.m+random(ac.r),ac.del);
end;

procedure tmon.fillwall(c:byte);
var
  i,j,sx,sy,x1,y1,x2,y2:integer;
  ok:boolean;
begin
  sx:=getsx;
  sy:=getsy;
  x1:=lx-sx div 2; x2:=x1+sx-1;
  y2:=ly; y1:=y2-sy+1;
  if (x1<0)or(y1<0)or(x2>=map.x)or(y2>=map.y) then begin  exit; end;
  for i:=x1 to x2 do
    for j:=y1 to y2 do
     map.land[j]^[i].land:=map.land[j]^[i].land or c;
end;
procedure tmon.clearwall(c:byte);
var
  i,j,sx,sy,x1,y1,x2,y2:integer;
  ok:boolean;
begin
  sx:=getsx;
  sy:=getsy;
  x1:=lx-sx div 2; x2:=x1+sx-1;
  y2:=ly; y1:=y2-sy+1;
  if (x1<0)or(y1<0)or(x2>=map.x)or(y2>=map.y) then begin exit; end;
  for i:=x1 to x2 do
    for j:=y1 to y2 do
     map.land[j]^[i].land:=map.land[j]^[i].land and (not c);
end;
procedure tmon.move;

var i:integer;
begin
{  if life then }clearwall(cwall);

  if not life then begin inc(delay,2);
    if delay>truptime*mfps/speed then begin done; exit; end; end;



  if freez>0 then dec(freez);
  if freez=0 then begin
  if ai then moveai;
  if kleft in key then runleft;
  if kright in key then runright;

  if delay=0 then
    IF KATACK2 in key Then
      attack(-weap);

  if delay=0 then
  if katack in key then begin
    attack(weap);
  end;

  if kjump in key then jump;
  if knext in key then takenext;
  if kprev in key then takeprev;
  if kdown in key then begin down:=true; if inwall(cwater) then dy:={dy+}monster[tip].jumpy{*0.5}; end
    else down:=false;
  end;

  tobj.move;

  if freez>0 then exit;
  if deldam>0 then dec(deldam);

  if inwall(clava) and (deldam=0) then
  begin
    damage(mx,my,0,5,2,0,0,0,0);
    deldam:=round(mfps/speed);
  end;

  if inwall(cfunc)then
   with map do
   if life then
    for i:=0 to maxf do
     if f^[i].enable then
     if (mx>=f^[i].x)and (my>=f^[i].y)and
     (mx<=f^[i].x+f^[i].getsx)and (my<=f^[i].y+f^[i].getsy) then begin
      if f^[i].tip=12 then damage(0,0,0,100,0,0,hero,0,0);
      if f^[i].tip=23 then damage(0,0,0,0,0,10,hero,0,0);
     end;

  if deldam=0 then
  begin
    if inwall(cwater) then
    begin
      fired:=0; {OXY}
      deldam:=round(0.1*mfps/speed);
      if oxy>0 then oxy:=oxy-1;
      if (oxy=0)and(hero>0) then begin health:=health-1; oxylife:=oxylife+1; damage(mx,my,0,0,0,0,who,0,0);end;
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
{    dec(fired);}
  end;
  if fired>0 then begin
    damage(mx,my,0,oxysec*speed/mfps,0,0,0,0,0);
    dec(fired);
    if fired<0 then fired:=0;
  end;
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
     vis:=min(
     round(
     statedel/
     (mfps*
     monster[tip].bombi.delay
     /speed/
     monster[tip].bombi.max))+1,
     monster[tip].bombi.max);
  end;
  die:
  begin
     state:=die;
     inc(statedel);
     vis:=min(
     round(statedel/(mfps*monster[tip].diei.delay/speed/monster[tip].diei.max))+1,
     monster[tip].diei.max
     );
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
  if (life)and(state<>die)and(state<>crash) then fillwall(cwall);
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
    if (ty<=0)or(ty>=map.y-1)or(tx<=0)or(tx>=map.x-1) then begin
       break;
    end;
    case level.sniper of
     false: if (abs(target.x-tx*8)<16)and(abs(target.y-ty*8)<24{+abs(target.x-tx*8)div 8})then
     begin
       see:=true;
       break;
     end;
     true:  if (abs(target.x-tx*8)<32)and(abs(target.y-ty*8)<(abs(target.x-tx*8)))then begin
       see:=true;
       break;
     end;
    end;
    if (map.land[ty]^[tx].land and cwall)>0 then begin see:=false; break; end;
  until false;
  if ((abs(target.x-x)+abs(target.y-y))<32)and(level.sniper) then
  begin
    see:=true;
  end;
end;
var i,tar,j:longint;
  min,d:real;
begin
  min:=maxlongint{(map.x+map.y)*8*10}; tar:=0;
  with map do
  if rtimer.hod mod 10=(who mod 10) then begin
    for i:=1 to level.maxpl do begin
      j:=player[i].hero;
      if not m^[j].life then continue;
      target.x:=round(m^[j].x);
      target.y:=round(m^[j].y);
      movesee;
      d:=round(abs(m^[j].x-self.mx)+abs(m^[j].y-self.my));
      if (d<min)and see then begin min:=d; tar:=j; end;
    end;
    if tar>0 then begin
      target.x:=round(m^[tar].x);
      target.y:=round(m^[tar].y);
      movesee;
{      see:=true;}
{      log('who',who);
      log('min',round(min));
      log('see',integer(see));}
    end;
  end;

  if (not see)and not level.look and (random(300)=0)then know:=false;
  if (know){and(tar>0)} then
  begin
    if level.sniper then
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
    if (weap=1)or((fired>0)and(level.sniper)) then if target.x<self.x then include(key,kleft) else include(key,kright);
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
{  if dx<0 then dx:=0;
  if dy<0 then dy:=0;
  if dx>x*8-(maxx-minx) then dx:=x*8-(maxx-minx);
  if dy>y*8-(maxy-miny) then dy:=y*8-(maxy-miny);}
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

function getlevel(title: string):string;
var
  s:searchrec;
  max:integer;
begin
  findfirst(levdir+'*'+levext,anyfile,s);
  max:=0;  men[max]:='';
  while doserror=0 do
  begin
    inc(max);
    men[max]:=getfilename(s.name);
    findnext(s);
  end;
  getlevel:=men[menu(max,1,title)];
end;

function getlevellist(title: string):integer;
var
  i:integer;
begin
  for i:=1 to level.max do
    men[i]:=level.name[i];
  getlevellist:=menu(level.max,1,title);
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
     if downcase(s)='yes'then }level.endgame:=true;
   end;
   2: begin
        wb.print(100,50,'Записать');
        s:=enterfile(map.name);
        if s<>'' then begin map.name:=s; map.save; end;
      end;
   3: begin
        wb.print(100,50,'Загрузить');
        s:=getlevel{enterfile(map.name)}('Загрузить');
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
    13: begin what:=items; itm.shift:=1; end;
    14: begin what:=items; itm.shift:=21; end;
    15: begin what:=items; itm.shift:=40; end;
    16: begin what:=items; itm.shift:=58; end;
    17: begin what:=items; itm.shift:=80; end;
    19: land.mask:=0;
    20: land.mask:=cwall;
    21: land.mask:=cstand;
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
     y:=y-28*speed/mfps;
     my:=round(y);
     ly:=my div 8;
     if inwall(cwall) then
       y:=y+48/(mfps/speed);
     my:=round(y);
     ly:=my div 8;
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
constructor tobj.newObj; begin {nothing} end;
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
{  log('tip',tip);
  log('Dest',integer(dest));
  case dest of
   left: log('Left',0);
   right: log('Right',0);
  else log('No dest',0);
  end;
}
  inc(my);
  case state of
   stand:
      p^[monster[tip].
      stand[dest]].
      spritesp(
      mx-ax,
      my-ay);
   run:  p^[monster[tip].run[vis,dest]].spritesp(mx-ax,my-ay);
   fire:  p^[monster[tip].fire[dest]].spritesp(mx-ax,my-ay);
   hack:  p^[monster[tip].damage[dest]].spritesp(mx-ax,my-ay);
   die:  p^[monster[tip].die[vis,dest]].spritesp(mx-ax,my-ay);
   crash:  p^[monster[tip].bomb[vis,dest]].spritesp(mx-ax,my-ay);
   hai:  p^[monster[tip].hai[dest]].spritesp(mx-ax,my-ay);
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
   run,stand,fire,hack,hai: getsy:=monster[tip].y;
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
//  if (integer(dest)<0)or(integer(dest)>2)then dest:=left;
  tip:=at;
  state:=stand;
  curstate:=stand;
  statedel:=0;
  vis:=1;
  health:=monster[tip].health;
  armor:=monster[tip].armor;
  fired:=0;
  case level.death of
  false: takeitem(freeitem);
  true: takeitem(freemultiitem);
  end;
  if ai then takeitem(monster[tip].defitem)
        else
  begin
    if not level.death then begin
      takeitem(playdefitem);
      weap:=it[playdefitem].weapon;
    end
    else begin
      takeitem(multiitem);
      weap:=it[multiitem].weapon;
    end
  end;
  mx:=round(x); my:=round(y);
  dx:=0; dy:=0;
  know:=false; see:=false;
  barrel:=monster[tip].h=0;
  if barrel then begin ai:=false; dest:=left;end;
  key:=[];
  delay:=15;
end;
procedure tobj.init(ax,ay,adx,ady:real; af:boolean);
begin
  enable:=true;
  down:=false;
  x:=ax; y:=ay;
  mx:=round(x); my:=round(y);
  lx:=mx div 8;
  ly:=my div 8;
  dx:=adx; dy:=ady;
  startx:=mx;
  starty:=my;
  first:=af;
end;
procedure tObj.checkdeath;
begin
  if inwall(cDeath) then
    tObj.done;
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
      n: integer{tmaxnode};
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
    dest: byte;
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
  assign(ff,levdir+name+levext);
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
      blockread(ff,mon,7{sizeof(mon)});
//      log('Dest mon',integer(mon.dest));
      initmon(mon.x,mon.y,mon.tip,tdest(mon.dest),true,true,0);
    end;
    for i:=0 to mitem-1 do
    begin
      blockread(ff,itm,6{sizeof(itm)});
      inititem(itm.x,itm.y,0,0,itm.tip,true);
    end;
    for i:=0 to mf-1 do
    begin
      blockread(ff,func,10{sizeof(func)});
      initf(func.x,func.y,func.sx,func.sy,func.tip);
    end;
    if not level.editor then
    if not level.death then
    for i:=0 to maxf-1 do
     if f^[i].enable then
      case f^[i].tip of
        1,2,3,4:
         if f^[i].tip<=level.maxpl then player[f^[i].tip].reinit(round(f^[i].x),
          round(f^[i].y),player[f^[i].tip].deftip,f^[i].dest);
      end;

  if not level.editor then
  if level.death then
   for j:=1 to level.maxpl do
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
   with nodes do begin
    blockread(ff,x,2);
    blockread(ff,y,2);
    blockread(ff,c,1);
    blockread(ff,maxl,1);
    blockread(ff,l[0],3);
    blockread(ff,l[1],3);
    blockread(ff,l[2],3);
    blockread(ff,l[3],3);
    blockread(ff,index,2);
  end;
//     blockread(ff,nodes,20{sizeof(nodes)});
     cn:=nodes.index;
     n^[cn].init(nodes.x,nodes.y,nodes.c,cn);
     for j:=0 to nodes.maxl do
      if nodes.l[j].n<>cn then
       map.n^[cn].addlink(nodes.l[j].n,nodes.l[j].c);
    end;
    reloadpat;
  end;
  close(ff);
  g:=9.8*ms2; usk:=ausk;
  deltanode;
end;
procedure tmap.save;
var
  ff:file;
  mpat,mmon,mitem,mf,i,j,mnode:longint;
  mon:record
    x,y,tip:integer;
    dest: byte;
  end;
  itm:record
    x,y,tip:integer;
  end;
  func:record
    x,y,sx,sy,tip:integer;
  end;
begin
  level.add(name);
  assign(ff,levdir+name+levext);
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
  for i:=0 to maxnode do if n^[i].enable then inc(mnode);
  blockwrite(ff,mnode,4);
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
    mon.dest:=byte(m^[i].dest);
    mon.tip:=m^[i].tip;
    blockwrite(ff,mon,{sizeof(mon)}7);
  end;
  for i:=0 to maxitem do
  if item^[i].enable then
  begin
    itm.x:=round(item^[i].x);
    itm.y:=round(item^[i].y);
    itm.tip:=item^[i].tip;
    blockwrite(ff,itm,{sizeof(itm)}6);
  end;
  for i:=0 to maxf do
  if f^[i].enable then
  begin
    func.x:=round(f^[i].x);
    func.y:=round(f^[i].y);
    func.sx:=round(f^[i].sx);
    func.sy:=round(f^[i].sy);
    func.tip:=f^[i].tip;
    blockwrite(ff,func,{sizeof(func)}10);
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
   with nodes do begin
    blockwrite(ff,x,2);
    blockwrite(ff,y,2);
    blockwrite(ff,c,1);
    blockwrite(ff,maxl,1);
    blockwrite(ff,l[0],3);
    blockwrite(ff,l[1],3);
    blockwrite(ff,l[2],3);
    blockwrite(ff,l[3],3);
    blockwrite(ff,index,2);
  end;
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
  if a and cDeath>0 then getcol:=red;
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
  fillchar(m^,sizeof(m^),0);        for i:=0 to maxmon do m^[i].newObj;
  fillchar(item^,sizeof(item^),0);  for i:=0 to maxitem do item^[i].newObj;
  fillchar(f^,sizeof(f^),0);        for i:=0 to maxf do f^[i].newObj;
  fillchar(pix^,sizeof(pix^),0);    for i:=0 to maxpix do pix^[i].newObj;
  fillchar(b^,sizeof(b^),0);        for i:=0 to maxpul do b^[i].newObj;
  fillchar(n^,sizeof(n^),0);        for i:=0 to maxnode do n^[i].newObj;
  fillchar(e^,sizeof(e^),0);
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
procedure tmap.newObj;
var i:longint;
begin
  new(m);
  new(item);
  new(f);
  new(pix);
  new(b);
  new(n);
  new(e);
  x:=0;
  clear;
end;
procedure tmap.move;
var i:longint;
begin
  if not level.editor then
  begin
    for i:=0 to maxitem do if item^[i].enable then item^[i].move;

    for i:=0 to maxmon do
      if m^[i].enable then m^[i].fillwall(cwall);
    for i:=0 to maxmon do
      if m^[i].enable then m^[i].move;
    for i:=0 to maxmon do
      if m^[i].enable then m^[i].clearwall(cwall);

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
  assign(dat,inidir+'wall.ini');
  reset(dat);
  k:=0;
  while not seekeof(dat) do begin readln(dat); inc(k);end;
  close(dat);

  assign(dat,inidir+'wall.ini');
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
    s1:=downcase(copy(s,1,i-1));
    s2:=copy(s,i+1,length(s)-i);
    if s1='players' then maxallpl:=vl(s2);
    if s1='debug' then if s2='on' then debug:=true;

    if (i>0)and(nm>0)and(nm<=maxplays) then
    with bot[nm] do
    begin
      if s1='name' then name:=s2;
      if s1='bot' then bot:=vl(s2);
      if s1='tip' then tip:=vl(s2);
      if s1='screen' then
      begin
       if s2='all' then scr:=all;
       if s2='up' then scr:=up;
       if s2='down' then scr:=down;
       if s2='none' then scr:=nonec;
       if s2='up-left' then scr:=ul;
       if s2='up-right' then scr:=ur;
       if s2='down-left' then scr:=dl;
       if s2='down-right' then scr:=dr;
      end;
    end;
  end;
  close(f);
end;
procedure botmenu;
const
  max=32;
var
  c:array[1..max] of string[32];
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
    assign(f,botdir+g.name);
    reset(f);
    readln(f,men[s]);
    close(f);
    findnext(g);
  end;
  s:=menu(s,1,'Игроки');
  if s<>0 then
   loadbots(c[s]);
end;
type
  tmod=(single,coop,death);
procedure modmenu(t: tmod);
const
  max=32;
var
  c:array[1..max] of string[32];
  s:integer;
  g:searchrec;
  f:text;
  ok: boolean;
  r: string;
begin
  findfirst('*.mod',anyfile,g);
  s:=0;
  while doserror=0 do
  begin
    inc(s);
    c[s]:=g.name;
    ok:=false;
    assign(f,g.name);
    reset(f);
    readln(f,men[s]);
    repeat
      readln(f,r);
      r:=upcase(r);
      if (pos(upcase('single'),r)>0)and(t=single) then ok:=true;
      if (pos(upcase('cooperative2'),r)>0)and(t=coop) then ok:=true;
      if (pos(upcase('deathmatch'),r)>0)and(t=death) then ok:=true;
    until r='[MAIN]';
    close(f);

    findnext(g);
    if not ok then dec(s);
  end;
  s:=menu(s,1,'Моды');
  if s<>0 then
    loadmod(c[s]);
end;
function skillmenu:integer;
var s:integer;
begin
  men[1]:='Проще пареной репы';
  men[2]:='Для сельской местности';
  men[3]:='Норма';
  men[4]:='Жизнь';
  men[5]:='Кошмар';
  s:=menu(5,3,'Сложность');
  skillmenu:=s;
  with level do
  case s of
   1: begin reswap:=false;reswaptime:=30; monswaptime:=240; rail:=false; look:=false;sniper:=false; end;
   2: begin reswap:=false;reswaptime:=60; monswaptime:=180; rail:=false; look:=true; sniper:=false; end;
   3: begin reswap:=false;reswaptime:=90; monswaptime:=120; rail:=true;  look:=true; sniper:=false; end;
   4: begin reswap:=false;reswaptime:=120;monswaptime:=60;  rail:=true;  look:=true; sniper:=true; end;
   5: begin reswap:=true; reswaptime:=300;monswaptime:=30;  rail:=true;  look:=true; sniper:=true; end;
  end;
end;
function getsave(title:string):integer;
const
  max=8;
var
  f: file;
  s:string;
  c: array[1..4]of char;
  i: integer;
begin
  men[0]:='';
  for i:=1 to max do begin
     assign(f,'saves\save'+st(i)+'.sav');
    {$i-}reset(f,1);
    {$i+}
    if ioresult<>0 then begin men[i]:='пусто'; continue; end;
    blockread(f,c,4);
    blockread(f,s,32);
    men[i]:=s;
    close(f);
  end;
  getsave:=menu(max,1,title);
end;

const
  xorvalue=$7A3E6bc;

procedure xorwrite(var f:file; var x; l: longint);
type
  ta=array[0..65520 div 4]of longint;
var
  a:^ta;
  i: longint;
begin
  new(a);
  move(x,a^,l);
  for i:=0 to l div 4-1 do
    a^[i]:=a^[i] xor (xorvalue+i*$1ac);

  blockwrite(f,a^,l);
  dispose(a);
end;
procedure xorread(var f:file; var x; l: longint);
var
  a:array[0..65520 div 4]of longint absolute x;
  i: longint;
begin
  blockread(f,x,l);
  for i:=0 to l div 4-1 do
    a[i]:=a[i] xor (xorvalue+i*$1ac);
end;

procedure savegame(a: integer);
var
  ff: file;
  c:array[1..4]of char;
  s:string;
begin
  if a=0 then exit;
  assign(ff,'saves\save'+st(a)+'.sav');
  rewrite(ff,1);
  c:='SAVE';
  blockwrite(ff,c,4);
  s:=level.name[level.cur]{+Update or enter};
  blockwrite(ff,s,32);
  xorwrite(ff,curmod,32);
  xorwrite(ff,level,sizeof(level));
  with map do begin
{    blockwrite(ff,patname^,sizeof(arrayofstring8));}
    xorwrite(ff,m^,sizeof(arrayofmon));
    xorwrite(ff,item^,sizeof(arrayofitem));
    xorwrite(ff,f^,sizeof(arrayoff));
    xorwrite(ff,pix^,sizeof(arrayofpix));
    xorwrite(ff,b^,sizeof(arrayofpul));
    xorwrite(ff,e^,sizeof(arrayofbomb));
    xorwrite(ff,n^,sizeof(arrayofnode));
  end;
  xorwrite(ff,player,sizeof(player));
  xorwrite(ff,must,sizeof(must));
  xorwrite(ff,map.g,sizeof(map.g));
  xorwrite(ff,usk,sizeof(usk));
  close(ff);
end;
procedure loadgame(a: integer);
var
  ff: file;
  c:array[1..4]of char;
  s:string;
begin
  if a=0 then exit;
  assign(ff,'saves\save'+st(a)+'.sav');
{$i-}  reset(ff,1); {$i+}
  if ioresult<>0 then exit;
  c:='SAVE';
  blockread(ff,c,4);
  blockread(ff,s,32);

  xorread(ff,s,32);
  loadmod(s);

  xorread(ff,level,sizeof(level));
  level.load;


  with map do begin
{    blockread(ff,patname^,sizeof(arrayofstring8));}
    xorread(ff,m^,sizeof(arrayofmon));

    xorread(ff,item^,sizeof(arrayofitem));
    xorread(ff,f^,sizeof(arrayoff));
    xorread(ff,pix^,sizeof(arrayofpix));
    xorread(ff,b^,sizeof(arrayofpul));
    xorread(ff,e^,sizeof(arrayofbomb));
    xorread(ff,n^,sizeof(arrayofnode));
  end;
  xorread(ff,player,sizeof(player));
  xorread(ff,must,sizeof(must));
  xorread(ff,map.g,sizeof(map.g));
  xorread(ff,usk,sizeof(usk));
  close(ff);
  loaded:=true;
end;
procedure gamemenu;
var
  i:integer;
begin
  for i:=0 to 255 do
    pkey[i]:=false;

  level.endgame:=false;
  men[1]:='продолжить';
  men[2]:='сохранить';
  men[3]:='загрузить';
  men[4]:='главное меню';
  case menu(4,1,'') of
   0,1: level.endgame:=false;
   2: savegame(getsave('сохранить'));
   3: loadgame(getsave('загрузить'));
   4: level.endgame:=true;
  end;
  unpush:=false;
end;
procedure mainmenu;
var
  s:string;
  t: integer;
begin
 loaded:=false;
 repeat
   level.first:=false;
   men[1]:='ОДИН игрок';
   men[2]:='вместе';
   men[3]:='бой';
   men[4]:='загрузить';
   men[5]:='редактор';
   men[6]:='выход';
   with level do
   case menu(6,1,'') of
    1: begin // Single player game
         modmenu(single);
         level.name[1]:=level.savefirst;
         level.skill:=skillmenu;
         level.first:=level.skill<>0;
         level.cur:=0;
         level.editor:=false;
         level.multi:=false;
         level.death:=false;
       end;
    2: begin // Cooperative
         modmenu(coop);
         botmenu;
         level.name[1]:=level.savefirst;
         level.skill:=skillmenu;
         first:=level.skill<>0;
         level.cur:=0;editor:=false; multi:=true; death:=false;
       end;
    3: begin // DeathMatch
         modmenu(rf.Death);
         botmenu;
//         level.name[1]:=level.savefirst;
         level.skill:=skillmenu;

         first:=level.skill<>0;
         if first then
         begin
           t:=getlevellist('уровень');
           if t<>0 then begin
              level.setup;
              level.cur:=t;
              level.load;
           end;
         end;
         editor:=false; multi:=true; death:=true;
         reswap:=true;
       end;
    4: begin loadgame(getsave('загрузить')); if loaded then break; end;
    5: begin debug:=true; editor:=true;first:=true;end;
    0,6: begin endgame:=true; first:=true;end;
   end;
 until level.first;
end;
procedure drawwin;
var t:tnpat;
begin
  box(0,0,getmaxx,getmaxy);
  if putbmpall('win'+st(random(maxwin)+1)) then
    delay(3);
end;
procedure drawlose;
var t:tnpat;
begin
  box(0,0,getmaxx,getmaxy);
  if putbmpall('lose'+st(random(maxlose)+1)) then
    delay(3);
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
(******************************** PROGRAM ***********************************)
var
  i,j:longint;
  adelay:longint;
  lev:string;
begin
{Main Loading}
  loadres;
  w.load(wadfile);
  loadbmp('error');
{  write(load[1]);}  {loadbots('bot.ini');}
{  write(load[2]);}  loadwalls;
{  write(load[3]);}  loadbombs;
{  write(load[4]);}  loadbullets;
{  write(load[5]);}  loadweapons;
{  write(load[6]);}  loaditems;
{  write(load[7]);}  loadmonsters;
{  write(load[8]);}  loadfuncs;


  wb.load('stbf_',10,1); rb.load('stcfn',5,2);

{  intro:=loadbmp('intro');}
  loadmod('rf.mod');
{  skull1:=loadbmp('skull1'); skull2:=loadbmp('skull2');
  for i:=1 to 7 do en[i]:=loadbmp('puh'+st(i));}

  rocket2:=loadbmp('rocketl');
  pnode:=loadbmp('node');  pnodei:=loadbmp('nodei');  pnodeg:=loadbmp('nodeg');
  for i:=0 to 9 do d[i]:=loadbmp('d'+st(i)); dminus:=loadbmp('dminus'); dpercent:=loadbmp('dpercent');
  cur:=loadbmp('cursor');
{  heiskin[left]:=loadbmp('hai');}
{   heiskin[right]:=loadbmpr('hai');}
{Init Screen...}

//  initgraph(res);
  mx:=640; my:=480;
  setmode(mx,my);
  loadfont(inidir,8{'8x8.fnt'});
  getmaxx:=mx;
  getmaxy:=my;

  minx:=0;
  miny:=0;
  maxx:=getmaxx;
  maxy:=getmaxy;

{  clear;
  line(0,0,mx,my,15);
  screen;
  readkey;}

  mfps:=30; loadpal(inidir+'playpal.bmp');
//  if accel<>-1 then setaccelerationmode(accel);
{Load first level}
  level.first:=true;
  map.newObj;

 repeat
  mainmenu;
  if level.endgame then break;
  if not level.editor then begin scrx:=getmaxx+1; scry:=getmaxy-50; end
  else begin scrx:=getmaxx-90; scry:=getmaxy-50; end;

  if level.editor then
  begin
    map.create(defx,defy,0,0,defname);
    ed.land.curname:=allwall^[1];
    ed.land.mask:=1;
    ed.what:=face;
    ed.cool:=true;
    level.maxpl:=0;
    map.addpat(allwall^[1]);
  end;


  if (not level.editor)and(not loaded)and not level.death then level.next;

  {Start game}
  keybuf:='';
  if (not level.editor)and(not loaded) then drawintro;
  GetIntVec($9,@vec);  SetIntVec($9,Addr(keyb));
  speed:=1;
  level.endgame:=false;

  time.init(timer.time);
  rtimer.init(timer.time);

  time.clear;rtimer.clear; time.fps:=mfps;
  winall:=false;
  if not level.editor then
  begin
    ddx:=1; ddy:=1;  Sensetivity(1,1);
  end
  else
  begin
    ddx:=6; ddy:=6;    Sensetivity(12,12);
  end;
  mousebox(0,0,getmaxx,getmaxy); loaded:=false;
  unpush:=false;
  repeat
    rtimer.move;
    time.move;  mx:=mouse.x;  my:=mouse.y; push:=mouse.push; push2:=mouse.push2;push3:=mouse.push3;
    case res of
     0,1: add:=1;
     2,3: add:=7;
    end;
    lastx:=mx-getmaxx div 2+add;
    lasty:=my-getmaxy div 2;
    if not level.editor {and(rtimer.hod mod 10=0)}then
    begin
      setMouseCursor(getmaxx div 2,getmaxy div 2);
    end;

   for j:=1 to min(3,level.maxpl) do
     for i:=1 to maxkey do
       player[j].key[i]:=pkey[ckey[j,i]];

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
   if pkey[60 {F2}]then
     savegame(getsave('сохранить'));
   if pkey[61 {F3}]then
     loadgame(getsave('загрузить'));
   if (not level.death) then begin
    if pkey[44{Z}] then
      for i:=2 to level.maxpl do
        player[i].coverme(1);
    if pkey[45{X}] then
      for i:=2 to level.maxpl do
        player[i].takeposition(map.m^[player[1].hero].mx,map.m^[player[1].hero].my);
    if pkey[46{C}] then
      for i:=2 to level.maxpl do
        player[i].freebot;
    if pkey[47{V}] then
      for i:=2 to level.maxpl do
        player[i].gotoexit;
     for i:=1 to 9 do {ShortCut Weapon}
      if pkey[i+1] then
        map.m^[player[1].hero].fastweap(i);


     end;
     keyb;
    {Manual}
    while keypressed do
    begin
      if length(keybuf)=255 then keybuf:=copy(keybuf,2,254);
      keybuf:=keybuf+downcase(readkey);

     if pos('debug',keybuf)>0 then begin debug:=not debug;  keybuf:='';end;
     if (pos('lev',keybuf)>0)or(pos('map',keybuf)>0) then begin
       j:=pos('lev',keybuf)+3;
       if j>3 then begin
         lev:=copy(keybuf,j,length(keybuf));
         if pos('lev',lev)>0 then keybuf:=copy(keybuf,j,length(keybuf));
       end;
       j:=pos('map',keybuf)+3;
       if j>3 then begin
         lev:=copy(keybuf,j,length(keybuf));
         if pos('map',lev)>0 then keybuf:=copy(keybuf,j,length(keybuf));
       end;

       with level do
         for i:=1 to max do
           if lev=downcase(name[i]) then begin cur:=i-1; j:=0; break; end;
       if j=0 then begin
         for i:=1 to level.maxpl do player[i].win:=true;
         keybuf:='';
       end;
     end;

   if not level.reswap then
     if not level.death then
      begin
       if pos('god',keybuf)>0 then
         begin
           for i:=1 to level.maxpl do
            if map.m^[player[i].hero].god=0 then map.m^[player[i].hero].god:=-1
            else map.m^[player[i].hero].god:=0;
           keybuf:='';
          end;
       if (pos('kill',keybuf)>0)or(pos('iddqd',keybuf)>0) then
         begin
           for i:=1 to level.maxpl do
              map.m^[player[i].hero].damage(map.m^[player[i].hero].mx,map.m^[player[i].hero].my,0,10000,100,0,0,0,-5);
           keybuf:='';
          end;
       if pos('all',keybuf)>0 then
         begin
           for i:=1 to level.maxpl do
            for j:=1 to 39 do
              map.m^[player[i].hero].takeitem(j);
           keybuf:='';
          end;
       if pos('tank',keybuf)>0 then
         begin
           for i:=1 to level.maxpl do
            for j:=41 to 60 do
              map.m^[player[i].hero].takeitem(j);
           keybuf:='';
        end;
      end;
      end;
       if pos('win',keybuf)>0 then begin
           for i:=1 to level.maxpl do
              player[i].win:=true;
         keybuf:='';
       end;

    for i:=1 to level.maxpl do player[i].move;
    {Move}
    map.move;
    level.endgame:=level.endgame or (pkey[1]and unpush);
    if not pkey[1] then unpush:=true;
    if not level.multi then
      level.endgame:=level.endgame or player[1].lose or player[1].win
     else
     for i:=1 to level.maxpl do
       level.endgame:=level.endgame or player[i].win;
   if level.multi then
    for i:=1 to level.maxpl do
     if player[i].lose then
       player[i].initmulti;
    if level.editor then ed.move;
    {Draw}
    clear;
    for i:=1 to level.maxpl do player[i].draw;
    if level.editor then ed.draw;
    rb.print(getmaxx-24,getmaxy-8,st0(round(rtimer.fps),3));
    if level.editor then p^[cur].sprite(mx,my);

{    for i:=0 to 255 do
    for j:=0 to 5 do
      putpixel(i,j,i);}
    screen;
//    readkey;
{    speed:=1;}
    if time.fps<>0 then speed:=mfps/time.fps*usk;
    if speed>5 then speed:=5;

    if (not level.editor)and sfps then
    begin
      speed:=1;
      adelay:=round(adelay+(time.fps-mfps)*1000);
      if adelay<0 then adelay:=0;
      for i:=0 to adelay do;
    end;

    if (time.hod mod 50=0)and not level.death and not level.editor then begin
      j:=0;
      for i:=0 to maxmon do
        if (map.m^[i].life)and(map.m^[i].ai)then inc(j);
      for i:=0 to maxf do
        if (map.f^[i].enable)and(map.f^[i].tip=10{win})then inc(j);
      if j=0 then player[1].win:=true;
    end;

    if level.endgame then
    begin
     case level.multi of
      true:
      begin
        if player[1].win or player[2].win or player[3].win or player[4].win then
        begin
          level.first:=false;
          drawwin;
          loadnextlevel;
          level.endgame:=false;
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
          level.first:=false;
          drawwin;
          loadnextlevel;
          level.endgame:=false;
          time.clear;
          rtimer.clear;
        end else
        if player[1].lose then
        begin
          drawlose;
          reloadelevel;
          level.endgame:=false;
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
  until level.endgame or winall;
  winall:=false;
  SetIntVec($9,@vec);
 until false;
  {End game}
  closegraph;
  map.done;
{  outtro;}
   WEAPONINFO;
end.

