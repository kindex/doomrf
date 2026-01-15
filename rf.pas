{$Ifndef FPC} Turbo Pascal not supported. Only Free Pascal{$endif}
{$Mode Tp}
program RF; {First verion: 27.2.2001}
uses sdlinput,wads,sdlgraph,grx,sprites,rfunit,sdltimer,api,sysutils,dos,sdl2_mixer;
const {(C) DiVision: KindeX , Zonik , Dark Sirius }
  game='Doom RF';
  version='2.1';
  data='15.01.2026';
  title:string='DOOM RF [513] v' {+version+' ['+data+']'};
  shortintro=game+' ['+version+']';
  menutitle='DOOM 513';

  accel:integer=-1;
  levdir:string='RF/Levels/';
  savedir:string='RF/Saves/';
  levext='.lev';
  dotmod='.mod';
  maxpix:longint=maxarraypix;
    maxmust=256;

  maxl=8;
  maxmsg=32;

  defence1:real=1/4;
  defence2:real=1/3;
  fraglimit:integer=-1;
  mousepl=4;
  kniferange=20;
  oxysec=10;
  bombfire=4;
  reswapbomb=2;
  barrelbomb=5;
  maxpmaxx=200;
  maxpmaxy=200;
  cwall = 1 shl 0;  cstand= 1 shl 1;  cwater= 1 shl 2;  clava = 1 shl 3; cshl= 1 shl 4; cshr= 1 shl 5;
     cFunc= 1 shl 6; cDeath=1 shl 7;

  cOverDraw=cshl+cshr; // Поверх

  cjump = 1 shl 0;
  cimp = 1 shl 1; cgoal = 1 shl 0;
  maxmon=196;
  maxitem=256;
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
  scroolspeed=8;
  truptime=45;
  reswaptime:integer=60;  monswaptime:integer=30;
  botsee:array[1..5]of integer=(800,600,400,200,0);
  edwallstr:array[1..8]of string[16]=
  ('Стена',  'Ступень',  'Вода',  'Лава',  '<< /Over',  '>> /Over',  'Function',  'Deathmatch');
{  ednodestr:array[1..4]of string[16]=
  ( 'Цель-Выход',  'Важный',  'Предмет',  '-'  );}
  maxedmenu=12+5+4+1+2+1;
  edmenustr:array[1..maxedmenu]of string[16]=
  ('Выход',  'Сохранить',  'Загрузить',  'Новая',  'Текстуры',  'Стены',
   'Монстры',  'Предметы',  'Функции',  'Скрытые',  'Пути',  '(C)',
   'Оружие','Патроны','Аптечки','Интерьер','Колонны',
   '','Пусто','Стена','Ступень','Обои','Текстуры+','Стены+','Сообщения');
type
  real=single;
  tcapt=array[1..4]of char;
  tcolor=record
    m,r:byte;
    del:real;
  end;
  tkeys=array[1..maxkey]of boolean;
const
  origlev:tcapt='FL04'; lever00:tcapt='FLEV';
  maxallpl:integer=4;
  blood:tcolor=(m:180; r:12; del: 4{6}{3.5});
  water:tcolor=(m:200; r:8; del:2.5);
  blow:tcolor=(m:160; r:8; del:2.5);
  ice:tcolor=(m:186; r:10; del:2.5);
  air:tcolor=(m:192; r:2; del: 30);
type
{   tnpat=0..maxpat;}
   tmsg=object
     enable: boolean;
     x,y,sx,sy: integer;
     msg: string[80];
     procedure init(ax,ay,asx,asy: integer; a:string);
     procedure event;
     procedure draw(ax,ay: integer);
     procedure done;
   end;
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
  ttime=object
    fin: longint;
    procedure init(a: real {sec});
    procedure add(a:real);
    procedure clear;
    function getest: real;
    function ready: boolean;
    function en: boolean;
  end;
  tobj=object
    enable,standing,first,down,elevator,upr:boolean;
    lx,ly,mx,my,startx,starty:integer; {map}
    savex,savey:real;
    x,y,dx,dy:real;
    constructor newObj;
    procedure init(ax,ay,adx,ady:real; af:boolean);
    function getstand:boolean; virtual;
    function getgrid:byte;
    function getsx:integer; virtual;
    function getsy:integer; virtual;
    function getftr:real; virtual;
    function getupr:real; virtual;
    function getg:real; virtual;
    function check:boolean; virtual;
    procedure move;   virtual;
    procedure draw(ax,ay:integer);
    procedure done;   virtual;
    function inwall(c:byte):boolean; virtual;
    function inwater:boolean; virtual;
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
    water: boolean;
    procedure init(ax,ay,adx,ady:real; ac:longint; al:real);
    procedure move; virtual;
    procedure draw(ax,ay:integer);
    function getg:real; virtual;
  end;
  tstate=(stand,run,fire,die,crash,hack,hai, duck);
  tmon=object(tobj)
     life,ai,know,see,barrel,aqua,sniperman: boolean;
     target: record x,y,mon:integer end;
     who,lastwho: integer{0..maxmon};
     angle,co,si: real;
     dest: tdest;
     tip: tmaxmontip;
     vis,hero,longjumpn,jumpfr,statedel,savedel :longint;
     armorhit,armorbomb,armoroxy,armorfreez,qdamage,god,delay,freez,fired,deldam : ttime;
     state,curstate:tstate;
     health,armor,buhalo,vempire,oxy,oxylife,g,usk,longjump:real;
     weap: longint{tmaxweapon};
     w:array[tmaxweapon]of byte;
     key:set of 1..maxkey;
     bul:array[tmaxbul]of integer;

     function getstand:boolean; virtual;
     function getcx:real;
     function getcy:real;
     function clever: boolean;
     function getmaxhealth: real;
     function getg:real; virtual;
     function onhead(ax,ay: integer):boolean;
     procedure clearwall(c:byte);
     procedure fillwall(c:byte);
     procedure takebest(mode:integer);
     procedure init(ax,ay,adx,ady:real; at:tmaxmontip; ad:tdest; aw:longint; aai,af:boolean; ah:longint);
     function cantakeweap(n: longint):boolean;
     function takegod(n:real):boolean;
     function takeweap(n:tmaxweapon):boolean;
     function takebul(n:tmaxbul; m:integer):boolean;
     function takeitem(nn:integer):boolean;
     function takearmor(n:real):boolean;
     function takehealth(n:real):boolean;
     function takemegahealth(n:real):boolean;
     procedure dier(dwho: integer);
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
     procedure setstate(astate:tstate; ad: real);
     procedure setcurstate(astate:tstate; ad: real);
     procedure kill(dwho: integer);
     procedure explode(dwho: integer);
     procedure giveweapon;
     procedure moveai;
     procedure done; virtual;
     procedure setdelay(n:real);
  end;
  tbul=object(tobj)
     who,tip,etime: integer;
     qdamage: integer;
     range: longint;
     procedure init(ax,ay, adx,ady:real; at,aw:integer; qd: boolean);
     procedure draw(ax,ay:integer);
     procedure move; virtual;
     function check:boolean; virtual;
     procedure detonate;
     function getftr:real; virtual;
     function getupr:real; virtual;
     function getg:real; virtual;
  end;
  titem=object(tobj)
    tip: tmaxit;
    function getftr:real; virtual;
    function getg:real; virtual;
    procedure init(ax,ay,adx,ady:real; at:integer; af:boolean);
    procedure draw(ax,ay:integer);
    procedure done; virtual;
  end;
  tF=object(tobj)
    tip,sx,sy: integer;
    dest: tdest;
    procedure init(ax,ay,asx,asy,at,an:integer);
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
     x,y{,life,maxlife}: integer;
     life: ttime;
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
  arrayofpix =array[0..maxarraypix ]of tpix;
  arrayofpul =array[0..maxpul ]of tbul;
  arrayofbomb=array[0..maxexpl]of tbomb;
  arrayofnode=array[0..maxnode]of tnode;
  tmap=object
    name:string[32];
    copy,com:string;
    land:tland;
    x,y,dx,dy:longint;
    totmon, totitem: longint;
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
    msg: array[0..maxmsg]of tmsg;
    wallpaper: string;
    wlp: tnpat;
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
    function initbul(ax,ay,adx,ady:real; at,who:integer; qd: boolean):integer;
    function initpix(ax,ay,adx,ady:real; ac:longint; al:real):integer;
    function initf(ax,ay,asx,asy,atip:integer):integer;
    function initmsg(ax,ay,asx,asy:integer):integer;
    function inititem(ax,ay,adx,ady:real; at:integer; af:boolean):integer;
    procedure randompix(ax,ay,adx,ady,rdx,rdy:real; ac:tcolor);
    function space(ax,ay: integer): boolean;
  end;
  ted=object
    what: (face,wall,mons,items,func,node, wlp, fillwall, fillface, mes);
    startd,startd2,endd,endd2: record x,y: integer; end;
    drag,drag2: boolean;
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
    startx,starty,deftip,n,frag,die,kill, taken:longint;
    startdest:tdest;
    health,maxhealth,armor,oxy:real;
    drugs,reverse,shift,cwave: ttime;
    weap: tmaxweapon;
    tip,ammo,ammo2,x1,y1,x2,y2:longint;
    hero: longint;
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
  tloadext=(firstlev,nextlev, loadlev);
  tlevel=object
    max,cur:integer;
    name:array[0..40]of string[8];
    skill: longint;
    editor,endgame,multi,death,first,rail,look,sniper,reswap,started,cheater,training:boolean;
    maxpl:integer;
    start,curtime: longint;
    alltime: longint;
    procedure setup;
    function loadini(a,b:string):boolean;
    procedure load(a: tloadext);
    procedure loadfirst;
    procedure next;
    procedure add(a:string);
  end;
  tinfo=object
    l:array[0..maxl]of record
      s:string;
      c: color;
      time: ttime;
    end;
    ml: integer;
    procedure clear;
    procedure add(astr:string; ac:color; at:real);
    procedure move;
    procedure draw(ax,ay: integer);
    procedure delete(a:integer);
  end;
(******************************** Variables *********************************)
var
  scrmode: (normal,reverse,shift,wave);
  settings:record
    botdelay,mondelay, botgetgoal, botreset: integer;
  end;
  unpush: boolean;
  keybuf,wintext1,wintext2:string;
  pnode,pnodei,pnodeg, panel1,panel2: tnpat;
  time,rtimer:ttimer;
  map:tmap;
  speed:real;
  ed:ted;
  d:array[0..9]of tnpat;
  dminus,dpercent:tnpat;
  allwall: arrayofstring8;
  mx,my,lastx,lasty,add, hod:longint;
  push,push2,push3,loaded, si, origlevels:boolean;
  mfps,maxallwall:longint;
  cur:tnpat;
  player:array[1..maxplays]of tplayer;
  level:tlevel;
  info: tinfo;
  lastinidir,winallbmp,startbmp,winbmp,losebmp:string;
  botcol:array[1..maxplays]of color;
  must:array[0..maxmust]of record
    tip: integer;
    x,y,curtip: integer;
    dest: tdest;
    delay: ttime;
  end;

{ Sound system }
var
  soundEnabled: boolean;
  soundCache: array[0..63] of record
    name: string[32];
    chunk: PMix_Chunk;
  end;
  soundCacheCount: integer;
  menuNavSound: string[32];
  menuSelectSound: string[32];
  menuBackSound: string[32];

function LoadSound(name: string): PMix_Chunk; forward;
procedure InitSound; forward;
procedure DoneSound; forward;
procedure PlaySound(name: string); forward;

procedure loadmod(a:string); forward;
(******************************** IMPLEMENTATION ****************************)

{ Sound system implementation }
function LoadSound(name: string): PMix_Chunk;
var i: integer; path: string;
begin
  LoadSound := nil;
  if (not soundEnabled) or (name = '') then exit;
  for i := 0 to soundCacheCount - 1 do
    if soundCache[i].name = name then begin
      LoadSound := soundCache[i].chunk;
      exit;
    end;
  if soundCacheCount < 64 then begin
    path := 'RF/sfx/' + name + #0;
    soundCache[soundCacheCount].name := name;
    soundCache[soundCacheCount].chunk := Mix_LoadWAV(@path[1]);
    LoadSound := soundCache[soundCacheCount].chunk;
    inc(soundCacheCount);
  end;
end;

procedure InitSound;
var i: integer;
begin
  soundEnabled := false;
  soundCacheCount := 0;
  if Mix_OpenAudio(22050, MIX_DEFAULT_FORMAT, 2, 2048) < 0 then begin
    exit;
  end;
  Mix_AllocateChannels(16);
  soundEnabled := true;

  for i := -maxweapon to maxweapon do begin
    LoadSound(weapon[i].shotSound);
    LoadSound(weapon[i].pickupSound);
  end;
  for i := 1 to maxmontip do begin
    LoadSound(monster[i].hitSound);
    LoadSound(monster[i].dieSound);
  end;
  for i := 1 to maxbul do
    LoadSound(bul[i].hitSound);
  for i := 1 to maxbomb do
    LoadSound(bomb[i].sound);
  for i := 1 to maxit do
    LoadSound(it[i].pickupSound);
  { Menu sounds }
  LoadSound(menuNavSound);
  LoadSound(menuSelectSound);
  LoadSound(menuBackSound);
end;

procedure DoneSound;
var i: integer;
begin
  if not soundEnabled then exit;
  for i := 0 to soundCacheCount - 1 do
    if soundCache[i].chunk <> nil then
      Mix_FreeChunk(soundCache[i].chunk);
  Mix_CloseAudio;
  soundEnabled := false;
end;

procedure PlaySound(name: string);
var
  chunk: PMix_Chunk;
  sounds: array[0..7] of string[32];
  count, i, p: integer;
  s: string;
begin
  if name = '' then exit;
  if debug then writeln('PlaySound: ', name);

  { Parse comma-separated sounds }
  count := 0;
  s := name + ',';
  while (pos(',', s) > 0) and (count < 8) do begin
    p := pos(',', s);
    sounds[count] := copy(s, 1, p - 1);
    delete(s, 1, p);
    while (length(sounds[count]) > 0) and (sounds[count][1] = ' ') do
      delete(sounds[count], 1, 1);
    if sounds[count] <> '' then inc(count);
  end;

  if count = 0 then exit;

  { Pick random sound }
  i := random(count);
  chunk := LoadSound(sounds[i]);
  if chunk <> nil then
    Mix_PlayChannel(-1, chunk, 0);
end;

procedure tmsg.init(ax,ay,asx,asy: integer; a:string);
begin
  enable:=true;
  x:=ax; y:=ay;
  sx:=sy; sy:=asy;
  msg:=a;
end;
procedure tmsg.event;
begin
  info.add(msg,white,10);
  done;
end;
procedure tmsg.draw(ax,ay: integer);
begin
  rectangle(x-ax,y-ay,x-ax+sx,y-ay+sy,yellow);
{  for i:=0 to maxfname do
    if fname[i].n=tip then begin cur:=i; break; end;
  p[fname[cur].skin].spritesp(mx-ax,my-ay);}
  print(x-ax,y-ay,yellow,msg);
end;
procedure tmsg.done;
begin
  enable:=false;
end;

procedure error(a:string);
begin
  clear;
  wb.print((getmaxx-wb.width(a))div 2, getmaxy div 2 - 40, a);
  screen;
  readkey;
end;
procedure ttime.init(a: real {sec});
begin
  fin:=time.tik+round(a*tps);
  if a<0 then fin:=maxlongint;
end;
procedure ttime.clear;
begin
  fin:=0;
end;
procedure ttime.add(a: real {sec});
begin
  if ready then fin:=time.tik;
  fin:=fin+{time.tik+}round(a*tps);
  if a<0 then fin:=maxlongint;
end;
function ttime.ready: boolean;
begin
  ready:=(time.tik>=fin){and(fin>0)};
end;
function ttime.en: boolean; // enable
begin
  en:=time.tik<fin;
end;
function ttime.getest: real;
begin
  getest:=(fin-time.tik)/tps;
end;

procedure outtro;
var
  i:integer;
begin
  writeln('The ',game,' <-> ',version,' [',data,']');
  for i:=1 to maxtit do begin
    writeln(tit[i]);
  end;
{  textattr:=4+8;
  writeln('Запускайте только RF.BAT !!! (иначе у вас не будет работать клавиатура)');
  textattr:=7;}
//  textattr:=14;
//  writeln('*** Если у вас проблемы с графикой - '
//   #13#10'замените число в первой строчке в файле res.ini на 0');
//  textattr:=7;
//  writeln(':)');
end;
procedure firstintro;
begin
  writeln(title);
  outtro;
end;
function tmon.clever: boolean;
begin
  clever:=(monster[tip].health>200){or(level.sniper and ai)};
end;
function tmon.onhead(ax,ay: integer):boolean;
begin
  onhead:=(abs(ax-getcx)<getsx*8)and
   ((abs((getcy-getsy*4)-ay)<=16)or
    (abs((getcy+getsy*4)-ay)<=16));
end;

procedure tinfo.clear;
begin
  ml:=0;
end;
procedure tinfo.add;
begin
  if not level.started then exit;
  if astr='' then exit;
  if ml=maxl then delete(1);
  inc(ml);
  l[ml].s:=astr;
  l[ml].c:=ac;
//  if speed<>0 then
  l[ml].time.init(at);
end;
procedure tinfo.move;
var
  i: integer;
begin
  i:=1;
  while i<=ml do
   begin
//     dec(l[i].time);
     if l[i].time.ready then delete(i)
     else
     inc(i);
   end;
end;

procedure tinfo.draw(ax,ay: integer);
const
  h=10;
var
  i,y,c: integer;
begin
  y:=0;
  for i:=1 to ml do begin
    if l[i].time.getest>1 then begin
      print(ax,ay+y, l[i].c, l[i].s);
      inc(y,h);
    end
    else begin
      c:=getcolor(
      round(pal[l[i].c*4+2]*l[i].time.getest),
      round(pal[l[i].c*4+1]*l[i].time.getest),
      round(pal[l[i].c*4+0]*l[i].time.getest));

      print(ax,ay+y,c, l[i].s);
      inc(y,round(h*l[i].time.getest));
    end
  end;
end;

procedure tinfo.delete(a:integer);
var
  i:integer;
begin
 for i:=a to ml-1 do
   l[i]:=l[i+1];
  dec(ml);
end;

function tmon.getcx:real;
begin
  getcx:=x;
end;
function tmon.getcy:real;
begin
  getcy:=y-getsy*4;
end;

