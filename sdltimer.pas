{$mode objfpc}{$H+}
unit sdltimer;

interface

uses sdl2;

const
  tps: longint = 100;    // Ticks per second (emulated)
  besttps: longint = 100;
  onesec = 1;
  tpr = 18.2;            // DOS timer frequency (for compatibility)

type
  ttip = (none, average, time, frame);
  ttimer = object
    hod: longint;                    // frame counter
    fps: extended;                   // frames per second
    tik, start, elapsed, ever: longint; // ticks
    tip: ttip;
    fullsec, sec, min, hour: longint; // time components
    fpsstr: string[32];
    procedure init(a: ttip; b: integer);
    procedure clear;
    procedure move;
    procedure process;
    procedure gettime;
    procedure getfps;
  end;

var
  startTicks: UInt32;

procedure initvec;  // No-op for SDL2
procedure donevec;  // No-op for SDL2
function st(a: longint): string;

implementation

uses sysutils;

function st(a: longint): string;
begin
  st := IntToStr(a);
end;

procedure initvec;
begin
  startTicks := SDL_GetTicks;
end;

procedure donevec;
begin
  // No-op - SDL2 doesn't need timer cleanup
end;

procedure ttimer.init(a: ttip; b: integer);
begin
  fps := 30;
  tip := a;
  ever := b;
  clear;
end;

procedure ttimer.clear;
begin
  process;
  start := tik;
  fullsec := 0;
  hod := 0;
end;

procedure ttimer.process;
begin
  // Convert SDL milliseconds to emulated ticks (100 Hz)
  tik := (SDL_GetTicks * tps) div 1000;
  elapsed := tik - start;
  if elapsed = 0 then Inc(elapsed); // avoid div by 0
  fullsec := elapsed div tps;
end;

procedure ttimer.move;
begin
  Inc(hod);
  process;
  gettime;
  case tip of
    average: getfps;
    time: if hod >= round(fps) * onesec then begin getfps; clear; end;
    frame:
    begin
      if hod > 5 then getfps;
      if hod = ever then begin getfps; clear; end;
    end;
  end;
end;

procedure ttimer.gettime;
begin
  sec := fullsec mod 60;
  min := fullsec div 60 mod 60;
  hour := fullsec div 3600;
end;

procedure ttimer.getfps;
begin
  if elapsed <> 0 then
    fps := hod / (elapsed / tps)
  else
    fps := -1;
  fpsstr := st(round(fps)) + '.' + st(round(fps * 10) mod 10) + ' fps';
end;

initialization
  startTicks := SDL_GetTicks;

end.