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

procedure makecrc(a:string);
var
  c: longint;
  f:text;
begin
  write('Loading ',a,'...');
  c:=crc(a);
  a[length(a)-0]:='C';
  a[length(a)-1]:='R';
  a[length(a)-2]:='C';
  assign(f,a);
  rewrite(f);
  writeln(f,c);
  close(f);
  writeln('Done');
end;

var
  i: integer;
begin
  writeln('myCRC maker (C) DiVision 2002');
  for i:=1 to paramcount do makecrc(paramstr(i));
end.