procedure tmon.setdelay(n:real);
begin
  delay.init(n/usk);
end;
function tobj.getg:real;
begin
  getg:=map.g;
end;
function tmon.getg;
begin
  if inwater or monster[tip].turret or monster[tip].fly then getg:=0 else
    getg:=g;
end;
function tbul.getg;
begin
  getg:=bul[tip].g;
end;
function titem.getg;
begin
  case it[tip].cant of
  false: getg:=map.g;
  true: getg:=0;
  end;
end;

procedure putlogo(a,b:string; del: integer);
var
  c,i,j: integer;
begin
  clear;
  box(0,0,getmaxx,getmaxy);
  c:=1;
  while bmpexist(a+st(c)) do inc(c);
  dec(c);
  c:=random(c)+1;
  if bmpexist(a+st(c)) then begin
    putbmpall(a+st(c));
    rb.print((getmaxx-rb.width(b)) div 2,getmaxy-10,b);
    screen;
    delay(del);
  end;
end;
procedure winallgame;
begin
  clear;

//  putbmpall(winallbmp);

  putlogo(winallbmp,'',0);

  wb.print((getmaxx-wb.width(wintext1))div 2,getmaxy div 2-40,wintext1);
  wb.print((getmaxx-wb.width(wintext2))div 2,getmaxy div 2,wintext2);
  screen;
  delay(10);
  winall:=true;
end;
function menu(max,def:integer; title: string):integer;
var
  ch,hod,enter,i,maxl,mouseItem:integer;
  wasMousePressed,mousePressed:boolean;
  mouseY,lastMouseY:integer;
  keyboardMode:boolean;
const
  x1:integer=80;
  y1:integer=50;
  d=22;
procedure draw;
var
  i,j,sx,sy:integer;
  tt: string;
begin
  clear;

{  putintro('intro');}

  sx:=(getmaxx-p[intro].x) div 2;
  sy:=(getmaxy-p[intro].y) div 2;

  p[intro].put(sx,sy);

{  wb.print(x1,y1+(i-1)*d,men[i]);}

  wb.print(x1,y1-d*2,title);

  for i:=1 to max do
    wb.print(x1,y1+(i-1)*d,men[i]);
  if hod mod 90<45 then j:=skull1 else j:=skull2;
  p[j].sprite(x1-30,y1-5+(ch-1)*d);

  tt:=menutitle+': '+runmod+' ['+version+']';
  box(0,0,getmaxx, getmaxy);
  rb.print((maxx-rb.width(tt))div 2,maxy-10, tt);

  screen;
end;
procedure nav(newCh: integer);
begin
  if ch <> newCh then begin
    PlaySound(menuNavSound);
    ch := newCh;
  end;
  keyboardMode := true;
end;
procedure sel;
begin
  PlaySound(menuSelectSound);
  enter := ch;
end;

begin
  while keypressed do readkey;
  maxl:=150;
  for i:=1 to max do
    if wb.width(men[i])>maxl then maxl:=wb.width(men[i]);
  x1:=(getmaxx-maxl)div 2;
  if x1<30 then x1:=30;

  level.endgame:=false;
  if max=1 then begin menu:=def; exit; end;
  if max=0 then begin menu:=0; exit; end;

  ch:=def;  hod:=0; enter:=0;
  wasMousePressed:=sdlinput.push;
  lastMouseY:=Y;
  keyboardMode:=false;
  if (ch<1)or(ch>max)then ch:=1;
  repeat
    inc(hod);
    y1:=(getmaxy-max*d)div 2;
    if y1<30 then y1:=30;
    if (y1+(ch-1)*d>getmaxy-30)then y1:=-(ch-1)*d+getmaxy-30;
    draw;
    { Mouse handling }
    PollEvents;
    mousePressed := sdlinput.push;
    mouseY := Y;
    { If mouse moved - disable keyboard mode }
    if mouseY <> lastMouseY then keyboardMode := false;
    lastMouseY := mouseY;
    { Mouse affects selection only if NOT in keyboard mode }
    if (not keyboardMode) and (mouseY >= y1) and (mouseY < y1 + max*d) then
    begin
      mouseItem := (mouseY - y1) div d + 1;
      ch := mouseItem;
      if mousePressed and not wasMousePressed then begin
        PlaySound(menuSelectSound);
        enter := mouseItem;
      end;
    end;
    wasMousePressed := mousePressed;
    if quit_requested then break;
    if keypressed then
    case readkey of
      #13: sel;
      #27: begin PlaySound(menuBackSound); break; end;
      #9:  nav((ch) mod max + 1);
      #0:case readkey of
        #80: if ch<max then nav(ch+1);   {Down}
        #72: if ch>1 then nav(ch-1);     {Up}
        #73: nav(1);                      {PgUp}
        #81: nav(max);                    {PgDn}
        #71: nav(1);                      {Home}
        #79: nav(max);                    {End}
       end;
    end;
  until (enter>0) or quit_requested;
  menu:=enter;
  while keypressed do readkey;
end;
procedure weaponinfo;
var i:integer;
begin
//  writeln;
//  writeln('Урон от оружия в секунду.');
  for i:=0 to maxweapon do
   with weapon[i] do
   if name<>'' then
   begin
     write(name:16,' - ',damages:6:2);
     if bomb>0 then write(' / Взрыв - ',bomb:6:2);
     if hits>0 then write(' / Ближнее - ',hits:6:2);
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

  assign(f,a{+dotmod});
{$i-}  reset(f); {$i+}
  if ioresult<>0 then begin writeln('WARNING: ',a,' file not found !!!'); exit;end;
  checkcrc(a);

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
      if s1='parent' then
        loadmod(s2);

{      if s1='bmpdir' then
        dbmp:=s2+'/';}

      if s1='intro' then
        intro:=loadasbmp(s2);

      if s1='panel1' then
        panel1:=loadasbmp(s2);
      if s1='panel2' then
        panel2:=loadasbmp(s2);

      if s1='blood' then
        bloodu:=vlr(s2);
      if s1='speed' then
        ausk:=vlr(s2);

      if s1='fraglimit' then
        fraglimit:=vl(s2);

      if s1='diskload' then
        diskload:=boolean(s2='true');
      if s1='origlevels' then
        origlevels:=boolean(s2='true');

      if s1='30fps' then
        sfps:=boolean(s2='true');

      if s1='cursor' then begin
        skull1:=loadbmp(s2+'1');
        skull2:=loadbmp(s2+'2');
      end;

      if s1='vis' then
        for i:=1 to 8 do en[i]:=loadbmp(s2+st(i));

      if s1='freeitem' then
        freeitem:=vl(s2);
      if s1='wintext1' then wintext1:=s2;
      if s1='wintext2' then wintext2:=s2;
      if s1='winallbmp' then winallbmp:=s2;

//      if s1='inidir' then inidir:=mainmod+'\'+s2+'\';

      if s1='free death item' then
        freemultiitem:=vl(s2);
      if s1='health' then
        playdefhealth:=vl(s2);
      if s1='maxarmor' then
        playmaxarmor:=vl(s2);

      if s1='defitem' then
        playdefitem:=vl(s2);
      if s1='death item' then
        multiitem:=vl(s2);
      if copy(s1,1,3)='tip' then
        tip[vl(copy(s1,4,1))]:=vl(s2);

      if s1='start' then startbmp:=s2;
      if s1='win' then winbmp:=s2;
      if s1='lose' then losebmp:=s2;

      if s1='menunavsound' then menuNavSound:=s2;
      if s1='menuselectsound' then menuSelectSound:=s2;
      if s1='menubacksound' then menuBackSound:=s2;
    end;
  end;
end;
function tmap.space(ax,ay: integer): boolean;
var
  l: longint;
begin
  space:=true;
  ax:=ax div 8;
  ay:=ay div 8;
  if (ax>0)and(ay>0)and(ax<x)and(ay<y) then
  begin
    l:=land[ay]^[ax].land;
    space:=(l and cwall)=0 {)or((l and cfunc)=0)};
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
   '-': p[dminus].sprite(x+i*dsize,y);
   '%': p[dpercent].sprite(x+i*dsize,y);
   '0'..'9': p[d[vl(s[i])]].sprite(x+i*dsize,y);
  end;
end;

function strtime(a:longint): string;
var
 r:string;
begin
  r:=st(a mod 60)+' сек';
  a:=a div 60;
  if a>0 then
    r:=st(a mod 60)+' мин '+ r;
  a:=a div 60;
  if a>0 then
    r:=st(a)+' час '+ r;

  strtime:=r;
end;

procedure drawwin;
const
  kills='Убийства - ';
  items='Предметы - ';
  times='Время - ';
  alltimes='Всего - ';
var
  c,i,j: integer;
  a,b: string;
  del: longint;
begin
  if level.training then exit;
  level.alltime:=level.alltime+level.curtime-level.start;
  a:=winbmp;
  b:='Теперь можно отпраздновать победу';
  del:=6;
  clear;
  box(0,0,getmaxx,getmaxy);
  c:=1;
  while bmpexist(a+st(c)) do inc(c);
  dec(c);
  c:=random(c)+1;
  if bmpexist(a+st(c)) then begin
    putbmpall(a+st(c));
    rb.print((getmaxx-rb.width(b)) div 2,getmaxy-10,b);
    if level.multi then delay(del);
  end;

  if not level.multi then begin
{    wb.print((getmaxx-rb.width(map.name)) div 2, 100, map.name);}
    if map.totmon<>0 then begin
      wb.print(100, 20, Kills);
      digit(100+wb.width(Kills),18,round(player[1].kill/map.totmon*100),'%');
    end;

    if map.totitem<>0 then begin
    wb.print(300, 20, Items);
    digit(300+wb.width(items),18,round(player[1].taken/map.totitem*100),'%');
    end;

    wb.print(100, 50, Times+strtime(round((time.tik-level.start)/tps)));
    wb.print(100, 80, allTimes+strtime(round((level.alltime)/tps)));
    screen;
    delay(del);
  end;
end;
procedure drawlose;
begin
  if level.training then exit;
  putlogo(losebmp,'У вас проблемы со здоровьем',3);
end;
procedure drawintro;
begin
  if level.training then exit;
  putlogo(startbmp,'И вот время...',3);
  time.move;
//  level.start:=time.cur;
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
  i,j,t, k:longint;
begin
  for i:=0 to maxnode do n^[i].c:=0;

  for i:=0 to maxnode do
   if n^[i].enable then
    for j:=0 to n^[i].maxl do
    begin
      t:=n^[i].l[j].n;
      n^[i].l[j].d:=round(sqrt(sqr(n^[t].x-n^[i].x))+sqr(n^[t].y-n^[i].y));

   with map do
    for k:=0 to maxf do
     if f^[k].enable then
     if
     (mx>=f^[k].x)and
     (my>=f^[k].y)and
     (mx<=f^[k].x+f^[k].getsx)and
     (my<=f^[k].y+f^[k].getsy)
      then case f^[k].tip of
        13,25{Teleport}: n^[i].l[j].d:=0;
        end;
    end;

  for i:=0 to maxnode do
    for j:=0 to maxf do
     if f^[j].enable then
     if  (n^[i].mx>=f^[j].x)and
         (n^[i].my>=f^[j].y)and
         (n^[i].mx<=f^[j].x+f^[j].getsx)and
         (n^[i].my<=f^[j].y+f^[j].getsy)
           then if f^[j].tip in [10,15] then n^[i].c:=n^[i].c or cgoal;
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
  if c=0 then p[pnode].spritec(mx-ax,my-ay);
  if c and cimp>0 then p[pnodei].spritec(mx-ax,my-ay);
  if c and cgoal>0 then p[pnodeg].spritec(mx-ax,my-ay);
  for i:=0 to maxl do
  begin
    if (l[i].c and cjump)>0 then col:=red else col:=green;
    tx:=map.n^[l[i].n].mx;
    ty:=map.n^[l[i].n].my;
    line(mx-ax,my-ay,
    (tx+mx)div 2-ax,
    (ty+my)div 2-ay,col);
  end;
  if debug and not (rf.level.editor) then
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
    player[1].init(0,0,getmaxx,getmaxy,60,270,tip[1],right,'Player',1,bot[1]);
    player[1].settip(tip[1]);
  end;
  true:
  begin
    maxpl:=maxallpl;
   for i:=1 to maxpl do {InitBots}
   begin
    case scrc[i] of
      all: begin x1:=0; x2:=getmaxx; y1:=0; y2:=getmaxy ;end;
      up: begin  x1:=0; x2:=getmaxx; y1:=0; y2:=getmaxy div 2;end;
      down: begin x1:=0; x2:=getmaxx; y1:=1+getmaxy div 2; y2:=getmaxy ;end;
      ul: begin  x1:=0; x2:=getmaxx div 2; y1:=0; y2:=getmaxy div 2;end;
      dl: begin  x1:=0; x2:=getmaxx div 2; y1:=1+getmaxy div 2; y2:=getmaxy;end;
      ur: begin  x1:=1+getmaxx div 2; x2:=getmaxx; y1:=0; y2:=getmaxy div 2;end;
      dr: begin  x1:=1+getmaxx div 2; x2:=getmaxx; y1:=1+getmaxy div 2; y2:=getmaxy;end;
      else  {none} begin x1:=0; x2:=0; y1:=0; y2:=0 ;end;

    end;
    player[i].init(x1,y1,x2,y2,50*i,60*i,tip[i],right,'No name',i,bot[i]);
    player[i].settip(tip[i]);
  end;
 end;
 end;
 for i:=1 to maxpl do
 begin
   fillchar(player[i].key,sizeof(player[i].key),0);
   player[i].settip(tip[i]);
 end;
end;
procedure tlevel.loadfirst;
begin
  setup;
  cur:=1; load(firstlev);
end;

procedure tf.door;
var
  ti,tj,j: integer;
  x1,y1,x2,y2: integer;
  v,i: integer;
  a,bb: string;
begin
  if not enable then exit;
  j:=id+1;
  with map do begin
    x1:=(round(f^[j].x) div 8);
    x2:=round(f^[j].x+f^[j].sx) div 8;
    y1:=(round(f^[j].y) div 8);
    y2:=round(f^[j].y+f^[j].sy) div 8;
    for ti:=x1 to x2 do
      for tj:=y1 to y2 do begin
        land[tj]^[ti].vis:=byte(f^[id].tip=16);
        land[tj]^[ti].land:=byte(f^[id].tip=16);
      end;

    x1:=(round(f^[id].x) div 8);
    x2:=round(f^[id].x+f^[j].sx) div 8;
    y1:=(round(f^[id].y) div 8);
    y2:=round(f^[id].y+f^[j].sy) div 8;
    for ti:=x1 to x2 do
      for tj:=y1 to y2 do begin
        v:=land[tj]^[ti].vis;
        if v>0 then
          if downcase(system.copy(patname^[v],1,2))='sw' then
          begin
            bb:=system.copy(map.patname^[v],6,1);
            if bb='0' then bb:='1' else
            if bb='1' then bb:='0';
            a:=system.copy(patname^[v],1,5)+bb;
            land[tj]^[ti].vis:=map.addpat(a);
          end;
      end;
  end;
  enable:=false;
  tip:=0;
end;

procedure tlevel.load;
var i:integer;
begin
  info.clear;
{ if not first then} started:=false;
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
  started:=true;
  info.clear; speed:=1;
  info.add(map.copy,dark,10);
  info.add(map.com,dark,10);
  case a of
    firstlev: begin start:=time.tik; alltime:=0; end;
    nextlev: begin start:=time.tik;  end;
    loadlev: begin start:=time.tik-(curtime-start); end;
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
      load(nextlev);
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
    load(nextlev);
  end;
 end;
end;

function tlevel.loadini(a,b:string):boolean;
var
  f:text;
  s: string;
begin
  assign(f,a{+dotmod});
{$i-}  reset(f); {$i+}
  if ioresult<>0 then begin loadini:=false; exit; end;
  cur:=0; max:=0;

  repeat
    readln(f,s);
  until (downcase(s)='[levellist-'+b+']')or(eof(f));
  if eof(f) then begin loadini:=false; close(f); exit; end;
  repeat
    inc(max);
    readln(f,name[max]);
  until eof(f) or (downcase(name[max])='end');
  close(f);
  dec(max);
  loadini:=true;
  writeln('Levels formod ',a,' loaded!');
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
     must[i].delay.init(del);
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
  drugs.clear;
  cwave.clear;
  shift.clear;
  reverse.clear;
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

procedure tf.init(ax,ay,asx,asy,at,an:integer);
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

  if (tip in [13,12,25,23,26,27]) then
  for i:=max(0,ax div 8) to min(map.x-1,(ax+asx)div 8) do
    for j:=max(0,ay div 8) to min(map.y-1,(ay+asy)div 8) do
     map.land[j]^[i].land:=map.land[j]^[i].land or cfunc;

  if (at=14 {target})and(map.f^[an-1].tip in [13,25]{Teleport})then begin
    sx:=map.f^[an-1].sx;
    sy:=map.f^[an-1].sy;
  end;
end;
function tmon.takegod(n:real):boolean;
begin
  if god.ready then
  begin
    god.init(n);
    takegod:=true;
    if not level.multi then
      info.add('Вы взяли бессмертие !',red,5);
  end
   else
    takegod:=false;
end;

function tmon.takearmor(n:real):boolean;
begin
  if armor<playmaxarmor then begin
    armor:=armor+n;
    takearmor:=true;
    if armor>playmaxarmor then armor:=playmaxarmor;
    if (not level.multi)and (hero>0) then
      info.add('Вы взяли '+st(round(n))+' брони',yellow,5);
  end
  else
    takearmor:=false;
end;

function tmon.getmaxhealth: real;
begin
  if hero>0 then
   getmaxhealth:=playdefhealth
  else
    getmaxhealth:=monster[tip].health;
end;

function tmon.takehealth(n:real):boolean;
begin
  if health>=getmaxhealth then begin takehealth:=false; exit; end;

  if not level.multi and (hero>0) then
    info.add('Вы взяли '+st(round(n))+' здоровья',green,5);

  health:=health+n;
  fired.clear;
  if health>getmaxhealth then health:=getmaxhealth;
  takehealth:=true;
end;
function tmon.takemegahealth(n:real):boolean;
begin
  if health>=getmaxhealth*2 then begin takemegahealth:=false; exit; end;
  health:=health+n;

  if not level.multi and (hero>0) then
    info.add('Вы взяли '+st(round(n))+' здоровья',green,5);

  fired.clear;
  if health>getmaxhealth*2 then health:=getmaxhealth*2;
  takemegahealth:=true;
