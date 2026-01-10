{$mode objfpc}{$H+}
unit sdlgraph;

// SDL2-based graphics unit for doomrf2
// Replaces fpgraph.pp with SDL2 rendering
// Supports 256-color palettized graphics

interface

uses sdl2, sdl2_image, sysutils;

const
  // Screen constants
  SCREEN_WIDTH = 640;
  SCREEN_HEIGHT = 480;
  WINDOW_SCALE = 2;

  maximumx = 800;
  maximumy = 600;
  bpp = 1;  // Bytes per pixel (8-bit palettized)

type
  xy = longint;
  tpoint = record
    x, y: xy;
  end;
  color = byte;  // 8-bit palette index
  tfont8x8 = array[byte, 0..7] of byte;

var
  // Standard colors (palette indices, set after loadpal)
  white: color = 15;
  grey: color = 7;
  dark: color = 8;
  black: color = 0;
  red: color = 4;
  blue: color = 1;
  green: color = 2;
  yellow: color = 14;
  fon: color = 0;
  palLoaded: boolean = false;

  // Screen buffer
  scr: array[0..maximumy-1, 0..maximumx-1] of color;

  // Viewport variables
  min, max: tpoint;      // Drawing viewport
  d: tpoint;             // Drawing viewport size
  omin, omax: tpoint;    // Output viewport
  od: tpoint;            // Output viewport size

  // Screen dimensions
  mx, my: xy;
  bpl: xy;  // Bytes per line

  // Font data
  fonth: integer;
  font8x8: tfont8x8;
  font8x14: array[byte, 0..13] of byte;
  font8x16: array[byte, 0..15] of byte;
  font8x19: array[byte, 0..18] of byte;

  // Palette (BGRA format from BMP)
  pal: array[0..256*4-1] of byte;

// Graphics initialization
procedure setmode(const ax, ay: xy);
procedure closegraph;
function getmaxx: integer;
function getmaxy: integer;

// Screen output
procedure screen; overload;
procedure screen(n, k: integer); overload;
procedure screen(n: integer); overload;
procedure screenr;
procedure retrace;

// Drawing primitives
procedure clear; overload;
procedure clear(a: color); overload;
procedure bar(ax, ay, bx, by: xy; c: color);
procedure putpixel(const ax, ay: xy; c: color);
procedure line(x1, y1, x2, y2: xy; c: color);
procedure linex(x, y, y2: xy; c: color);
procedure liney(y, x, x2: xy; c: color);
procedure rectangle(x1, y1, x2, y2, c: integer);

// Viewport
procedure setviewport(ax, ay, bx, by: integer);
procedure setscreenport(ax, ay, bx, by: integer);
procedure fullscreen;
procedure screen_view;

// Color functions
function rgb(r, g, b: byte): longint;
function getcolor(r, g, b: longint): byte;
procedure dergb_16(l: longint; var r, g, b: byte);

// Palette
procedure loadpal(name: string);
procedure setpal;
procedure setpalbrightness(k: integer);
procedure loadpal2(name: string);

// Font/Text
procedure print(x, y: xy; c: color; s: string);
procedure setfont(h: integer);
procedure loadfont(a: string; h: integer);

// Sprite
procedure sprite(var a; x, y, l: xy);

// SDL2 specific
function GetSDLWindow: PSDL_Window;
function GetSDLRenderer: PSDL_Renderer;

implementation

var
  sdlWindow: PSDL_Window;
  sdlRenderer: PSDL_Renderer;
  sdlTexture: PSDL_Texture;
  sdlSurface8: PSDL_Surface;
  sdlPalette: PSDL_Palette;
  sdlInitialized: boolean = false;

function GetSDLWindow: PSDL_Window;
begin
  Result := sdlWindow;
end;

function GetSDLRenderer: PSDL_Renderer;
begin
  Result := sdlRenderer;
end;

function getmaxx: integer;
begin
  Result := mx - 1;
end;

function getmaxy: integer;
begin
  Result := my - 1;
end;

function getcolor(r, g, b: longint): byte;
var
  i, last: byte;
  minDist, curDist: longint;
begin
  minDist := MaxLongint;
  last := 0;
  for i := 0 to 255 do
  begin
    curDist := sqr(r - pal[i*4+2]) + sqr(g - pal[i*4+1]) + sqr(b - pal[i*4+0]);
    if curDist < minDist then
    begin
      minDist := curDist;
      last := i;
    end;
  end;
  Result := last;
end;

procedure UpdateSDLPalette;
var
  colors: array[0..255] of TSDL_Color;
  i: integer;
