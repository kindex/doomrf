uses wads,api;
var w:twad;
procedure about;
begin
  writeln('Syntax: WADEDIT.EXE <Операция> FILE.WAD MASK [EXT]');
  writeln('MASK - Маска файла (PlayPal  *  *.*  Pl)');
  writeln('Ext  - Расширение (.bmp .pix)');
  writeln('Операции');
  writeln('A (Add)    - Добавить файлы Mask');
  writeln('E (Extract)- Извлечь файлы Mask1 с асширеием Ext');
  writeln('R (Remove) - Удалить файлы Mask');
  writeln('D (Dir)    - Показать все файлы');
  writeln('F (Find)   - Показать файлы Mask');
  halt;
end;
var op:string;
begin
  writeln('WAD Editor v0.1 Ivanov Andrey <-[■]-> IVA vision [24.12.2k]');
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
{  w.add('*.tmp');
  w.dir;
{  w.delete('wad');}
{  w.dir;}
{  w.extract('*','.pix');}
  w.close;
end.