{$n+}
{Warning: FPC doesn't work 100x (Don't use initvec)}
unit timer;
interface
const
  tps:longint=18; {Tiks per second (18.2)}
  besttps:longint=100;
  onesec=1;
type
   ttip=(none,average,time,frame);
   ttimer=object
      hod:longint;               {integer}
      fps:extended;              {frame/sec}
      tik,start,elapsed,ever:longint; {Tiks}
      tip:ttip;
      fullsec,sec,min,hour: longint; {Sec:min:hour}
      fpsstr:string[32];
      procedure init(a:ttip; b: integer);
      procedure clear;
      procedure move;
      procedure process;
      procedure gettime;
      procedure getfps;
   end;
var
  oldtimer: pointer;

procedure initvec; {NY = 200 Hz}
procedure donevec; {NY = 18.2 Hz}

implementation
uses crt,dos,ports,api;

procedure ttimer.gettime;
begin
  sec:=fullsec mod 60;
  min:=fullsec div 60 mod 60;
  hour:=fullsec div 3600;
end;
procedure ttimer.clear;
begin
  process;
  start:=tik;
  fullsec:=0;
  hod:=0;
end;
procedure ttimer.init(a:ttip; b:integer);
begin
  fps:=30;
  tip:=a; ever:=b;
  clear;
end;
procedure ttimer.move;
begin
  inc(hod);  process; gettime;
  case tip of
   average: getfps;
   time: if hod>=round(fps)*onesec then begin getfps; clear;end;
   frame:
   begin
     if hod>5 then getfps;
     if hod=ever then begin getfps; clear;end;
   end;
 end;
end;
procedure ttimer.process;
begin
  tik:=meml[seg0040:$6c];
  elapsed:=tik-start;
  if elapsed=0 then inc(elapsed); {div 0}
  fullsec:=elapsed div tps;
end;
procedure ttimer.getfps;
begin
  if elapsed<>0 then
    fps:=hod/(elapsed/tps)
  else
    fps:=-1;
  fpsstr:=st(round(fps))+'.'+st(round(fps*10)mod 10)+' fps';
end;

procedure mytimer; interrupt;
begin
  inc(meml[seg0040:$6c]);
end;
procedure initvec;
var
  usk:longint;
begin
  SetIntVec (8, @mytimer);
  tps:=besttps;
  usk:=round(tps/18.2);

  Port[$43] := $34;                             { Ускорили частоту }
  Port[$40] := ($10000 div usk) and $FF;        { таймера в        }
  Port[$40] := ($10000 div usk) shr 8;          { usk раз          }
end;
procedure donevec;
begin
  SetIntVec (8, OldTimer);
  Port[$43] := $34;                             { Вернули прежнюю частоту }
  Port[$40] := $00;                             { таймера -               }
  Port[$40] := $00;                             { 18.2 герц               }
end;
begin
  GetIntVec (8, OldTimer);
end.
