unit rfunit;
interface
uses api,grx,sdlinput,sprites,sdlgraph;
const
  maxsdir=16;

  maxtit=9;
  mainmod:string='RF';
  runmod:string='RF';
  tit:array[1..maxtit]of string=(
  'Copyright DiVision ','>--=[�]=--<','^ ^',
  'PRG',
  'Andrey Ivanov "KindeX[MMX]" kindexz@gmail.com',
  'Levels & Design',
  'Alexander Rodionov "Dark Sirius[MMX]"',
  'Pavel Burakov "Zonik[MMX]"',
  ''
  );

var
  debug:boolean = true;
  s,o: longint; // Keyboard mem[s:o]
type
  tbot=record
     tip,bot:integer;
//     scr:;
     name:string[32];
  end;
const
  maxplays=8;
  {Start RF.MOD}
  playdefitem:integer=2;

  playdefhealth:integer=100;
  playmaxarmor:integer=200;

  freeitem:integer=1;
  multiitem:integer=2;
  Freemultiitem:integer=1;
  bot:array[1..maxplays]of integer=(0,1,1,1,1,1,1,1);
  tip:array[1..maxplays]of integer=(10,9,12,11,8,7,6,5);
  scrc:array[1..maxplays]of (nonec,up,down,all,ul,ur,dl,dr)=(all,nonec,nonec,nonec,nonec,nonec,nonec,nonec);

  {End}
  usk: real = 1;
  ausk: real = 1;
  bloodu: real = 0.1;
  ppm=14; {pixel per meter (from plays.bmp)}
  ms=ppm/30; { meter/sec}
  ms2=ms/30; { meter/sec2}
  maininidir:string[32]='RF/ini/';
  inidir:string[32]='RF/ini/';
  maxmust=256;
  maxit=96;
  maxf=128;  maxarraypix=512;  maxpul=512;  maxexpl=64;  maxmontip=64;
  maxweapon=48;  maxbomb=32;  maxnode=300;
  maxbul=32;
  maxmonframe=10;
  maxfname=64;
type
   tdest=(left,right);

   tmaxit=0..maxit;
   tmaxmontip=0..maxmontip;
   tmaxweapon=0..maxweapon;
   tmaxbomb=0..maxbomb;
   tmaxbul=0..maxbul;
   tmaxnode=0..maxnode;

var
  maxs: integer;
  sdir: array[1..maxsdir]of string;
  pkey:array[byte]of boolean {absolute _key_pressed};
  must:array[0..maxmust]of record
    tip: integer;
    x,y,curtip: integer;
    dest: tdest;
    delay: longint;
  end;
  it:array[tmaxit]of record
    name:string[40];
    vis:string[32];
    skin:array[0..maxmonframe]of tnpat;
    weapon,ammo,count,max,longjumpn:longint;
    health,armor,megahealth,god,longjump,
      armorhit,armorbomb,armoroxy,armorfreez,qdamage,
      drugs,reverse,shift,wave:real;
    speed:real;
    cant,aqua:boolean;
  end;
  bul:array[tmaxbul]of record
    name:string[40];
    vis, visr:string[32];
    maxfly,maxflyr,delfly,shot:byte;
    fly, flyr:array[0..maxmonframe]of tnpat;
    hit,freez,fire,mg,prise,g,per,time: real;
    max: longint;
    laser,walldetonate,rotate: boolean;
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
    vis:string[32];
    skin: tnpat;
    bul,pul: tmaxbul;
    mg,prise:real;
    shot,hit,reload,speed,speedy,per,damages,bomb,hits, range:real; {shot time}
    slot,reloadslot,cool,shortcut,multi,input:longint;
    sniper,double:boolean;
  end;
  monster:array[tmaxmontip]of record
    name:string[40];
    x,y:integer;
    dest:tdest;
    health,armor,h,stay:longint;
    defitem: tmaxweapon; {?}
    fish, turret, barrel, fly:boolean;
    speed,jumpx,jumpy,acsel,brakes,gun,defangle:real;
    vis:string[32];
    stand,damage,fire,hai:array[tdest]of tnpat;
    turvis: tnpat;
    run,die,bomb, duck:array[0..maxmonframe-1,tdest]of tnpat;
    runi,damagei,diei,bombi, ducki:record
       max:longint; delay:real;
    end;
  end;
  fname:array[0..maxfname]of record
    name:string[16];
    vis:string[32];
    skin: tnpat;
    n: integer;
  end;
