unit bbp_tool;

interface

procedure tools;

implementation

uses bbp_vars, grwins, crt, extras, editrout, optimer, vgagraph,
     video, {vfont8x8,} types, grmenus, sos;

procedure tools;
var choice:byte;
procedure exportbook(fn:string);
var x,y,z :word;
    c     :numberrec;
    t     :text;
begin
  openbox(10,28,7,51,11,true,true,false);
  textattr:=colors.win_title;
  center(7,' Export Phone Book ');
  vmemwrite(31,9,'To:',colors.win_text);
  gotoxy(35,9);
  setcursorsize($6,$7); edituc(fn,12); setcursorsize($32,$32);
  center(11,' Working ');
  sosopen;
  sosfopen(phonebookname);
  assign(t,fn);
  {$I-}
  rewrite(t);
  {$I+}
  if ioresult<>0 then begin
    center(9,'** I/O ERROR !! **');
    delayms(2000);
    closebox(10);
    exit;
  end;
  writeln(t,'<<< This Phone Book exported using BlueBEEP! v',version);
  writeln(t,'<<< Copyright (C) 1993-1995 by Onkel Dittmeyer');
  writeln(t);
  writeln(t,' #    Name                                  Number');
  writeln(t,'------------------------------------------------------------------------------');
  for x:=1 to maxnums do begin
    sosread(@c,sizeof(c));
    c.name:=scrambled(c.name);
    c.number:=scrambled(c.number);
    if c.name<>blankpbentry then begin
      write(t,x:3,'   ',c.name);
      for y:=1 to 38-length(c.name) do write(t,' ');
      writeln(t,c.number);
    end;
  end;
  sosclose;
  writeln(t,'---EOF------------------------------------------------------------------------');
  close(t);
  closebox(10);
end;

procedure importoldtlo;
var s:string;
    temprec:oldtlonumrec;
    x:word;
begin
  openbox(1,10,10,70,16,true,true,false);
  textattr:=colors.win_title;
  center(10,'Import TLO 0.1á-0.9á Phone Book');
  textattr:=colors.win_text;
  gotoxy(13,12); write('Path to TLO files: ');
  s:='C:\TLO';
  setcursorsize($6,$7);
  edituc(s,36);
  setcursorsize($32,$32);
  center(14,'** Importing **');
  if not exist(s+'\TARGETS.TLO') then begin
    center(14,'** FILES NOT FOUND! **');
    delayms(2000);
    closebox(1);
    exit;
  end;
  assign(oldtlobook,s+'\TARGETS.TLO');
  reset(oldtlobook);
  sosopen;
  sosfopen(phonebookname);
  for x:=0 to filesize(oldtlobook)-1 do begin
    read(oldtlobook,temprec);
    numbers[x+1]^.name:=temprec.descrip;
    numbers[x+1]^.number:=temprec.number;
    if numbers[x+1]^.name='NONE' then numbers[x+1]^.name:=blankpbentry;
    if numbers[x+1]^.number='NONE' then numbers[x+1]^.number:='';
    sosseek(sizeof(numberrec)*x);
    numbers[x+1]^.name:=scrambled(numbers[x+1]^.name);
    numbers[x+1]^.number:=scrambled(numbers[x+1]^.number);
    soswrite(numbers[x+1],sizeof(numberrec));
    numbers[x+1]^.name:=scrambled(numbers[x+1]^.name);
    numbers[x+1]^.number:=scrambled(numbers[x+1]^.number);
  end;
  close(oldtlobook);
  sosclose;
  center(14,'Successfully imported !');
  victorioustune;
  tapenter(16);
  closebox(1);
end;

procedure importnewtlo;
var s       :string;
    temprec :newtlonumrec;
    x, cnt  :word;
begin
  openbox(23,07,10,73,19,true,true,false);
  textattr:=colors.win_title;
  center(10,'Import TLO 1.0 or later Phone Book');
  textattr:=colors.win_text;
  center(12,'NOTE: If using more than one phone book in TLO 3.0 or later,');
  center(13,'      only the first five phonebooks will be imported.      ');
  gotoxy(13,15); write('Path to TLO files: ');
  s:='C:\TLO';
  setcursorsize($6,$7);
  edituc(s,36);
  setcursorsize($32,$32);
  center(17,'** Importing **');
  if not exist(s+'\NUMBERS.TLO') then begin
    center(17,'** FILES NOT FOUND! **');
    delayms(2000);
    closebox(23);
    exit;
  end;
  assign(newtlobook,s+'\NUMBERS.TLO');
  reset(newtlobook);
  sosopen;
  sosfopen(phonebookname);
  cnt:=filesize(newtlobook)-1;
  if cnt>maxnums then cnt:=maxnums;
  for x:=0 to cnt do begin
    read(newtlobook,temprec);
    numbers[x+1]^.name:=temprec.descrip;
    numbers[x+1]^.number:=temprec.number;
    if numbers[x+1]^.name='NONE' then numbers[x+1]^.name:=blankpbentry;
    if numbers[x+1]^.number='NONE' then numbers[x+1]^.number:='';
    if numbers[x+1]^.name='' then numbers[x+1]^.name:=blankpbentry;
    if numbers[x+1]^.number='-UNUSED-' then numbers[x+1]^.number:='';
    sosseek(sizeof(numberrec)*x);
    numbers[x+1]^.name:=scrambled(numbers[x+1]^.name);
    numbers[x+1]^.number:=scrambled(numbers[x+1]^.number);
    soswrite(numbers[x+1],sizeof(numberrec));
    numbers[x+1]^.name:=scrambled(numbers[x+1]^.name);
    numbers[x+1]^.number:=scrambled(numbers[x+1]^.number);
  end;
  close(newtlobook);
  sosclose;
  center(17,'Successfully imported !');
  victorioustune;
  tapenter(19);
  closebox(23);
