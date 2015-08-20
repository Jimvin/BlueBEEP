unit pdial;

interface

uses bitmani,crt,optimer,extras,bbp_vars;

var   waitfordt,                  { wait for dial tone for how many ms    }
      pulse_mark,                 { pulse dial mark time in miliseconds   }
      pulse_space,                { pulse dial space time in miliseconds  }
      pulse_interdig,             { pulse dial interdigit delay           }
      portadress,                 { parallel port adress                  }
      hookbit,                    { onhook/offhook bit on device          }
      playrecbit,                 { play/record bit (off=play, on=record) }
      phonebit :word;             { phone bit, off = phone on air         }

procedure setportbit(bitnr:byte;visual:boolean);
procedure clrportbit(bitnr:byte;visual:boolean);
procedure dialpulsedigit(dig:char;visual:boolean);
procedure dialpulse(nr:string;visual:boolean);

implementation

procedure setportbit(bitnr:byte;visual:boolean);
var x:byte;
begin
  x:=port[portadress];
  setbitinbyte(bitnr,x);
  port[portadress]:=x;
  if visual then begin
    if bitnr=hookbit then vmemwrite(18,13,' ON-HOOK ',colors.keypad_pressed);
    if bitnr=playrecbit then begin
      vmemwrite(28,13,' PLAY ',colors.keypad_released);
      vmemwrite(35,13,' REC ',colors.keypad_pressed);
    end;
    if bitnr=phonebit then vmemwrite(41,13,' PHONE ',colors.keypad_released);
  end;
end;

procedure clrportbit(bitnr:byte;visual:boolean);
var x:byte;
begin
  x:=port[portadress];
  clrbitinbyte(bitnr,x);
  port[portadress]:=x;
  if visual then begin
    if bitnr=hookbit then vmemwrite(18,13,' ON-HOOK ',colors.keypad_released);
    if bitnr=playrecbit then begin
      vmemwrite(28,13,' PLAY ',colors.keypad_pressed);
      vmemwrite(35,13,' REC ',colors.keypad_released);
    end;
    if bitnr=phonebit then vmemwrite(41,13,' PHONE ',colors.keypad_pressed);
  end;
end;

procedure dialpulsedigit(dig:char;visual:boolean);
var tacks,x,outbyte:byte;
begin
  if visual then begin
    if dig='1' then vmemwrite(3,5,' 1 ',colors.keypad_pressed);
    if dig='2' then vmemwrite(9,5,' 2 ',colors.keypad_pressed);
    if dig='3' then vmemwrite(15,5,' 3 ',colors.keypad_pressed);
    if dig='4' then vmemwrite(3,7,' 4 ',colors.keypad_pressed);
    if dig='5' then vmemwrite(9,7,' 5 ',colors.keypad_pressed);
    if dig='6' then vmemwrite(15,7,' 6 ',colors.keypad_pressed);
    if dig='7' then vmemwrite(3,9,' 7 ',colors.keypad_pressed);
    if dig='8' then vmemwrite(9,9,' 8 ',colors.keypad_pressed);
    if dig='9' then vmemwrite(15,9,' 9 ',colors.keypad_pressed);
    if dig='0' then vmemwrite(9,11,' 0 ',colors.keypad_pressed);
    if dig='A' then vmemwrite(20,5,' KP1 ',colors.keypad_pressed);
    if dig='B' then vmemwrite(26,5,' KP2 ',colors.keypad_pressed);
    if dig='C' then vmemwrite(32,5,' ST ',colors.keypad_pressed);
    if dig='D' then vmemwrite(37,5,' KP2E ',colors.keypad_pressed);
    if dig='E' then vmemwrite(44,5,' STE ',colors.keypad_pressed);
    if dig='F' then vmemwrite(50,5,' C11 ',colors.keypad_pressed);
    if dig='G' then vmemwrite(56,5,' C12 ',colors.keypad_pressed);
    if dig='H' then vmemwrite(62,5,' EO ',colors.keypad_pressed);
  end;
  case dig of
    '1' :tacks:=1;
    '2' :tacks:=2;
    '3' :tacks:=3;
    '4' :tacks:=4;
    '5' :tacks:=5;
    '6' :tacks:=6;
    '7' :tacks:=7;
    '8' :tacks:=8;
    '9' :tacks:=9;
    '0' :tacks:=10;
    'A' :tacks:=11;
    'B' :tacks:=12;
    'C' :tacks:=13;
    'D' :tacks:=14;
    'E' :tacks:=15;
    'F' :tacks:=16;
    'G' :tacks:=17;
    'H' :tacks:=18;
  end;
  for x:=1 to tacks do begin
    clrportbit(hookbit,visual);
    delayms(pulse_mark);
    setportbit(hookbit,visual);
    delayms(pulse_space);
  end;
  if visual then begin
    if dig='1' then vmemwrite(3,5,' 1 ',colors.keypad_released);
    if dig='2' then vmemwrite(9,5,' 2 ',colors.keypad_released);
    if dig='3' then vmemwrite(15,5,' 3 ',colors.keypad_released);
    if dig='4' then vmemwrite(3,7,' 4 ',colors.keypad_released);
    if dig='5' then vmemwrite(9,7,' 5 ',colors.keypad_released);
    if dig='6' then vmemwrite(15,7,' 6 ',colors.keypad_released);
    if dig='7' then vmemwrite(3,9,' 7 ',colors.keypad_released);
    if dig='8' then vmemwrite(9,9,' 8 ',colors.keypad_released);
    if dig='9' then vmemwrite(15,9,' 9 ',colors.keypad_released);
    if dig='0' then vmemwrite(9,11,' 0 ',colors.keypad_released);
    if dig='A' then vmemwrite(20,5,' KP1 ',colors.keypad_released);
    if dig='B' then vmemwrite(26,5,' KP2 ',colors.keypad_released);
    if dig='C' then vmemwrite(32,5,' ST ',colors.keypad_released);
    if dig='D' then vmemwrite(37,5,' KP2E ',colors.keypad_released);
    if dig='E' then vmemwrite(44,5,' STE ',colors.keypad_released);
    if dig='F' then vmemwrite(50,5,' C11 ',colors.keypad_released);
    if dig='G' then vmemwrite(56,5,' C12 ',colors.keypad_released);
    if dig='H' then vmemwrite(62,5,' EO ',colors.keypad_released);
  end;
  if keypressed then exit;
  delayms(pulse_interdig);
end;

procedure dialpulse(nr:string;visual:boolean);
var x,save:byte;
    ch:char;
begin
  save:=textattr;
  setportbit(hookbit,visual);
  for x:=1 to length(nr) do begin
    if nr[x] in ['0'..'9','A'..'H']
    then begin
      textattr:=colors.high;
      write(nr[x]);
      dialpulsedigit(nr[x],visual);
      if keypressed then begin
        repeat ch:=readkey until ch<>#0;
        clrportbit(playrecbit,visual);
        clrportbit(hookbit,visual);
        exit;
      end;
    end else begin
      textattr:=colors.normal;
      write(nr[x]);
    end;
  end;
  textattr:=save;
end;

begin
  if paramstr(1)='/(C)' then begin
    writeln('PDIAL.PAS  v1.00   Pulse Dialing & Phone Relay I/O Routines');
    writeln('                   Copyright (C) 1993 Onkel Dittmeyer/SLAM');
    writeln;
    readln;
  end;
end. 
