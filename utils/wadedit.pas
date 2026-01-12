uses wads,api;
var w:twad;
procedure about;
begin
  writeln('Syntax: WADEDIT.EXE <опция> FILE.WAD MASK [EXT]');
  writeln('MASK - маска файла (PlayPal  *  *.*  Pl)');
  writeln('Ext  - расширение (.bmp .pix)');
  writeln('Опции');
  writeln('A (Add)    - добавить файлы Mask');
  writeln('E (Extract)- извлечь файлы Mask1 с расширением Ext');
  writeln('R (Remove) - удалить файлы Mask');
  writeln('D (Dir)    - показать все файлы');
  writeln('F (Find)   - показать файлы Mask');
  halt;
end;
var op:string;
begin
  writeln('WAD Editor v0.1 Ivanov Andrey <-[Ж]-> IVA vision [24.12.2k]');
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