end;

function tmon.takeitem(nn:integer):boolean;
var
  ok:boolean;
begin
  ok:=false;
  if it[nn].god<>0 then
     ok:=takegod(it[nn].god) or ok;

  if (it[nn].drugs<>0)and(hero<>0) then begin
    player[hero].drugs.add(it[nn].drugs);
    ok:=true;
  end;
  if (it[nn].wave<>0)and(hero<>0) then begin
    player[hero].cwave.init(it[nn].wave);
    ok:=true;
  end;
  if (it[nn].shift<>0)and(hero<>0) then begin
    player[hero].shift.init(it[nn].shift);
    ok:=true;
  end;
  if (it[nn].reverse<>0)and(hero<>0) then begin
    player[hero].reverse.init(it[nn].reverse);
    ok:=true;
  end;

  if it[nn].longjump<>0 then begin
    longjump:=it[nn].longjump;
    inc(longjumpn,it[nn].longjumpn);
    ok:=true;
  end;
  if it[nn].armorhit<>0 then begin
    armorhit.add(it[nn].armorhit);
    ok:=true;
  end;
  if it[nn].armorbomb<>0 then begin
    armorbomb.add(it[nn].armorbomb);
    ok:=true;
  end;
  if it[nn].armoroxy<>0 then begin
    armoroxy.init(it[nn].armoroxy);
    ok:=true;
  end;
  if it[nn].armorfreez<>0 then begin
    armorfreez.init(it[nn].armorfreez);
    ok:=true;
  end;
  if it[nn].qdamage<>0 then begin
    qdamage.init(it[nn].qdamage);
    ok:=true;
  end;
  if it[nn].aqua then begin
    aqua:=true;
    ok:=true;
  end;

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
  if ok then PlaySound(it[nn].pickupSound);
  takeitem:=ok;
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
var
  i:integer;
procedure fill(n: tnpat);
var
  i,j,x,y,dx,dy: integer;
begin
  x:=p[n].x;
  y:=p[n].y;

  dx:=(map.dx div 2 mod x);
  dy:=(map.dy div 2 mod y);

  for i:=x1 div x-1 to x2 div x+1 do
    for j:=y1 div y-1 to y2 div y+1 do
      p[n].sprite(i*x-dx,j*y-dy);
end;
begin
  if not level.editor then
  begin
    god:=map.m^[hero].god.en;
    weap:=map.m^[hero].weap;
    health:=map.m^[hero].health;
    oxy:=map.m^[hero].oxy;
    armor:=map.m^[hero].armor;
    tip:=map.m^[hero].tip;

    maxhealth:=map.m^[hero].getmaxhealth;

    ammo:=map.m^[hero].bul[weapon[weap].bul];
    ammo2:=map.m^[hero].bul[weapon[-weap].bul];
    if not drowed then exit;
    box(x1,y1,x2,y2);
    map.setdelta(round(map.m^[hero].x),round(map.m^[hero].y-14),(x2-x1) div 2,(y2-y1) div 2);
    if map.wlp=0 then
      sdlgraph.bar(x1,y1,x2,y2,fon)
    else
      fill(map.wlp);
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
    p[panel1].sprite(minx,maxy-40);
    if not god then
     if health>0 then
     p[en[norm(1,6,round(7-6*health/maxhealth))]].spritec(minx+20,maxy-20)
    else
     p[en[7]].spritec(minx+20,maxy-20)
    else
     p[en[8]].spritec(minx+20,maxy-20);

    digit(minx+34,maxy-37,round(health),'%');
    if round(armor)<>0 then
      digit(minx+34,maxy-17,round(armor),' ');

    for i:=1 to map.m^[hero].w[weap] do
      p[weapon[weap].skin].spritec(minx+165+(i-1)*10,maxy-20+(i-1)*10);

    if ammo>0 then
      digit(minx+105,maxy-37,ammo,' ');
    if (weapon[-weap].bul<>weapon[weap].bul)and(ammo2>0)then
      digit(minx+105,maxy-17,ammo2,' ');

    if not map.m^[hero].qdamage.ready then
      rb.print(minx+300,maxy-40,'QDamage: '+st(round(map.m^[hero].qdamage.getest)));
    if map.m^[hero].aqua then
      rb.print(minx+300,maxy-30,'Прыжки');
    if map.m^[hero].longjumpn>0 then
      rb.print(minx+300,maxy-20,'Прыжков: '+st(map.m^[hero].longjumpn));

    if not map.m^[hero].armorhit.ready then
      rb.print(minx+210,maxy-40,'Armor: '+st(round(map.m^[hero].armorhit.getest)));
    if not map.m^[hero].armorbomb.ready then
      rb.print(minx+210,maxy-30,'Bomb: '+st(round(map.m^[hero].armorBomb.getest)));
    if not map.m^[hero].armorfreez.ready then
      rb.print(minx+210,maxy-20,'No Freez: '+st(round(map.m^[hero].armorFreez.getest)));
    if not map.m^[hero].armoroxy.ready then
      rb.print(minx+210,maxy-10,'No Fire: '+st(round(map.m^[hero].armorOxy.getest)));

  end;
  true:
  begin
    rb.print(minx+5,miny+5,st(n));
{    p[en[norm(1,6,round(7-6*health/maxhealth))]].putblack(0,160);}
    p[panel2].sprite(maxx-60,miny);
    digit(maxx-56,miny+4,round(health),'%');
    digit(maxx-56,miny+17+4,round(armor),' ');

    for i:=1 to map.m^[hero].w[weap] do
      p[weapon[weap].skin].spritec(maxx-28+(i-1)*10,miny+50+(i-1)*10);

    digit(maxx-56,miny+50,ammo,' ');
    if (weapon[-weap].bul<>weapon[weap].bul)and(ammo2>0)then
      digit(maxx-56,miny+65,ammo2,' ');

    rb.print(maxx-57,miny+15+66,'Frags:'+st(frag));
    rb.print(maxx-57,miny+15+74,'Kills:'+st(kill));
    rb.print(maxx-57,miny+15+82,'Die: '+st(die));

    if map.m^[hero].qdamage.en then
      rb.print(maxx-60,miny+110,'QDam '+st(round(map.m^[hero].qdamage.getest)));
    if map.m^[hero].aqua then
      rb.print(maxx-60,miny+120,'Прыжки');
    if map.m^[hero].longjumpn>0 then
      rb.print(maxx-60,miny+130,'Jump '+st(map.m^[hero].longjumpn));

    if not map.m^[hero].armorhit.ready then
      rb.print(maxx-60,miny+140,'Armor '+st(round(map.m^[hero].armorhit.getest)));
    if map.m^[hero].armorbomb.en then
      rb.print(maxx-60,miny+150,'Bomb '+st(round(map.m^[hero].armorBomb.getest)));
    if map.m^[hero].armorfreez.en then
      rb.print(maxx-60,miny+160,'Freez '+st(round(map.m^[hero].armorFreez.getest)));
    if map.m^[hero].armoroxy.en then
      rb.print(maxx-60,miny+170,'Fire '+st(round(map.m^[hero].armorOxy.getest)));

    {    if god then digit(minx+(minx++maxx)div 2-24,miny+(maxy+miny)div 2+30,round(map.m^[hero].god/rtimer.fps),' ');}
    if miny>0 then line(minx,miny,maxx,miny,red);
    if maxy<my then line(minx,maxy,maxx,maxy,red);
    if minx>0 then line(minx,miny,minx,maxy,red);
    if maxx<mx then line(maxx,miny,maxx,maxy,red);
  end;
 end;
 if not level.editor then begin
  box(0,0,getmaxx,getmaxy);
  if oxy<100 then
    digit((x1+x2)div 2-20,(y1+y2)div 2+30,round(oxy),'%');
  if map.m^[hero].god.en and (map.m^[hero].god.getest<60) then
    digit((x1+x2)div 2-12,(y1+y2)div 2+30,round(map.m^[hero].god.getest),' ');
  if map.m^[hero].freez.en then
    digit((x1+x2)div 2-12,(y1+y2)div 2+30,round(map.m^[hero].freez.getest),' ');
 end;
{  if map.m^[hero].fired>0 then
    digit((x1+x2)div 2-12,(y1+y2)div 2+30,round(map.m^[hero].fired/rtimer.fps),' ');}
end;
procedure tmon.takebest(mode:integer);
var i,c:integer;
   dam:real;
begin
  dam:=0; c:=1;
  for i:=1 to maxweapon do
   if cantakeweap(i) then
    if dam<weapon[i].damages then
    if
    (mode=0)and(weapon[i].hit>0)or
    (mode=1)and(weapon[i].hit=0)and(weapon[i].bomb=0)or
    (mode=2)and(weapon[i].hit=0)
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
  if delay.en then exit; try:=0; last:=weap;
  repeat
    inc(try);
    inc(weap);
    if weap>maxweapon then weap:=1;
    if rfunit.weapon[weap].shortcut=n then
      if cantakeweap(weap)then break;
  until try>maxweapon;
  if try>maxweapon then weap:=last else
  setdelay(0.25);
end;
function tmon.cantakeweap(n: longint):boolean;
begin
  cantakeweap:=(w[n]>0)and ((bul[rfunit.weapon[n].bul]>=max(1,weapon[n].input))
  or(rfunit.weapon[n].hit>0));
end;
procedure tmon.takenext;
var
  try: integer;
begin
  try:=0;
  if delay.en then exit;
  repeat
    inc(try);
    inc(weap);
    if weap>maxweapon then weap:=1;
    if cantakeweap(weap)then break;
  until try>maxweapon;
  setdelay(0.25);
end;
procedure tmon.takeprev;
var
  try: integer;
begin
  try:=0;
  if delay.en then exit;
  repeat
    inc(try);
    dec(weap);
    if weap<0 then weap:=maxweapon;
    if cantakeweap(weap)then break;
  until try>maxweapon;
  setdelay(0.25);
end;
function tmap.getnode(mx,my:longint):integer;
function canmove(x1,y1,x2,y2: integer):boolean;
var
  i:integer;
  r:boolean;
begin
  r:=true;
{  for i:=x1 div 8 to x2 div 8 do
    r:=r and space(y1,i);}
  canmove:=r;
end;
var i,d,min,c:longint;
begin
  c:=-1;
  min:=maxint;
  for i:=0 to maxnode do
   if n^[i].enable then
   begin
     d:=round(sqrt(sqr(mx-n^[i].mx)+sqr(my-n^[i].my)*2));
     if (d<min){and(canmove(mx,my,n^[i].mx,n^[i].my))} then
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
      if map.m^[hero].onhead(round(map.m^[m].getcx),round(map.m^[m].getcy))then begin
       seex:=round(map.m^[m].getcx-map.m^[hero].getcx);
       seey:=round(map.m^[m].getcy-map.m^[hero].getcy);
       map.m^[hero].target.x:=round(map.m^[m].getcx);
       map.m^[hero].target.y:=round(map.m^[m].getcy);
       map.m^[hero].target.mon:=m;
       seeany:=true;
       exit;
      end;
      if (abs(map.m^[m].getcy-map.m^[hero].getcy)<24) then
        if abs(map.m^[m].getcx-map.m^[hero].getcx)<min then
        begin
           min:=round(abs(map.m^[m].getcx-map.m^[hero].getcx));
           f:=m;
      end;
     end;
  if f=-1 then exit;
  if map.m^[f].mx<mx then d:=-1 else d:=1;
  seeany:=true;
  cx:=mx; cy:=my;
  while abs(map.m^[f].getcx-cx)>6 do
  begin
    if (map.land[cy div 8-2]^[cx div 8].land and cwall)>0 then
        begin seeany:=false; exit; end;
    cx:=cx+d*4;
  end;
  seex:=round(map.m^[f].getcx-map.m^[hero].getcx);
  seey:=round(map.m^[f].getcy-map.m^[hero].getcy);
  map.m^[hero].target.x:=round(map.m^[m].getcx);
  map.m^[hero].target.y:=round(map.m^[m].getcy);
  map.m^[hero].target.mon:=m;
end;

procedure tplayer.move;

procedure tracepuls;
const
  d=ppm*5;
var
  i,j,cx,cy, dy: integer;
  ok: boolean;
begin
  ok:=false;
  if not level.look and (random(5)<>0) then exit;
  j:=hero;
  cx:=round(map.m^[j].getcx);
  cy:=round(map.m^[j].getcy);
  dy:=round(map.m^[j].getsy*4);

  for i:=0 to maxpul do
    if (map.b^[i].enable)and(map.b^[i].who<>j)then
     if (abs(cx-map.b^[i].mx)<d)and(abs(cy-map.b^[i].my)<dy)then
       if
         ((map.b^[i].dx>0)and(cx>map.b^[i].mx))or
         ((map.b^[i].dx<0)and(cx<map.b^[i].mx)) then
           ok:=true;

   if ok then include(map.m^[hero].key, kjump);
end;

var
  dest:tdest;

function getgoal:integer;
var
  i,j,ge,findn:integer;
  mind,d: real;
begin
  if time.hod mod 500=0 then map.deltanode;
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



var
  i,j,ti,tj,k:longint;

begin
  if (ammo<max(1,weapon[weap].input))and(weapon[weap].hit=0) then
    map.m^[hero].takebest(1);

  if (level.death)and(fraglimit=frag) then begin win:=true;exit; end;

  if bot=0 then begin // Only human
    scrmode:=normal;
    if shift.en then scrmode:=rf.shift;
    if reverse.en then scrmode:=rf.reverse;
    if cwave.en then scrmode:=rf.wave;
    if abs(drugs.getest)<0.5 then setpal;
    if drugs.en and not level.multi then begin
      k:=random(100);
      setpalbrightness(k);
  end;
  end;
  mx:=map.m^[hero].mx;
  my:=map.m^[hero].my;
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
        if m^[hero].takeitem(item^[i].tip) then begin
          if item^[i].first then inc(taken);
          item^[i].done;
        end;

    if bot=0 then
    for i:=0 to maxmsg do
     if msg[i].enable then
     if
     (mx>=msg[i].x)and
     (my>=msg[i].y)and
     (mx<=msg[i].x+msg[i].sx)and
     (my<=msg[i].y+msg[i].sy)
     then
     begin
       msg[i].event;
     end;

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
        17: begin map.m^[hero].g:=map.g*1.6;  end;
        18: begin map.m^[hero].g:=map.g/1.6;  end;
        19: begin map.m^[hero].g:=9.8*ms2;  end;
        26: begin map.m^[hero].g:=0{9.8*ms2};  end;
        20: begin map.m^[hero].usk:=usk*1.6;  end;
        21: begin map.m^[hero].usk:=usk/1.6;  end;
        22: begin map.m^[hero].usk:=ausk;  end;
        24 {10%}: begin
             if map.m^[hero].health>(6-level.skill)*10 then
               map.m^[hero].health:=(6-level.skill)*10;
        end;
        28 {no weap}: begin
             fillchar(map.m^[hero].w,sizeof(map.m^[hero].w),0);
             fillchar(map.m^[hero].bul,sizeof(map.m^[hero].bul),0);
//             map.m^[hero].w[0]:=1;
             map.m^[hero].weap:=0;
        end;
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
    if ((hod mod settings.botdelay)=(hero mod settings.botdelay))then see:=seeany;

    if (((hod+2) mod round(settings.botgetgoal/speed))=(hero mod round(settings.botgetgoal/speed)))then  goal:=getgoal;
    reset:=reset or((hod mod settings.botreset)=(hero mod settings.botreset));

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
      case random(5) of
      0,1:  include(map.m^[hero].key,kjump);
        2: include(map.m^[hero].key,kdown);
//        2: include(map.m^[hero].key,katack);
      end;
      last.x:=map.m^[hero].mx;
      last.y:=map.m^[hero].my;

      if nextn=-1 then exit;
    end;

    if see  then
    begin
      curn:=map.getnode(mx,my);

      if (map.m^[hero].onhead(round(map.m^[hero].target.x),round(map.m^[hero].target.y))and((not level.death)or(level.skill>=4)))
      then begin
        wmode:=0;
        include(map.m^[hero].key,kdown);
      end
      else
      if abs(seex)>128 then wmode:=2 else
         wmode:=1;

{      if level.skill>3 then} map.m^[hero].takebest(wmode);
      if map.m^[hero].weap=1 then wmode:=0;

      if seey<0 then include(map.m^[hero].key,kjump);
      downed:=false;

      if (seex>0)and(((dest=left)or(seex>botsee[level.skill])) or (wmode=0)) then
         begin exclude(map.m^[hero].key,kleft); include(map.m^[hero].key,kright); end
       else
      if (seex<0)and(((dest=right)or(seex<-botsee[level.skill])) or (wmode=0))then
         begin exclude(map.m^[hero].key,kright);include(map.m^[hero].key,kleft); end;

      case random(2)of
      0: include(map.m^[hero].key,katack);
      1: include(map.m^[hero].key,katack2);
      end;

      tracepuls;

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
   p[it[tip].skin[1]].spritesp(mx-ax,my-ay)
  else
   p[it[tip].skin[norm(
   1,it[tip].max,
    round(int(it[tip].max*(rtimer.hod*speed*1.2)/mfps))mod it[tip].max+1
   )
   ]].spritesp(mx-ax,my-ay)
end;


procedure tmon.attack(nweap: longint);
var
  l:shortint;
  sp,per,ry,d,ty,s , rx, sx,sy, px,py, tp,kh :real;
  i,j,k:longint;
begin
  if (delay.en)or not life then exit;
  if state=duck then kh:=0.5 else kh:=1;
  case dest of
   left: l:=-1;
   right: l:=1;
  end;
  if weapon[nweap].hit>0 then
  begin
    s:=weapon[weap].range;
    rx:=getcx+l*getsx*4;
    ry:=getcy{-getsy*2};
    for i:=0 to maxmon do
     if (map.m^[i].enable)and(map.m^[i].life) then
       if (who<>i)and((not ai) or(ai xor map.m^[i].ai)) then begin
       if
       (map.m^[i].getcx+map.m^[i].getsx*4+s>rx)and
       (map.m^[i].getcx-map.m^[i].getsx*4-s<rx)and
       (map.m^[i].getcy+map.m^[i].getsy*4+s>ry)and
       (map.m^[i].getcy-map.m^[i].getsy*4-s<ry)
       then
         map.m^[i].damage(round(map.m^[i].getcx),round(map.m^[i].y-map.m^[i].getsy*6),weapon[nweap].hit*w[nweap],0,0,0,who,0,0);
     end;
  end;
  setdelay(weapon[nweap].shot);
  if (not ai)and(bul[weapon[nweap].bul]<=0) then exit;
  ry:=0; rx:=1;

  sp:=(weapon[nweap].speed)*l;
  per:=(rfunit.bul[weapon[nweap].bul].per+weapon[nweap].per)/100;

  d:=sqrt(sqr(target.x-getcx)+sqr(target.y-getcy));
  if ai and (clever or level.sniper)then
  begin