var
  curmod: string;
  skull1,skull2,intro:tnpat;
  en:array[1..8]of tnpat;
  men:array[0..100]of string[80];

procedure loadmonsters(a:string);
procedure loadweapons(a:string);
procedure loadbombs(a:string);
procedure loadbullets(a:string);
procedure loaditems(a:string);
procedure loadfuncs(a:string);
procedure keyb; {interrupt;}
procedure loadkeys;
procedure manualinfo;
procedure addsdir(s:string);
function findbmp(s:string):string;
function bmpexist(s:string):boolean;
function crc(a:string):longint;
procedure checkcrc(a:string);

(****************************************************)implementation
var
  buf: array[0..32000]of byte;

function crc(a:string):longint;
var
  f:file;
  i,r,reads:longint;
begin
  r:=0;
  assign(f,a);
  reset(f,1); i:=504;
  while not eof(f)do begin
    blockread(f,buf,32000, reads);
    if reads=0 then break;
    for i:=0 to reads-1 do
      r:=r+buf[i]*(i+504)*13;
  end;
  close(f);
  crc:=r;
end;

procedure checkcrc(a:string);
var
  b:string;
  f:text;
  c,cr: longint;

begin
  if ((runmod<>'RF')and(runmod<>'Doom'))or debug then exit;
  c:=crc(a);
  b:=a;
  b[length(b)-0]:='C';
  b[length(b)-1]:='R';
  b[length(b)-2]:='C';
  assign(f,b);
{$i-}  reset(f); {$i+}
if ioresult=0 then begin
  readln(f,cr);
  close(f);
  end else cr:=0;
  if c<>cr then begin
    writeln;
    writeln(a,' changed! Reinstall game, cheater ;)');
//    writeln('You can''t change RF and DOOM mods');
    writeln;
    halt;
  end;
end;


function bmpexist(s:string):boolean;
var
  i:integer;
begin
  for i:=1 to maxs do
    if fexist(sdir[i]+s+'.bmp') then begin bmpexist:=true; exit; end;
  bmpexist:=false;
end;

function findbmp(s:string):string;
var
  i:integer;
begin
  for i:=maxs downto 1 do
    if fexist(sdir[i]+s+'.bmp') then begin
      findbmp:=sdir[i]+s+'.bmp';
      exit;
    end;
  findbmp:='';
end;

procedure addsdir(s:string);
begin
  inc(maxs);
  sdir[maxs]:=s+'/';
  writeln('Using BMP directory ',s+'/');
end;

procedure manualinfo;
begin
  writeln('��ࠢ����� : 1(Center) 2(Left)  3(PAD)  4(Mouse)    ');
  writeln('��ࠢ�     : Right     D        PgDn    Left        ');
  writeln('�����      : Left      A        End     Right       ');
  writeln('��릮�     : Up        W        Pad 5   Up          ');
  writeln('����       : Down      S        Ins     Down        ');
  writeln('��५���   : Ctrl      Tab      +       Left Button ');
  writeln('��५���2  : Alt       CapsLock Num Lock            ');
  writeln('�।��㦨� : Shift     Q        *                   ');
  writeln('������㦨� : Enter     ~        -       Right Button');
  writeln('��ࠢ����� ��⠬�: Z-�� ����  X-��࠭��� ������  C-���쭮 V - ᬨ୮!');
  writeln('F2 - ��࠭���  F3 - ����㧨��');
end;
procedure keyb; {interrupt;}
begin
  PollEvents;
end;

procedure loadmonsters(a:string);
var
  f:text;
  s,s1,s2:string;
  nm,i,j:longint;
