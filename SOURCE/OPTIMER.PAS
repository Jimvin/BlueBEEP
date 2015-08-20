unit OpTimer;

interface

procedure InitializeTimer;
procedure RestoreTimer;
function ReadTimer : LongInt;
function ElapsedTime(Start, Stop : LongInt) : Real;
procedure delayms(len: longint);

implementation

const
  TimerResolution = 1193181.667;
var
  Delta : LongInt;

function Cardinal(L : LongInt) : Real;
begin
  if L < 0 then Cardinal := 4294967296.0+L
  else Cardinal := L;
end;

function ElapsedTime(Start, Stop : LongInt) : Real;
begin
  ElapsedTime := 1000.0*Cardinal(Stop-(Start+Delta))/TimerResolution;
end;

procedure InitializeTimer;
begin
  Port[$43] := $34;
  inline($EB/$00);
  Port[$40] := $00;
  inline($EB/$00);
  Port[$40] := $00;
end;

procedure RestoreTimer;
begin
  Port[$43] := $36;
  inline($EB/$00);
  Port[$40] := $00;
  inline($EB/$00);
  Port[$40] := $00;
end;

function ReadTimer : LongInt;
begin
asm
  cli
  mov  al,0Ah
  out  20h,al
  xor  al,al
  out  43h,al
  in   al,20h
  mov  di,ax
  in   al,40h
  mov  bl,al
  in   al,40h
  mov  bh,al
  not  bx
  in   al,21h
  mov  si,ax
  mov  al,0FFh
  out  21h,al
  mov  ax,40h
  mov  es,ax
  mov  dx,es:[6Ch]
  mov  ax,si
  out  21h,al
  sti
  mov  ax,di
  test al,1
  jz   @done
  cmp  bx,0FFh
  ja   @done
  inc  dx
  @done:
  mov [bp-4],bx
  mov [bp-2],dx
end;
end;

procedure Calibrate;
var
  I : Word;
  L1, L2, Diff : LongInt;
begin
  Delta := MaxInt;
  for I := 1 to 1000 do begin
    L1 := ReadTimer;
    L2 := ReadTimer;
    Diff := L2-L1;
    if Diff < Delta then
      Delta := Diff;
  end;
end;

procedure delayms(len: longint);
var start : longint;                           {* Merker fuer Startticks     *}
begin
  start := readtimer;                        {* Merker laden               *}
  repeat                                     {* Solange warten bis...      *}
  until elapsedtime(Start,Readtimer) >= len; {* Zeit vertrichen ist        *}
end;

begin
  InitializeTimer;
  Calibrate;
end.
