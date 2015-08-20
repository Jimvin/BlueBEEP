unit keyunit;

interface
function keyfor(s:string):longint;

implementation

function keyfor(s:string):longint;
var x,y,z :longint;
    bla   :string;
begin
  if length(s)<4 then begin
    randomize;
    y:=random(65535)*random(255);
    keyfor:=y;
    exit;
  end;
  y:=0;
  for x:=1 to length(s) do y:=y+(ord(s[x])*length(s));
  for x:=1 to length(s) do y:=y+(ord(s[x])-(length(s)+x));
  for x:=1 to length(s) do y:=y+((ord(s[x])-20)*(length(s) div 2));
  y:=y*y;
  y:=y+(length(s)*length(s));
  keyfor:=y;
end;

begin
  if paramstr(1)='/(C)' then begin
    writeln('KEYUNIT.PAS  v1.00  Key Generation Routines');
    writeln('                    (C) 1993 by OD/SLAM');
    writeln;
    readln;
  end;
end.
