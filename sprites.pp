Unit Sprites; { $define high} {$define ignorecase}
interface
uses fpgraph;
const
  maxdots=1024*1024*bpp;
  maxpat=2048;
  dbmp:string='BMP\';
  dotbmp:string[4]='.bmp';
type
  tnpat=0..maxpat;
  filename=string[32];
  tsign=array[1..2]of char;
  tbmpfmt=record
     Sign:tsign;  // BM
     Size  : longint;   {X*Y+FMT+PAL}
     Reserved1,Reserved2 : word;
     fmtsize     : longint;   {FMT+PAL}
     USize       : longint;   {40 ?}
     X,Y         : longint;
     pages      : word; {1}
     Bits    : word; {8/24}
     Compression   : longint;{0}
     ImageSize     : longint;{x(mod 4=0)*y}
     XPPM,YPPM : longint; {-}
     ClrUsed, ClrImportant  : longint  {-}
  end;
  tarraycolor=array[0..maxdots]of color;
  tsprtag=(none,ibmp,ispr);
  ttarget=(left, right);
  tbmp=object
    tag: tsprtag;
    target: ttarget;
    name: filename;// Only name (no path, no extention)
    x,y,xl:longint;
    fmt:tbmpfmt;
    bmpsize: longint;
    bmp: ^tarraycolor;
    procedure setname(a:string);
    function getname:string;
    function equal(a:string; b: ttarget):boolean; // filename(a)=name [IgnoreCase]

    procedure load(a:string);
    procedure loadfile(a:string);
    procedure load8(var f:file);
    procedure load16(var f:file); // Not tested
    procedure load24(var f:file);

    function loadwad(s:string):boolean;

    procedure initdata(ax,ay:longint);
    procedure initdata8(ax,ay:longint);
    procedure donedata;
    procedure done;

    procedure put(ax,ay:xy);      // Ignore black dots
    procedure putsprite(ax,ay:xy);// Put only dots<>black //Wery slow -> use tSpr

    procedure save8(a:string);
    procedure reverse;
  end;
  sprtable=array[0..maxdots]of word; // XYLCCCCXYLCCC...
  { по 2 байта /    L    \
    X1 Y1 L1 : CC CC CC CC
    X2 Y2 L2 : CC CC CC ...
  }
  tspr=object(tbmp) {$ifndef high}
//    tSpr support only 16bit color and lines less than maxword
    {$endif}
    sprsize,spritems,sprlines: longint;
    spr: ^sprtable;
    procedure load(a:string);
    procedure loadbmp(a:string); // Load as BMP
    procedure donedata;
    procedure done;

    procedure convert2spr;

    procedure put(ax,ay:xy);
    procedure sprite(ax,ay:xy);
    procedure spritec(ax,ay:longint);
    procedure spritesp(ax,ay:longint);
    procedure spriteo(ax,ay:xy; c: color);

    function loadr(a:string):boolean;
  end;
const
  bmpsign:tsign='BM';
  fmtsize=sizeof(tbmpfmt);
var
  temp: sprtable;// For tspr.convert2spr
  error: integer;// =0 - All Ok; =1 - Error
  p:array[tnpat]of tSpr;  // Bitmaps, Srites
  noImage,noindex: tnpat; // For errors
  diskload: boolean;
  outc: integer;

//function loadimage(a:string):image;
function loadasbmp(a:string):tnpat;
function loadbmp(a:string):tnpat;
function loadbmpr(a:string):tnpat;


implementation
uses api,wads;

procedure out(a:char);
begin
  if outc mod 10=0 then write(a);
  inc(outc);
end;

procedure swapb(var a,b:color);
var t:color;
begin
  t:=a; a:=b; b:=t;
end;

procedure tbmp.reverse;
var i,j:longint;
begin
  for j:=0 to y-1 do
   for i:=0 to x div 2-1 do
     swapb(bmp^[i+j*x],bmp^[(x-i-1)+j*x]);
  target:=right;
end;


function tbmp.loadwad(s:string):boolean;
var
  dx,dy,i,j:longint;
  t:array[0..1024*2{Or more- max x}] of byte;
