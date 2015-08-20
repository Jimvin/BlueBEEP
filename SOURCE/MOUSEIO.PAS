unit mouseio;

interface
function MouseLeftClicked:boolean;
function MouseRightClicked:boolean;
function InitMouse:boolean;
procedure MouseOn;
procedure MouseOff;
procedure MoveMouseTo(x,y:word);
procedure MouseRange(xmin,ymin,xmax,ymax:word);
function  MouseX:word;
function  MouseY:word;
procedure GetNextClick(var x,y:word);

var mouseison :boolean;

implementation
uses dos,bitmani;

function MouseLeftClicked:boolean;
var r:registers;
begin
  r.ax:=$0003;
  intr($33,r);
  MouseLeftClicked:=gesetztinword(0,r.bx);
end;

function MouseRightClicked:boolean;
var r:registers;
begin
  r.ax:=$0003;
  intr($33,r);
  MouseRightClicked:=gesetztinword(1,r.bx);
end;

function InitMouse:boolean;
var r:registers;
begin
  with r do begin
    ax:=$0000;
    intr($33,r);
    if ax=$0000 then begin
      initmouse:=false;
      exit;
    end;
    ax:=$0001;
    intr($33,r);
  end;
  initmouse:=true;
end;

procedure MouseOn;
var r:registers;
begin
  if not(mouseison) then begin
    r.ax:=$0001;
    intr($33,r);
    mouseison:=true;
  end;
end;

procedure MouseOff;
var r:registers;
begin
  if mouseison then begin
    r.ax:=$0002;
    intr($33,r);
    mouseison:=false;
  end;
end;

procedure MoveMouseTo(x,y:word);
var r:registers;
begin
  r.ax:=$0004;
  r.cx:=x*8-1;
  r.dx:=x*8-1;
  intr($33,r);
end;

procedure MouseRange(xmin,ymin,xmax,ymax:word);
var r:registers;
begin
  r.ax:=$0007;
  r.cx:=xmin*8-1;
  r.dx:=xmax*8-1;
  intr($33,r);
  r.ax:=$0008;
  r.cx:=ymin*8-1;
  r.dx:=ymax*8-1;
  intr($33,r);
end;

function mousex:word;
var r:registers;
begin
  r.ax:=$0003;
  intr($33,r);
  mousex:=r.cx div 8+1;
end;

function mousey:word;
var r:registers;
begin
  r.ax:=$0003;
  intr($33,r);
  mousey:=r.dx div 8+1;
end;

procedure GetNextClick(var x,y:word);
var r:registers;
begin
  repeat r.ax:=$0003; intr($33,r); until r.bx<>0;
  x:=r.cx div 8+1;
  y:=r.dx div 8+1;
  repeat until not mouseleftclicked;
end;

begin
  if paramstr(1)='/(C)' then begin
    writeln('MOUSEIO.PAS  v1.30   Mouse Interface Routines via Interrupt 33h');
    writeln('                     Copyright (C) 1993 by Onkel Dittmeyer/SLAM');
    writeln;
    readln;
  end;
  mouseison:=false;
end.