end;

procedure importcardlist;
var s:string;
    tempstring:string;
    temprec:numberrec;
    x:word;
    t:text;
begin
  openbox(1,10,10,70,16,true,true,false);
  textattr:=colors.win_title;
  center(10,'Import Calling Card List');
  textattr:=colors.win_text;
  gotoxy(13,12); write('File to import: ');
  s:='CARDLIST.TXT';
  setcursorsize($6,$7);
  edit(s,36);
  setcursorsize($32,$32);
  center(14,'** Importing **');
  if not exist(s) then begin
    center(14,'** FILE NOT FOUND! **');
    delayms(2000);
    closebox(1);
    exit;
  end;
  assign(t,s);
  reset(t);
  sosopen;
  sosfopen(phonebookname);
  x:=0;
  repeat
    sosread(@temprec,sizeof(temprec));
  until scrambled(temprec.name)=blankpbentry;
  x:=sos_filepos-1;
  while not eof(t) do begin
    readln(t,tempstring);
    numbers[x+1]^.name:='Calling Card';
    numbers[x+1]^.number:=tempstring;
    numbers[x+1]^.name:=scrambled(numbers[x+1]^.name);
    numbers[x+1]^.number:=scrambled(numbers[x+1]^.number);
    sosseek(x*sizeof(numberrec));
    soswrite(numbers[x+1],sizeof(numberrec));
    numbers[x+1]^.name:=scrambled(numbers[x+1]^.name);
    numbers[x+1]^.number:=scrambled(numbers[x+1]^.number);
    inc(x);
  end;
  close(t);
  sosclose;
  center(14,'Successfully imported !');
  victorioustune;
  tapenter(16);
  closebox(1);
end;

procedure importphonebook;
var s, tempstring     :string;
    temprec           :numberrec;
    numcol,namecol    :byte;
    x                 :word;
    t                 :text;
begin
  openbox(1,07,10,73,18,true,true,false);
  textattr:=colors.win_title;
  center(10,'Import Phone Book');
  textattr:=colors.win_text;
  setcursorsize($6,$7);
  s:='PHONEBK.LST';
  namecol:=7;
  numcol:=45;
  gotoxy(13,12); write('Import from ASCII file: ');    edit(s,36);
  gotoxy(12,13); write('Entry name start column: ');   editbyte(namecol);
  gotoxy(10,14); write('Entry number start column: '); editbyte(numcol);
  setcursorsize($32,$32);
  center(16,'** Importing **');
  if not exist(s) then begin
    center(16,'** FILE NOT FOUND! **');
    delayms(2000);
    closebox(1);
    exit;
  end;
  assign(t,s);
  reset(t);
  sosopen;
  sosfopen(phonebookname);
  x:=0;
  repeat
    sosread(@temprec,sizeof(temprec));
  until scrambled(temprec.name)=blankpbentry;
  x:=(sos_filepos div sizeof(numberrec))-1;
  sosseek(x*sizeof(numberrec));
  while not eof(t) do begin
    readln(t,tempstring);
    if tempstring<>'' then if tempstring[1]<>';' then begin
      numbers[x+1]^.name:=striptrail(copy(tempstring,namecol,pbentrynamelen));
      numbers[x+1]^.number:=striptrail(copy(tempstring,numcol,pbentrynumlen));
      numbers[x+1]^.name:=scrambled(numbers[x+1]^.name);
      numbers[x+1]^.number:=scrambled(numbers[x+1]^.number);
      soswrite(numbers[x+1],sizeof(numberrec));
      numbers[x+1]^.name:=scrambled(numbers[x+1]^.name);
      numbers[x+1]^.number:=scrambled(numbers[x+1]^.number);
      inc(x);
    end;
  end;
  close(t);
  sosclose;
  center(16,'Successfully imported !');
  victorioustune;
  tapenter(18);
  closebox(1);
end;

procedure flythroughspace;
const numstars=280;                          { number of stars on screen     }
      zmin=1;                                { closest star                  }
      zmax=200;                              { farest star                   }
      xymax=23100;                           { MAXINT / SQRT(2) due turning  }
      sfarbe=31;                             { star base color               }
