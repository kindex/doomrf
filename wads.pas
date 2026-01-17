{$mode tp}
unit wads;

interface
uses api,sysutils;
const
  maxwad=16;
type
  tcapt=array[1..4]of char;
  tel=object
    n {Pos},l {Size}:longint;
    name:array[1..8]of char;
    curpos:longint;
    function getname:string;
    procedure read(var f:file; var p; s:longint);
    procedure assign(var f:file; w:longint);
    procedure seek(w:longint);
  end;
  ptable=^ttable;
  ttable=array[1..8000]of tel;
  tarray=array[1..64000]of byte;
  twad=object
    name:string;
    capt:tcapt; {IWAD PWAD}
    n {Items},tab {Table Pos}:longint;
    table: ptable;
    f:file;
    findn,error:longint;
    findstr:string;
    cur: tel;
    loaded:boolean;
    procedure dir;
    procedure find(ss:string);
    procedure writecapt;
    procedure extractfile(mask,g:string);
    procedure extract(mask,g:string);
    procedure add(mask:string);
    procedure create(ss:string);
    procedure delete(ss:string);
    procedure addfile(ss:string);
    procedure addasbmp(ss:string);
    procedure assign(ss:string);
    procedure read(var p; s:longint);
    procedure load(s:string);
    procedure findfirst(s:string);
    procedure findnext;
    procedure loadpal;
    procedure close;
    function  getel(s:string):integer;
    function  exist(s:string):boolean;
  end;
  taw=object
    mw,cw: integer;
    w:array[1..maxwad] of twad;
    procedure addall(s:string);
    procedure addwad(s:string);
    procedure assign(ss:string);
    procedure read(var p; s:longint);
    function  exist(s:string):boolean;
  end;

var
  aw: taw;
  p:^tarray;


implementation
uses tbmp;

procedure twad.extract(mask,g:string);
begin
  findfirst(mask);
  while error=0 do
  begin
    extractfile(cur.getname,g);
    findnext;
  end;
end;
procedure twad.extractfile(mask,g:string);
var
  p:^tarray;
  res:file;
  b: tbmpobj;
begin
  fillchar(b,sizeof(b),0);
  write('Извлекаю ',mask:12,' в ',mask+g:12);
  if (upcase(mask)<>'PLAYPAL')
  and
  (b.loadwad(mask)) then begin
    b.save8(mask+g);
    write(' (as BMP 8 bit) ');
  end
  else begin
  getel(mask);
  getmem(p, cur.l);
  if pos('.',mask)=0 then system.assign(res,mask{+g}) else system.assign(res,mask);
{$i-}  rewrite(res,1); {$i+}
  if ioresult<>0 then begin writeln(' ****** Ошибка создания файла !!!'); freemem(p, cur.l);exit;end;
  system.seek(f,cur.n);
  system.blockread(f,p^,cur.l);
  system.blockwrite(res,p^,cur.l);
  freemem(p, cur.l);
  system.close(res);
 end;
  writeln('Ok':5)
end;
procedure twad.add(mask:string);
var ss:TSearchRec;
begin
  if not loaded then create(name);
  if sysutils.FindFirst(mask,faAnyFile,ss)=0 then
  begin
    repeat
      if pos('.bmp',downcase(ss.name))>0 then
       addasbmp(ss.name)
       else
      addfile(ss.name);
    until sysutils.FindNext(ss)<>0;
    sysutils.FindClose(ss);
  end;
end;
procedure twad.writecapt;
begin
  seek(f,4); blockwrite(f,n,4); blockwrite(f,tab,4);
end;

procedure twad.delete(ss:string);
var
  k,i,sm,sos:longint;
  p: pointer;
begin
  write('Удаляю ',ss:10);
  k:=getel(ss);
  if error<>0 then begin writeln(' ******* Не могу найти ',ss);exit; end;


  sm:=filesize(f);
  getmem(p,sm);
  sos:=sm-table^[k+1].n-n*16;
  write(' (двигаю ',sos,' байтов) ');
  seek(f,table^[k+1].n); blockread (f,p^,sos);
  seek(f,table^[k].n);   blockwrite(f,p^,sos);

  for i:=k to n-1 do begin
    table^[i]:=table^[i+1];
    dec(table^[i].n, cur.l);
  end;
  dec(n);

  dec(tab, cur.l);
  seek(f, tab); blockwrite(f,table^,n*16);
  truncate(f);

  writecapt;

  freemem(p,sm);


  writeln('Ok');
end;

procedure twad.addfile(ss:string);
var
  res:file;
  p:^tarray;
  k:tel;
  i:integer;
  reads:word;
