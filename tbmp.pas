{$mode objfpc}{$H+}
unit tbmp;

interface

const
  bpp = 1;
  maxdots = 1024*1024*bpp;

type
  xy = longint;
  color = byte;
  filename = string[32];
  tsign = array[1..2] of char;

  tbmpfmt = packed record
    Sign: tsign;
    Size: longint;
    Reserved1, Reserved2: word;
    fmtsize: longint;
    USize: longint;
    X, Y: longint;
    pages: word;
    Bits: word;
    Compression: longint;
    ImageSize: longint;
    XPPM, YPPM: longint;
    ClrUsed, ClrImportant: longint
  end;

  tarraycolor = array[0..maxdots] of color;
  tsprtag = (none, ibmp, ispr);
  ttarget = (left, right);

  tbmpobj = object
    tag: tsprtag;
    target: ttarget;
    name: filename;
    x, y, xl: longint;
    fmt: tbmpfmt;
    bmpsize: longint;
    bmp: ^tarraycolor;

    procedure setname(a: string);
    function getname: string;
    function equal(a: string; b: ttarget): boolean;

    procedure loadfile(a: string);
    procedure load8(var f: file);
    procedure load24(var f: file);

    function loadwad(s: string): boolean;

    procedure initdata(ax, ay: longint);
    procedure initdata8(ax, ay: longint);
    procedure donedata;
    procedure done;

    procedure save8(a: string);
  end;

const
  bmpsign: tsign = 'BM';
  fmtsize = sizeof(tbmpfmt);

var
  pal: array[0..256*4-1] of byte;
  error: integer;

implementation

uses api;

function getfilename_local(n: string): string;
begin
  while pos('/', n) <> 0 do
    n := copy(n, pos('/', n) + 1, length(n));
  if pos('.', n) = 0 then getfilename_local := n
  else getfilename_local := copy(n, 1, pos('.', n) - 1);
end;

procedure tbmpobj.setname(a: string);
begin
  name := getfilename_local(a);
end;

function tbmpobj.getname: string;
begin
  getname := name;
end;

function tbmpobj.equal(a: string; b: ttarget): boolean;
begin
  equal := (getfilename_local(a) = name) and (target = b);
end;

procedure tbmpobj.initdata(ax, ay: longint);
begin
  x := ax; y := ay;
  bmpsize := x * y * bpp;
  xl := x * bpp;
  getmem(bmp, bmpsize);
end;

procedure tbmpobj.initdata8(ax, ay: longint);
begin
  x := ax; y := ay;
  bmpsize := x * y;
  xl := x;
  getmem(bmp, bmpsize);
end;

procedure tbmpobj.donedata;
begin
  if bmpsize <> 0 then begin
    freemem(bmp, bmpsize);
    bmpsize := 0;
    bmp := nil; x := 0; y := 0;
    tag := none;
  end;
end;

procedure tbmpobj.done;
begin
  donedata;
  name := '';
end;

procedure tbmpobj.loadfile(a: string);
var
  f: file;
begin
  done;
  assign(f, a);
  {$i-} reset(f, 1); {$i+}
  if ioresult <> 0 then exit;
  blockread(f, fmt, fmtsize);
  if fmt.sign <> bmpsign then begin close(f); exit; end;
  x := fmt.x;
  y := fmt.y;
  initdata8(x, y);
  case fmt.bits of
    8: load8(f);
    24: load24(f);
    else begin donedata; close(f); exit; end;
  end;
  close(f);
  setname(a);
  tag := ibmp;
end;

procedure tbmpobj.load8(var f: file);
var
  p: array[0..256, 0..3] of byte;
  i, j, bpl_loc: longint;
  t: array[0..2048] of byte;
  null: longint;
begin
  seek(f, fmtsize);
  blockread(f, p, sizeof(p));
  seek(f, fmt.fmtsize);
  bpl_loc := fmt.imagesize div y - xl;
  for i := y - 1 downto 0 do begin
    blockread(f, t, xl);
    if bpl_loc <> 0 then blockread(f, null, bpl_loc);
    for j := 0 to x - 1 do
      bmp^[i * x + j] := t[j];
  end;
  tag := ibmp;
end;

procedure tbmpobj.load24(var f: file);
var
  i, j, bpl_loc, k: longint;
  null: longint;
  t: array[0..2048*3] of byte;
  r, g, b, best: byte;
  dist, bestdist: longint;
begin
  seek(f, fmt.fmtsize);
  bpl_loc := fmt.imagesize div y - x * 3;
  for i := y - 1 downto 0 do begin
    blockread(f, t, x * 3);
    if bpl_loc <> 0 then blockread(f, null, bpl_loc);
    for j := 0 to x - 1 do begin
      r := t[j * 3 + 2];
      g := t[j * 3 + 1];
      b := t[j * 3 + 0];
      best := 0; bestdist := MaxLongint;
      for k := 0 to 255 do begin
        dist := sqr(longint(pal[k*4+2]) - r) +
                sqr(longint(pal[k*4+1]) - g) +
                sqr(longint(pal[k*4+0]) - b);
        if dist < bestdist then begin bestdist := dist; best := k; end;
      end;
      bmp^[i * x + j] := best;
    end;
  end;
  tag := ibmp;
end;

function tbmpobj.loadwad(s: string): boolean;
begin
  loadwad := false;
end;

procedure tbmpobj.save8(a: string);
var
  x2, j, null: longint;
  f: file;
begin
  x2 := x;
  case x mod 4 of
    1: x2 := x2 + 3;
    2: x2 := x2 + 2;
    3: x2 := x2 + 1;
  end;
  fmt.Sign := 'BM';
  fmt.ImageSize := x2 * y;
  fmt.Size := sizeof(fmt) + 256 * 4 + fmt.imagesize;
  fmt.Reserved1 := 0; fmt.Reserved2 := 0;
  fmt.fmtsize := sizeof(fmt) + 256 * 4;
  fmt.USize := 40;
  fmt.X := x; fmt.Y := y;
  fmt.pages := 1; fmt.Bits := 8;
  fmt.Compression := 0;
  fmt.XPPM := 0; fmt.YPPM := 0;
  fmt.ClrUsed := 256; fmt.ClrImportant := 256;
  assign(f, a);
  rewrite(f, 1);
  blockwrite(f, fmt, sizeof(fmt));
  blockwrite(f, pal, 256 * 4);
  null := 0;
  for j := y - 1 downto 0 do begin
    blockwrite(f, bmp^[j * x], x);
    if x2 > x then blockwrite(f, null, x2 - x);
  end;
  close(f);
end;

end.