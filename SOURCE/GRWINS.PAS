unit grwins;

interface

uses crt, types, video, bbp_vars, ferror, vgagraph;

var old :array [1..100] of pointer;
    x   :byte;
    cnt :byte;

procedure OpenBox(num,ux,uy,lx,ly:byte;shadow,fill,zoom:boolean);
procedure CloseBox(num:byte);
procedure IgnBox(num:byte);

implementation

function Stg(w:word):String;
var s:string;
begin
  str(w,s);
  stg:=s;
end;

procedure put(x,y,col:byte;c:char);
begin
  mem[vadr:2*((y-1)*80+x)-2]:=ord(c);
  mem[vadr:2*((y-1)*80+x)-1]:=col;
end;

procedure vshadow(x,y:byte);
begin
  mem[vadr:2*((y-1)*80+x)-1]:=colors.shadow;
end;

procedure drawbox(ux,uy,lx,ly:byte;fill:boolean);
var x:byte;
begin
  put(ux,uy,colors.win_border_1,'Ú');
  put(lx,uy,colors.win_border_1,'¿');
  put(ux,ly,colors.win_border_1,'À');
  put(lx,ly,colors.win_border_1,'Ù');
  put(ux+1,uy,colors.win_border_1,'Ä');
  put(lx-1,uy,colors.win_border_1,'Ä');
  put(ux+1,ly,colors.win_border_1,'Ä');
  put(lx-1,ly,colors.win_border_1,'Ä');
  put(ux+2,uy,colors.win_border_2,'Ä');
  put(lx-2,uy,colors.win_border_2,'Ä');
  put(ux+2,ly,colors.win_border_2,'Ä');
  put(lx-2,ly,colors.win_border_2,'Ä');
  put(ux+3,uy,colors.win_border_2,'Ä');
  put(lx-3,uy,colors.win_border_2,'Ä');
  put(ux+3,ly,colors.win_border_2,'Ä');
  put(lx-3,ly,colors.win_border_2,'Ä');
  put(ux,uy+1,colors.win_border_2,'³');
  put(ux,ly-1,colors.win_border_2,'³');
  put(lx,uy+1,colors.win_border_2,'³');
  put(lx,ly-1,colors.win_border_2,'³');
  for x:=ux+4 to lx-4 do put(x,uy,colors.win_border_3,'Ä');
  for x:=ux+4 to lx-4 do put(x,ly,colors.win_border_3,'Ä');
  for x:=uy+2 to ly-2 do put(ux,x,colors.win_border_3,'³');
  for x:=uy+2 to ly-2 do put(lx,x,colors.win_border_3,'³');
  if fill then for x:=ux+1 to lx-1 do for y:=uy+1 to ly-1 do put(x,y,colors.win_fill,' ');
end;

procedure zoombox(eulx,euly,elrx,elry:byte);
var ulx, uly, lrx, lry :word;
begin
  ulx:=eulx+((elrx-eulx) div 2)-1;
  uly:=euly+((elry-euly) div 2)-1;
  lrx:=eulx+((elrx-eulx) div 2)+1;
  lry:=euly+((elry-euly) div 2)+1;
  while not((ulx=eulx) and (uly=euly) and (lrx=elrx) and (lry=elry)) do begin
    if cnt=0 then begin cnt:=1; vsync; end else dec(cnt);
    drawbox(ulx,uly,lrx,lry,true);
    if ulx>eulx then dec(ulx);
    if uly>euly then dec(uly);
    if lrx<elrx then inc(lrx);
    if lry<elry then inc(lry);
  end;
end;

procedure openbox(num,ux,uy,lx,ly:byte;shadow,fill,zoom:boolean);
var x,y :byte;
begin
  cnt:=0;
  if old[num]<>nil then fatalerror('Window save pointer #'+stg(num)+' is already busy. Report to author.');
  if num<>0 then begin
    getmem(old[num],4000);
    move(mem[vadr:0],old[num]^,4000);
  end;
  if zoom then zoombox(ux,uy,lx,ly);
  drawbox(ux,uy,lx,ly,fill);
  if shadow then begin
    for x:=ux+2 to lx+2 do vshadow(x,ly+1);
    for x:=uy+1 to ly do for y:=1 to 2 do vshadow(lx+y,x);
  end;
end;

procedure CloseBox(num:byte);
begin
  move(old[num]^,mem[vadr:0],4000);
  freemem(old[num],4000);
  old[num]:=nil;
end;

procedure IgnBox(num:byte);
begin
  freemem(old[num],4000);
  old[num]:=nil;
end;

begin
  if paramstr(1)='/(C)' then begin
    writeln('GRWINS.PAS       Window & Zoomwindow routines in Txt mode');
    writeln('                 (C) 1991-1994 by Onkel Dittmeyer');
    writeln;
    readln;
  end;
  for x:=1 to 100 do old[x]:=nil;
end.
