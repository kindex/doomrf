uses wads,api;
var w:twad;
procedure about;
begin
  writeln('Syntax: WADEDIT.EXE <������> FILE.WAD MASK [EXT]');
  writeln('MASK - ��᪠ 䠩�� (PlayPal  *  *.*  Pl)');
  writeln('Ext  - ����७�� (.bmp .pix)');
  writeln('����樨');
  writeln('A (Add)    - �������� 䠩�� Mask');
  writeln('E (Extract)- ������� 䠩�� Mask1 � ���२�� Ext');
  writeln('R (Remove) - ������� 䠩�� Mask');
  writeln('D (Dir)    - �������� �� 䠩��');
  writeln('F (Find)   - �������� 䠩�� Mask');
  halt;
end;
var op:string;
begin
  writeln('WAD Editor v0.1 Ivanov Andrey <-[�]-> IVA vision [24.12.2k]');
  writeln;
  if paramcount<3 then about;
  w.load(paramstr(2));
  op:=upcase(paramstr(1));
  case  op[1] of
   'A':  w.add(paramstr(3));
   'E':  w.extract(paramstr(3),paramstr(4));
   'R':  w.delete(paramstr(3));
   'D':  w.dir;
   'F':  w.find(paramstr(3));
  end;
{  w.create('12345.wad');}
{  w.add('*.tmp');}
{  w.dir;}
{  w.delete('wad');}
{  w.dir;}
{  w.extract('*','.pix');}
  w.close;
end.