begin
  if x>0 then done;

  name:=s;
  w.assign(name);
  w.read(x,2); w.read(y,2);
  w.read(dx,2); w.read(dy,2);

  {$ifndef high}
  initdata8(x,y);
  if (w.cur.l=longint(x)*longint(y)+8) then
  begin
    w.read(bmp^,x*y);
    loadwad:=true;
    tag:=ibmp;
  end
  else begin x:=0; y:=0; loadwad:=false; end;
  error:=0;
  {$else high}
  initdata(x,y);
  if (w.cur.l=longint(x)*longint(y)+8) then
  begin
    for i:=0 to y-1 do begin
      w.read(t,x);
      for j:=0 to x-1 do
        bmp^[i*x+j]:=rgb(pal[t[j]*4+2],pal[t[j]*4+1],pal[t[j]*4+0]);
    end;
    loadwad:=true;
    tag:=ibmp;
  end
  else begin x:=0; y:=0; loadwad:=false; end;
  error:=0;
  {$endif}

end;

function loadbmp(a:string):tnpat;
var
  i: longint;
begin
  error:=0;
  a:=dbmp+a; // BMP\<a>.bmp
  for i:=0 to maxpat do
   if (p[i].x>0)and(p[i].equal(a,left)) then begin
     loadbmp:=i; exit; // Image was loaded in past - All OK
   end;
  for i:=0 to maxpat do
   if p[i].tag=none then begin
     p[i].load(a+'.bmp'); // Loading...
     if p[i].tag=none then
       loadbmp:=noImage // Image not found
     else loadbmp:=i; // All OK
     exit;
   end;
  error:=1;
  loadbmp:=noImage; // No free index for image
end;
function loadbmpr(a:string):tnpat;
var
  i:tnpat;
begin
   error:=0;
  a:=dbmp+a; // BMP\<a>.bmp
  for i:=0 to high(i) do
   if p[i].equal(a,right) then begin
     loadbmpr:=i; exit; // Image was loaded in past - All OK
   end;
  for i:=0 to maxpat do
   if p[i].tag=none then begin
     p[i].loadr(a+'.bmp'); // Loading...
     if p[i].tag=none then loadbmpr:=noImage // Image not found
     else loadbmpr:=i; // All OK
     exit;
   end;
  error:=1;
  loadbmpr:=noIndex; // No free index for image
end;

function loadasbmp(a:string):tnpat;
var
  i:tnpat;
begin
  error:=0;
  a:=dbmp+a; // BMP\<a>.bmp
  for i:=0 to maxpat do
   if p[i].equal(a,left) then begin
     loadasbmp:=i; exit; // Image was loaded in past - All OK
   end;
  for i:=0 to maxpat do
   if p[i].tag=none then begin
     p[i].loadbmp(a+'.bmp'); // Loading...
     if p[i].tag=none then loadasbmp:=noImage // Image not found
     else loadasbmp:=i; // All OK
     exit;
   end;
  error:=1;
  loadasbmp:=noIndex; // No free index for image
end;

procedure doneimages; // Free Mem Bug
var
  i:integer;
begin
  for i:=0 to high(i) do
    if p[i].tag<>none then
     p[i].done;
end;

