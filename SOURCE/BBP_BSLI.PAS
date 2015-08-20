{ -------------------------------------------------------------------------- }
{                                                                            }
{                       BlueBEEP BSL Script Interpreter                      }
{                   Copyright (C) 1993 by Onkel Dittmeyer                    }
{                                                                            }
{                     BSLI started Aug 01 1993 00:32:25                      }
{                                                                            }
{ -------------------------------------------------------------------------- }

unit bbp_bsli;

interface

procedure loadscript(fn:string);

implementation

uses crt, bbp_vars, bbp_proc, video, extras, optimer,
     bbunit, ferror, sos;

procedure loadscript(fn:string);
var script    :array[1..200] of ^string;
    scriptlen :word;
    savescr   :array[1..4000] of byte;
    scr_svars :array[1..9] of string;
    scr_wvars :array[1..9] of word;
    allparms  :string;
    parm      :array[1..9] of string;
    x         :word;
    t         :text;
    numparms  :byte;

procedure execute_bsl(command:string);
var cmd,s :string;
    x,y,z :byte;
    ch    :char;
procedure change_dialset(setname:string);
var workset :dialsettype;
    x       :byte;
    didit   :boolean;
begin
  sosopen;
  sosfopen(dsfilename);
  didit:=false;
  for x:=1 to maxdialsets do begin
    sosread(@workset,sizeof(workset));
    if uppercase(workset.standard)=uppercase(setname) then begin
      curds:=workset;
      config.curdset:=x;
      didit:=true;
    end;
  end;
  sosclose;
  if not didit then fatalerror('BSL Error: Dialset '+setname+' could not be located.');
end;

procedure change_trunk(trunkname:string);
var worktrk :trunktype;
    x       :byte;
    didit   :boolean;
begin
  sosopen;
  sosfopen(trunkfilename);
  didit:=false;
  for x:=1 to maxdialsets do begin
    sosread(@worktrk,sizeof(worktrk));
    if uppercase(worktrk.name)=uppercase(trunkname) then begin
      curtrunk:=worktrk;
      config.curtrunk:=x;
      didit:=true;
    end;
  end;
  sosclose;
  if not didit then fatalerror('BSL Error: Trunk '+trunkname+' could not be located.');
end;

begin
  if pos(' ',command)=0 then cmd:=uppercase(command) else cmd:=copy(uppercase(command),1,pos(' ',command)-1);
  allparms:=copy(command,pos(' ',command)+1,length(command)-pos(' ',command));
  s:=command;
  x:=0;
  while pos(' ',s)<>0 do begin
    inc(x);
    y:=pos(' ',s);
    s[y]:=#255;
    if pos(' ',s)<>0 then parm[x]:=copy(s,y+1,pos(' ',s)-y-1) else
      parm[x]:=copy(s,y+1,length(s)-y);
  end;
  numparms:=x;
  for x:=1 to numparms do if uppercase(copy(parm[x],1,2))='%S' then
    parm[x]:=scr_svars[ord(parm[x][3])-60];
  if cmd='' then exit;
  if cmd[1]=';' then exit;
  if cmd='CLEAR_SCREEN' then clrscr;
  if cmd='WRITE' then write(allparms);
  if cmd='WRITELN' then writeln(allparms);
  if cmd='DIAL' then dial(parm[1],false,false,false);
  if cmd='DELAY' then delayms(wvalue(parm[1]));
  if cmd='CHANGE_DIALSET' then change_dialset(parm[1]);
  if cmd='CHANGE_TRUNK' then change_trunk(parm[1]);
  if cmd='FAST_EXIT' then begin window(1,1,80,25); clrscr; halt(0); end;
  if cmd='WAIT_ENTER' then repeat ch:=readkey until ch=#13;
  if cmd='PLAY_TRUNK' then playtrunk(curtrunk,false);
  if cmd='MODEM_DIAL' then modemdial(parm[1]);
  if cmd='MODEM_DROP_DTR' then lscomm.comlowerdtr;
  if cmd='MODEM_RAISE_DTR' then lscomm.comraisedtr;
  if cmd='SEND_TONE' then soundplay(wvalue(parm[1]),wvalue(parm[2]),wvalue(parm[3]),wvalue(parm[4]));
end;

begin
  if not exist(fn) then fatalerror('BSLI script file '+fn+' not found!');
  for x:=1 to 9 do scr_svars[x]:='';
  for x:=1 to 9 do scr_wvars[x]:=0;
  move(mem[vadr:0],save,4000);
  textattr:=colors.normal;
  clrscr;
  textattr:=colors.status;
  gotoxy(1,25);
  write(' BlueBEEP v',version,' BSL Script Interpreter');
  clreol;
  textattr:=colors.normal;
  window(1,1,80,24);
  gotoxy(1,1);
  setcursorsize($6,$7);
  write('Loading script ',fn,'...');
  assign(t,fn);
  reset(t);
  scriptlen:=0;
  while not eof(t) do begin
    inc(scriptlen);
    getmem(script[scriptlen],sizeof(script[scriptlen]^));
    readln(t,script[scriptlen]^);
  end;
  writeln(scriptlen,' lines read.');
  for x:=1 to scriptlen do execute_bsl(script[x]^);
  writeln;
  write('Script ended, press [RETURN] to continue...');
  readln;
  for x:=1 to scriptlen do dispose(script[x]);
  move(save,mem[vadr:0],4000);
  window(1,1,80,25);
  setcursorsize($32,$32);
end;
end.
