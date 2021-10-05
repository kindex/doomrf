uses wads,api,fpgraph,sprites;
//var w:twad;
Procedure loadpal(name:string);
var ff:file;
    i,c,max,t:integer;
begin
  assign(ff,name);
{$i-}  reset(ff,1); {$i+}
if ioresult<>0 then exit;
  seek(ff,54);
  blockread(ff,pal,256*4);
  close(ff);
end;
procedure about;
begin
  writeln('Syntax: WADEDIT.EXE <Операция> FILE.WAD MASK [PAL]');
  writeln('MASK - Маска файла (PlayPal  *  *.*  Pl)');
  writeln('Ext  - Расширение (.bmp .pix)');
  writeln('Операции');
  writeln('A (Add)    - Добавить файлы Mask');
  writeln('E (Extract)- Извлечь bmp''ешки Mask+.bmp (палитра - PAL)');
  writeln('R (Remove) - Удалить файлы Mask');
  writeln('D (Dir)    - Показать все файлы');
  writeln('F (Find)   - Показать файлы Mask');
  writeln('N (New)    - Создать wad-файл');
  halt;
end;
var op:string;
begin
  writeln('WAD Editor v0.1 Ivanov Andrey <-[■]-> IVA vision [24.12.2k]');
  writeln;
  if paramcount<2 then about;
//  nw.load(paramstr(2));

  aw.addwad(paramstr(2));

  op:=upcase(paramstr(1));
  case op[1] of
   'A':  aw.w[1].add(paramstr(3));
   'E':  begin
//     w.loadpal;
     loadpal(paramstr(4));
     aw.w[1].extract(paramstr(3),'.bmp');
   end;
   'R':  aw.w[1].delete(paramstr(3));
   'D':  aw.w[1].dir;
   'F':  aw.w[1].find(paramstr(3));
   'N':  aw.w[1].create(paramstr(2));
  end;
  aw.w[1].close;
end.
