{$A+,B+,D+,E-,F-,G+,I+,L+,N+,P-,Q-,R-,S-,T-,V+,X+,Y+ Final}
unit rfunit;
interface
uses api,grx,crt;
const
  game='Doom RF';
  version='1.37';
  data='8.12.2001';
  title='DOOM 513: Richtiger Faschist' {+version+' ['+data+']'};
  company='DIVision '#10#13'     _'#10#13'>--=[■]=--<'#10#13'    ^ ^';
  autor='Andrey Ivanov [kindeX]';
  comment='Full fersion *** Realise *** Freeware *** Special for PROGMEISTARS and PUHEL';
  shortintro=game+' ['+version+']';
var
  debug:boolean;
type
  tbot=record
     tip,bot:integer;
     scr:(up,down,all,none,ul,ur,dl,dr);
     name:string[32];
  end;
const
  maxplays=4;
  {Start RF.MOD}
  playdefitem:integer=2;
  playdefhealth:integer=100;
  freeitem:integer=1;
  multiitem:integer=2;
  Freemultiitem:integer=1;
  maxlose:integer=11;
  maxwin:integer=6;
  maxstart:integer=4;
  bot:array[1..maxplays]of tbot=(
  (tip:10; bot:0; scr:up;   name:'Player1'),
  (tip:9;  bot:1; scr:down; name:'bot2'),
  (tip:12; bot:1; scr:none; name:'bot3'),
  (tip:12; bot:1; scr:none; name:'bot4'){,
  (tip:12; bot:1; scr:none; name:'bot5'),
  (tip:12; bot:1; scr:none; name:'bot6'),
  (tip:12; bot:1; scr:none; name:'bot7'),
  (tip:12; bot:1; scr:none; name:'bot8')}
  );
  {End}
  usk: real = 1;
  ausk: real = 1;
  bloodu: real = 0.1;
  ppm=14; {pixel per meter (from plays.bmp)}
  ms=ppm/30; { meter/sec}
  ms2=ms/30; { meter/sec2}
  inidir='ini\';
  maxmust=128;
  maxit=96;
  maxf=32;  maxpix=512;  maxpul=512;  maxexpl=32;  maxmontip=32;
  maxweapon=32;  maxbomb=16;  maxnode=300;
  maxbul=16;
  maxmonframe=10;
  maxfname=32;
type
   tdest=(left,right);
   tmaxit=0..maxit;
   tmaxmontip=0..maxmontip;
   tmaxweapon=0..maxweapon;
   tmaxbomb=0..maxbomb;
   tmaxbul=0..maxbul;
   tmaxnode=0..maxnode;

var
  must:array[0..maxmust]of record
    tip: integer;
    x,y,curtip: integer;
    dest: tdest;
    delay: longint;
  end;
  it:array[tmaxit]of record
    name:string[40];
    vis:string[8];
    skin:array[0..maxmonframe]of tnpat;
    weapon,ammo,count,max:longint;
    health,armor,megahealth,god:real;
    speed:real;
    cant:boolean;
  end;
  bul:array[tmaxbul]of record
    name:string[40];
    vis:string[8];
    maxfly,delfly,shot:byte;
    fly:array[0..maxmonframe]of tnpat;
    hit,freez,fire,mg,prise,rotate,g,per,time: real;
    staywall: integer;
    bomb: tmaxbomb;
  end;
  bomb:array[tmaxbomb]of record
    name:string[40];
    vis:string[8];
    rad,maxfire: longint;
    time,hit,fired: real;
    fire:array[0..maxmonframe]of tnpat;
  end;
  weapon:array[-maxweapon..maxweapon]of record
    name:string[40];
    vis:string[8];
    skin: tnpat;
    bul,pul: tmaxbul;
    mg,prise:real;
    shot,hit,reload,speed,speedy,per,damages,bomb:real; {shot time}
    slot,reloadslot,cool,shortcut,multi:longint;
    sniper:boolean;
  end;
  monster:array[tmaxmontip]of record
    name:string[40];
    x,y:integer;
    dest:tdest;
    health,armor,h:longint;
    defitem: tmaxweapon; {?}
    stay:boolean;
    speed,jumpx,jumpy,acsel,brakes:real;
    vis:string[8];
    stand,damage,fire,hai:array[tdest]of tnpat;
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
var
  outc: integer;
  curmod: string;
  skull1,skull2,intro:tnpat;
  en:array[1..7]of tnpat;
  men:array[0..30]of string[40];