begin
  if sdlPalette = nil then Exit;

  for i := 0 to 255 do
  begin
    colors[i].r := pal[i*4+2];  // BMP is BGR
    colors[i].g := pal[i*4+1];
    colors[i].b := pal[i*4+0];
    colors[i].a := 255;
  end;

  SDL_SetPaletteColors(sdlPalette, @colors[0], 0, 256);
end;

procedure loadpal(name: string);
var
  ff: file;
begin
  Assign(ff, name);
  {$I-} Reset(ff, 1); {$I+}
  if IOResult <> 0 then Exit;

  Seek(ff, 54);  // Skip BMP header
  BlockRead(ff, pal, 256*4);
  Close(ff);
  palLoaded := true;

  // Update SDL palette
  UpdateSDLPalette;

  // Update standard colors
  white := getcolor(255, 255, 255);
  red := getcolor(255, 0, 0);
  green := getcolor(0, 255, 0);
  blue := getcolor(0, 0, 255);
  grey := getcolor(200, 200, 200);
  dark := getcolor(100, 100, 100);
  yellow := getcolor(255, 255, 0);
end;

procedure setpal;
begin
  UpdateSDLPalette;
end;

procedure setpalbrightness(k: integer);
var
  colors: array[0..255] of TSDL_Color;
  i: integer;
begin
  if sdlPalette = nil then Exit;
  for i := 0 to 255 do
  begin
    colors[i].r := pal[i*4+2] * k div 100;
    colors[i].g := pal[i*4+1] * k div 100;
    colors[i].b := pal[i*4+0] * k div 100;
    colors[i].a := 255;
  end;
  SDL_SetPaletteColors(sdlPalette, @colors[0], 0, 256);
end;

procedure loadpal2(name: string);
var
  ff: file;
begin
  Assign(ff, name);
  {$I-} Reset(ff, 1); {$I+}
  if IOResult <> 0 then Exit;

  Seek(ff, 54);
  BlockRead(ff, pal, 256*4);
  Close(ff);

  // Don't update SDL palette, just recalculate colors
  white := getcolor(255, 255, 255);
  red := getcolor(255, 0, 0);
  green := getcolor(0, 255, 0);
  blue := getcolor(0, 0, 255);
  grey := getcolor(200, 200, 200);
  dark := getcolor(100, 100, 100);
  yellow := getcolor(255, 255, 0);
end;

procedure setmode(const ax, ay: xy);
var
  windowWidth, windowHeight: integer;
begin
  mx := ax;
  my := ay;

  // Initialize SDL if needed
  if not sdlInitialized then
  begin
    if SDL_Init(SDL_INIT_VIDEO or SDL_INIT_TIMER or SDL_INIT_EVENTS) < 0 then
    begin
      WriteLn('SDL_Init failed: ', SDL_GetError);
      Halt(1);
    end;
    // Initialize SDL2_image for PNG support
    if IMG_Init(IMG_INIT_PNG) = 0 then
      WriteLn('IMG_Init warning: ', IMG_GetError);
    sdlInitialized := true;
  end;

  // Calculate window size
  windowWidth := ax * WINDOW_SCALE;
  windowHeight := ay * WINDOW_SCALE;

  // Create window
  sdlWindow := SDL_CreateWindow('DOOM 513',
    SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
    windowWidth, windowHeight,
    SDL_WINDOW_SHOWN or SDL_WINDOW_RESIZABLE);

  if sdlWindow = nil then
  begin
    WriteLn('SDL_CreateWindow failed: ', SDL_GetError);
    Halt(1);
  end;

  // Create renderer with vsync
  sdlRenderer := SDL_CreateRenderer(sdlWindow, -1,
    SDL_RENDERER_ACCELERATED or SDL_RENDERER_PRESENTVSYNC);

  if sdlRenderer = nil then
  begin
    WriteLn('SDL_CreateRenderer failed: ', SDL_GetError);
    Halt(1);
  end;

  // Set logical size for automatic scaling
  SDL_RenderSetLogicalSize(sdlRenderer, ax, ay);

  // Create 8-bit surface for palette support
  sdlSurface8 := SDL_CreateRGBSurface(0, ax, ay, 8, 0, 0, 0, 0);
  if sdlSurface8 = nil then
  begin
    WriteLn('SDL_CreateRGBSurface failed: ', SDL_GetError);
    Halt(1);
  end;

  // Create palette
  sdlPalette := SDL_AllocPalette(256);
  SDL_SetSurfacePalette(sdlSurface8, sdlPalette);

  // Create streaming texture for fast updates
  sdlTexture := SDL_CreateTexture(sdlRenderer,
    SDL_PIXELFORMAT_ARGB8888,
    SDL_TEXTUREACCESS_STREAMING,
    ax, ay);

  bpl := ax;
  fullscreen;
  clear;
  fon := black;