function getfilename(n:string):string;
begin
  {$ifdef ignorecase} n:=downcase(n); {$endif}
  while pos('\',n)<>0 do
    n:=copy(n,pos('\',n)+1,length(n));
  if pos('.',n)=0 then getfilename:=n else getfilename:=copy(n,1,pos('.',n)-1);
end;

procedure tbmp.load(a:string);
begin
  if diskload and fexist(a) then
  begin
{    load:=}tbmp.loadfile(a);
    if x<>0 then
    begin
{      convert2spr;}
      out(':');
    end;
  end;
  if x=0 then
  if w.exist(a) then
  begin
{    load:=}tbmp.loadwad(getfilename(a));
    if x<>0 then
     begin
//       convert2spr;
       out('.');
     end;
  end;
  target:=left;
  if x=0 then error:=1 else error:=0;//if x=0 then load:=false;
end;

procedure tbmp.loadfile(a:string);
var
  f:file;
begin
  done;
  assign(f,a{+dotbmp});
{$i-}  reset(f,1);{$i+}
  if ioresult<>0 then begin
    error:=1;
    exit;
  end;
  blockread(f,fmt,fmtsize);
  if fmt.sign<>bmpsign then begin error:=1; exit; end;
  x:=fmt.x;
  y:=fmt.y;
  initdata(x,y);
  case fmt.bits of
   8: load8(f);
   16: load16(f);
   24: load24(f);
   else begin donedata; error:=1; exit; end;
  end;
  close(f);
  error:=0;
  setname(a);
//  out(':');
end;
procedure tbmp.load8(var f:file);
var
  p:array[0..256,0..3]of byte;
  i,j,bpl:longint;
  t:array[0..1024*2{Or more- max x}] of byte;
begin
  seek(f,fmtsize); // 54
  blockread(f,p,sizeof(p));
  seek(f,fmt.fmtsize); //54+1024
  bpl:=fmt.imagesize div y;
  for i:=y-1 downto 0 do begin
    blockread(f,t,bpl);
    for j:=0 to x-1 do
    {$ifdef high}
      bmp^[i*x+j]:=rgb(p[t[j],2],p[t[j],1],p[t[j],0]);
    {$else high}
      bmp^[i*x+j]:=t[j]{rgb(p[t[j],2],p[t[j],1],p[t[j],0])};
    {$endif}
  end;
  tag:=ibmp;
end;
procedure tbmp.load16(var f:file);
var
  i,j,bpl: longint;
  null: longint;
begin
  seek(f,fmt.fmtsize);
  bpl:=fmt.imagesize div y-xl;
  for i:=y-1 downto 0 do begin
    blockread(f,bmp^[i*x],xl);
    if bpl<>0 then blockread(f,null,bpl);
  end;
  tag:=ibmp;
end;
procedure tbmp.load24(var f:file);
var
  i,j,bpl,r,g,b: longint;
  null: longint;
  t:array[0..1024*2*3{Or more- max x}] of byte;
begin
  seek(f,fmt.fmtsize);
  bpl:=fmt.imagesize div y-x*3; // Остаток
  for i:=y-1 downto 0 do begin
    blockread(f,t,x*3);
    if bpl<>0 then blockread(f,null,bpl);
    for j:=0 to x-1 do begin
    {$ifdef high}
      bmp^[i*x+j]:=rgb(t[j*3+2],t[j*3+1],t[j*3+0]);
    {$else high}
      r:=t[j*3+2];
      g:=t[j*3+1];
      b:=t[j*3+0];
      bmp^[i*x+j]:=getcolor(r,g,b);
    {$endif}
    end;
  end;
  tag:=ibmp;
end;
procedure tbmp.initdata(ax,ay:longint);
begin
  bmpsize:=x*y*bpp;
  xl:=x*bpp;
  getmem(bmp,bmpsize);
end;
procedure tbmp.initdata8(ax,ay:longint);
begin
  bmpsize:=x*y;
  xl:=x;
  getmem(bmp,bmpsize);
end;
procedure tbmp.donedata;
begin
  if bmpsize<>0 then begin
    freemem(bmp,bmpsize);
    bmpsize:=0;
    bmp:=nil; x:=0; y:=0;
    tag:=none;
  end;
end;
procedure tbmp.put(ax,ay:xy);
var
  i:xy;
begin
  if tag=iBmp then
  for i:=0 to y-1 do
    sprite(bmp^[i*x],ax,ay+i,x);
end;
procedure tbmp.putsprite(ax,ay:xy);
var
  i,j:xy;
  c:color;
begin
  if tag=iBmp then
  for i:=0 to y-1 do
    for j:=0 to x-1 do begin
      c:=bmp^[i*x+j];
      if c<>black then putpixel(ax+j,ay+i,c);
   end;
end;

procedure tspr.load(a:string);
begin
  error:=0;
  done;
  tbmp.load(a);
  if error=0 then convert2spr;
  if error=0 then setname(a);
end;

procedure tspr.loadbmp(a:string);
begin
  error:=0;
  done;
  tbmp.load(a);
//  if error=0 then convert2spr;
  if error=0 then setname(a);
end;

function tspr.loadr(a:string):boolean;
begin
  error:=0;
  done;
  tbmp.load(a);
  if error=0 then reverse;
  if error=0 then convert2spr;
  if error=0 then setname(a);
  loadr:=error=0;
end;
procedure tspr.convert2spr;
// sizeof(spr)<=2*sizeof(data)
var
  fon: color;
  i,j,sx,ex,l,s,ss,sprmem: longint;
begin
  if tag=ibmp then begin // only bmp -> spr // data^[x,y] -> sprtable
   fon:=black;
   ss:=0; s:=0;
   for j:=0 to y-1 do begin
     i:=0;
     repeat
       while (i<x)and(bmp^[j*x+i]=fon) do inc(i);
       if i=x then break; // Full Line=fon// Only one exit from cycle
       sx:=i; // Start of string
       while (i<x)and(bmp^[j*x+i]<>fon) do inc(i);
       ex:=i-1; // End of sptring
       l:=ex-sx+1;// Length

       temp[ss+0]:=sx; // X
       temp[ss+1]:=j;  // Y
       temp[ss+2]:=l;  // Length
       move(bmp^[j*x+sx],temp[ss+3],l*bpp); // Line
       {$ifndef high}
       l:=l + l mod 2;
       l:=l div 2;
       {$endif}
//       inc(sprmem,6+l*bpp);
       inc(s);
       inc(ss,l+3);
     until false;
   end;
   spritems:=ss;
   sprlines:=s;
   sprsize:=spritems*2{bpp};
   getmem(spr,sprsize);
   move(temp,spr^,sprsize);
   tag:=ispr;
  end;
  if tag<>ispr then error:=1;
end;

procedure tspr.spritec(ax,ay:longint);
begin
  sprite(ax-x div 2,ay-y div 2);
end;

procedure tspr.spritesp(ax,ay:longint);
begin
  sprite(ax-x div 2,ay-y);
end;

procedure tspr.sprite(ax,ay:xy);
var
  i,ss,sx,sy,l: longint;
begin
  if tag=ibmp then begin tbmp.put(ax,ay); exit; end;
  ss:=0;
  for i:=1 to sprlines do begin
    sx:=spr^[ss+0];
    sy:=spr^[ss+1];
//    if sy+ay>max.y then break;
     l:=spr^[ss+2];
     fpgraph.sprite(spr^[ss+3],ax+sx,ay+sy,l);
     {$ifndef high}
     l:=l + l mod 2;
     l:=l div 2;
     {$endif}
     inc(ss,l+3);
  end;
end;

procedure tspr.spriteo(ax,ay:xy; c:color);
var
  i,ss,sx,sy,l: longint;
begin
  if c=0 then begin spritesp(ax,ay); exit; end;
  ax:=ax-x div 2; ay:=ay-y;
  ss:=0;
  for i:=1 to sprlines do begin
    sx:=spr^[ss+0];
    sy:=spr^[ss+1];
//    if sy+ay>max.y then break;
     l:=spr^[ss+2];
     putpixel(ax+sx-1,ay+sy,c);
     fpgraph.sprite(spr^[ss+3],ax+sx,ay+sy,l);
     putpixel(ax+sx+l,ay+sy,c);
     {$ifndef high}
     l:=l + l*bpp mod 2;
     l:=l div 2;
     {$endif}
     inc(ss,l+3);
  end;
end;
procedure tSpr.put(ax,ay:xy);
begin
 case tag of
  iBmp: tBmp.put(ax,ay);
  iSpr: sprite(ax,ay);
 end;
end;


procedure tBmp.done;
begin
  donedata;
  name:='';
end;
procedure tSpr.done;
begin
  case tag of
  iSpr: tspr.donedata;
  iBmp: tBmp.donedata;
  end;
  name:='';
end;
procedure tSpr.donedata;
begin
  freemem(spr,sprsize);
  sprsize:=0;
  spritems:=0;
  sprlines:=0;
  x:=0; y:=0;
  tag:=none;
end;
procedure tbmp.setname(a:string);
begin
  name:=getfilename(a);
end;
function tbmp.getname:string;
begin
  getname:=name;
end;
function tbmp.equal(a:string; b: ttarget):boolean; // filename(a)=name
begin
  equal:=(getfilename(a)=name)and(target=b);
end;
procedure tbmp.save8(a:string);
var
  x2,i,j,null: longint;
  f:file;
begin
  x2:=x; case x mod 4 of
    1: x2:=x2+3;
    2: x2:=x2+2;
    3: x2:=x2+1;
  end;
  fmt.Sign:='BM';
  fmt.ImageSize:=x2*y;
  fmt.Size:= sizeof(fmt)+256*4+fmt.imagesize;
  fmt.Reserved1:=0 ;fmt.Reserved2:=0;
  fmt.fmtsize:=sizeof(fmt)+256*4;   {FMT+PAL}
  fmt.USize:=40;   {40 ?}
  fmt.X:=x;
  fmt.Y:=y;
  fmt.pages:=1; {1}
  fmt.Bits:=8; {8/24}
  fmt.Compression:=0;{0}
  fmt.XPPM:=fmt.YPPM; {-}
  fmt.ClrUsed:=256; fmt.ClrImportant:=256;

  assign(f,a);
  rewrite(f,1);
  blockwrite(f,fmt,sizeof(fmt));
  blockwrite(f,pal,256*4);
  for j:=y-1 downto 0 do begin
    blockwrite(f,bmp^[j*x],x);
    if x2>x then blockwrite(f,null,x2-x);
  end;
  close(f);
end;
begin
  noImage:=0; NoIndex:=0;
  fillchar(p,sizeof(p),0);
  outc:=0;
  diskload:=false;
end.
