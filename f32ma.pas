Unit F32MA; (* Fast 32-bit Memory Access Library Version 1.0.              *)
 (* Copyright (c) 1999, Maxim Radugin aka Kilowatt. All rights reserved.   *)

 {$G+}
Interface

  Procedure Move32(Var Source; SourceOffset : Word; Var Dest; DestOffset, Count : Word);
  Procedure FillChar32(Var Source; SourceOffset, Count : Word; Value : Byte);

Implementation

  Procedure Move32(Var Source; SourceOffset : Word; Var Dest; DestOffset, Count : Word); Assembler;
    Asm
      PUSH    DS                                   (* Save DS register data on stack                       *)
      LDS     SI, Source                           (* DS:SI - points to Source                             *)
      ADD     SI, SourceOffset                     (* Seek to specified position in Source                 *)
      LES     DI, Dest                             (* ES:DI - points to Dest                               *)
      ADD     DI, DestOffset                       (* Seek to specified position in Dest                   *)
      MOV     CX, Count                            (* CX = Count (Number of bytes to copy)                 *)
      MOV     AX, CX                               (* AX = CX                                              *)
      CLD                                          (* Clear Direction Flag                                 *)
      SHR     CX, 02h                              (* CX = CX div 4 (Number of double words to copy)       *)
      DB      66h
      REP     MOVSW                                (* Copy double words                                    *)
      MOV     CL, AL                               (* CL = AL (Number of bytes to copy)                    *)
      AND     CL, 03h                              (* CL = CL and 3                                        *)
      REP     MOVSB                                (* Copy bytes                                           *)
      POP     DS                                   (* Restore DS register data from stack                  *)
    End;

  Procedure FillChar32(Var Source; SourceOffset, Count : Word; Value : Byte); Assembler;
    Asm
      LES     DI, Source                           (* ES:DI - points to Source                             *)
      ADD     DI, SourceOffset                     (* Seek to specified position in Source                 *)
      MOV     CX, Count                            (* CX = Count (Number of bytes to fill)                 *)
      SHR     CX, 01h                              (* CX = CX div 2 (Number of words to fill)              *)
      MOV     AL, Value                            (* AL = Value                                           *)
      MOV     AH, AL                               (* AH = AL                                              *)
      REP     STOSW                                (* Fill words                                           *)
      TEST    Count, 01h                           (* Check if CX mod 2 = 0                                *)
      JZ      @Done                                (* If CX mod 2 = 0 then goto @Done                      *)
      STOSB                                        (* Copy byte                                            *)
     @Done:
    End;

End.