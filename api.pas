{$n+}
unit api;
interface
const
  pi2=pi*2;
  pi05=pi*0.5;
function  downcase(c:string):string;
function  upcase(c:string):string;
function  st(i:longint):string;
function  st0(i:longint; j:byte):string;
function  vl(i:string):longint;
function  vlr(i:string):extended;
function  r(i:extended):longint;
function  min(a,b:longint):longint;
function  minext(a,b:extended):extended;
function  max(a,b:longint):longint;
function  maxext(a,b:extended):extended;
function  fexist(name:string):boolean;
function  getfilename(name:string):string;
function  norm(a,b,c:longint):longint;
procedure restart;

implementation
uses dos;
function norm(a,b,c:longint):longint;
begin
  if a>c then norm:=a else if b<c then norm:=b else norm:=c;
end;
function getfilename(name:string):string;
begin
  while pos('\',name)<>0 do
    name:=copy(name,pos('\',name)+1,length(name));
  getfilename:=upcase(name)
end;
function fexist(name:string):boolean;
var
  f:file;
  s:searchrec;
begin
{  name:=upcase(name);
  findfirst(name,anyfile,s);
  if s.name=name then fexist:=true else fexist:=false;
  writeln(s.name);}
  assign(f,name);
  {$i-} reset(f);{$i+}
  if ioresult=0 then fexist:=true else begin fexist:=false;exit;end;
  close(f);
end;
function min(a,b:longint):longint;
begin if a<b then min:=a else min:=b; end;
function minext;
begin if a<b then minext:=a else minext:=b; end;
function max(a,b:longint):longint;
begin if a<b then max:=b else max:=a; end;
function maxext;
begin if a<b then maxext:=b else maxext:=a; end;
procedure restart; assembler;
asm
  mov ax,$f000
  push ax
  mov ax,$fff0
  push ax
  retf
end;

function r(i:extended):longint;
begin
  if (i<maxlongint)and(i>-maxlongint)then
  r:=round(i) else i:=0;
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
function vl;
var s:longint;
    j:integer;
begin
  val(i,s,j);
  vl:=s;
end;
function vlr;
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

function upcase;
var i:integer;
begin
  upcase[0]:=c[0];
  for i:=1 to length(c) do
  if (c[i]>#96)and(c[i]<#123)then upcase[i]:=chr(ord(c[i])-32)
  else upcase[i]:=c[i]
end;

function downcase;
var i:integer;
begin
  downcase[0]:=c[0];
  downcase:=c;
  for i:=1 to length(c) do
  if (c[i]>#64)and(c[i]<#90)then
  downcase[i]:=chr(ord(c[i])+32);
end;

end.
Units: Wins -> Wins2 -> IVA -> API