begin

  assign(f,a{inidir+'monster.ini'});
{$i-}  reset(f); {$i+}
  if ioresult<>0 then exit;
  checkcrc(a);

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
      if s1='name' then name:=s2;
      if s1='h' then h:=vl(s2);
      if s1='firstitem' then defitem:=vl(s2);
      if s1='sizex' then x:=vl(s2);
      if s1='sizey' then y:=vl(s2);
      if s1='health' then health:=vl(s2);
      if s1='armor' then armor:=vl(s2);
      if s1='stay' then stay:=vl(s2);
      if s1='fish' then fish:=boolean(downcase(s2)='true');
      if s1='speed' then speed:=vlr(s2);
      if s1='acsel' then acsel:=vlr(s2);
      if s1='brakes' then brakes:=vlr(s2);
      if s1='jumpx' then jumpx:=vlr(s2);
      if s1='jumpy' then jumpy:=vlr(s2);
      if s1='vis' then vis:=s2;
      if s1='run' then runi.delay:=vlr(s2);
      if s1='die' then diei.delay:=vlr(s2);
      if s1='bomb' then bombi.delay:=vlr(s2);
      if s1='duck' then ducki.delay:=vlr(s2);
      if s1='gun' then gun:=vlr(s2);
      if s1='defangle' then defangle:=vlr(s2);

      if s1='barrel' then barrel:=boolean(downcase(s2)='true');
      if s1='turret' then turret:=boolean(downcase(s2)='true');
      if s1='fly' then fly:=boolean(downcase(s2)='true');
      if s1='turvis' then turvis:=loadasbmp(s2);
    end;
  end;
  close(f);
  for i:=1 to maxmontip do
  with monster[i] do
   if name<>'' then
   begin
     writeln('Loading monster ',i,': ',name,' vis=',vis);
     stand[left]:=loadbmp(vis+'s');
     stand[right]:=loadbmpr(vis+'s');


     hai[left]:=loadbmp(vis+'h');
     hai[right]:=loadbmpr(vis+'h');

     damage[left]:=loadbmp(vis+'d');
     damage[right]:=loadbmpr(vis+'d');
     fire[left]:=loadbmp(vis+'f1');
     fire[right]:=loadbmpr(vis+'f1');

     duck[1,left]:=loadbmp(vis+'c');
     duck[1,right]:=loadbmpr(vis+'c');
     ducki.max:=1;
     if duck[1,right]=noImage then
     for j:=1 to maxmonframe do
      if exist(vis+'c'+st(j))then
      begin
        duck[j,left]:=loadbmp(vis+'c'+st(j));
        duck[j,right]:=loadbmpr(vis+'c'+st(j));
        ducki.max:=j;
      end;

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
procedure loadweapons(a:string);
var
  f:text;
  s,s1,s2:string;
  nm,i,j:longint;
begin

  assign(f,a{inidir+'weapon.ini'});
{$i-}  reset(f); {$i+}
  if ioresult<>0 then exit;
  checkcrc(a);

  while not eof(f) do
  begin
    readln(f,s);
    if (s[1]=';')or(s='')or(s[1]='/')then continue;
    if s[1]='[' then begin
      nm:=vl(copy(s,2,length(s)-2));
      if nm<0 then weapon[nm]:=weapon[abs(nm)];
      continue;
    end;
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
      if s1='range' then range:=vlr(s2)*ppm;

      if s1='shot' then shot:=vlr(s2);
      if s1='reload' then reload:=vlr(s2);
      if s1='speed' then speed:=vlr(s2);
      if s1='speedy' then speedy:=vlr(s2);
      if s1='slot' then slot:=vl(s2);
      if s1='%' then per:=vlr(s2);
      if s1='multi' then multi:=vl(s2);
      if s1='input' then input:=vl(s2);
      if s1='realodslot' then reloadslot:=vl(s2);
      if s1='sniper' then sniper:=boolean(downcase(s2)='on');
      if s1='double' then double:=boolean(downcase(s2)='true');
    end;
  end;
  close(f);
  for i:=0 to maxweapon do
   with weapon[i] do
   if name<>'' then
   begin
     skin:=loadbmp(vis);
     damages:=0; bomb:=0;
     if multi<=0 then multi:=1;
     hits:=0;
     if hit>0 then hits:=hit/shot;
     damages:=hits+damages+multi*rfunit.bul[pul].shot*rfunit.bul[pul].hit/shot;
     if rfunit.bul[pul].bomb>0 then damages:=damages+rfunit.bomb[rfunit.bul[pul].bomb].hit/shot;
     if rfunit.bul[bul].bomb>0 then bomb:=rfunit.bomb[rfunit.bul[pul].bomb].hit;
   end;