end;

procedure closegraph;
begin
  if sdlTexture <> nil then SDL_DestroyTexture(sdlTexture);
  if sdlPalette <> nil then SDL_FreePalette(sdlPalette);
  if sdlSurface8 <> nil then SDL_FreeSurface(sdlSurface8);
  if sdlRenderer <> nil then SDL_DestroyRenderer(sdlRenderer);
  if sdlWindow <> nil then SDL_DestroyWindow(sdlWindow);

  sdlTexture := nil;
  sdlPalette := nil;
  sdlSurface8 := nil;
  sdlRenderer := nil;
  sdlWindow := nil;

  mx := 0;
  my := 0;
  setviewport(0, 0, -1, -1);
end;

procedure screen;
var
  pixels: PUint32;
  pitch: integer;
  i, j: integer;
  c: byte;
begin
  if sdlTexture = nil then Exit;

  // Lock texture for direct pixel access
  SDL_LockTexture(sdlTexture, nil, @pixels, @pitch);

  // Convert 8-bit palettized to 32-bit ARGB
  for j := omin.y to omax.y do
    for i := omin.x to omax.x do
    begin
      c := scr[j, i];
      // ARGB format: Alpha=255, R, G, B
      pixels[j * (pitch div 4) + i] :=
        $FF000000 or
        (longword(pal[c*4+2]) shl 16) or  // R
        (longword(pal[c*4+1]) shl 8) or   // G
        longword(pal[c*4+0]);              // B
    end;

  SDL_UnlockTexture(sdlTexture);

  // Render
  SDL_RenderClear(sdlRenderer);
  SDL_RenderCopy(sdlRenderer, sdlTexture, nil, nil);
  SDL_RenderPresent(sdlRenderer);
end;

procedure screen(n, k: integer);
var
  pixels: PUint32;
  pitch: integer;
  i, j: integer;
  c: byte;
begin
  if sdlTexture = nil then Exit;

  SDL_LockTexture(sdlTexture, nil, @pixels, @pitch);

  // Interlaced rendering (every n-th line offset by k)
  for j := omin.y to omax.y do
    if (j + k) mod n = 0 then
      for i := omin.x to omax.x do
      begin
        c := scr[j, i];
        pixels[j * (pitch div 4) + i] :=
          $FF000000 or
          (longword(pal[c*4+2]) shl 16) or
          (longword(pal[c*4+1]) shl 8) or
          longword(pal[c*4+0]);
      end;

  SDL_UnlockTexture(sdlTexture);
  SDL_RenderClear(sdlRenderer);
  SDL_RenderCopy(sdlRenderer, sdlTexture, nil, nil);
  SDL_RenderPresent(sdlRenderer);
end;

procedure screen(n: integer);
var
  pixels: PUint32;
  pitch: integer;
  i, j, dx: integer;
  c: byte;
begin
  if sdlTexture = nil then Exit;

  SDL_LockTexture(sdlTexture, nil, @pixels, @pitch);

  // Wave effect
  for j := omin.y + 1 to omax.y - 1 do
  begin
    dx := Round(Cos((j + n) / 30) * 10);  // Reduced wave amplitude
    for i := omin.x to omax.x do
    begin
      c := scr[j, (i + dx + mx) mod mx];  // Wrap around
      pixels[j * (pitch div 4) + i] :=
        $FF000000 or
        (longword(pal[c*4+2]) shl 16) or
        (longword(pal[c*4+1]) shl 8) or
        longword(pal[c*4+0]);
    end;
  end;

  SDL_UnlockTexture(sdlTexture);
  SDL_RenderClear(sdlRenderer);
  SDL_RenderCopy(sdlRenderer, sdlTexture, nil, nil);
  SDL_RenderPresent(sdlRenderer);
end;

procedure screenr;
var
  pixels: PUint32;
  pitch: integer;
  i, j: integer;
  c: byte;
