unit mycrt;
interface
Function ReadKey : {output} Char;
Function KeyPressed : {output} Boolean;
Procedure Delay(ms : Word);

implementation
Function ReadKey : {output} Char; Assembler;
Asm
  mov ah, 00h
  int 16h
end; { ReadKeyChar. }

{ Function to indicate if a key is in the keyboard buffer. }
Function KeyPressed : {output} Boolean; Assembler;
Asm
  mov ah, 01h
  int 16h
  mov ax, 00h
  jz @1
  inc ax
  @1:
end; { KeyPressed. }
Procedure Delay(ms : Word); Assembler;
Asm {machine independent Delay Function}
  mov ax, 1000;
  mul ms;
  mov cx, dx;
  mov dx, ax;
  mov ah, $86;
  int $15;
end;

end.