end;

procedure loadbombs(a: string);
var
  f:text;
  s,s1,s2:string;
  nm,i,j:longint;
begin
  assign(f,a{inidir+'bomb.ini'});
{$i-}  reset(f); {$i+}
  if ioresult<>0 then exit;
  checkcrc(a);

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
procedure loadbullets(a:string);
var
  f:text;
  s,s1,s2:string;
  nm,i,j:longint;
begin

  assign(f,a{inidir+'bullet.ini'});
{$i-}  reset(f); {$i+}
  if ioresult<>0 then exit;
  checkcrc(a);

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
      if s1='visr' then visr:=s2;
      if s1='prise' then prise:=vlr(s2);
      if s1='mg' then mg:=vlr(s2);
      if s1='g' then g:=vlr(s2)*ms2;
      if s1='hit' then hit:=vlr(s2);
      if s1='freez' then freez:=vlr(s2);
      if s1='fire' then fire:=vlr(s2);
      if s1='bomb' then bomb:=vl(s2);
      if s1='fly' then delfly:=vl(s2);

      if s1='rotate' then rotate:=s2='true';
      if s1='%' then per:=vlr(s2);
      if s1='max' then max:=vl(s2);
      if s1='shot' then shot:=vl(s2);
      if s1='time' then time:=vlr(s2);
      if s1='staywall' then staywall:=vl(s2);
      if s1='laser' then laser:=s2='true';
      if s1='walldetonate' then walldetonate:=s2='true';
    end;
  end;
  close(f);
  for i:=1 to maxbul do
   with bul[i] do if name<>'' then
   begin
      if exist(vis)then
      begin
        if bul[i].rotate then
        fly[1]:=loadasbmp(vis)
        else
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
      flyr:=fly;
      maxflyr:=maxfly;
      if exist(visr)then
      begin
        flyr[1]:=loadbmp(visr);
        maxflyr:=1;
      end
      else
     for j:=1 to maxmonframe do
      if exist(visr+st(j))then
      begin
        flyr[j]:=loadbmp(visr+st(j));
        maxflyr:=j;
      end;
   end;
end;

procedure loaditems(a:string);
var
  f:text;
  s,s1,s2:string;
  nm,i,j:longint;
begin
  assign(f,a{inidir+'item.ini'});
{$i-}  reset(f); {$i+}
  if ioresult<>0 then exit;
  checkcrc(a);
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
      if s1='longjump' then longjump:=vlr(s2);
      if s1='longjumpn' then longjumpn:=vl(s2);
      if s1='god' then god:=vlr(s2);
      if s1='cant' then cant:=boolean(downcase(s2)='true');
      if s1='aqua' then aqua:=boolean(downcase(s2)='true');

      if s1='armorhit' then armorhit:=vlr(s2);
      if s1='armorbomb' then armorbomb:=vlr(s2);
      if s1='armoroxy' then armoroxy:=vlr(s2);
      if s1='armorfreez' then armorfreez:=vlr(s2);
      if s1='qdamage' then qdamage:=vlr(s2);

      if s1='drugs' then drugs:=vlr(s2);
      if s1='wave' then wave:=vlr(s2);
      if s1='reverse' then reverse:=vlr(s2);
      if s1='shift' then shift:=vlr(s2);
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

procedure loadfuncs(a:string);
var
  f:text;
  i,cur:integer;
begin
  cur:=0;

  assign(f,a{inidir+'func.ini'});
{$i-}  reset(f); {$i+}
if ioresult<>0 then exit;
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
procedure loadkeys;
begin
  writeln('SDL2 keyboard input initialized');
end;
//  new(p); fillchar(p^,sizeof(p^),0);
//  new(tempbmp); new(tempdata); new(cbmp);
  {Game data}
begin
  fillchar(bomb,sizeof(bomb),0);
  fillchar(monster,sizeof(monster),0);
  fillchar(weapon,sizeof(weapon),0);
  fillchar(bul,sizeof(bul),0);

  fillchar(it,sizeof(it),0);
end.