begin
  if sdlTexture = nil then Exit;

  SDL_LockTexture(sdlTexture, nil, @pixels, @pitch);

  // Reverse (upside down)
  for j := omin.y to omax.y do
    for i := omin.x to omax.x do
    begin
      c := scr[max.y - j, i];
      pixels[j * (pitch div 4) + i] :=
        $FF000000 or
        (longword(pal[c*4+2]) shl 16) or
        (longword(pal[c*4+1]) shl 8) or
        longword(pal[c*4+0]);
    end;

  SDL_UnlockTexture(sdlTexture);
  SDL_RenderClear(sdlRenderer);
  SDL_RenderCopy(sdlRenderer, sdlTexture, nil, nil);
  SDL_RenderPresent(sdlRenderer);
end;

procedure retrace;
begin
  // SDL2 with VSYNC handles this automatically
  // Just a small delay for compatibility
  SDL_Delay(1);
end;

procedure setviewport(ax, ay, bx, by: integer);
begin
  min.x := ax;
  min.y := ay;
  max.x := bx;
  max.y := by;
  d.x := bx - ax + 1;
  d.y := by - ay + 1;
end;

procedure setscreenport(ax, ay, bx, by: integer);
begin
  omin.x := ax;
  omin.y := ay;
  omax.x := bx;
  omax.y := by;
  od.x := bx - ax + 1;
  od.y := by - ay + 1;
end;

procedure fullscreen;
begin
  setviewport(0, 0, mx - 1, my - 1);
  setscreenport(0, 0, mx - 1, my - 1);
end;

procedure screen_view;
begin
  omin := min;
  omax := max;
  od := d;
end;

procedure clear;
begin
  bar(0, 0, mx - 1, my - 1, fon);
end;

procedure clear(a: color);
begin
  bar(0, 0, mx - 1, my - 1, a);
end;

procedure putpixel(const ax, ay: xy; c: color);
begin
  if (ax >= min.x) and (ax <= max.x) and (ay >= min.y) and (ay <= max.y) then
    scr[ay, ax] := c;
end;

procedure bar(ax, ay, bx, by: xy; c: color);
var
  i, w: xy;
begin
  if ax < min.x then ax := min.x;
  if ay < min.y then ay := min.y;
  if bx > max.x then bx := max.x;
  if by > max.y then by := max.y;

  if (ax > bx) or (ay > by) then Exit;

  w := bx - ax + 1;
  for i := ay to by do
    FillChar(scr[i, ax], w, c);
end;

procedure linex(x, y, y2: xy; c: color);
var
  i: integer;
begin
  if y2 > y then
    for i := y to y2 do putpixel(x, i, c)
  else
    for i := y2 to y do putpixel(x, i, c);
end;

procedure liney(y, x, x2: xy; c: color);
var
  t: integer;
begin
  if x2 < x then
  begin
    t := x;
    x := x2;
    x2 := t;
  end;
  bar(x, y, x2, y, c);
end;

procedure line(x1, y1, x2, y2: xy; c: color);
var
  a, b: real;
  z, i: integer;
begin
  // Early exit if completely outside viewport
  if ((x1 < min.x) and (x2 < min.x)) or
     ((x1 > max.x) and (x2 > max.x)) or
     ((y1 < min.y) and (y2 < min.y)) or
     ((y1 > max.y) and (y2 > max.y)) then Exit;

  // Swap if needed
  if (x2 < x1) and (y2 < y1) then
  begin
    z := x2; x2 := x1; x1 := z;
    z := y2; y2 := y1; y1 := z;
  end;

  // Vertical line
  if x1 = x2 then
  begin
    linex(x1, y1, y2, c);
    Exit;
  end;

  // Horizontal line
  if y1 = y2 then
  begin
    liney(y1, x1, x2, c);
    Exit;
  end;

  // Diagonal line
  if (x2 - x1 <> 0) and (y2 - y1 <> 0) then
  begin
    a := (x2 - x1) / (y2 - y1);
    b := (y2 - y1) / (x2 - x1);

    if (a > 1) or (a < -1) then
    begin
      if (x2 - x1) > 0 then
        for i := 0 to x2 - x1 do
          putpixel(i + x1, Round(i * b) + y1, c)
      else
        for i := 0 to Abs(x2 - x1) do
          putpixel(x1 - i, y1 - Round(i * b), c);
    end
    else
    begin
      if (y2 - y1) > 0 then
        for i := 0 to (y2 - y1) do
          putpixel(Round(i * a) + x1, i + y1, c)
      else
        for i := 0 to Abs(y2 - y1) do
          putpixel(x1 - Round(i * a), y1 - i, c);
    end;
  end;
end;

procedure rectangle(x1, y1, x2, y2, c: integer);
begin
  line(x1, y1, x2, y1, c);
  line(x1, y1, x1, y2, c);
  line(x2, y1, x2, y2, c);
  line(x1, y2, x2, y2, c);
