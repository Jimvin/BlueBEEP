unit menus;
interface
uses windows,crt;
var menuitem  :array[1..23] of string[80];
    menucount :integer;
function menu(lux,luy,def:integer):integer;
function nbmenu(lux,luy,def:integer):integer;
implementation


procedure vmemwrite(x,y:integer;str:string;color:byte);
var i:word;
begin
  for i:=1 to length(str) do mem[$B800:2*((y-1)*80+(x-1)+i)]:=ord(str[i]);
  for i:=1 to length(str) do mem[$B800:2*((y-1)*80+(x-1)+i)+1]:=color;
end;

function menu(lux,luy,def:integer):integer;
var x,wide,pos,lastpos :byte;
    ch                 :char;
begin
  lux:=lux+1;
  luy:=luy+1;
  wide:=0;
  for x:=1 to menucount do
    if length(menuitem[x])>wide then wide:=length(menuitem[x]);
  for x:=1 to menucount do
    vmemwrite(lux+2,luy+x,menuitem[x],blue*16+yellow);
  lastpos:=def;
  pos:=def;
  repeat
    vmemwrite(lux+1,luy+lastpos,' '+menuitem[lastpos],blue*16+yellow);
    for x:=lux+2+length(menuitem[lastpos]) to lux+wide+2 do
      vmemwrite(x,luy+lastpos,' ',blue*16+yellow);
    vmemwrite(lux+1,luy+pos,' '+menuitem[pos],yellow);
    for x:=lux+2+length(menuitem[pos]) to lux+wide+2 do
      vmemwrite(x,luy+pos,' ',yellow);
    lastpos:=pos;
    repeat ch:=readkey until ch in [#0,#13,#27];
    if not(ch in [#13,#27]) then ch:=readkey;
    case ch of
      'H':if pos>1 then dec(pos) else pos:=menucount;
      'P':if pos<menucount then inc(pos) else pos:=1;
      'I':pos:=1;
      'Q':pos:=menucount;
      'G':pos:=1;
      'O':pos:=menucount;
    end;
  until ch in [#27,#13];
  menu:=pos;
  if ch=#27 then menu:=0;
end;

function nbmenu(lux,luy,def:integer):integer;
var x,wide,pos,lastpos :byte;
    ch                 :char;
begin
  luy:=luy+1;
  lux:=lux+1;
  wide:=0;
  for x:=1 to menucount do
    if length(menuitem[x])>wide then wide:=length(menuitem[x]);
  for x:=1 to menucount do
    vmemwrite(lux+2,luy+x,menuitem[x],cyan);
  lastpos:=def;
  pos:=def;
  repeat
    vmemwrite(lux+1,luy+lastpos,' '+menuitem[lastpos],cyan);
    for x:=lux+2+length(menuitem[lastpos]) to lux+wide+2 do
      vmemwrite(x,luy+lastpos,' ',cyan);
    vmemwrite(lux+1,luy+pos,' '+menuitem[pos],blue*16+white);
    for x:=lux+2+length(menuitem[pos]) to lux+wide+2 do
      vmemwrite(x,luy+pos,' ',blue*16+white);
    lastpos:=pos;
    repeat ch:=readkey until ch in [#0,#13,#27];
    if not(ch in [#13,#27]) then ch:=readkey;
    case ch of
      'H':if pos>1 then dec(pos) else pos:=menucount;
      'P':if pos<menucount then inc(pos) else pos:=1;
      'I':pos:=1;
      'Q':pos:=menucount;
      'G':pos:=1;
      'O':pos:=menucount;
    end;
  until ch in [#27,#13];
  nbmenu:=pos;
  if ch=#27 then nbmenu:=0;
end;
end.2  ,