//    ty:=-(target.y-getcy)/d;
{    if ty>abs(target.x-x)/d*}
    ry:=(getcy-target.y)/d*(-l);
    rx:=abs(getcx-target.x)/d;
  end;
  if ai and onhead(target.x, target.y) and clever{and (abs(getcx-target.x)<getsx*8)} then
  begin
    rx:=0;
    if target.y>getcy then ry:=1*l
    else ry:=-1*l;
    l:=0;
  end;

  if monster[tip].turret or sniperman then begin
    rx:=cos(angle);
    ry:=sin(angle);
    l:=0;
    sp:=(weapon[nweap].speed);
  end;

  for k:=1 to w[abs(nweap)] do begin
  for j:=1 to max(1,weapon[nweap].multi) do
  if ai or (bul[weapon[nweap].bul]>=max(1,weapon[nweap].input))then
  begin
    if not ai then dec(bul[weapon[nweap].bul],max(1,weapon[nweap].input));

    for i:=1 to rfunit.bul[weapon[nweap].pul].shot do begin
//      dx:=
      px:=sp*(random*per-per/2)+sp*rx+dx;
      py:=sp*(random*per-per/2)+sp*ry-weapon[nweap].speedy;
{      if ai then begin
         tp:=px; px:=py; py:=tp;
      end;}
      map.initbul(x+l*getsx*3 + rx*monster[tip].gun,
      y-round(monster[tip].h*kh- ry*monster[tip].gun),
      px,py,weapon[nweap].pul,who, qdamage.en);
    end;
    if state<>duck then setstate(fire,0.1);
    PlaySound(weapon[nweap].shotSound);
  end;
  end;
end;


function tmon.takeweap(n:tmaxweapon):boolean;
begin
  if (w[n]=0){and(not level.multi)} then
    if (weapon[n].cool>=weapon[weap].cool) then weap:=n;

  if not level.multi and (hero>0)and (w[n]=0) then
    info.add(rfunit.weapon[n].name,white,5);

  if weap=0 then weap:=n;
  inc(w[n]);
  case (weapon[n].double)of
  true: if w[n]>2 then w[n]:=2;
  false: if w[n]>1 then w[n]:=1;
  end;
  {error mg}
  takeweap:=true;
end;
function tmon.takebul(n:tmaxbul; m:integer):boolean;
begin
  {error mg}
  if bul[n]<rfunit.bul[n].max then begin
    inc(bul[n],m);
    if bul[n]>rfunit.bul[n].max then
       bul[n]:=rfunit.bul[n].max;
    takebul:=true;
    if not level.multi and (hero>0) then
      info.add(st(round(m))+' '+rfunit.bul[n].name,grey,5);
  end else
    takebul:=false;
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
  if (state=duck)and (kright in key)  or (kleft in key) then
     getftr:=1;
end;
function tmon.getupr:real;
begin
  getupr:=0.1;
end;
procedure tbul.init(ax,ay, adx,ady:real; at,aw:integer; qd: boolean);
var
  l,i,sx,sy: integer;
begin
  tip:=at;
  who:=aw;
  tobj.init(ax,ay,adx,ady,false);
  etime:=round(bul[tip].time*mfps/speed);
  range:=0;
  case qd of
   false: qdamage:=1;
   true: qdamage:=4;
  end;
{  log(st(tip),etime);}
//  check;
end;
procedure tbul.draw(ax,ay:integer);
var
  i,tx:longint;
  fr: integer;
begin
{  tobj.draw(ax,ay);}
{  if bul[tip].rotate<>0 then
    p^[bul[tip].fly[1]].putrot(mx-ax,my-ay,cos(x/30),sin(x/30),0.75,0.75)
  else}
 case bul[tip].laser of
 false: begin
   if bul[tip].rotate then begin
     // putrot not implemented in SDL2, use regular sprite
     p[bul[tip].fly[1]].spritec(mx-ax,my-ay);
   end
   else
   if dx>0 then begin
     if bul[tip].maxfly=1 then p[bul[tip].fly[1]].spritec(mx-ax,my-ay)
     else p[bul[tip].fly[(mx div bul[tip].delfly mod bul[tip].maxfly)+1]].spritec(mx-ax,my-ay);
   end else
     if bul[tip].maxflyr=1 then p[bul[tip].flyr[1]].spritec(mx-ax,my-ay)
     else p[bul[tip].flyr[(mx div bul[tip].delfly mod bul[tip].maxflyr)+1]].spritec(mx-ax,my-ay);

  end;
  true:begin
   fr:=round((1-etime/round(bul[tip].time*mfps/speed))*bul[tip].maxfly)+1;
   if fr>bul[tip].maxfly then
     fr:=bul[tip].maxfly;

   tx:=p[bul[tip].fly[fr]].x;
   if range>0 then
    for i:=0 to range div tx do
      p[bul[tip].fly[fr]].spritec(mx-ax+i*tx,my-ay)
     else
   for i:=0 downto (range+4) div tx do
      p[bul[tip].fly[fr]].spritec(mx-ax+i*tx,my-ay)
  end;
  end;
end;

function tbul.check:boolean;
var
  r: boolean;
  i:integer;
  cx,cy: integer;
  ax,ay,sx,sy,l: longint;
begin
  r:=tobj.check;
  check:=r;
  if not enable then exit;
  if dx>0 then l:=1 else l:=-1;
//  if dy>0 then ll:=1 else ll:=-1;
  if upr then
    if (bul[tip].time=0)or bul[tip].walldetonate then begin
      for i:=0 to random(5)+5 do
        map.randompix(x-8*l,savey{+dy},0,0,5,5,blow);
      if bul[tip].staywall>0 then
        map.inititem(x-8*l,y,dx,dy,bul[tip].staywall,false);
      detonate;
      exit;
    end;

  for i:=0 to maxmon do
   if map.m^[i].enable and map.m^[i].life then
   if not((map.m^[i].ai)and(map.m^[who].ai))or not level.rail then
   begin
     ax:=map.m^[i].mx;     ay:=map.m^[i].my;
     sx:=map.m^[i].getsx*4;   sy:=map.m^[i].getsy*8;
     if (mx>=ax-sx)and(my<=ay)and(mx<=ax+sx)and(my>=ay-sy)then
     begin
       if (i<>who){or free} then begin
         map.m^[i].damage(mx{-8*l},my,
         bul[tip].hit*qdamage,0,
         bul[tip].fire*qdamage,
         bul[tip].freez*qdamage,
         who,dx*bloodu,dy*bloodu);
         map.m^[i].dx:=map.m^[i].dx+dx*0.1;
         PlaySound(bul[tip].hitSound);
         detonate;
         check:=true;
         exit;
       end;
     end
{     else
       if (i=who)and(bul[tip].time<>0) then
         free:=true;}
  end;
end;

procedure tbul.move;
var
  i,ax,ay,sx,sy,l:integer;
  sdy,sdx: real;
begin
  case bul[tip].laser of
  false: begin
    sdx:=dx; ax:=mx;
    tobj.move;
   if (inwall(cwater)) then
   begin
