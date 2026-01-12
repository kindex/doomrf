{$mode objfpc}{$H+}
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
function  UTF8ToCP866(const s: string): string;

implementation
function norm(a,b,c:longint):longint;
begin
  if a>c then norm:=a else if b<c then norm:=b else norm:=c;
end;
function getfilename(name:string):string;
begin
  while pos('/',name)<>0 do
    name:=copy(name,pos('/',name)+1,length(name));
  getfilename:=upcase(name)
end;
function fexist(name:string):boolean;
var
  f:file;
begin
  assign(f,name);
  {$i-} reset(f);{$i+}
  if ioresult=0 then fexist:=true else begin fexist:=false;exit;end;
  close(f);
end;
function min(a,b:longint):longint;
begin if a<b then min:=a else min:=b; end;
function minext(a,b:extended):extended;
begin if a<b then minext:=a else minext:=b; end;
function max(a,b:longint):longint;
begin if a<b then max:=b else max:=a; end;
function maxext(a,b:extended):extended;
begin if a<b then maxext:=b else maxext:=a; end;
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

function upcase(c:string):string;
var i:integer;
begin
  SetLength(upcase, length(c));
  for i:=1 to length(c) do
  if (c[i]>#96)and(c[i]<#123)then upcase[i]:=chr(ord(c[i])-32)
  else upcase[i]:=c[i]
end;

function downcase(c:string):string;
var i:integer;
begin
  downcase:=c;
  for i:=1 to length(c) do
  if (c[i]>#64)and(c[i]<#90)then
  downcase[i]:=chr(ord(c[i])+32);
end;

{ Convert UTF-8 string to CP866 for font rendering }
function UTF8ToCP866(const s: string): string;
var
  i, len: integer;
  b1, b2: byte;
  cp: word;
begin
  Result := '';
  i := 1;
  len := Length(s);
  while i <= len do
  begin
    b1 := Ord(s[i]);
    if b1 < 128 then
    begin
      { ASCII - copy as is }
      Result := Result + s[i];
      Inc(i);
    end
    else if (b1 and $E0) = $C0 then
    begin
      { 2-byte UTF-8 sequence }
      if i + 1 <= len then
      begin
        b2 := Ord(s[i + 1]);
        cp := ((b1 and $1F) shl 6) or (b2 and $3F);
        { Convert Unicode to CP866 }
        case cp of
          $0410..$041F: Result := Result + Chr(cp - $0410 + $80);  { А-П -> 128-143 }
          $0420..$042F: Result := Result + Chr(cp - $0420 + $90);  { Р-Я -> 144-159 }
          $0430..$043F: Result := Result + Chr(cp - $0430 + $A0);  { а-п -> 160-175 }
          $0440..$044F: Result := Result + Chr(cp - $0440 + $E0);  { р-я -> 224-239 }
          $0401: Result := Result + Chr($F0);  { Ё -> 240 }
          $0451: Result := Result + Chr($F1);  { ё -> 241 }
        else
          Result := Result + '?';  { Unknown char }
        end;
        Inc(i, 2);
      end
      else
        Inc(i);
    end
    else if (b1 and $F0) = $E0 then
    begin
      { 3-byte UTF-8 - skip }
      Inc(i, 3);
    end
    else if (b1 and $F8) = $F0 then
    begin
      { 4-byte UTF-8 - skip }
      Inc(i, 4);
    end
    else
      Inc(i);
  end;
end;

end.
Units: Wins -> Wins2 -> IVA -> API
