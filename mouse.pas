Unit Mouse;
(**********************************)Interface(*****************************)
Uses Dos;
Const
  MOUSEinT = $33; {mouse driver interrupt}
Type
  mouseType = (twoButton,threeButton,another);
  buttonState = (buttonDown,buttonUp);
Var
  mouse_present : Boolean;
  mouse_buttons : mouseType;
  eventX,eventY,eventButtons : Word; {any event handler should update}
  eventhappened : Boolean;           {these Vars to use getLastEvent }
  XMotions,YMotions : Word;          {per 8 pixels}
  mouseCursorLevel : Integer;
Procedure initMouse;
Procedure show;   Procedure hide;
Function  X:Word; Function  Y:Word;
function  push:boolean;function  push2:boolean;function  push3:boolean;
Function  down(Button : Byte) :boolean;
Function  buttonPressed : Boolean;
Procedure setMouseCursor(x,y : Word);
Function  LastXPress(Button:Byte):Word; Function LastYPress(Button : Byte) : Word;
Function  LastXRelease(Button:Byte):Word;Function  LastYRelease(Button : Byte) : Word;
Procedure mouseBox(left,top,right,bottom : Word); {limit mouse rectangle}
Procedure Sensetivity(x,y : Word);
(**************************)Implementation(********************************)
Const  mouseGraph:Boolean=False; {assume Text mode upon entry}
Var
  reg : Registers;  {general Registers used}
  grMode, grDrv : Integer; {detect Graphic mode if any}
  grCode : Integer;     {return initGraph code in here}
  interceptX,interceptY : Word;
Procedure callMouse;
begin
  intr(MOUSEinT,REG);
end;
Procedure initMouse;
begin
  With reg do
  begin
    ax:=0; {detect genius mouse}
    bx:=0; {be sure what mode we get}
    callMouse;
    mouse_present := (ax <> 0); {not an iret..}
    if ((bx and 2) <> 0) then  mouse_buttons := twoButton
    else if ((bx and 3) <> 0)  then
         mouse_buttons := threeButton
    else
         mouse_buttons := another; {unknown to us}
  end; {with}
  eventX := 0;
  eventButtons := 0;
  eventY := 0;
  eventhappened := False;
  XMotions := 8; YMotions := 16;
  mouseCursorLevel := 0; { not visiable, one show to appear }
end;
Procedure show;
begin
  reg.ax:=1; {enable cursor display}
  callMouse;
  inc(mouseCursorLevel);
end;
Procedure hide;
begin
  reg.ax:=2; {disable cursor display}
  callMouse;
  dec(mouseCursorLevel);
end;
Function X : Word;
begin
  reg.ax := 3;
  callMouse;
  X := reg.cx div 2;
end;
Function Y : Word;
begin
  reg.ax := 3;
  callMouse;
  Y := reg.dx;
end;
function push:boolean;
begin
  if down(1) then push:=true
  else push:=false;
end;
function push2:boolean;
begin
  if down(2) then push2:=true
  else push2:=false;
end;
function push3:boolean;
begin
  if down(4) then push3:=true
  else push3:=false;
end;
Function down(Button : Byte):boolean;
begin
  reg.ax := 3;
  callMouse;
  if ((reg.bx and Button) <> 0) then  down := true  else down := false
end;
Function buttonPressed : Boolean;
begin
  reg.ax := 3;
  callMouse;
  if ((reg.bx and 7) <> 0) then  buttonPressed := True
     else buttonPressed := False;
end;
Procedure setMouseCursor(x,y : Word);
begin
  With reg do begin
    ax := 4;
    cx := x;
    dx := y; {prepare parameters}
    callMouse;
  end; {with}
end;
Function lastXPress(Button : Byte) : Word;
begin
        reg.ax := 5;
        reg.bx := Button;
        callMouse;
        lastXPress := reg.cx;
end;
Function lastYPress(Button : Byte) : Word;
begin
        reg.ax := 5;
        reg.bx := Button;
        callMouse;
        lastYPress := reg.dx;
end;
Function lastXRelease(Button : Byte) : Word;
begin
        reg.ax := 6;
        reg.bx := Button;
        callMouse;
        lastXRelease := reg.cx;
end;
Function lastYRelease(Button : Byte) : Word;
begin
        reg.ax := 6;
        reg.bx := Button;
        callMouse;
        lastYRelease := reg.dx;
end;
Procedure swap(Var a,b : Word);
Var c : Word;
begin
  c := a;  a := b;    b := c;
end;
Procedure mouseBox(left,top,right,bottom : Word);
begin
  if (left > right) then swap(left,right);
  if (top > bottom) then swap(top,bottom); {make sure they are ordered}
  reg.ax := 7;
  reg.cx := left;
  reg.dx := right;
  callMouse;
  reg.ax := 8;
  reg.cx := top;
  reg.dx := bottom;
  callMouse;
end;
Procedure Sensetivity(x,y : Word);
begin
  reg.ax := 15;
  reg.cx := x; {# of mouse motions to horizontal 8 pixels}
  reg.dx := y; {# of mouse motions to vertical 8 pixels}
  callMouse;
  XMotions := x; YMotions := y; {update global Unit Variables}
end;
begin
   eventX:=0;   eventY:=0;
   eventHappened := False;
   initMouse;
end.