var   stars      :array[0..numstars] of record x,y,z:integer; end;
      starsbuf   :array[0..numstars] of record ox,oy,oc:integer; end;
      drawed     :boolean;                   { screen empty --> zeroed       }
      xmove,ymove:integer;
      xm,ym,dz :integer;
      cs,sn    :longint;                     { cosinus/sinus pre-calculation }
      w        :real;
      xmp,ymp:integer;
      ch     :char;
      speed  :integer;
      turn   :real;
      x      :longint;
      vsave  :^vgascreen;
      tmp    :word;
procedure initstars;
var i:integer;
begin
  xm:=160;
  ym:=100;
  randomize;
  for i:=0 to numstars do with stars[i] do begin
    x:=integer(random(xymax*2))-xymax;
    y:=integer(random(xymax*2))-xymax;
    z:=random(zmax-zmin)+zmin;
  end;
end;
procedure parastars(p1:integer;p2:real;xmv,ymv:integer);
var i:word;
begin
  xmove:=xmv;
  ymove:=ymv;
  dz:=p1; w:=p2;
  xm:=160;
  ym:=100;
  cs:=round(cos(w)*2048);
  sn:=round(sin(w)*2048);
end;
procedure clearstars;
var i:integer;
begin
  for i:=0 to numstars do with starsbuf[i] do putpixel(ox,oy,oc);
end;
procedure drawstars;
var i:word;
    xx,yy:longint;
begin
  for i:=0 to numstars do begin
    with stars[i] do begin
      z:=z+dz;
      x:=(x*cs) div 2048+(y*sn) div 2048; {in 68000 assembler wird aus div 2048 = asr (),11 !}
      y:=(y*cs) div 2048-(x*sn) div 2048;
      x:=x+xmove;
      y:=y+ymove;
      if (z<zmin) or (z>zmax) then begin
        x:=random(xymax*2)-xymax;
        y:=random(xymax*2)-xymax;
        if z>zmax then z:=zmin else z:=zmax;
      end;
      xx:=xm+x div z;
      yy:=ym-y div z;
    end;
    with starsbuf[i] do begin
      if drawed then putpixel(ox,oy,vsave^[oy*320+ox]);
      ox:=xx;oy:=yy;
      if mem[$a000:yy*320+xx]=0 then putpixel(xx,yy,sfarbe-(stars[i].z div 17));
    end;
  end;
  drawed:=true;
end;
begin
  move(mem[vadr:0],save,4000);
  ch:='S';
  speed:=-1;
  turn:=0.00;
  xmp:=0;
  ymp:=0;
  enter256colormode;
  {text8x8(75,96,'BLUEBEEP IS SLEEPING...',gray,1);}
  new(vsave);
  move(mem[$a000:0],vsave^,64000);
  parastars(speed,turn,xmp,ymp);
  initstars;
  repeat
    drawstars;
    if keypressed then begin
      ch:=readkey;
      if ch=#0 then ch:=readkey;
      case ch of
        CurUp:inc(speed);                  { speed increase                  }
        CurDn:dec(speed);                  { speed decrease                  }
        CurLf:turn:=turn+0.005;            { turn left                       }
        CurRt:turn:=turn-0.005;            { turn right                      }
          '4':dec(xmp,5);                  { moves left                      }
          '6':inc(xmp,5);                  { moves right                     }
          '8':dec(ymp,5);                  { moves up                        }
          '2':inc(ymp,5);                  { moves down                      }
          '0':begin                        { screenclear                     }
                cleardevice;
                for tmp:=0 to 63999 do vsave^[tmp]:=0;
              end;
      end;
      parastars(speed,turn,xmp,ymp);
    end;
  until ch=Esc;
  dispose(vsave);
  for x:=1 to 200 do begin { "Black Hole" Effect }
    turn:=turn+0.005;
    parastars(speed,turn,xmp,ymp);
    drawstars;
  end;
  closegraph;
  setcursorsize($32,$32);
  move(save,mem[vadr:0],4000);
end;

begin
  choice:=1;
  repeat
    menuitem[1]:='Export Phone Book';
    menuitem[2]:='Print Phone Book';
    menuitem[3]:='Import phone book from ASCII';
    menuitem[4]:='Import TLO V0.1-V0.9 phone book';
    menuitem[5]:='Import TLO V1.0-V3.3 phone book';
    menuitem[6]:='Import Card List';
    menuitem[7]:='Flight Through Space';
    menuinfo[1]:='Export your phone book to an ASCII file on disk';
    menuinfo[2]:='Export your phone book to a list on the printer';
    menuinfo[3]:='Import phone book from ASCII text file';
    menuinfo[4]:='Import your TLO (The Little Operator) version 0.1á to 0.9á to BlueBEEP!';
    menuinfo[5]:='Import your TLO (The Little Operator) version 1.0 or later to BlueBEEP!';
    menuinfo[6]:='Import Calling Card List from a text file';
    menuinfo[7]:='Relax, lean back, and enjoy a flight through space';
    menucount:=7;
    choice:=menu(19,4,choice,true,true,true,true,true);
    case choice of
      1: exportbook('PHONEBK.LST');
      2: exportbook('LPT1');
      3: importphonebook;
      4: importoldtlo;
      5: importnewtlo;
      6: importcardlist;
      7: flythroughspace;
    end;
  until choice=0;
end;
end.