begin
  system.assign(res,ss);
{$i-}  system.reset(res,1); {$i+}
  if ioresult<>0 then begin error:=1; writeln(' ******* Не могу найти ',ss,'!!!'); exit;end;
  if pos('.',ss)>0 then ss:=copy(ss,1,pos('.',ss)-1);
  k.l:=filesize(res);
  k.n:=tab;
  ss:=getfilename(ss);
  if getel(ss)>0 then
  begin
    delete(ss);
  end;

  write('Добавляю ',ss:10,' в ',name,': ');
  k.name:=#0#0#0#0#0#0#0#0;
  for i:=1 to length(ss) do k.name[i]:=ss[i];
  inc(n);
  table^[n]:=k;
  inc(tab,k.l);
  system.seek(f,tab);
  blockwrite(f,table^,n*16);
  seek(f,k.n);
  new(p);
  while not eof(res) do
  begin
    blockread(res,p^,32*1024,reads);
    if reads=0 then break;
    blockwrite(f,p^,reads);
    write('.');
  end;
  dispose(p);
  system.close(res);
  writecapt;
  writeln('Ok');
end;

procedure twad.addasbmp(ss:string);
var
  k:tel;
  i:integer;
  reads:word;
  x,y,dx,dy,ost,t:longint;
  p: tbmpobj;
begin
  fillchar(p,sizeof(p),0);
  p.loadfile(ss);
  if p.x=0 then
     begin error:=1; writeln(' ******* Не могу загрузить ',ss,'!!!'); exit;end;

  if pos('.',ss)>0 then ss:=copy(ss,1,pos('.',ss)-1);

  x:=p.x;  y:=p.y;

  k.l:=x*y+8; k.n:=tab;
  ss:=getfilename(ss);
  if getel(ss)>0 then begin
    delete(ss);
  end;

  write('Добавляю ',ss:10,' в ',name,': ');
  k.name:=#0#0#0#0#0#0#0#0; for i:=1 to length(ss) do k.name[i]:=ss[i];
  inc(n);
  table^[n]:=k;
  inc(tab,k.l);
  system.seek(f,tab);
  blockwrite(f,table^,n*16);

  seek(f,k.n);
  blockwrite(f,x ,2);
  blockwrite(f,y ,2);
  blockwrite(f,dx,2);
  blockwrite(f,dy,2);

  blockwrite(f,p.bmp^,x*y);

//  dispose(p);
  writecapt;
  writeln('Ok');
end;
procedure twad.create(ss:string);
begin
  n:=0; tab:=12;
  name:=ss;
  capt:='IWAD';
  system.assign(f,name);
  system.rewrite(f,1);
  system.blockwrite(f,capt,4);
  system.blockwrite(f,n,4);
  system.blockwrite(f,tab,4);
  system.seek(f,tab);
  new(table);
end;
procedure twad.read(var p; s:longint);
begin
  cur.read(f,p,s);
end;
procedure twad.assign(ss:string);
var i:longint;
begin
  ss:=upcase(getfilename(ss));
  if pos('.',ss)>0 then ss:=copy(ss,1,pos('.',ss)-1);
  i:=getel(ss);
  { getel already sets cur := table^[i] with correct n, l, name }
  { Just reset curpos for sequential reading }
  if error=0 then
    cur.curpos := 0;
end;
procedure tel.seek(w:longint);
begin
  if curpos+w>l then w:=l-curpos;
  curpos:=w;
end;
procedure tel.assign(var f:file; w:longint);
begin
{  if (w>=0)and(w<filesize(f)) then begin}
//  writeln(name,': ',w);
  system.seek(f,w);
  system.blockread(f,n,4);
  system.blockread(f,l,4);
  system.blockread(f,name,8);
  curpos:=0;
{  end;}
end;
procedure tel.read(var f:file; var p; s:longint);
var
  actual: longint;
begin
//  if curpos+s>l then s:=l-curpos;
  system.seek(f,n+curpos);
  system.blockread(f,p,s,actual);
  inc(curpos,s);
end;
procedure twad.close;
begin
  if not loaded then exit;
  system.close(F);
{  freemem(table,n*16);}
  dispose(table);
  name:='';
end;
procedure twad.loadpal;
var
  e:tel;
  rgb:array[0..2]of byte;
  i:integer;
begin
  e.assign(f,tab+getel('PLAYPAL')*16);
  for i:=0 to 255 do begin
    e.read(f,rgb,3);  // Read RGB from Doom PLAYPAL
    pal[i*4+0]:=rgb[2]; // B
    pal[i*4+1]:=rgb[1]; // G
    pal[i*4+2]:=rgb[0]; // R
    pal[i*4+3]:=0;      // A
  end;
{  port[$3c8]:=0;
  for i:=0 to 255 do
  begin
(*r*)  port[$3c9]:=pal[(i*3)+0];
(*g*)  port[$3c9]:=pal[(i*3)+1];
(*b*)  port[$3c9]:=pal[(i*3)+2];
  end;}
