{$mode tp}
{$g+,n+}
unit api;
interface

const pi2=pi*2;
      pi05=pi*0.5;

function  downcase(c:string):string;
function  upcase(c:string):string;
function  st(i:longint):string;
function  st0(i:longint; j:byte):string;
function  vlr(i:string):extended;
function  vl(i:string):longint;
function  r(i:real):longint;
function  min(a,b:longint):longint;
function  max(a,b:longint):longint;
function  fexist(name:string):boolean;
function  getfilename(n:string):string;
function  norm(a,b,c:longint):longint;
function  getnextstr(var ss:string):string;
function  getnext(var ss:string):longint;
function  mod2(a,b:longint):longint;
function  div2(a,b:longint):longint;
procedure restart;
procedure hide_cursor;

implementation
uses dos;

function mod2(a,b:longint):longint;
var
  r:longint;
begin
  r:=a mod b;
  if r<0 then inc(r,abs(b));
  mod2:=r;
end;

function div2(a,b:longint):longint;
begin
  div2:=(a-mod2(a,b)) div b;
end;


function getnext(var ss:string):longint;
  function pos(s:string):integer;
  var i:integer;
  begin
    for i:=1 to length(s) do if (s[i]=' ')or(s[i]=',')then begin pos:=i; exit;end;
  end;
var s:string;
    l,ll:integer;
begin
  while (ss[1]=' ')or(ss[1]=',') do ss:=copy(ss,2,length(ss)-1);
  l:=pos(ss);
  s:=copy(ss,1,l-1);
  ss:=copy(ss,l+1,length(ss)-l);
  val(s,ll,l);
  if l=0 then getnext:=ll else getnext:=0;
end;

function getnextstr(var ss:string):string;
  function pos(s:string):integer;
  var i:integer;
  begin
    for i:=1 to length(s) do if (s[i]=' ')or(s[i]=',')then begin pos:=i; exit;end;
  end;
var s:string;
    l:integer;
begin
  while (ss[1]=' ')or(ss[1]=',') do ss:=copy(ss,2,length(ss)-1);
  l:=pos(ss);
  s:=copy(ss,1,l-1);
  ss:=copy(ss,l+1,length(ss)-l);
  getnextstr:=s;
end;

function norm(a,b,c:longint):longint;
begin
  if a>c then norm:=a else if b<c then norm:=b else norm:=c;
end;

function getfilename(n:string):string;
begin
  while pos('\',n)<>0 do
    n:=copy(n,pos('\',n)+1,length(n));
  if pos('.',n)=0 then getfilename:=n else getfilename:=copy(n,1,pos('.',n)-1);
end;

function fexist(name:string):boolean;
var
  s:searchrec;
  r:integer;
begin
   name:=upcase(name);
   findfirst(name,anyfile,s);
   fexist:=doserror=0;
//   if downcase(s.name)=downcase(name) then fexist:=true else fexist:=false;
end;

function min(a,b:longint):longint;
begin if a<b then min:=a else min:=b; end;

function max(a,b:longint):longint;
begin if a<b then max:=b else max:=a; end;

procedure restart; assembler;
asm
  mov ax,$f000
  push ax
  mov ax,$fff0
  push ax
  retf
end;

function  r(i:real):longint;
begin
  r:=round(i);
end;

function st(i:longint):string;
var s:string;
begin
  str(i,s);
  st:=s;
end;

function st0(i:longint; j:byte):string;
var s:string;
begin
  str(i,s);
  while length(s)<j do s:='0'+s;
  st0:=s;
end;

function vl(i:string):longint;
var s:longint;
    j:integer;
begin
  val(i,s,j);
  vl:=s;
end;

function vlr(i:string):extended;
var s:extended;
    j:integer;
begin
  val(i,s,j);
  vlr:=s;
end;

procedure hide_cursor;
var regs:registers;
begin
  with regs do
  begin
    ah:=1;
    ch:=$20;
    cl:=0;
    bh:=0;
    intr($10,regs);
  end;
end;

function upcase(c:string):string;
var i:integer;
begin
  upcase[0]:=c[0];
  for i:=1 to length(c) do
  case c[i] of
    ' '..'¯': upcase[i]:=chr(ord(c[i])-32);
    'à'..'ï': upcase[i]:=chr(ord(c[i])-32-32-16);
  else upcase[i]:=system.upcase(c[i])
  end;
end;

function downcase(c:string):string;
var i:integer;
begin
  downcase[0]:=c[0];
  for i:=1 to length(c) do
  case c[i] of
    '€'..'','A'..'Z': downcase[i]:=chr(ord(c[i])+32);
    ''..'Ÿ': downcase[i]:=chr(ord(c[i])+32+32+16);
  else downcase[i]:=c[i];
  end;
end;

end.