//     standing:=true;
     dx:=dx*0.97;
     dy:=dy*0.97;
   end;
    if (bul[tip].time=0)and((abs(dx)+abs(dy))<(0.2))then begin detonate; exit; end;
    if (bul[tip].time<>0)then begin
      if etime>0 then dec(etime);
      if (etime=0)and(bul[tip].time<>0) then begin detonate; exit; end;
    end;
  end;
  true: {laser} begin
  if bul[tip].laser and (range=0)then begin
    if dx<0 then l:=-1 else l:=1;
    while not inwall(cwall) do lx:=lx+l;
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
    ((ax>=(range+mx-sx))and(range<0)and(ax<=mx))or
    ((ax<=(range+mx+sx))and(range>0)and(ax>=mx))
    then
    begin
      map.m^[i].damage(ax,my,
      bul[tip].hit*qdamage,
      0,
      bul[tip].fire*qdamage,
      bul[tip].freez*qdamage,
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
   if bomb[tip].fired=0 then p[bomb[tip].fire[vis]].spritec(x-ax,y-ay)
   else p[bomb[tip].fire[vis]].spritesp(x-ax,y-ay);
end;
procedure tbomb.move;
begin
  if life.ready then begin kill; exit; end;
//  dec(life);
  vis:=norm(1,bomb[tip].maxfire,bomb[tip].maxfire-round((life.getest/bomb[tip].time*bomb[tip].maxfire)));
end;

procedure tbomb.init;
var
  i,s:integer;
  rad,x1,y1,pr: real;
begin
  enable:=true;
  x:=ax; y:=ay; tip:=at;
  vis:=1; who:=aw;
  life.init(bomb[tip].time);
  PlaySound(bomb[tip].sound);
  s:=bomb[tip].rad{*2};
  if (bomb[tip].hit<>0)or(bomb[tip].fired<>0)then
  for i:=0 to maxmon do
   if map.m^[i].enable then
{    if
    (map.m^[i].getcx>(x-s))and
    (map.m^[i].getcy>(y-s))and
    (map.m^[i].getcx<(x+s))and
    (map.m^[i].getcy<(y+s))
    then} begin
      x1:=map.m^[i].getcx;
      y1:=map.m^[i].getcy;
      rad:=sqrt(sqr(x1-x)+sqr(y1-y));
{Update bombs !!!!}
      if rad*2<s then
        map.m^[i].damage(round(map.m^[i].x),round(map.m^[i].y-map.m^[i].getsy*6),0,bomb[tip].hit,bomb[tip].fired,0,who,0,0)
      else
      if rad<s then begin
        pr:=2*(s-rad)/s;
        map.m^[i].damage(round(map.m^[i].x),round(map.m^[i].y-map.m^[i].getsy*6),0,bomb[tip].hit*pr,bomb[tip].fired{*pr},0,who,0,0);
      end;

    end;
end;

procedure tmon.setstate;
var
  last: tstate;
begin
  if not life then exit;
  last:=state;
  state:=astate;
  if inwall(cwall) and (last=duck) then state:=duck
  else
   savedel:=round(ad*mfps/speed);
//   savedel.init(ad);
end;
procedure tmon.setcurstate(astate:tstate; ad: real);
var
  last: tstate;
begin
  if not life then exit;
  last:=curstate;
  curstate:=astate;
  if inwall(cwall) and (last=duck) then curstate:=duck
  else
   savedel:=round(ad*mfps/speed);
//  savedel.init(ad);
end;
procedure tmon.giveweapon;
var i:integer;
begin
  if barrel then exit;
  if ai then
  begin
    if monster[tip].stay<>0 then
      map.inititem(x,y,dx,dy,monster[tip].stay,false)
  end
  else
  begin
    for i:=1 to maxit do
     if (it[i].weapon=weap)and(w[weap]>0) then
     begin
       bul[it[i].ammo]:=0;
       weap:=0;
       map.inititem(x,y,dx,dy,i,false);
       break;
     end;
  end;
end;
function gett(a:integer): string;
begin
  if player[a].bot=0 then
    gett:='Игрок '+st(a)
  else
    gett:='Бот '+st(a)
end;
function gett2(a:integer): string;
begin
  if player[a].bot=0 then
    gett2:='Игрока '+st(a)
  else
    gett2:='Бота '+st(a)
end;
procedure tmon.dier;
begin
  if not life then exit;

{  info.add(st(dwho)+' -> '+st(who),red,10);
  info.add(st(lastwho)+' -> '+st(who),red,10);}

if not barrel then
begin
  if not level.multi then
  if hero>0 then
    info.add('Вы убиты !!!',red,100)
  else begin
    if (dwho<>who)and(map.m^[dwho].hero>0) then
      info.add(monster[tip].name+' убит',red,5) else
    if (dwho=who)then
      info.add(monster[tip].name+' совершил самоубийство',red,5)
    else
      info.add(monster[tip].name+' убит своими',red,5);
  end;
 if level.multi then begin
  if (not level.death)and(hero>0)and(player[hero].bot>0)and (map.m^[dwho].hero>0)and(who<>dwho) then begin
    info.add(gett(hero)+': Не стреляй в меня, '+gett(map.m^[dwho].hero)+', - я не твой противник !!!',white, 10);
  end;
  if (level.death)and(hero>0){and(player[hero].bot>0)}and(dwho>=0)and(map.m^[dwho].hero>0) then begin
    if who<>dwho then
      info.add(gett(map.m^[dwho].hero)+' убил '+gett2(hero),botcol[map.m^[dwho].hero], 5)
    else
      info.add(gett(map.m^[dwho].hero)+' совершил самоубийство',botcol[map.m^[dwho].hero], 5);
  end;
 end;
  if (map.m^[who].hero=0)and(dwho>=0)and(map.m^[dwho].hero>0) then
      inc(player[map.m^[dwho].hero].kill) else

  if (map.m^[who].hero<>0)then begin
    inc(player[map.m^[who].hero].die);
    if (dwho>=0)and(map.m^[dwho].hero>0)and(dwho<>who) then
      inc(player[map.m^[dwho].hero].frag);
  end;
end;
  setdelay(truptime);
  life:=false;

{  if (hero>0)and(lastwho>0)then
  begin
      inc(player[hero].die);
      if who=lastwho then dec(player[hero].frag);
      if (map.m^[who].hero>0)and(who<>lastwho) then
       inc(player[map.m^[lastwho].hero].frag);
    end;}
end;
procedure tmon.kill;
begin
  if not life then exit;
  setcurstate(die,monster[tip].diei.delay);
  PlaySound(monster[tip].dieSound);
  giveweapon;
  dier(dwho);
end;
procedure tmon.explode;
begin
  if not life then exit;
  setcurstate(crash,monster[tip].bombi.delay);
  PlaySound(monster[tip].dieSound);
  giveweapon;
  dier(dwho);
end;

procedure tmon.damage(ax,ay:integer; hit,bomb,coxy,afreez:real; dwho:integer; adx,ady: real);
var
  i:integer;
  l: boolean;
begin
  if ax=0 then begin
    ax:=round(x);
    ay:=round(y-getsy*6)
  end;
  l:=health>0;

  if armorhit.en then hit:=hit*0.25;
  if armorbomb.en then bomb:=bomb*0.25;
  if armoroxy.en then coxy:=0;
  if armorfreez.en then afreez:=0;

  if (coxy>0)and(dwho=-1)then dwho:=lastwho;

  if (freez.en)and(afreez=0) then begin
    hit:=hit*10;
    bomb:=bomb*10;
  end;
  if clever then begin
    coxy:=0;
    afreez:=0;
  end;
  know:=true;
  if barrel and not life then exit;
  if god.en then exit;
{  if fired=0 then }
  fired.add(coxy){*byte(hero>0)};
  freez.add(afreez);

  if afreez>0 then fired.clear;
  if coxy>0 then freez.clear;

  if armor=0 then
   health:=health-hit-bomb
  else
  begin
    health:=health-(hit+bomb)*defence1;
    armor:=armor-(hit+bomb)*defence2;
    if armor<0 then begin health:=health+armor/defence2; armor:=0; end;
  end;

  if dwho>=0 then
    lastwho:=dwho;

  if ai and (dwho>=0)and ((target.mon=-1)or not see)then begin
    target.mon:=dwho;
  end;

  if (health<=0)  then {Kill monster}
  begin
    health:=0;
    if l then clearwall(cwall + cdeath);
//    if hero>0 then inc(player[hero].die);
{    if (dwho>0)and(hero>0) then player[hero].hero:=dwho;}
  end;

  if freez.ready then
    setstate(hack,0.1);
  if not barrel and not monster[tip].turret then
  if freez.en then
  for i:=1 to min(32,round((hit+bomb)*5)) do
    map.randompix(ax,ay,dx+adx,dy+ady,5,5,ice)
  else
  for i:=1 to min(64,round((hit+bomb)*10)) do
    map.randompix(ax,ay,dx+adx,dy+ady,5,5,blood)
  else
  for i:=1 to min(32,round((hit+bomb)*5)) do
    map.randompix(ax,ay,dx+adx,dy+ady,5,5,blow);

  if (health<=0)and l then
    if (bomb>0)or(freez.en) then begin explode(dwho); freez.clear; end
    else kill(dwho);

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
  if (state=die)or(state=crash)or barrel then exit;
  sx:=getsx;
  sy:=getsy;
  x1:=lx-sx div 2; x2:=x1+sx-1;
  y2:=ly; y1:=y2-sy+1;
  if (x1<0)or(y1<0)or(x2>=map.x)or(y2>=map.y) then begin  exit; end;
  for i:=x1 to x2 do
    for j:=y1 to y2 do
     if map.land[j]^[i].land and c=0 then
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
    if map.land[j]^[i].land and c=c then
      map.land[j]^[i].land:=map.land[j]^[i].land and (not c);
end;
procedure tmon.move;
var
  i:integer;
  ldx: real;
begin
{  if life then }clearwall(cwall+cdeath);

  if not life then
  begin
    if inwater then dy:=-0.3;

//    inc(delay,2);
    if delay.ready  then
    begin
      done;
      exit;
    end;
  end;

//  if freez.en then dec(freez);
  if freez.ready then
begin

  if life then begin
  if kdown in key then
  begin
    if inwater or ((getg=0)and not standing)then dy:={dy+}monster[tip].jumpy*0.5*usk
    else
     if not inwall(cstand) and ((getgrid and cstand)=0) then begin
       savedel:=0;
       setstate(duck,0.1);
     end
    else
     down:=true;
  end
    else down:=false;
   if kleft in key then runleft;
  if kright in key then runright;
{  if standing and not (kleft in key) and not (kleft in key)then begin
    ldx:=dx;
    if dx>0 then
      dx:=dx-monster[tip].brakes*ms*sqrt(usk)*speed/mfps
    else
     if dx<0 then
      dx:=dx+monster[tip].brakes*ms*sqrt(usk)*speed/mfps;
    if ldx*dx<=0 then dx:=0;
  end;}

  if delay.ready then
    IF KATACK2 in key Then
      attack(-weap);

  if delay.ready then
  if katack in key then begin
    attack(weap);
  end;

  if jumpfr>0 then dec(jumpfr);
  if jumpfr=0 then
    if kjump in key then begin
     if (inwater) or ((getg=0)and not standing) then
      dy:=-{dy+}monster[tip].jumpy*0.6*usk
     else
      jump;
    end;

  if knext in key then takenext;
  if kprev in key then takeprev;
 end;
end;

  if monster[tip].turret then begin dx:=0; dy:=0; end;
  tobj.move;

  if freez.en then exit;
//  if deldam.en>0 then dec(deldam);
  if inwall(clava) and (deldam.ready) then
  begin
    damage(mx,my,0,5,0{2},0,who,0,0);
    deldam.init(1);
  end;

  if inwall(cfunc)then
   with map do
   if life then
    for i:=0 to maxf do
     if f^[i].enable then
     if (self.mx>=f^[i].x)and (self.my>=f^[i].y)and
     (self.mx<=f^[i].x+f^[i].getsx)and (self.my<=f^[i].y+f^[i].getsy) then begin
      if f^[i].tip=12 then
        damage(0,0,0,1000,0,0,who,0,0);
      if f^[i].tip=23 then damage(0,0,0,0,0,10,who,0,0);
      if f^[i].tip=27 then ai:=false;
     end;

  if life and  (not monster[tip].fish)and (not barrel) and inwater then begin
    if random(round(time.fps))=0 then
      map.randompix(getcx, getcy-getsy*3, dx, dy , 0.1, 0.1, air);
  end;

  if deldam.ready then
  begin
    if inwall(cwater)then fired.clear; {OXY}
    if god.ready then  begin
    if inwater then
    begin
      deldam.init(0.1);
      if (oxy>0)and not aqua then oxy:=oxy-1;
      if (oxy=0)and(hero>0) then begin
        health:=health-1;
        if health<=0 then kill(0);
        oxylife:=oxylife+1;
        damage(mx,my,0,0,0,0,who,0,0);
      end;
    end else
    begin
      if oxy<30 then oxy:=30;
      if oxy<100 then
        begin
          oxy:=oxy+1; deldam.init(0.15);
          for i:=1 to 3 do map.randompix(mx,my,dx,dy,1,1,water);
        end;
      if oxylife>0 then
      begin
        if health<monster[tip].health then health:=health+1;
        oxylife:=oxylife-1;
        deldam.init(0.2);
      end;
    end;
   end;
  end;

  if not life and (abs(delay.getest-truptime)<4) then fired.clear;

  if barrel and not life and not ai then
{   if delay>mfps/speed*0.25 then}
   begin
     map.initbomb(mx,my,barrelbomb,lastwho);
     ai:=true;
   end;
 if deldam.ready then
  if (fired.en) then
  begin
    map.initbomb(mx,my,bombfire,lastwho);
    deldam.init(0.1);
{    dec(fired);}
  end;
  if fired.en then begin
    damage(mx,my,0,oxysec*speed/mfps,100,0,-1,0,0);
//    dec(fired);
//    if fired<0 then fired:=0;
  end;
//  if delay.en>0 then dec(delay);
{  if god>0 then dec(god);
  if armorhit>0 then dec(armorhit);
  if armorbomb>0 then dec(armorbomb);
  if armoroxy>0 then dec(armoroxy);
  if armorfreez>0 then dec(armorfreez);
  if qdamage>0 then dec(qdamage);}

  if not monster[tip].turret then
  case curstate of
  run:begin
       if state<>duck then
         state:=run;
       inc(statedel);
       if (monster[tip].runi.max<>0)and(mfps*monster[tip].runi.delay<>0)then
         vis:=round(statedel/(mfps*monster[tip].runi.delay)*usk)mod monster[tip].runi.max+1;
     end;
  crash:
  begin
     state:=crash;
     inc(statedel);
     vis:=min(
     round(
     statedel/
     (mfps*
     monster[tip].bombi.delay/usk
     /speed/
     monster[tip].bombi.max))+1,
     monster[tip].bombi.max);
  end;
  die:
  begin
     state:=die;
     inc(statedel);
     vis:=min(
     round(statedel/(mfps*monster[tip].diei.delay/usk/speed/monster[tip].diei.max))+1,
     monster[tip].diei.max
     );
  end;
  else if savedel>0 then begin dec(savedel); end;
//  else if savedel.en then begin dec(savedel); end;
  end;
  if savedel=0 then begin setstate(stand,0.1); statedel:=0; vis:=1; end;
//  if savedel.ready then begin setstate(stand,0.1); statedel:=0; vis:=1; end;
  if (state=stand)and(standing)and(not elevator)then
  begin
    if abs(dx)<monster[tip].brakes*ms2 then dx:=0 else
    case dest of
      left: if dx<0 then dx:=dx+monster[tip].brakes*ms2 else dx:=0;
      right: if dx>0 then dx:=dx-monster[tip].brakes*ms2 else dx:=0;
    end;
  end;
  if (curstate<>crash)and(curstate<>die)then curstate:=stand;
  if (life)and(state<>die)and(state<>crash) then fillwall(cwall + cdeath);
end;

procedure tmon.moveai;

procedure moveturret;
var
  tx,ty, sx ,sy, ex,ey,d:integer;
  first: boolean;
begin
  key:=[];
  see:=false;
  tx:=mx div 8{lx};
  ty:=(my-monster[tip].h) div 8{ly-2};
  sx:=tx; sy:=ty;
  ex:=target.x div 8;
  ey:=target.y div 8;
  see:=true; first:=true;

  d:=0;
  repeat
    inc(d);
    tx:=sx+round(co*d);
    ty:=sy+round(si*d);

//{    if debug then }map.initbomb(tx*8,ty*8,reswapbomb,0);

    if (ty<=0)or(ty>=map.y-1)or(tx<=0)or(tx>=map.x-1) then begin
       see:=false;
       break;
    end;
    if (map.land[ty]^[tx].land and cwall)>0 then begin
      if not first then begin see:=false; break; end;
    end else first:=false;
  until (abs(tx-ex)<=2)and(abs(ty-ey)<=2)

end;

procedure movesee;
var
  tx,ty,tex, tey, l, sx ,sy, ex,ey:integer;
  d:real;
  first: boolean;
begin
  if monster[tip].turret then begin moveturret; exit; end;
begin
  key:=[];
  see:=false;
  case dest of
   left:  l:=-1;
   right: l:=1;
  end;
  tx:=round(getcx) div 8{lx};
  ty:=round(getcy) div 8{ly-2};
  sx:=tx; sy:=ty;
  ex:=target.x div 8;
  ey:=target.y div 8;
  see:=true; first:=true;

  if (abs(sy-ey)>4)and not (clever or level.sniper) then see:=false;

  tex:=0;  tey:=0;
  if (ty>0)and(ty<map.y) and ((abs(sx-ex)>abs(ey-sy))or not (clever or level.sniper))and see then
  repeat
    tex:=tex+l;
    if clever or level.sniper then
     if abs(sx-ex)<>0 then
       tey:=round(abs(tex)/abs(sx-ex)*(ey-sy));


    tx:=sx+tex;
    ty:=sy+tey;

//    if debug then map.initbomb(tx*8,ty*8,reswapbomb,0);

    if (ty<=0)or(ty>=map.y-1)or(tx<=0)or(tx>=map.x-1) then begin
       see:=false;
       break;
    end;
    if (map.land[ty]^[tx].land and cwall)>0 then begin
      if not first then begin see:=false; break; end;
    end else first:=false;
  until abs(tx-ex)<=2
  else see:=false;

  if onhead(target.x,target.y) then
  begin
    see:=true;
  end;
end;
end;

var
  i,j:longint;
  min,d, ra,xx,yy,dd,spd:real;
begin
  if not ai or not life then exit;

  if monster[tip].turret and know then begin
    d:=min;
    xx:=-r(target.x-self.x); yy:=-r(target.y-self.y);
    dd:=sqrt(sqr(xx)+sqr(yy));
    if (xx>0)then ra:=pi+arctan(yy/xx) else
    if (xx<0)then ra:=arctan(yy/xx) else ra:=pi/2;

    while angle>pi do angle:=angle-pi*2;
    while angle<-pi do angle:=angle+pi*2;

        while ra+pi<angle do ra:=ra+pi*2;
        while ra-pi>angle do ra:=ra-pi*2;

        spd:=monster[tip].speed/360*(pi*2)*speed/mfps;

        if abs(ra-angle)<spd then angle:=ra else
        if ra>angle then angle:=angle+spd
        else angle:=angle-spd;
      end;

  if not ((who mod settings.mondelay)=(hod mod settings.mondelay)) then exit;

{  if monster[tip].turret then begin
    angle:=angle+0.2*speed;
  end;}

  min:=maxlongint{(map.x+map.y)*8*10};
  if monster[tip].turret then know:=false;
  with map do
//  if rtimer.hod mod settings.mondelay=(who mod settings.mondelay) then
  begin
    for i:=1 to level.maxpl do begin
      j:=player[i].hero;
      if not m^[j].life then continue;
      target.x:=round(m^[j].getcx);
      target.y:=round(m^[j].getcy);
      d:=round(abs(m^[j].x-self.mx)+abs(m^[j].y-self.my));
      if monster[tip].turret then begin
        co:=(target.x-self.x)/d;
        si:=(target.y-self.y)/d;
      end;
      movesee;
      if (d<min)and see then begin if monster[tip].turret then know:=true; min:=d; target.mon:=j; end;
    end;

    if (target.mon<>-1){and see} then begin
      target.x:=round(m^[target.mon].getcx);
      target.y:=round(m^[target.mon].getcy);
      si:=sin(angle);
      co:=cos(angle);
      if not map.m^[target.mon].life then see:=false else movesee;
    end;
  end;

//  if (not see)and not level.look and (random(300)=0)and not inwater then know:=false;

  if not see and inwater and know and life then begin
     if (target.y>self.getcy+getsx*5) then include(key,kdown)
     else
     if (target.y<self.getcy-getsx*5) then include(key,kjump);

     if target.x<self.getcx then include(key,kleft) else include(key,kright);

  end;

  if (know){and(tar>0)} then
  begin
    if clever or level.sniper then
    begin
     if (dest=left)and(target.x>self.getcx) then include(key,kright) else
     if (dest=right)and(target.x<self.getcx) then include(key,kleft);
    end;

    if not see then
     if (abs(target.x-self.getcx)>12) then
     begin
      if target.x<self.getcx then include(key,kleft) else include(key,kright);
     end
     else
    if random(300 div settings.mondelay)=0 then include(key,kjump);

    if not see then
     if (abs(target.y-self.getcy)>12) then
     if monster[tip].fly then
       if target.y<self.getcy then include(key,kjump) else include(key,kdown);

    if (weap=1)or((fired.en)and(clever or level.sniper)) then if target.x<self.getcx then include(key,kleft) else include(key,kright);
  end;
  if see then begin include(key,katack); know:=true; end;

  if onhead(target.x,target.y) then begin
     know:=true;
     if clever then begin
       include(key,katack);
       if target.x+8<self.getcx then
       include(key,kleft) else
       if target.x-8>self.getcx then
       include(key,kright);
     end else begin
       if target.x<self.getcx then
       include(key,kright) else
       if target.x>self.getcx then
       include(key,kleft);
       include(key,katack);
     end;
  end;
end;
procedure tmon.runright;
var
  K: real;
begin
  if not life then exit;
  if monster[tip].fish and not inwater then exit;
{  if not standing then exit;error}
//  if standing then k:=1 else k:=0.7;
  if state=duck then k:=0.5 else k:=1;

  if state<>duck then
    if state<>run then setcurstate(run,0.05);

  if dest=left then dest:=right;
  if dx<0 then dx:=dx+monster[tip].brakes*ms{2}*sqrt(usk)*speed/mfps*k
  else
   dx:=dx+monster[tip].acsel*ms{2}*sqrt(usk)*speed/mfps*k;
  if dx>monster[tip].speed*ms*usk*k then dx:=monster[tip].speed*ms*usk*k;

  if state<>duck then
    if savedel<=1 then setcurstate(run,0.05);

  checkstep
end;
procedure tmon.runleft;
var
  K:real;
begin
  if not life then exit;
  if monster[tip].fish and not inwater then exit;

  if state=duck then k:=0.5 else k:=1;

  if state<>duck then
    if state<>run then setcurstate(run,0.05);
  if dest=right then dest:=left;
  if dx>0 then dx:=dx-monster[tip].brakes*ms{2}*sqrt(usk)*speed/mfps*k
  else
   dx:=dx-monster[tip].acsel*ms{2}*sqrt(usk)*speed/mfps*k;

  if dx<-monster[tip].speed*ms*usk*k{*k} then dx:=-monster[tip].speed*ms*usk*k{*k};

  if state<>duck then
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
  setstate(run,0.3);

  if longjumpn=0 then
  dy:=-monster[tip].jumpy
  else begin
    dy:=-monster[tip].jumpy*sqrt(longjump);
    jumpfr:=round(mfps/speed*0.5);
    if longjumpn>0 then dec(longjumpn);
    if longjumpn=0 then longjump:=1;
  end;
end;
procedure tmon.checkstep;
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
var
  j:longint;
begin
  for j:=1 to maxt do land.t[j].b:=0;
  for j:=1 to land.maxtt do
   if j+land.ch<=maxallwall then
     land.t[j].b:=loadbmp(allwall[j+land.ch]);
end;

procedure ted.draw;
const ddd=60;
var i,j:longint;
begin
  map.draw;
  if cool or (what=wall)or(what=fillwall) then map.drawhidden;
  for i:=0 to maxf do if map.f^[i].enable then map.f^[i].draw(map.dx,map.dy,i);

  for i:=0 to maxmsg do if map.msg[i].enable then map.msg[i].draw(map.dx,map.dy);

  map.drawnodes;
  case what of
   func:
   with fun do
   begin
     for i:=0 to getmaxx div ddd-1 do
     begin
       if shift+i=cur then bar(i*ddd,scry+12,(i+1)*ddd-1,getmaxx,white);
       if (shift+i>=0)and(shift+1<=maxfname)then begin
         print(i*ddd,scry+2,not white,fname[shift+i].name);
         p[fname[shift+i].skin].put(i*ddd,scry+12);
       end;
     end;
   end;
   mons:
   with mon do
   begin
     for i:=0 to getmaxx div ddd-1 do
     begin
       if shift+i=cur then bar(i*ddd,scry+12,(i+1)*ddd-1,getmaxx,white);
       print(i*ddd,scry+2,not white,monster[shift+i].name);
       p[monster[shift+i].stand[right]].put(i*ddd,scry+12);
     end;
   end;
   items:
   with itm do
   begin
     for i:=0 to getmaxx div ddd-1 do
     begin
       if shift+i=cur then bar(i*ddd,scry+12,(i+1)*ddd-1,getmaxx,white);
       print(i*ddd,scry+2,not white,it[shift+i].name);
       p[it[shift+i].skin[1]].put(i*ddd,scry+12);
     end;
   end;
   wall,fillwall:
   begin
     for i:=1 to 8 do
     print(0+100*byte(i>4),scry+i*10-byte(i>4)*40,
       white-30*byte(0<(land.mask and (1 shl (i-1)))),edwallstr[i]);
   end;
{   node:
   begin
     for i:=1 to 4 do print(0,scry+i*10,
     white-30*byte(0<(nodes.mask and (1 shl (i-1)))),ednodestr[i]);
   end;}
   face,fillface: with land do
   begin
     for i:=1 to maxtt do
      if (i+ch<=maxallwall)and(t[i].b<>0) then
     begin
       if i+ch=cur then bar(t[i].x-1,t[i].y-1,t[i].x+p[t[i].b].x+1,t[i].y+p[t[i].b].y,white);
        p[t[i].b].sprite(t[i].x,t[i].y);
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
     print(scrx,(i-1)*10,red,edmenustr[i]);

  if drag or drag2 then rectangle(startd.x-map.dx,startd.y-map.dy,endd.x-map.dx,endd.y-map.dy,white);
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
procedure swapint(var a,b: integer);
var
  t: integer;
begin
  t:=a; a:=b; b:=t;
end;

procedure ted.move;
var
  i,freex,j,x1,y1,xp,yp:longint;
  s:string;
  ok:boolean;
begin
//  reload;

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
        wb.print(100,50,'Сохранить');
        s:=enterfile(map.name);
        if s<>'' then begin map.name:=s; map.save; end;
      end;
   3: begin
        wb.print(100,50,'Загрузить');
        s:=getlevel{enterfile(map.name)}('Загрузить');
        if s<>'' then map.load(s);
      end;
    4: begin
         wb.print(100,50,'Новая игра');
         s:='yes';
         readline(100,100,s,s,white,0);
         if downcase(s)='yes'then
         begin
           map.done;
           map.create(defx,defx,0,0,defname);
           map.clear;
           wb.print(100,110,'Авторские права');
           s:='Автор: ';
           readline(1,160,map.copy,s,white,0);
           map.initnode(32,32,nodes.mask);
         end;
       end;
    5: begin scry:=getmaxy-50; what:=face;  reload; end;
    6:  begin scry:=getmaxy-50; what:=wall; end;
    7:  begin scry:=getmaxy-50; what:=mons; end;
    8:  begin scry:=getmaxy-50; what:=items;end;
    9:  begin scry:=getmaxy-50; what:=func; end;
    10: begin cool:=not cool; repeat sdlinput.PollEvents until not sdlinput.push; end;
    11: begin scry:=getmaxy; what:=node; end;
    12:begin
         wb.print(100,50,'Комментарии');
{         readline(1,100,map.copy,map.copy,white,0);}
         readline(1,100,map.com,map.com,white,0);
       end;
    13: begin scry:=getmaxy-50;what:=items; itm.shift:=1; end;
    14: begin scry:=getmaxy-50;what:=items; itm.shift:=21; end;
    15: begin scry:=getmaxy-50;what:=items; itm.shift:=40; end;
    16: begin scry:=getmaxy-50;what:=items; itm.shift:=58; end;
    17: begin scry:=getmaxy-50;what:=items; itm.shift:=80; end;
    19: land.mask:=0;
    20: land.mask:=cwall;
    21: land.mask:=cstand;
    22: {Wallpapers} begin
        wb.print(100,50,'Обои');
        map.wallpaper:=enterwall(map.wallpaper);
    end;
    23: begin scry:=getmaxy-50; what:=fillface;  reload; end;
    24: begin scry:=getmaxy-50; what:=fillwall; end;
    25: begin scry:=getmaxy; what:=mes; end;
  end;
 end;

  if not push then begin
    if (fun.editing) and (what=mes) then begin
      fun.editing:=false;
      map.msg[fun.f].msg:=enterfile(map.msg[fun.f].msg);
    end;
    if fun.editing then fun.editing:=false;
  end;

  if mo(0,scry,getmaxx,getmaxy)then // Кнопки управления снизу
  if (not drag)and(not drag2) then
  begin
   if push then
    case what of
     wall,fillwall:begin
       repeat sdlinput.PollEvents until not sdlinput.push;
       i:=(my-scry)div 10;
       if mx>100 then inc(i,4);
       land.mask:=land.mask xor (1 shl (i-1));
     end;
     face,fillface: with land do
      begin
        if mx>=(getmaxx-4) then inc(ch,8)
          else
        if (mx<=4)and(ch>0) then  dec(ch,8)
          else
        for i:=1 to maxtt do if mo(t[i].x-1,t[i].y-1,t[i].x+p[t[i].b].x,t[i].y+p[t[i].b].y) then
        begin
          curname:=p[t[i].b].name;
          cur:=ch+i;
        end;
        reload;
      end;
     func: with fun do
      begin
        if mx>=(getmaxx-4) then inc(shift)  else
        if (mx<=4)and(shift>0) then dec(shift)
        else  cur:=shift+mx div 60;
       repeat sdlinput.PollEvents until not sdlinput.push;
      end;
     mons: with mon do
      begin
        if mx>=(getmaxx-4) then inc(shift)  else
        if (mx<=4)and(shift>0) then dec(shift)
        else  cur:=shift+mx div 60;
       repeat sdlinput.PollEvents until not sdlinput.push;
      end;
     items: with itm do
      begin
        if mx>=(getmaxx-4) then inc(shift)  else
        if (mx<=4)and(shift>0) then dec(shift)
        else  cur:=shift+mx div 60;
       repeat sdlinput.PollEvents until not sdlinput.push;
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
          repeat sdlinput.PollEvents until not sdlinput.push;
        end;
        items:with itm do
        begin
          map.inititem((mx+map.dx),(my+map.dy),0,0,cur,true);
          repeat sdlinput.PollEvents until not sdlinput.push;
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
         mes:
         with fun do
           if editing then
           begin
             map.msg[fun.f].sx:=round(mx+map.dx-map.msg[fun.f].x);
             map.msg[fun.f].sy:=round(my+map.dy-map.msg[fun.f].y);
            end
           else
           begin
             editing:=true;
             f:=map.initmsg(mx+map.dx,my+map.dy,8,8);
           end;

        fillwall,fillface: begin
          if not drag then begin
            startd2.x:=mx+map.dx;
            startd2.y:=my+map.dy;
            endd2:=startd2;
            endd:=endd2;
            startd:=startd2;
            drag:=true;
          end else begin
            endd2.x:=mx+map.dx;
            endd2.y:=my+map.dy;
            endd:=endd2;
            startd:=startd2;
            if startd.x>endd.x then swapint(startd.x,endd.x);
            if startd.y>endd.y then swapint(startd.y,endd.y);
          end;
        end;

        face:
         begin
           land.cur:=map.addpat(land.curname);
          for i:=0 to p[map.pat[land.cur]].x div 8-1 do
           for j:=0 to p[map.pat[land.cur]].y div 8-1 do
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
       mes: begin
         for i:=0 to maxmsg do
              if map.msg[i].enable then
                  begin
                     if
                     (map.msg[i].x<=mx+map.dx+4)and
                     (map.msg[i].y<=my+map.dy+4)and
                     (map.msg[i].x+map.msg[i].sx>=mx+map.dx-4)and
                     (map.msg[i].y+map.msg[i].sy>=my+map.dy-4)then
                       fun.f:=i;
                  end;
         map.msg[fun.f].msg:=enterfile(map.msg[fun.f].msg);
       end;
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
        fillwall,fillface: begin
          if not drag2 then begin
            startd2.x:=mx+map.dx;
            startd2.y:=my+map.dy;
            endd2:=startd2;
            endd:=endd2;
            startd:=startd2;
            drag2:=true;
          end else begin
            endd2.x:=mx+map.dx;
            endd2.y:=my+map.dy;
            endd:=endd2;
            startd:=startd2;
            if startd.x>endd.x then swapint(startd.x,endd.x);
            if startd.y>endd.y then swapint(startd.y,endd.y);
          end;
        end;
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
         mes: for i:=0 to maxmsg do
                if map.msg[i].enable then
                  begin
                     if
                     (map.msg[i].x<=mx+map.dx+4)and
                     (map.msg[i].y<=my+map.dy+4)and
                     (map.msg[i].x+map.msg[i].sx>=mx+map.dx-4)and
                     (map.msg[i].y+map.msg[i].sy>=my+map.dy-4)then
                         map.msg[i].done;
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
      freex:=freex+p[b].x+2;
      if freex>=getmaxx then begin dec(maxtt); break; end;
   end;
  if not push and not push2 then
  case what of
    fillwall: begin
      if drag then begin
      drag:=false;
      for i:=startd.x div 8 to endd.x div 8 do
        for j:=startd.y div 8 to endd.y div 8 do
          map.putwall(i,j,land.mask);
       end;
      if drag2 then begin
      drag2:=false;
      for i:=startd.x div 8 to endd.x div 8 do
        for j:=startd.y div 8 to endd.y div 8 do
          map.putwall(i,j,0);
       end;
    end;
    fillface: begin
      if drag then begin
      drag:=false;
      land.cur:=map.addpat(land.curname);
      x1:=(startd.x) div 8;
      y1:=(startd.y) div 8;
      xp:=(p[map.pat[land.cur]].x+7) div 8;
      yp:=(p[map.pat[land.cur]].y+7) div 8;
      for i:=x1 to endd.x div 8 do
        for j:=y1 to endd.y div 8 do begin
//          map.deputpat(i,j);
          if ((i-x1)mod xp=0)and((j-y1)mod yp=0)then
            map.putpat(i,j,land.cur,land.mask);
        end;
      end;
      if drag2 then begin
      drag2:=false;
//      land.cur:=map.addpat(land.curname);
      x1:=(startd.x) div 8;
      y1:=(startd.y) div 8;
//      xp:=p[map.pat[land.cur]].x div 8;
//      yp:=p[map.pat[land.cur]].y div 8;
      for i:=x1 to endd.x div 8 do
        for j:=y1 to endd.y div 8 do begin
          map.deputpat({(mx+map.dx)div 8+}i,{(my+map.dy)div 8+}j);
{          if ((i-x1)mod xp=0)and((j-y1)mod yp=0)then
            map.putpat(i,j,0,0);}
        end;
      end;
    end;
  end;
end;
function tmap.initf(ax,ay,asx,asy,atip:integer):integer;
var i:longint;
begin
  for i:=0 to maxf do
    if not f^[i].enable then
    begin
      f^[i].init(ax,ay,asx,asy,atip,i);
      initf:=i;
      exit;
    end;
  initf:=0;
end;
function tmap.initmsg(ax,ay,asx,asy:integer):integer;
var i:longint;
begin
  for i:=0 to maxmsg do
    if not msg[i].enable then
    begin
      msg[i].init(ax,ay,asx,asy,'');
      initmsg:=i;
      exit;
    end;
  initmsg:=0;
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
function tmap.initbul(ax,ay,adx,ady:real; at,who:integer; qd: boolean):integer;
var i:longint;
begin
  for i:=0 to maxpul do
    if not b^[i].enable then
    begin
      b^[i].init(ax,ay,adx,ady,at,who,qd);
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
function tpix.getg:real;
begin
  if inwall(cwater)then
    getg:=-tobj.getg
   else
    getg:=tobj.getg;
end;
procedure tpix.move;
var
  b: boolean;
begin
  dec(life);
  if (life=0)or((abs(dx)+abs(dy))<0.01*ms) then begin done; exit; end;
  b:=inwall(cwater);
  if water and not b then done;
  if  b then water:=true;
  tobj.move;
end;

function tobj.check:boolean;
var
  i:integer;
begin
  upr:=inwall(cwall);
  check:=upr;

  if (inwall(cFunc)) then begin
   with map do
    for i:=0 to maxf do
     if f^[i].enable then
     if
     (mx>=f^[i].x)and
     (my>=f^[i].y)and
     (mx<=f^[i].x+f^[i].getsx)and
     (my<=f^[i].y+f^[i].getsy)
      then case f^[i].tip of
        13,25{Teleport}: begin
          self.x:=self.x+(f^[i+1].x-f^[i].x);
          self.y:=self.y+(f^[i+1].y-f^[i].y);
          self.mx:=round(self.x); self.lx:=self.mx div 8;
          self.my:=round(self.y); self.ly:=self.my div 8;
          savex:=self.x;
          savey:=self.y;
          upr:=false;
          check:=true;
{          while inwall(cwall) do begin
            self.y:=self.y-1; dec(self.my); self.ly:=self.my div 8;
          end;}

          if (typeof(tPix)<>typeof(self)) and (f^[i].tip=13)then
            initbomb(round(self.x),round(self.y-self.getsy*4),reswapbomb,0);
          exit;
        end;
      end;
  end;
end;

procedure tobj.move;
var
  x1,y1,x2,y2,i,j,ti,tj,slx,sly,nlx,nly:longint;
  br,str:boolean;
  gr: byte;
begin
  dy:=dy+getg*speed;
  savex:=x; slx:=lx;
  savey:=y; sly:=ly;

  str:=false;
  x1:=lx-getsx div 2; x2:=x1+getsx-1;  y2:=norm(0,map.y,ly);
  if typeof(tBul)<>typeof(self) then
  for i:=max(0,x1) to min(map.x,x2) do
    str:=str or boolean(map.land[y2]^[i].land and cstand);

  upr:=false;
  br:=false;

  if typeof(self)=typeof(tmon)then begin
  x:=x+dx*speed; mx:=round(x); nlx:=mx div 8;
  lx:=slx; x:=savex; mx:=round(x);
  if dx>0 then
  while (lx<=nlx)and(not check) do begin
    inc(lx);
    x:=x+8;
    mx:=mx+8;
  end else
  while (lx>=nlx)and(not check) do begin
    dec(lx);
    x:=x-8;
    mx:=mx-8;
  end;

  if not upr then begin
    x:=savex+dx*speed; mx:=round(x); lx:=mx div 8
  end
  else begin
    x:=savex;
    dx:=-dx*getupr;
    dy:=dy*getftr;
    mx:=round(x); lx:=mx div 8;
  end;

  y:=y+dy*speed; my:=round(y); nly:=my div 8;
  ly:=sly; y:=savey; my:=round(y);
  if dy>0 then
  while (ly<=nly)and(not check) do begin
    inc(ly);
    y:=y+8;
    my:=my+8;
  end else
  while (ly>=nly)and(not check) do begin
    dec(ly);
    y:=y-8;
    my:=my-8;
  end;

  if not upr then begin
    y:=savey+dy*speed; my:=round(y); ly:=my div 8
  end
  else begin
    y:=savey; dy:=dy-getg*speed;
    dy:=-dy*getupr;
    dx:=dx*getftr;
    my:=round(y); ly:=my div 8;
  end;

  end else // typeof <> tMon
  begin
    x:=x+dx*speed; mx:=round(x); nlx:=mx div 8;
  lx:=slx; x:=savex; mx:=round(x);

  if dx>0 then
  repeat
    inc(lx);
    x:=x+8;
    mx:=mx+8;
  until (lx>nlx) or check  else
  repeat
    dec(lx);
    x:=x-8;
    mx:=mx-8;
  until (lx<nlx)or check;

  if not upr then begin
    x:=savex+dx*speed; mx:=round(x); lx:=mx div 8; check;
  end
  else begin
    x:=savex;
    dx:=-dx*getupr;
    dy:=dy*getftr;
    mx:=round(x); lx:=mx div 8;
  end;

  y:=y+dy*speed; my:=round(y); nly:=my div 8;
  ly:=sly; y:=savey; my:=round(y);
  if dy>0 then
  repeat //while (ly<=nly)and(not check) do begin
    inc(ly);
    y:=y+8;
    my:=my+8;
  until (ly>nly) or check else
  repeat//while (ly>=nly)and(not check) do begin
    dec(ly);
    y:=y-8;
    my:=my-8;
  until (ly<nly) or check;

  if not upr then begin
    y:=savey+dy*speed; my:=round(y); ly:=my div 8; check;
  end
  else begin
    y:=savey;
    dy:=dy-getg*speed;
    dy:=-dy*getupr;
    dx:=dx*getftr;
    my:=round(y); ly:=my div 8;
  end;
end;
{  y:=savey+dy*speed; my:=round(y); ly:=my div 8;
  if inwall(cwall) then
  begin
    y:=savey;
    dy:=-dy*getupr;
    dx:=dx*getftr;
    my:=round(y); ly:=my div 8;
  end;
 }
  elevator:=false;
  standing:=getstand;

  x1:=lx-getsx div 2; x2:=x1+getsx-1;  y2:=norm(0,map.y,ly);
  br:=false;

  gr:=getgrid;

  if not down then
  if typeof(tBul)<>typeof(self) then
  for i:=max(0,x1) to min(map.x,x2) do
   if map.land[y2]^[i].land and cstand>0 then
//   if gr and cstand>0 then
   begin
     savey:=y;
     standing:=true;
     elevator:=true;
     if dy<0 then
       dy:=-dy*getupr
     else begin
       dy:=0;
      if not str then  y:=round(y)div 8 *8-1
      else y:=y-28*speed/mfps;
     end;

     my:=round(y);
     ly:=my div 8;

     if inwall(cwall) then
       y:=savey{y+48/(mfps/speed)};

     my:=round(y);
     ly:=my div 8;
     break;
   end;

   if typeof(self)<>typeof(tBul)then begin
   if (gr and cwater>0) then
   begin
//     standing:=true;
     dx:=dx*0.97;
     dy:=dy*0.97;
   end;

   if (gr and cshl>0) then
   begin
     standing:=true;
     elevator:=true;
//     dy:=-dy*getupr;
//     y:=y-28*speed/mfps;
     x:=x-28*speed/mfps;
     dx:=dx*0.95;
//     dx:=-1;
     mx:=round(x); lx:=mx div 8;
     if inwall(cwall) then begin x:=savex; mx:=round(x); lx:=mx div 8;end;
     br:=true;
   end;
   if gr and cshr>0 then
   begin
     standing:=true;
     elevator:=true;
//     dy:=-dy*getupr;
     x:=x+28*speed/mfps;
     dx:=dx*0.95;
//     y:=y-1;
//     x:=x+1;
//     dx:=1;
     mx:=round(x); lx:=mx div 8;
     if inwall(cwall) then begin x:=savex; mx:=round(x); lx:=mx div 8;end;
     br:=true;
   end;
  end;
//   if br then break;
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
var
  c: longint;
  r,cg,b: byte;
begin
  c:=0;
  if armorhit.en then c:=blue;
  if (armorbomb.en)then c:=red;
  if (armoroxy.en)then c:=green;
  if (armorfreez.en)then c:=green;
  r:=255; cg:=255; b:=255;
  if freez.en then begin r:=128; cg:=128; b:=255; end;
  dec(ay);

  if monster[tip].turret then if life then state:=stand else state:=die;

  case state of
   stand:p[monster[tip].stand[dest]].spriteo(mx-ax,my-ay,c,r,cg,b);
   run:  p[monster[tip].run[vis,dest]].spriteo(mx-ax,my-ay,c,r,cg,b);
   fire: p[monster[tip].fire[dest]].spriteo(mx-ax,my-ay,c,r,cg,b);
   hack: p[monster[tip].damage[dest]].spriteo(mx-ax,my-ay,c,r,cg,b);
   die:  p[monster[tip].die[vis,dest]].spriteo(mx-ax,my-ay,c,r,cg,b);
   crash:p[monster[tip].bomb[vis,dest]].spriteo(mx-ax,my-ay,c,r,cg,b);
   hai:  p[monster[tip].hai[dest]].spriteo(mx-ax,my-ay,c,r,cg,b);
   duck:
   p[monster[tip].duck[
   norm(1,monster[tip].ducki.max,(mx div round(monster[tip].ducki.delay+1) mod monster[tip].ducki.max)+1),
   dest]].spriteo(mx-ax,my-ay,c,r,cg,b);
  end;
  if monster[tip].turret {and life }then begin
    // putrot not implemented in SDL2, use static turret sprite
    p[monster[tip].turvis].spritec(mx-ax,my-ay-monster[tip].h);
  end;
{  if debug then
    rb.print(mx-ax,my-ay,st(who)+'->'+st(target.mon)+' - '+st(byte(see)));}
//  dec(my);
{  putpixel(mx-ax,my-ay,white);}
end;
procedure tf.draw;
var
  i,cur:integer;
begin
  rectangle(mx-ax,my-ay,mx-ax+sx,my-ay+sy,white);
  for i:=0 to maxfname do
    if fname[i].n=tip then begin cur:=i; break; end;
  p[fname[cur].skin].spritesp(mx-ax,my-ay);
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
   duck: getsy:=monster[tip].y div 2;
  end;
end;
procedure tmon.init(ax,ay,adx,ady:real; at:tmaxmontip; ad:tdest; aw:longint; aai,af:boolean; ah:longint);
begin
  fillchar(bul,sizeof(bul),0);
  tobj.init(ax,ay,adx,ady,af);
  sniperman:=false;
  target.mon:=-1;
  g:=map.g;
  longjump:=1;
  jumpfr:=0;
  usk:=ausk;

  armorhit.clear;
  armorbomb.clear;
  armoroxy.clear;
  armorfreez.clear;
  qdamage.clear;
  aqua:=false;

  hero:=ah;
  fillchar(w,sizeof(w),0); // No weapons
  weap:=0;
  delay.clear; deldam.clear; oxy:=100; oxylife:=0;
  ai:=aai;
  who:=aw;
  lastwho:=-1;
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
  fired.clear;
  if not ai then
  case level.death of
  false: takeitem(freeitem);
  true: takeitem(freemultiitem);
  end;
  if ai then begin
    takeitem(monster[tip].defitem);
    weap:=it[monster[tip].defitem].weapon;
  end else begin
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
  know:=false;
  angle:=-monster[tip].defangle/180*pi;
  see:=false;
  barrel:=monster[tip].barrel;
  if barrel then begin ai:=false; dest:=left;end;
  key:=[];
  delay.init(0.5);
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
  water:=false;
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
    if (map.land[j]^[i].land and (cwall+cstand)>0)
    {or(map.land[j]^[i].land and cstand>0)} then begin getstand:=true; exit; end;
  getstand:=false;
end;

function tmon.getstand:boolean;
begin
  getstand:=tobj.getstand and (my mod 8>=6);
end;

function tobj.getgrid:byte;
var
  i,j,sx,sy,x1,y1,x2,y2:integer;
  ok:boolean;
  r:byte;
begin
  sx:=getsx;
  sy:=getsy;
  r:=0;
  x1:=lx-sx div 2; x2:=x1+sx-1;
  y2:=ly+1; y1:=y2-sy-1;
  if (x1<0)or(y1<0)or(x2>=map.x)or(y2>=map.y) then begin getgrid:=cwall; exit; end;
  for i:=x1 to x2 do
    for j:=y2 to y2 do
      r:=(map.land[j]^[i].land) or r;
  getgrid:=r;
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
  if y1<0 then y1:=0;
  if y2<0 then y2:=0;
  if (x1<0)or(y1<0)or(x2>=map.x)or(y2>=map.y) then begin inwall:=true; exit; end;
  for i:=x1 to x2 do
    for j:=y1 to y2 do
    if map.land[j]^[i].land and c>0 then begin inwall:=true; exit; end;
  inwall:=false;
end;
function tobj.inwater:boolean;
var
  i,j,sx,sy,x1,y1,x2,y2:integer;
  ok:boolean;
begin
  sx:=getsx;
  sy:=getsy;
  x1:=lx-sx div 2; x2:=x1+sx-1;

  y2:=ly-sy div 2; y1:=y2-sy+1;
  if y2<0 then y2:=0;
  if y1<0 then y1:=0;
  if (x1<0)or(y1<0)or(x2>=map.x)or(y2>=map.y) then begin inwater:=true; exit; end;
  for i:=x1 to x2 do
    for j:=y1 to y2 do
    if map.land[j]^[i].land and cwater>0 then begin inwater:=true; exit; end;
  inwater:=false;
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
  ss:string;
  capt:tcapt;
  mpat,mmon,mitem,mf,mnode,i,j,cn,mmsg:longint;
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
  attr: word;
begin
  done;
  name:=s;
  g:=9.8*ms2; usk:=ausk;
  wallpaper:=''; wlp:=0;
  mmsg:=0;

  ss:=levdir+name+levext;
  assign(ff,ss);
  getfattr(ff,attr);
  setfattr(ff,0);
{$i-}  reset(ff,1);{$i+}
  if ioresult<>0 then begin
    error('FATAL ERROR '+ss+' not found !!!');
    closegraph;
    writeln('FATAL ERROR: '+ss+' not found !!!');
    halt(1);
  end;
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

    if ver>=4 then begin
      blockread(ff,mmsg,4);
      if (mmsg < 0) or (mmsg > maxmsg) then mmsg:=0;  // Validate mmsg
    end;

    blockread(ff,mnode,4);
    blockread(ff,reserved,16);
  end;
  writeln('Loading level: ', name, ' ver=', ver, ' mmsg=', mmsg);
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
    totmon:=0;
    for i:=0 to mmon-1 do
    begin
      blockread(ff,mon,7{sizeof(mon)});
//      log('Dest mon',integer(mon.dest));
      if not m^[initmon(mon.x,mon.y,mon.tip,tdest(mon.dest),true,true,0)].barrel
        then inc(totmon);
    end;
    totitem:=0;
    for i:=0 to mitem-1 do
    begin
      blockread(ff,itm,6{sizeof(itm)});
      if not it[itm.tip].cant then inc(totitem);
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
  if ver>=3 then begin
    blockread(ff,wallpaper,sizeof(wallpaper));
    if wallpaper<>'' then
      wlp:=loadasbmp(wallpaper);
  end;
  if ver>=4 then begin
    {$I-}
    for i:=0 to mmsg-1 do
      blockread(ff,msg[i],sizeof(msg[i]));
    if ioresult<>0 then; // Ignore read errors for messages (backwards compatibility)
    {$I+}
  end;
  close(ff);
  setfattr(ff,attr);
  deltanode;
end;


procedure tmap.save;
var
  ff:file;
  mpat,mmon,mitem,mf,i,j,mnode,mmsg:longint;
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
  attr: word;
begin
  level.add(name);
  assign(ff,levdir+name+levext);
  getfattr(ff,attr);
  if (attr and readonly>0)and(doserror=0) then begin error('Нельзя изменять стандартные уровни!'); exit; end;
{$i-}  rewrite(ff,1); {$i+}
  if ioresult<>0 then begin error('Не могу сохранить '+levdir+name+levext); exit; end;
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
  mmsg:=0;
  for i:=0 to maxmsg do
    if msg[i].enable then
      inc(mmsg);

  blockwrite(ff,mmsg,4);
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
  blockwrite(ff,wallpaper,sizeof(wallpaper));
  for i:=0 to maxmsg do
    if msg[i].enable then
      blockwrite(ff,msg[i],sizeof(msg[i]));
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
  for i:=-8 to (maxx-minx) div 8+1 do
    for j:=-8 to (maxy-miny) div 8+1 do
    if (j+y1<y)and(i+x1<x)then
    if (j+y1>=0)and(i+x1>=0)then
     if (land[j+y1]^[i+x1].vis<>0)and((land[j+y1]^[i+x1].land and cOverDraw)<>cOverDraw) then
       p[pat[land[j+y1]^[i+x1].vis]].put(minx+i*8-dx mod 8,miny+j*8-dy mod 8);

  for i:=0 to maxpix do  if pix^[i].enable  then pix^[i]. draw(-minx+dx,-miny+dy);
  for i:=0 to maxitem do if item^[i].enable then item^[i].draw(-minx+dx,-miny+dy);
  for i:=0 to maxmon do  if m^[i].enable    then m^[i].   draw(-minx+dx,-miny+dy);
  for i:=0 to maxexpl do if e^[i].enable    then e^[i].   draw(-minx+dx,-miny+dy);
  for i:=0 to maxpul do  if b^[i].enable    then b^[i].   draw(-minx+dx,-miny+dy);

  for i:=-8 to (maxx-minx) div 8+1 do
    for j:=-8 to (maxy-miny) div 8+1 do
    if (j+y1<y)and(i+x1<x)then
    if (j+y1>=0)and(i+x1>=0)then
     if (land[j+y1]^[i+x1].vis<>0)and((land[j+y1]^[i+x1].land and cOverDraw)=cOverDraw) then
       p[pat[land[j+y1]^[i+x1].vis]].put(minx+i*8-dx mod 8,miny+j*8-dy mod 8);
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
  fillchar(must, sizeof(must), 0);
  fillchar(m^,sizeof(m^),0);        for i:=0 to maxmon do m^[i].newObj;
  fillchar(item^,sizeof(item^),0);  for i:=0 to maxitem do item^[i].newObj;
  fillchar(f^,sizeof(f^),0);        for i:=0 to maxf do f^[i].newObj;
  fillchar(pix^,sizeof(pix^),0);    for i:=0 to maxpix do pix^[i].newObj;
  fillchar(b^,sizeof(b^),0);        for i:=0 to maxpul do b^[i].newObj;
  fillchar(n^,sizeof(n^),0);        for i:=0 to maxnode do n^[i].newObj;
  fillchar(e^,sizeof(e^),0);
  fillchar(msg,sizeof(msg),0);
  wlp:=0; wallpaper:='';
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
      if m^[i].enable then m^[i].fillwall(cwall+cdeath);
    for i:=0 to maxmon do
      if m^[i].enable then m^[i].moveai;
    for i:=0 to maxmon do
      if m^[i].enable then m^[i].move;
    for i:=0 to maxmon do
      if m^[i].enable then m^[i].clearwall(cwall+cdeath);

    for i:=0 to maxf do if f^[i].enable then f^[i].move;
    for i:=0 to maxpix do if pix^[i].enable then pix^[i].move;
    for i:=0 to maxpul do if b^[i].enable then b^[i].move;
    for i:=0 to maxexpl do if e^[i].enable then e^[i].move;
    for i:=0 to maxmust do
     if must[i].tip<>0 then
      if must[i].delay.ready then {dec(must[i].delay) else}
      with must[i] do
      begin
        case tip of
         1: initmon(x,y,curtip,dest,true,true,0);
         2: inititem(x,y,0,0,curtip,true);
        end;
        tip:=0;
        initbomb(x,y-16,reswapbomb,-1);
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
procedure loadwalls(a:string);
var dat:text;
  k,i:longint;
begin
{  assign(dat,inidir+'wall.ini');
  reset(dat);
  k:=0;
  while not seekeof(dat) do begin readln(dat); inc(k);end;
  close(dat);}

  assign(dat,a{inidir+'wall.ini'});
{$i-}  reset(dat); {$i+}
  if ioresult<>0 then exit;
{  readln(dat,k);}
{  if debug and(k>10) then k:=10;}
//  getmem(allwall,(k+1)*9);
  i:=0;
  while not eof(dat) do
  begin
    inc(i);
    readln(dat,allwall[i]);
{    loadbmp(allwall^[i]);}
  end;
  maxallwall:=i;
  close(dat);
end;

{procedure loadbots(name:string);
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
end;}

procedure botmenu;
var
  r,p,i,bots,mans:integer;
begin
  men[1]:='Single';
  men[2]:='1 player';
  men[3]:='2 players';
  men[4]:='3 players';
  men[5]:='4 players';
  r:=menu(5,3,'Players');
  case r of
    1: p:=0;
    2: p:=1;
    3: p:=2;
    4: p:=3;
    5: p:=4;
    0: begin maxallpl:=0; level.maxpl:=0; exit; end;
  end;
  fillchar(bot,sizeof(bot),0);
  fillchar(scrc,sizeof(scrc),0);
  for i:=1 to maxplays do begin
    bot[i]:=1;
//    bot[i]:=tip[i];
  end;
  level.maxpl:=p;
  for i:=1 to p do
    bot[i]:=0;
  case p of
    1: scrc[1]:=all;
    2: begin
      scrc[1]:=up;
      scrc[2]:=down;
    end;
    3: begin
      scrc[1]:=up;
      scrc[2]:=dl;
      scrc[3]:=dr;
    end;
    4: begin
      scrc[1]:=dl;
      scrc[2]:=ul;
      scrc[3]:=dr;
      scrc[4]:=ur;
    end;
  end;
  mans:=level.maxpl;
  bots:=maxplays-level.maxpl;
  if level.maxpl>0 then men[1]:='No bots'
  else men[1]:='Cancel';
  men[2]:='1 bot';
  men[3]:='2 bots';
  men[4]:='3 bots';
  men[5]:='4 bots';
  men[6]:='5 bots';
  men[7]:='6 bots';
  men[8]:='7 bots';
  men[9]:='8 bots';
  level.maxpl:=menu(bots+1,bots+1,'Bots')-1;
  maxallpl:=mans+level.maxpl;
  bots:=maxallpl-mans;

  if mans=0 then
  case bots of
    1: scrc[1]:=all;
    2: begin
      scrc[1]:=up;
      scrc[2]:=down;
    end;
    3: begin
      scrc[1]:=up;
      scrc[2]:=dl;
      scrc[3]:=dr;
    end;
    else begin
      scrc[1]:=dl;
      scrc[2]:=ul;
      scrc[3]:=dr;
      scrc[4]:=ur;
    end;
  end;
end;
{procedure botmenu;
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
end;}

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
{    repeat
      readln(f,r);
      r:=upcase(r);
      if (pos(upcase('single'),r)=1)and(t=single) then ok:=true;
      if (pos(upcase('coop'),r)=1)and(t=coop) then ok:=true;
      if (pos(upcase('death'),r)=1)and(t=death) then ok:=true;
    until r='[MAIN]';}
    close(f);

    findnext(g);
//    if not ok then dec(s);
  end;
  s:=menu(s,1,'Mods');
  if s<>0 then
    loadmod(c[s]);
end;

procedure normskill(s:integer);
begin
 with level do
  case s of
   1: begin reswap:=false;reswaptime:=30; monswaptime:=240; rail:=false; look:=false;sniper:=false; end;
   2: begin reswap:=false;reswaptime:=40; monswaptime:=180; rail:=false; look:=true; sniper:=false; end;
   3: begin reswap:=false;reswaptime:=50; monswaptime:=120; rail:=false; look:=true; sniper:=false; end;
   4: begin reswap:=false;reswaptime:=60; monswaptime:=60;  rail:=false; look:=true; sniper:=true; end;
   5: begin reswap:=true; reswaptime:=90; monswaptime:=60;  rail:=true;  look:=true; sniper:=true; end;
  end;
end;
function skillmenu:integer;
var s:integer;
begin
  men[1]:='Easy';
  men[2]:='Medium';
  men[3]:='Normal';
  men[4]:='Hard';
  men[5]:='Nightmare';
  s:=menu(5,3,'Difficulty');
  skillmenu:=s;
  normskill(s);
{  with level do
  case s of
   1: begin reswap:=false;reswaptime:=30; monswaptime:=240; rail:=false; look:=false;sniper:=false; end;
   2: begin reswap:=false;reswaptime:=40; monswaptime:=180; rail:=false; look:=true; sniper:=false; end;
   3: begin reswap:=false;reswaptime:=50; monswaptime:=120; rail:=false; look:=true; sniper:=false; end;
   4: begin reswap:=false;reswaptime:=60; monswaptime:=60;  rail:=false; look:=true; sniper:=true; end;
   5: begin reswap:=true; reswaptime:=90; monswaptime:=60;  rail:=true;  look:=true; sniper:=true; end;
  end;}
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
     assign(f,savedir+'save'+st(i)+'.sav');
    {$i-}reset(f,1);
    {$i+}
    if ioresult<>0 then begin men[i]:='Empty'; continue; end;
    blockread(f,c,4);
    blockread(f,s,256);
    men[i]:=s;
    close(f);
  end;
  getsave:=menu(max,1,title);
  time.clear;
  rtimer.clear;
  unpush:=false;
end;

const
  xorvalue=$7A3E6bc;
type
  ta=array[0..3*65520 div 4]of longint;
var
  a:^ta;

procedure xorwrite(var f:file; var x; l: longint);
var
  i: longint;
begin
//  log('L = ',l);
//  dosmemmove(seg(x),ofs(x),seg(a^),ofs(a^),l);
  move(x,a^,l);

  for i:=0 to l div 4-1 do
    a^[i]:=a^[i] xor (xorvalue+i*$1ac);

  blockwrite(f,a^,l);
end;
procedure xorread(var f:file; var x; l: longint);
var
  a:ta absolute x;
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
  i: integer;
begin
  if a=0 then exit;
  ForceDirectories(savedir);
  assign(ff,savedir+'save'+st(a)+'.sav');
  rewrite(ff,1);
  c:='SAVE';
  blockwrite(ff,c,4);

  s:=level.name[level.cur]+{' - '+strtime(round(time.tik/tps))+}' - '+strtime(round((level.curtime-level.start)/tps));

  blockwrite(ff,s,256);
  xorwrite(ff,curmod,32);
  xorwrite(ff,level,sizeof(level));
  xorwrite(ff,map.x,sizeof(map.x));
  xorwrite(ff,map.y,sizeof(map.y));
  for i:=0 to map.y do
    xorwrite(ff,map.land[i]^,map.x*2);

  with map do begin
{    blockwrite(ff,patname^,sizeof(arrayofstring8));}
    xorwrite(ff,m^,sizeof(arrayofmon));
    xorwrite(ff,item^,sizeof(arrayofitem));
    xorwrite(ff,f^,sizeof(arrayoff));
    xorwrite(ff,pix^,sizeof(arrayofpix));
    xorwrite(ff,b^,sizeof(arrayofpul));
    xorwrite(ff,e^,sizeof(arrayofbomb));
    xorwrite(ff,n^,sizeof(arrayofnode));
    xorwrite(ff,msg,sizeof(msg));
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
  i: integer;
begin
  if a=0 then exit;
  assign(ff,savedir+'save'+st(a)+'.sav');
{$i-}  reset(ff,1); {$i+}
  if ioresult<>0 then exit;
  c:='SAVE';
  blockread(ff,c,4);
  blockread(ff,s,256);

  xorread(ff,s,32);
//  loadmod(s);

  xorread(ff,level,sizeof(level));

  level.load(loadlev);

  xorread(ff,map.x,sizeof(map.x));
  xorread(ff,map.y,sizeof(map.y));

  for i:=0 to map.y do
    xorread(ff,map.land[i]^,map.x*2);


  with map do begin
{    blockread(ff,patname^,sizeof(arrayofstring8));}
    xorread(ff,m^,sizeof(arrayofmon));

    xorread(ff,item^,sizeof(arrayofitem));
    xorread(ff,f^,sizeof(arrayoff));
    xorread(ff,pix^,sizeof(arrayofpix));
    xorread(ff,b^,sizeof(arrayofpul));
    xorread(ff,e^,sizeof(arrayofbomb));
    xorread(ff,n^,sizeof(arrayofnode));
    xorread(ff,msg,sizeof(msg));

{    for i:=0 to maxmon do m^[i].newObj;
    for i:=0 to maxitem do item^[i].newObj;
    for i:=0 to maxf do f^[i].newObj;
    for i:=0 to maxpix do pix^[i].newObj;
    for i:=0 to maxpul do b^[i].newObj;
    for i:=0 to maxnode do n^[i].newObj;}
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
  i,mm:integer;
begin
  setpal;
  for i:=0 to 255 do
    pkey[i]:=false;

  level.endgame:=false;
  sdlinput.show;
  mm:=4; if level.death then mm:=5;
  men[1]:='Continue';
  men[2]:='Save';
  men[3]:='Load';
  men[4]:='Main menu';
  men[5]:='Random level';
  case menu(mm,1,'') of
   0,1: level.endgame:=false;
   2: savegame(getsave('Save'));
   3: loadgame(getsave('Load'));
   4: level.endgame:=true;
   5: player[1].win:=true;
  end;
  if not level.endgame then sdlinput.hide;
  unpush:=false;
end;

procedure editormenu;
var
  i:integer;
begin
  setpal;
  for i:=0 to 255 do
    pkey[i]:=false;

  level.endgame:=false;

  men[1]:='Continue';
  men[2]:='Main menu';
  case menu(2,1,'') of
   0,1: level.endgame:=false;
//   2: savegame(getsave('Сохранить'));
//   3: loadgame(getsave('Загрузить'));
   2: level.endgame:=true;
  end;
  unpush:=false;
end;

procedure loadlevellist(b:string);
begin
{  if not }level.loadini(mainmod+'/levels.ini',b);{then}
{  if not }level.loadini(runmod+'/levels.ini',b);{then}
{  if not level.loadini(mainmod+'\mod.ini',b)then
   writeln('No mod.ini found in dirs '+runmod+' and '+mainmod);}
end;

procedure mainmenu;
var
  s:string;
  t: integer;
begin
 loaded:=false;
 repeat
   level.first:=false;
   men[1]:='Один игрок';
   men[2]:='Тренировка';
   men[3]:='Вместе';
   men[4]:='Бой';
   men[5]:='Загрузить';
   men[6]:='Редактор';
   men[7]:='Выход';
   with level do
   case menu(7,1,'') of
    1: begin // Single player game
         debug:=false;
         loadlevellist('single');
         level.cheater:=false;
         level.skill:=skillmenu;
         level.first:=level.skill<>0;
         level.cur:=0;
         level.editor:=false;
         level.multi:=false;
         level.death:=false;
         level.training:=false;
         maxallpl:=1; winall:=false;
         bot[1]:=0;
         scrc[1]:=all;
         level.setup;
       end;
    2: begin // Training player game
         debug:=false;
         loadlevellist('training');
         level.cheater:=false;
         level.skill:=3;
         normskill(3);
         level.first:=level.skill<>0;
         level.cur:=0;
         level.editor:=false;
         level.multi:=false;
         level.death:=false;
         level.training:=true;
         maxallpl:=1; winall:=false;
         bot[1]:=0;
         scrc[1]:=all;
         level.setup;
       end;
    3: begin // Cooperative
         debug:=false;
         loadlevellist('coop');
         level.cheater:=false;
         level.training:=false;
         level.skill:=skillmenu;
         botmenu;
         if maxallpl=0 then continue;
         first:=level.skill<>0;
         level.cur:=0;editor:=false; multi:=true; death:=false; winall:=false;
         level.setup;
       end;
    4: begin // DeathMatch
         debug:=false;
         level.death:=true;
         level.cheater:=false;
         level.training:=false;
         loadlevellist('death');
         level.skill:=skillmenu;
         botmenu;
         if maxallpl=0 then continue;
         winall:=false;
         first:=level.skill<>0;
         if first then
         begin
           t:=getlevellist('Уровень');
           if t<>0 then begin
              editor:=false; multi:=true; death:=true;
              reswap:=true;
              level.setup;
              level.cur:=t;
              level.load(firstlev);
           end else continue;
         end else continue;
       end;
    5: begin loadgame(getsave('Load')); if loaded then break; end;
    6: begin level.cheater:=false;
        winall:=false; endgame:=false; debug:=true; editor:=true;first:=true;end;
    0,7: begin endgame:=true; first:=true;end;
   end;
 until level.first;
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
procedure loading(a:string);
begin
//  lastinidir:=inidir;
{  write(load[1]);}  {loadbots('bot.ini');}
{  write(load[2]);}  loadwalls(a+'wall.ini');
{  write(load[3]);}  loadbombs(a+'bomb.ini');
{  write(load[4]);}  loadbullets(a+'bullet.ini');
{  write(load[5]);}  loadweapons(a+'weapon.ini');
{  write(load[6]);}  loaditems(a+'item.ini');
{  write(load[7]);}  loadmonsters(a+'monster.ini');
{  write(load[8]);}  loadfuncs(a+'func.ini');
end;

procedure addbmpdirs(a:string);
var
  f:text;
  s,s1,s2:string;
  nm,i,j:longint;
begin
  assign(f,a+'/mod.ini');
{$i-}  reset(f); {$i+}
  if ioresult<>0 then begin writeln('ERROR: Cannot open ',a+'/mod.ini'); exit; end;
  while not eof(f) do
  begin
    readln(f,s);
    if (s[1]=';')or(s='')or(s[1]='/')then continue;
    if s[1]='[' then
      begin nm:=vl(copy(s,2,length(s)-2)); continue; end;
    i:=pos('=',s);
    if i>0 then
    with monster[nm] do
    begin
      s1:=downcase(copy(s,1,i-1));
      s2:=copy(s,i+1,length(s)-i);
      if s1='bmpdir' then addsdir(a+'/'+s2);
    end;
  end;
  close(f);
end;

procedure loadmod(a:string);
begin
//  chdir('..\'+a);
//  mainmod:=a;

//  dbmp:=mainmod+'\BMP\';
//  mainmod:=upcase(mainmod);
//  runmod:=upcase(runmod);
  if origlevels then
  levdir:=runmod+'/Levels/'
  else
  levdir:=mainmod+'/Levels/';

  maininidir:=mainmod+'/';
  inidir:=runmod+'/';
  savedir:=runmod+'/Saves/';

  fillchar(p,sizeof(p),0);

//  w.load(a+'\'+a+'.wad');
  aw.addall(mainmod);
  if mainmod<>runmod then aw.addall(runmod);

  maxs:=0;
  addbmpdirs(mainmod);
  if mainmod<>runmod then
    addbmpdirs(runmod);

{  addsdir(mainmod+'/BMP');
  if mainmod<>runmod then addsdir(runmod+'/BMP');}

  write('Loading');
  noImage:=loadbmp('error');
//  level.loadini(runmod+'\mod.ini');
  loadmodfile(a+'/mod.ini');
  writeln('Menu sounds: nav=',menuNavSound,' sel=',menuSelectSound,' back=',menuBackSound);
  {  if upcase(lastinidir)<>upcase(inidir) then }
  loading(maininidir);
  if (maininidir<>inidir) then
    loading(inidir);
end;

procedure movemouse;
begin
    mx:=sdlinput.X;  my:=sdlinput.Y; push:=sdlinput.push; push2:=sdlinput.push2;push3:=sdlinput.push3 or pkey[59];
//    add:=7;
    {    case res of
     0,1: add:=1;
     2,3: add:=7;
    end;}
    lastx:=mx-getmaxx div 2+add;
    lasty:=my-getmaxy div 2;
    if not level.editor {and(rtimer.hod mod 10=0)}then
    begin
      setMouseCursor(getmaxx div 2,getmaxy div 2);
    end;
end;
procedure movekeyboard;
var
  i,j:longint;
  a: real;
begin
   keyb;
   for j:=1 to min(3,level.maxpl) do
     for i:=1 to maxkey do
       player[j].key[i]:=pkey[ckey[j,i]];

   player[1].key[kJump]:=player[1].key[kJump] or pkey[57{Space Bar}];

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
   if pkey[59 {F1}]then
     if unpush then begin si:=not si; unpush:=false; end;

   if pkey[60 {F2}]then
     savegame(getsave('Save'));
   if pkey[61 {F3}]then
     loadgame(getsave('Load'));
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
   if not level.death then begin
     a:=0;
     if pkey[73{PgUp}] then a:=-pi/4;
     if pkey[81{PgDn}] then a:=pi/4;
     if pkey[71{Home}] then a:=-3*pi/4;
     if pkey[79{End}] then a:=3*pi/4;
     if a<>0 then begin
       if cos(a)>0 then
       map.m^[player[1].hero].dest:=right
        else
       map.m^[player[1].hero].dest:=left;

       map.m^[player[1].hero].angle:=a;
       player[1].key[katack]:=true;
       map.m^[player[1].hero].sniperman:=true;
     end else
       map.m^[player[1].hero].sniperman:=false;
   end;
end;
procedure passwords;
var
  i,j: longint;
  lev:string;
  c:char;
begin
    while keypressed do
    begin
      if length(keybuf)=255 then keybuf:=copy(keybuf,2,254);
      c:=readkey;
      level.endgame:=level.endgame or (c=#27);
      keybuf:=keybuf+downcase(c);

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
            if map.m^[player[i].hero].god.ready then begin
              map.m^[player[i].hero].god.init(-1);
              map.m^[player[i].hero].life:=true;
              map.m^[player[i].hero].delay.clear;
              if map.m^[player[i].hero].health<=0 then map.m^[player[i].hero].health:=0.1;
            end
            else map.m^[player[i].hero].god.clear;
           keybuf:=''; level.cheater:=true;
          end;
       if (pos('iddqd',keybuf)>0) then
         begin
           for i:=1 to level.maxpl do begin
              map.m^[player[i].hero].god.clear;
              map.m^[player[i].hero].damage(map.m^[player[i].hero].mx,map.m^[player[i].hero].my,0,10000,100,0,-1,0,-5);
           end;
           keybuf:=''; //level.cheater:=true;
          end;
       if (pos('kill',keybuf)>0) then
         begin
           for i:=0 to maxmon do
             if map.m^[i].life and (map.m^[i].hero=0)then
              map.m^[i].damage(map.m^[i].mx,map.m^[i].my,0,10000,100,0,-1,0,-5);
           keybuf:=''; level.cheater:=true;
          end;
       if pos('all',keybuf)>0 then
         begin
           for i:=1 to level.maxpl do begin
            for j:=1 to 39 do
              map.m^[player[i].hero].takeitem(j);
            for j:=1 to maxbul do
              map.m^[player[i].hero].bul[j]:=bul[j].max;
           end;
           keybuf:=''; level.cheater:=true;
          end;
       if pos('open',keybuf)>0 then begin
           for i:=0 to maxf do
             if map.f^[i].tip=15 then map.f^[i].door(i);
           keybuf:=''; level.cheater:=true;
       end;
       if pos('tank',keybuf)>0 then
         begin
           for i:=1 to level.maxpl do
            for j:=41 to 50 do
              map.m^[player[i].hero].takeitem(j);
           keybuf:=''; level.cheater:=true;
        end;
       if pos('fly',keybuf)>0 then  begin
           for i:=1 to level.maxpl do
           if map.m^[player[i].hero].g<>0 then
             map.m^[player[i].hero].g:=0 else
             map.m^[player[i].hero].g:=map.g;
           keybuf:=''; level.cheater:=true;
        end;
       if pos('speed',keybuf)>0 then
         begin
           for i:=1 to level.maxpl do
            if map.m^[player[i].hero].usk=1 then
             map.m^[player[i].hero].usk:=3
             else
             map.m^[player[i].hero].usk:=1;
           keybuf:=''; level.cheater:=true;
        end;
      end;
      end;
       if pos('win',keybuf)>0 then begin
           for i:=1 to level.maxpl do
              player[i].win:=true;
         keybuf:='';  if not level.death then level.cheater:=true;
       end;
end;
procedure checkwingame;
var
  i,j: longint;
  w: boolean;
begin

    level.endgame:=
      level.endgame or (pkey[1{Esc}]and unpush);
    if not pkey[1] and not pkey[59] then unpush:=true;

  if not level.editor then begin
    if not level.multi then
      level.endgame:=level.endgame or player[1].lose or player[1].win
     else
     for i:=1 to level.maxpl do
       level.endgame:=level.endgame or player[i].win;
   if level.multi then
    for i:=1 to level.maxpl do
     if player[i].lose then
       player[i].initmulti;

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
        w:=false;
        for i:=1 to level.maxpl do w:=w or player[i].win;
        if w then
        begin
          for i:=1 to level.maxpl do
           if not map.m^[player[i].hero].life then
             player[i].initmulti;

          setpal;
          scrmode:=normal;
          level.first:=false;
          if not level.death then drawwin;
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
          setpal;
          scrmode:=normal;
          level.first:=false;
          drawwin;
          loadnextlevel;
          level.endgame:=false;
          time.clear;
          rtimer.clear;
        end else
        if player[1].lose then
        begin
          setpal;
          scrmode:=normal;
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
  end;
  if level.editor and level.endgame then
    begin
       editormenu;
       time.clear;
       rtimer.clear;
     end;
end;

procedure checktimer;
var
  i,j:longint;
  adelay:longint;
begin
  level.curtime:=time.tik;
  if time.fps<>0 then speed:=mfps/time.fps*usk;
  if speed>5 then speed:=5;

    if (not level.editor)and sfps then
    begin
      speed:=1;
      if rtimer.hod>100 then begin
        inc(i);
      end;
      adelay:=round(adelay+(time.fps-mfps)*1000);
      if adelay<0 then adelay:=0;
      for i:=0 to adelay do;
    end;
end;

procedure loaddoomini;
var
  f:text;
  s,s1,s2:string;
  nm,i,j:longint;

begin
  settings.botdelay:=10;
  settings.mondelay:=10;
  settings.botgetgoal:=50;
  settings.botreset:=1;
  maxpix:=maxarraypix;

  assign(f,'doom.ini');
{$i-}  reset(f);{$i+}
if ioresult<>0 then begin writeln('WARNING: doom.ini not fund; default mod = RF'); exit; end;
  while not eof(f) do
  begin
    readln(f,s);
    if (s[1]=';')or(s='')or(s[1]='/')then continue;
    if s[1]='[' then
      begin nm:=vl(copy(s,2,length(s)-2)); continue; end;
    i:=pos('=',s);
    if i>0 then begin
      s1:=downcase(copy(s,1,i-1));
      s2:=copy(s,i+1,length(s)-i);

      if s1='mainmod' then mainmod:=s2;
      if s1='runmod' then runmod:=s2;
      if s1='title' then title:=s2;
      if s1='bot delay' then settings.botdelay:=vl(s2);
      if s1='monster delay' then settings.mondelay:=vl(s2);
      if s1='bot get goal' then settings.botgetgoal:=vl(s2);
      if s1='bot reset' then settings.botreset:=vl(s2);
      if s1='max pix' then begin maxpix:=vl(s2); if maxpix>maxarraypix then maxpix:=maxarraypix; end;
    end;
  end;
  close(f);
end;

procedure drawsi;
procedure put(x,y,i: integer);
begin
  print(x,y,  botcol[i], gett(i)+' - '+st(player[i].frag)+'/'+st(player[i].die));
end;
type
  ttt=record
    who: integer;
    pr: real;
  end;
var
  i,j,cx,cy: integer;
  a:array[1..maxplays]of ttt;
  temp: ttt;
function get(a:longint): real;
begin
  if a=0 then get:=0.5 else get:=a;
end;
begin
  cx:=1; cy:=getmaxy-10*(level.maxpl+1);

  for i:=1 to level.maxpl do begin
    a[i].who:=i;
    a[i].pr:=(get(player[i].frag))/(get(player[i].die));
  end;

  for i:=1 to level.maxpl-1 do
    for j:=i+1 to level.maxpl do
      if a[i].pr<a[j].pr then begin
        temp:=a[i];
        a[i]:=a[j];
        a[j]:=temp;
      end;

  for i:=1 to level.maxpl do
    put(cx,cy+(10*i-1),a[i].who);
end;
(******************************** PROGRAM ***********************************)
var
  i,j:longint;
begin
  randomize; new(a);
  loaddoomini;

  firstintro; loadkeys;

//  chdir(mainmod);
  if (upcase(paramstr(1))='DEBUG')or(upcase(paramstr(2))='DEBUG')then debug:=true;
  if paramstr(1)<>'' then runmod:=paramstr(1);
  loadmod(runmod);

{Main Loading}
  loadpal2(maininidir+'playpal.bmp');

  curmod:=''; lastinidir:='';

  wb.load('stbf_',10,1); rb.load('stcfn',5,2);

//  rocket2:=loadbmp('rocketl');
  pnode:=loadbmp('node');  pnodei:=loadbmp('nodei');  pnodeg:=loadbmp('nodeg');
  for i:=0 to 9 do d[i]:=loadbmp('d'+st(i)); dminus:=loadbmp('dminus'); dpercent:=loadbmp('dpercent');
  cur:=loadbmp('cursor');
  botcol[1]:=white;  botcol[2]:=yellow;  botcol[3]:=green;  botcol[4]:=blue;
  botcol[5]:=red;  botcol[6]:=red;  botcol[7]:=red;  botcol[8]:=red;
  {Init Screen...}

//  initgraph(res);
  mx:=640; my:=480;
  setmode(mx,my); setpal;
  InitSound;
  Sensetivity(sdlgraph.WINDOW_SCALE, sdlgraph.WINDOW_SCALE);
  loadfont(maininidir,8);
  getmaxx:=mx; getmaxy:=my;
  minx:=0; miny:=0; maxx:=getmaxx; maxy:=getmaxy;

  mfps:=30;
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
    ed.land.curname:=allwall[1]; ed.land.mask:=1;   ed.what:=face;
    ed.cool:=true;   level.maxpl:=0;
    map.addpat(allwall[1]);  winall:=false;
    ed.drag:=false;
  end;


  time.clear;rtimer.clear; time.fps:=mfps;
  if (not level.editor)and(not loaded)and not level.death then level.next;

  {Start game}
  keybuf:='';
  if (not level.editor)and(not loaded) then drawintro;
  speed:=1;
  level.endgame:=false;

  time.init(ttip.time,50);
  rtimer.init(frame,480);

  time.clear;rtimer.clear; time.fps:=mfps;
  winall:=false;
  ddx:=sdlgraph.WINDOW_SCALE;
  ddy:=sdlgraph.WINDOW_SCALE;
  if level.editor then sdlinput.show else sdlinput.hide;
  mousebox(0,0,getmaxx,getmaxy); loaded:=false;
  unpush:=false; scrmode:=normal; hod:=0;  level.start:=time.tik; speed:=1; si:=true;
  level.alltime:=0;
  level.start:=time.tik;
  repeat
    rtimer.move; time.move; inc(hod);
    movemouse;
    movekeyboard;
    if not level.editor then begin
      passwords;
      for i:=1 to level.maxpl do player[i].move;
      map.move;
      info.move;
      for i:=1 to level.maxpl do player[i].draw;
      info.draw(1,1);
      if level.death and si then drawsi;
    end else begin
      while keypressed do readkey;
      clear;
      ed.move;
      map.move;
      ed.draw;
    end;

    if level.cheater then wb.print(275,200,'Cheater');

    rb.print(getmaxx-24,getmaxy-8,st0(round(rtimer.fps),3));
//    rb.print(getmaxx-24,getmaxy-16,st0(hod,3));

    case scrmode of
      normal: screen;
      shift: screen(10,hod);
      wave:  screen(hod);
      reverse: screenr;
    end;

//    crt.delay(200);

    checktimer;
    checkwingame;
  until level.endgame or winall or quit_requested;
  sdlinput.show;
  winall:=false;
 until quit_requested;
  {End game}
  DoneSound;
  closegraph;
//  map.done;

  firstintro;   //  outtro;
//  WEAPONINFO;
end.