end;
function twad.getel(s:string):integer;
var i:integer;
begin
  error:=0;
  for i:=1 to n do if upcase(table^[i].getname)=upcase(s) then
  begin
    getel:=i;
    cur:=table^[i];
    exit;
  end;
  getel:=0;
  error:=1;
end;
function tel.getname:string;
var
  t:string;
  i:byte;
begin
  i:=1; while (i<=8)and(name[i]<>#0) do inc(i);
  t:=name;
  t[0]:=char(i-1);
  getname:=t;
end;
procedure twad.findfirst(s:string);
begin
  findstr:=upcase(s);
  findn:=1;
  findnext;
end;
function twad.exist(s:string):boolean;
var c:longint;
begin
  if not loaded then begin exist:=false; exit; end;
  error:=0;
  c:=1;
  s:=upcase(getfilename(s));
  if pos('.',s)>0 then s:=copy(s,1,pos('.',s)-1);
  while c<=n do
  begin
    if s=upcase(table^[c].getname)  then begin exist:=true; exit; end;
    inc(c);
  end;
  exist:=false;
end;
procedure twad.findnext;
begin
  error:=0;
  while findn<=n do
  begin
    if
    (pos(upcase(findstr),upcase(table^[findn].getname))>0)or
    (findstr='*')or
    (findstr='*.*')
    then
    begin cur:=table^[findn];  inc(findn);exit;end;
    inc(findn);
  end;
  cur.n:=0;
  cur.l:=0;
  cur.name:=#0#0#0#0#0#0#0#0;
  error:=1;
end;

procedure twad.load;
const
  c:tcapt='IWAD';
  c2:tcapt='PWAD';
var
  i:integer;
begin
  name:=s;
  system.assign(f,name);
{$i-}  system.reset(f,1);{$i+}
 if ioresult<>0 then
   begin
     writeln('Не могу найти файл ',name);
{     create(name);}
     loaded:=false;
     exit;
   end;
  system.blockread(f,capt,4);
  if (c<>capt)and(c2<>capt) then begin system.close(f); writeln(name,'-Это не IWAD (PWAD) файл');halt;end;

  system.blockread(f,n,4);
  system.blockread(f,tab,4);
  system.seek(f,tab);
  new(table);
  { Read each entry separately: WAD entries are 16 bytes, but tel is 20 bytes (has curpos) }
  for i:=1 to n do begin
    system.blockread(f,table^[i].n,4);
    system.blockread(f,table^[i].l,4);
    system.blockread(f,table^[i].name,8);
    table^[i].curpos:=0;
  end;
  loaded:=true;

  writeln(name+' loaded (',n,' items)');
end;
procedure twad.dir;
var i:longint;
begin
  writeln('Имя         Позиция       Размер');
  for i:=1 to n do
   writeln(table^[i].name,table^[i].n:12,table^[i].l:12);
  writeln('Размер файла ',name,': ',n*16+tab);
  writeln('Элементов: ',n);
end;
procedure twad.find;
var i:longint;
begin
  writeln('Имя         Позиция       Размер');
  findfirst(ss);
  while error=0 do
  begin
    writeln(cur.name,cur.n:12,cur.l:12);
    findnext;
  end;
  writeln('Размер файла ',name,': ',n*16+tab);
  writeln('Элементов: ',n);
end;

procedure taw.assign(ss:string);
var
 i:integer;
begin
  for i:=mw downto 1 do
   if w[i].exist(ss)then begin
     cw:=i;
     w[cw].assign(ss);
     exit;
   end;
  error:=1;
end;
procedure taw.read(var p; s:longint);
begin
  w[cw].read(p,s);
end;
function  taw.exist(s:string):boolean;
var
  i: integer;
begin
  for i:=mw downto 1 do
   if w[i].exist(s)then begin
     exist:=true;
     exit;
   end;
  exist:=false;
end;
procedure taw.addwad(s:string);
begin
  inc(mw);
  w[mw].load(s);
end;

procedure taw.addall(s:string);
var
  f:TSearchRec;
begin
  if sysutils.FindFirst(s+PathDelim+'*.wad',faAnyFile,f)=0 then
  begin
    repeat
      addwad(s+PathDelim+f.name);
    until sysutils.FindNext(f)<>0;
    sysutils.FindClose(f);
  end;
end;

begin
  fillchar(aw,sizeof(aw),0);
  new(p);
end.