end;

function rgb(r, g, b: byte): longint;
begin
  Result := getcolor(r, g, b);
end;

procedure dergb_16(l: longint; var r, g, b: byte);
begin
  // 16-bit color to RGB (5-6-5 format)
  b := (l and $1F) shl 3;
  g := ((l shr 5) and $3F) shl 2;
  r := ((l shr 11) and $1F) shl 3;
end;

procedure sprite(var a; x, y, l: xy);
var
  dd: xy;
  b: array[0..1024] of color absolute a;
begin
  if (y > max.y) or (y < min.y) or (x + l < min.x) or (x > max.x) then Exit;

  if x + l > max.x then l := max.x - x + 1;

  if x < min.x then
  begin
    dd := min.x - x;
    l := l - (min.x - x);
    x := min.x;
    Move(b[dd], scr[y, x], l);
  end
  else
    Move(a, scr[y, x], l);
end;

// Font rendering

procedure print8(x, y: xy; c: color; s: string);
var
  i, j, k: integer;
begin
  if (x + Length(s) * 8 >= min.x) and (y + fonth >= min.y) and
     (x <= max.x) and (y <= max.y) then
  begin
    for k := 1 to Length(s) do
      for i := 0 to fonth - 1 do
        for j := 0 to 7 do
          if Odd(font8x8[Ord(s[k]), i] shr j) then
            putpixel(x + (k - 1) * 8 + 7 - j, y + i, c);
  end;
end;

procedure print14(x, y: xy; c: color; s: string);
var
  i, j, k: integer;
begin
  if (x + Length(s) * 8 >= min.x) and (y + fonth >= min.y) and
     (x <= max.x) and (y <= max.y) then
  begin
    for k := 1 to Length(s) do
      for i := 0 to fonth - 1 do
        for j := 0 to 7 do
          if Odd(font8x14[Ord(s[k]), i] shr j) then
            putpixel(x + k * 8 + 7 - j, y + i, c);
  end;
end;

procedure print16(x, y: xy; c: color; s: string);
var
  i, j, k: integer;
begin
  if (x + Length(s) * 8 >= min.x) and (y + fonth >= min.y) and
     (x <= max.x) and (y <= max.y) then
  begin
    for k := 1 to Length(s) do
      for i := 0 to fonth - 1 do
        for j := 0 to 7 do
          if Odd(font8x16[Ord(s[k]), i] shr j) then
            putpixel(x + k * 8 + 7 - j, y + i, c);
  end;
end;

procedure print19(x, y: xy; c: color; s: string);
var
  i, j, k: integer;
begin
  if (x + Length(s) * 8 >= min.x) and (y + fonth >= min.y) and
     (x <= max.x) and (y <= max.y) then
  begin
    for k := 1 to Length(s) do
      for i := 0 to fonth - 1 do
        for j := 0 to 7 do
          if Odd(font8x19[Ord(s[k]), i] shr j) then
            putpixel(x + k * 8 + 7 - j, y + i, c);
  end;
end;

procedure print(x, y: xy; c: color; s: string);
begin
  case fonth of
    8: print8(x, y, c, s);
    14: print14(x, y, c, s);
    16: print16(x, y, c, s);
    19: print19(x, y, c, s);
    else print8(x, y, c, s);
  end;
end;

procedure setfont(h: integer);
begin
  fonth := h;
end;

procedure loadfont(a: string; h: integer);
var
  f: file;
  filename: string;
begin
  filename := a + '8x' + IntToStr(h) + '.fnt';
  {$I-}
  Assign(f, filename);
  Reset(f, 1);
  {$I+}
  if IOResult <> 0 then Exit;

  case h of
    8: BlockRead(f, font8x8, 256 * h);
    14: BlockRead(f, font8x14, 256 * h);
    16: BlockRead(f, font8x16, 256 * h);
    19: BlockRead(f, font8x19, 256 * h);
  end;

  Close(f);
  setfont(h);
end;

// Initialize default 8x8 font (simple ASCII)
procedure InitDefaultFont;
var
  i, j: integer;
begin
  // Initialize with zeros
  FillChar(font8x8, SizeOf(font8x8), 0);

  // Try to load from file if exists
  {$I-}
  loadfont('', 8);
  {$I+}

  setfont(8);
end;

initialization
  InitDefaultFont;

finalization
  if sdlInitialized then
  begin
    closegraph;
    SDL_Quit;
  end;

end.