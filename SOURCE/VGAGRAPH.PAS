unit vgagraph;

interface
uses dos;
type vgascreen = array[0..63999] of byte;
const on  = FALSE;
      off = TRUE;

procedure Enter256ColorMode;
procedure vsync;
procedure CloseGraph;
procedure putpixel(x,y:word;color:byte);
function  getpixel(x,y:word):word;
procedure setrgbpalette(dac,r,g,b:byte);
procedure getrgbpalette(dac:word;var r,g,b:word);
procedure Bildaufbau(onoff:boolean);
procedure Cleardevice;
procedure go80x50;

implementation

Procedure Enter256ColorMode;
begin
  asm
    mov ax,0013h
    int 10h
  end;
end;

procedure vsync;
begin
  Repeat Until (Port[$3DA] And $08) = 0;
  Repeat Until (Port[$3DA] And $08) <> 0;
end;

procedure closegraph;
begin
  asm
    mov ax,0003h
    int 10h
  end;
end;

procedure putpixel(x,y:word;color:byte);
begin
  if (x<320) and (x>=0) and (y<200) and (y>=0) then
    mem[$A000:y*320+x]:=color;
end;

function getpixel(x,y:word):word;
begin
  getpixel:=mem[$A000:y*320+x];
end;

procedure setrgbpalette(dac,r,g,b:byte); assembler;
asm
  mov  dx,$3C8
  mov  al,dac
  out  dx,al
  inc  dx
  mov  al,r
  out  dx,al
  mov  al,g
  out  dx,al
  mov  al,b
  out  dx,al
end;

procedure getrgbpalette(dac:word;var r,g,b:word);
var reg:registers;
begin
  reg.ah:=$10;
  reg.al:=$15;
  reg.bx:=dac;
  intr($10,reg);
  r:=reg.dh;
  g:=reg.ch;
  b:=reg.cl;
end;

procedure Bildaufbau(onoff:boolean);
begin
  asm
    mov ah,12h
    mov bl,36h
    mov al,onoff
    int 10h
  end;
end;

procedure Cleardevice;
begin Enter256ColorMode; end;

procedure go80x50;
begin
  asm
    mov ax,1112h
    xor bl,bl
    int 10h
  end;
end;

begin
  if paramstr(1)='/(C)' then begin
    writeln('VGAGRAPH.PAS - v2.5 - (C) 1993 by Onkel Dittmeyer / S.L.A.M.');
    writeln('             Generic VGA I/O routines');
    readln;
  end;
end.