procedure loadmonsters;
procedure loadweapons;
procedure loadbombs;
procedure loadbullets;
procedure loaditems;
procedure loadfuncs;
procedure outtro;
procedure firstintro;
procedure out(a:char);
procedure loadmodfile(a:string);
procedure weaponinfo;
function menu(max,def:integer; title: string):integer;

(****************************************************)implementation
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

  {level.endgame:=false;}

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
     if bomb>0 then write(' / BOMB ',bomb:6:2);
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

procedure out(a:char);
begin
  if outc mod 10=0 then write(a);
  inc(outc);
end;
procedure firstintro;
var i:integer;
begin
  clrscr;
  textattr:=4*16+15;
  for i:=0 to 79 do mem[segb800:i*2+1]:=textattr;
  writeln(title:(80-length(title))div 2+length(title));
  textattr:=7;
  window(1,2,80,25);
  outtro;
  writeln('Free RAM: ',memavail);
end;
procedure outtro;
begin
  writeln('The ',game,' <-> ',version,' [',data,']');
  writeln('Copyright ',company);
  writeln('PRG: ',autor);
  writeln(comment);
  writeln;
  manualinfo;
  textattr:=14;
  writeln('*** Если у вас проблемы с графикой - '#13#10'замените число в первой строчке в файле res.ini на 0');
  textattr:=7;
  writeln(':)');
end;
procedure loadmonsters;
var
  f:text;
  s,s1,s2:string;
  nm,i,j:longint;
begin
  fillchar(monster,sizeof(monster),0);
  assign(f,inidir+'monster.ini');
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
     hai[left]:=loadbmp(vis+'h');
     hai[right]:=loadbmpr(vis+'h');

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
  assign(f,inidir+'weapon.ini');
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
      if s1='shortcut' then shortcut:=vl(s2);
      if s1='bul' then bul:=vl(s2);
      if s1='pul' then pul:=vl(s2);
      if s1='vis' then vis:=s2;
      if s1='mg' then mg:=vlr(s2);
      if s1='prise' then prise:=vlr(s2);
      if s1='hit' then hit:=vlr(s2);
      if s1='shot' then shot:=vlr(s2);
      if s1='reload' then reload:=vlr(s2);
      if s1='speed' then speed:=vlr(s2);
      if s1='speedy' then speedy:=vlr(s2);
      if s1='slot' then slot:=vl(s2);
      if s1='%' then per:=vlr(s2);
      if s1='multi' then multi:=vl(s2);
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
     damages:=damages+rfunit.bul[pul].shot*rfunit.bul[pul].hit/shot;
     damages:=damages+rfunit.bomb[rfunit.bul[pul].bomb].hit/shot;
     if rfunit.bul[bul].bomb>0 then bomb:=rfunit.bomb[rfunit.bul[pul].bomb].hit;
   end;
end;
procedure loadbombs;
var
  f:text;
  s,s1,s2:string;
  nm,i,j:longint;
begin
  fillchar(bomb,sizeof(bomb),0);
  assign(f,inidir+'bomb.ini');
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
  assign(f,inidir+'bullet.ini');
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
      if s1='freez' then freez:=vlr(s2);
      if s1='fire' then fire:=vlr(s2);
      if s1='bomb' then bomb:=vl(s2);
      if s1='fly' then delfly:=vl(s2);
      if s1='rotate' then rotate:=vlr(s2);
      if s1='%' then per:=vlr(s2);
      if s1='shot' then shot:=vl(s2);
      if s1='time' then time:=vlr(s2);
      if s1='staywall' then staywall:=vl(s2);
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
  assign(f,inidir+'item.ini');
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
  assign(f,inidir+'func.ini');
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
begin
  outc:=0; diskload:=true;
  new(p); fillchar(p^,sizeof(p^),0);
  new(tempbmp); new(tempdata); new(cbmp);
  {Game data}
  randomize;
  firstintro;

  debug:=upcase(paramstr(1)) ='DEBUG';
  if (memavail<1000000)and not debug then begin
    writeln;
    textattr:=4*16+14;
    writeln('FATAL ERROR: Не хватает оперативной памяти');
    textattr:=7;
    writeln;
    halt;
  end;
  write('Загрузка');
  hide_cursor;

end.
