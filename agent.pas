{$M $800,0,0 }
uses dos,crt;
const
  sign:string='Agent.exe is runing now';
var
  pkey:array[byte]of boolean;
  vec:procedure;
  f:text;
{$f+}
procedure keyb; interrupt;
var i,j:integer;
begin
  pkey[port[$60] mod $80]:=port[$60]<$80;
{  sound(100);
  delay(100);
  nosound;}
  inline ($9c);
  vec;
end;
{$f-}
begin
   assign(f,'agent.mem');
{$i-}   erase(f); {$i+}
   rewrite(f);
   writeln(f,seg(pkey));
   writeln(f,ofs(pkey));
   writeln(f,seg(sign));
   writeln(f,ofs(sign));
   close(f);

   GetIntVec($9,@Vec);
   SetIntVec($9,Addr(Keyb));
   keep(0);
end.