unit bbp_proc;

interface

uses lscomm, bbp_vars, extras, optimer, crt, grwins, pdial, bbunit,
     mouseio, video, grmenus, editrout, vgagraph, ferror, types, dos,
     keyunit, sos;

function  comreadline:string;
procedure comsendline(s:string);
procedure initmodem;
procedure error(s:string);
procedure modemdial(nr:string);
procedure switchon(b:boolean);
procedure switchoff(b:boolean);
procedure writeconfig;
procedure dial(s:string;visual,touch,cchange:boolean);
procedure playtrunk(trunk:trunktype;visual:boolean);
procedure imoutie;
function  hormenu(line:byte):byte;
procedure quit;
procedure passwordcheck;
procedure paraminfo;
function  chartodigit(ch:char):char;
function  stringtodigit(s:string):string;
procedure numscan(nr,fn:string);
function  inhilitelist(s:string):boolean;
procedure worldtime;
function  xlate(nr:string):string;
procedure recheck_id;
procedure sortphonebook;
function  partofnr(partnr:byte;nr:string):string;
function  parttoend(partnr:byte;nr:string):string;
function  countryfor(nr:string):string;

implementation

procedure error(s:string);
var x,save,savex,savey:byte;
begin
  savex:=wherex; savey:=wherey; save:=textattr;
  openbox(88,10,10,70,14,true,true,false);
  textattr:=colors.win_title;
  center(10,'Error!');
  textattr:=colors.win_error;
  center(12,s);
  for x:=1 to 3 do begin
    sound(300);
    delayms(100);
    nosound;
    delayms(100);
  end;
  tapenter(14);
  textattr:=save;
  gotoxy(save,savey);
  closebox(88);
end;

procedure comsendline(s:string);
var x:byte;
begin
  for x:=1 to length(s) do case s[x] of
    '|' :comtx(#13);
    '~' :delayms(500);
  else comtx(s[x]); end;
end;

function comreadline:string;
var s  :string;
    ch :char;
begin
  s:='';
  repeat
    ch:=comrx;
    if ch<>#0 then s:=s+ch;
  until (s[length(s)-1]=#13) and (s[length(s)]=#10);
  comreadline:=copy(s,1,length(s)-2);
end;

procedure initmodem;
var result   :word;
    s        :string;
begin
  cominstall(config.modemport,result);
  if result<>0 then begin
    case result of
      1: fatalerror('Invalid modem port number: '+stg(config.modemport));
      2: fatalerror('No hardware for port '+stg(config.modemport));
      3: fatalerror('LightSpeed(TM) modem driver already installed!');
    else fatalerror('Unexpected LightSpeed(TM) ComInstall() error '+stg(result));
    end;
  end;
  comraisedtr;
  comsetspeed(config.modemspeed);
  case config.modemparity of
    0: comsetparity(ComNone,config.modemstopbits);
    1: comsetparity(ComEven,config.modemstopbits);
    2: comsetparity(ComOdd,config.modemstopbits);
    3: comsetparity(ComZero,config.modemstopbits);
    4: comsetparity(ComOne,config.modemstopbits);
  end;
  if config.modeminit<>'' then begin
    comsendline(config.modeminit);
    s:=comreadline;
    s:=comreadline;
    if s<>'OK' then fatalerror('Unexpected modem init response: '+s);
    writeln('˛ Modem Initialisation: ',s);
  end else writeln('COM port ready');
end;

procedure modemdial(nr:string);
var ch,kch        :char;              { ch: incoming dtr key, kch: kbd key }
    skey,zoomed   :boolean;           { skey indicates sp., zoomed termwin }
    s             :string;
    savex, savey  :byte;
    save          :array[0..3999] of byte;
begin
  textattr:=colors.normal;
  if not(config.modem) then begin
    writeln;
    write('Modem required for modem dial... Please set it up!');
    exit;
  end;
  comraisedtr;
  writeln;
  write('Modem Dialing (');
  if config.phonesystem then write('Tone): ',nr) else write('Pulse): ',nr);
  if config.phonesystem then comsendline('ATDT'+nr+#13) else comsendline('ATDP'+nr+#13);
  window(1,16,80,24);
  textattr:=colors.special_high;
  clrscr;
  writeln;
  writeln('+ Modem Dialing Status Control -  F10 cancels, ALT-Z zooms +');
  writeln;
  textattr:=colors.special;
  setcursorsize($6,$7);
  zoomed:=false;
  repeat
    if not(comrxempty) then begin
      ch:=comrx;
      write(ch);
    end;
    if keypressed then begin
      kch:=readkey;
      skey:=kch=#0;
      if skey then kch:=readkey else comtx(kch);
      if skey and (kch=',') then begin
        savex:=wherex; savey:=wherey;
        if zoomed then begin
          for x:=0 to 14 do begin
            vsync;
            move(save[160*(14-x)],mem[vadr:0],(x+1)*160);
          end;
          window(1,16,80,24);
          gotoxy(savex,savey-15);
          zoomed:=false;
        end else begin
          move(mem[vadr:0],save,4000);
          savex:=wherex; savey:=wherey;
          window(1,1,80,24);
          setcursorsize($32,$32);
          gotoxy(1,1);
          for x:=1 to 15 do begin
            vsync;
            delline;
          end;
          gotoxy(savex,savey);
          setcursorsize($6,$7);
          zoomed:=true;
        end;
      end;
    end;
  until skey and (kch=F10);
  if zoomed then for x:=0 to 14 do begin
    vsync;
    move(save[160*(14-x)],mem[vadr:0],(x+1)*160);
  end;
  while not(comrxempty) do ch:=comrx;
  comlowerdtr;
  window(18,14,79,14);
  textattr:=colors.normal;
  writeln;
  write('Modem dialing finished.');
  setcursorsize($32,$32);
end;

procedure switchon(b:boolean);
begin
  if config.switchback>0 then clrportbit(playrecbit,b);
  if config.switchback=2 then setportbit(phonebit,b);
  if config.switchback>0 then delayms(curpulsedial.accesstime);
end;

procedure switchoff(b:boolean);
begin
  if config.switchback=1 then setportbit(playrecbit,b);
  if config.switchback=2 then clrportbit(phonebit,b);
end;

procedure writeconfig;
begin
  sosopen;
  sosfopen(cfgfilename);
  config.password:=scrambled(config.password);
  soswrite(@config,sizeof(config));
  config.password:=scrambled(config.password);
  sosclose;
end;

procedure dial(s:string;visual,touch,cchange:boolean);
var x:byte;
procedure dialnum(num:string;t:tonetype2;visual,touch:boolean);
var b:byte;
begin
  if visual then begin
    if num='1' then vmemwrite(3,5,' 1 ',colors.keypad_pressed);
    if num='2' then vmemwrite(9,5,' 2 ',colors.keypad_pressed);
    if num='3' then vmemwrite(15,5,' 3 ',colors.keypad_pressed);
    if num='4' then vmemwrite(3,7,' 4 ',colors.keypad_pressed);
    if num='5' then vmemwrite(9,7,' 5 ',colors.keypad_pressed);
    if num='6' then vmemwrite(15,7,' 6 ',colors.keypad_pressed);
    if num='7' then vmemwrite(3,9,' 7 ',colors.keypad_pressed);
    if num='8' then vmemwrite(9,9,' 8 ',colors.keypad_pressed);
    if num='9' then vmemwrite(15,9,' 9 ',colors.keypad_pressed);
    if num='*' then vmemwrite(3,11,' * ',colors.keypad_pressed);
    if num='0' then vmemwrite(9,11,' 0 ',colors.keypad_pressed);
    if num='#' then vmemwrite(15,11,' # ',colors.keypad_pressed);
    if num=' <KP1> ' then vmemwrite(20,5,' KP1 ',colors.keypad_pressed);
    if num=' <KP2> ' then vmemwrite(26,5,' KP2 ',colors.keypad_pressed);
    if num=' <ST> ' then vmemwrite(32,5,' ST ',colors.keypad_pressed);
    if num=' <KP2E> ' then vmemwrite(37,5,' KP2E ',colors.keypad_pressed);
    if num=' <STE> ' then vmemwrite(44,5,' STE ',colors.keypad_pressed);
    if num=' <C11> ' then vmemwrite(50,5,' C11 ',colors.keypad_pressed);
    if num=' <C12> ' then vmemwrite(56,5,' C12 ',colors.keypad_pressed);
    if num=' <EO> ' then vmemwrite(62,5,' EO ',colors.keypad_pressed);
  end;
  if cchange then begin
    textattr:=colors.high;
    write(num);
    textattr:=colors.normal;
  end;
  if touch then soundstart(t.one,t.two,t.three) else
  soundplay(t.one,t.two,t.three,round(t.mark*config.dialspeed));
  if touch then begin
    if mouseleftclicked then repeat until not mouseleftclicked else begin
      b:=port[$60];
      repeat until b<>port[$60];
    end;
    soundstop;
  end;
  if visual then begin
    if num='1' then vmemwrite(3,5,' 1 ',colors.keypad_released);
    if num='2' then vmemwrite(9,5,' 2 ',colors.keypad_released);
    if num='3' then vmemwrite(15,5,' 3 ',colors.keypad_released);
    if num='4' then vmemwrite(3,7,' 4 ',colors.keypad_released);
    if num='5' then vmemwrite(9,7,' 5 ',colors.keypad_released);
    if num='6' then vmemwrite(15,7,' 6 ',colors.keypad_released);
    if num='7' then vmemwrite(3,9,' 7 ',colors.keypad_released);
    if num='8' then vmemwrite(9,9,' 8 ',colors.keypad_released);
    if num='9' then vmemwrite(15,9,' 9 ',colors.keypad_released);
    if num='*' then vmemwrite(3,11,' * ',colors.keypad_released);
    if num='0' then vmemwrite(9,11,' 0 ',colors.keypad_released);
    if num='#' then vmemwrite(15,11,' # ',colors.keypad_released);
    if num=' <KP1> ' then vmemwrite(20,5,' KP1 ',colors.keypad_released);
    if num=' <KP2> ' then vmemwrite(26,5,' KP2 ',colors.keypad_released);
    if num=' <ST> ' then vmemwrite(32,5,' ST ',colors.keypad_released);
    if num=' <KP2E> ' then vmemwrite(37,5,' KP2E ',colors.keypad_released);
    if num=' <STE> ' then vmemwrite(44,5,' STE ',colors.keypad_released);
    if num=' <C11> ' then vmemwrite(50,5,' C11 ',colors.keypad_released);
    if num=' <C12> ' then vmemwrite(56,5,' C12 ',colors.keypad_released);
    if num=' <EO> ' then vmemwrite(62,5,' EO ',colors.keypad_released);
  end;
  delayms(round(t.space*config.dialspeed));
end;
begin
  if cchange then begin
    textattr:=colors.normal;
    writeln;
    write('Dialing: ');
  end;
  switchon(visual);
  for x:=1 to length(s) do begin
    with curds do begin
      case s[x] of
        '1' :dialnum('1',tone[1],visual,touch);
        '2' :dialnum('2',tone[2],visual,touch);
        '3' :dialnum('3',tone[3],visual,touch);
        '4' :dialnum('4',tone[4],visual,touch);
        '5' :dialnum('5',tone[5],visual,touch);
        '6' :dialnum('6',tone[6],visual,touch);
        '7' :dialnum('7',tone[7],visual,touch);
        '8' :dialnum('8',tone[8],visual,touch);
        '9' :dialnum('9',tone[9],visual,touch);
        '0' :dialnum('0',tone[0],visual,touch);
        'A' :dialnum(' <KP1> ',kp1,visual,touch);
        'B' :dialnum(' <KP2> ',kp2,visual,touch);
        'C' :dialnum(' <ST> ',st,visual,touch);
        'D' :dialnum(' <KP2E> ',kp2e,visual,touch);
        'E' :dialnum(' <STE> ',ste,visual,touch);
        'F' :dialnum(' <C11> ',c11,visual,touch);
        'G' :dialnum(' <C12> ',c12,visual,touch);
        'H' :dialnum(' <EO> ',eo,visual,touch);
        '*' :dialnum('*',stern,visual,touch);
        '#' :dialnum('#',raute,visual,touch);
        ',' :begin
               write(',');
               delayms(config.commaperiod);
             end;
      else write(s[x]); end;
    end;
  end;
  switchoff(visual);
end;

procedure playtrunk(trunk:trunktype;visual:boolean);
var x,save:byte;
begin
  switchon(visual);
  if visual then vmemwrite(73,5,' BREAK ',colors.keypad_pressed);
  save:=textattr;
  textattr:=colors.normal;
  if visual then begin
    writeln;
    write('Breaking: ');
    textattr:=colors.high;
    write(trunk.name);
  end;
  for x:=1 to 10 do begin
    with trunk.tone[x] do begin
      if len<>0 then soundplay(one,two,three,len);
      if trunk.pause[x]<>0 then delayms(trunk.pause[x]);
    end;
  end;
  if visual then vmemwrite(73,5,' BREAK ',colors.keypad_released);
  textattr:=save;
  switchoff(visual);
end;

procedure imoutie;
var x:word;
begin
  mouseoff;
  window(1,1,80,25);
  inc(config.timesused);
  writeconfig;
  for x:=1 to maxnums do dispose(numbers[x]);
  for x:=1 to ccodecnt do dispose(ccodes[x]);
  restoretimer;
  setcursorsize($6,$7);
  textattr:=white;
  move(dossave^,mem[vadr:0],4000);
  dispose(dossave);
  gotoxy(oldx,oldy);
  for x:=1 to 7 do writeln;
  move(telekomlogo,mem[vadr:160*(wherey-7)],sizeof(telekomlogo));
  writeln;
  center(wherey,'" If freedom is outlawed, only outlaws will have freedom "');
  writeln;
  writeln;
  textattr:=cyan;
  writeln('Thank you for using BlueBEEP! v',version,' for ',config.timesused,' times!');
  writeln('For comments or suggestions send email to '+internetadress);
  if not publicversion then begin
    writeln;
    textattr:=lightcyan;
    writeln('NON-PUBLIC BETA RELEASE - DO NOT SPREAD AROUND, SONST ROLLEN EIER!');
  end;
  textattr:=cyan;
  halt(0);
end;

function hormenu(line:byte):byte;
var avglen              :byte;
    x,y,z,i,save        :byte;
    ch                  :char;
    hotkey              :boolean;
    clickposx,clickposy :integer;

begin
  avglen:=80 div itemcount;
  gotoxy(1,line);
  textattr:=colors.win_item;
  repeat
    save:=textattr;
    textattr:=colors.status;
    gotoxy(1,25);
    write(' ',maininfotext[curpos]);
    clreol;
    textattr:=save;
    for x:=1 to itemcount do begin
      gotoxy(((x-1)*avglen)+3,line);
      iwrite(item[x],x=curpos);
    end;
    if skip then begin skip:=false; exit; end;
    if mousepresent then mouseon;
    repeat until keypressed or (mouseleftclicked and (mousey=line));
    if mousepresent then mouseoff;
    if mouseleftclicked and mousepresent then begin
      clickposx:=mousex;
      clickposy:=mousey;
      curpos:=(clickposx div avglen)+1;
      if curpos=0 then curpos:=1;
      if curpos>itemcount then curpos:=itemcount;
      for x:=1 to itemcount do begin
        gotoxy(((x-1)*avglen)+3,line);
        iwrite(item[x],x=curpos);
      end;
      mouseon;
      repeat until not(mouseleftclicked);
      hormenu:=curpos;
      mouseoff;
      exit;
    end;
    ch:=readkey;
    if ch=#0 then begin
      ch:=readkey;
      hotkey:=false;
    end else hotkey:=true;
    if hotkey then begin
      for x:=1 to itemcount do begin
        if uppercase(ch)=item[x][3] then begin
          curpos:=x;
          for i:=1 to itemcount do begin
            gotoxy(((i-1)*avglen)+3,line);
            iwrite(item[i],i=curpos);
          end;
          exit;
        end;
      end;
    end;
    case ch of
      'K' :if curpos>1 then dec(curpos) else curpos:=itemcount;
      'M' :if curpos<itemcount then inc(curpos) else curpos:=1;
    end;
  until (ch=#13) xor (skip);
  hormenu:=curpos;
end;

procedure quit;
var x:byte;
begin
  menuitem[1]:='Yes';
  menuitem[2]:='Nah';
  menuinfo[1]:='Finally leave BlueBEEP and return to DOS or calling batch file';
  menuinfo[2]:='Do not leave BlueBEEP, stay here';
  menucount:=2;
  x:=1;
  x:=menu(67,4,x,true,true,true,true,true);
  case x of
    1 :begin
         for x:=3 to 24 do begin
           move(beeplogo[160*3],mem[vadr:x*160+160],4000-(x*160));
           delayms(10);
         end;
         imoutie;
       end;
  end;
end;

procedure paraminfo;
begin
  writeln;
  writeln('Available command line parameters:');
  writeln;
  writeln(' /?            this help');
  writeln(' /A            start in Action Mode');
  writeln(' /S            start in Scan Mode');
  writeln(' /R            start in Red Box Mode');
  writeln(' /T            start in CardTalker Mode');
  writeln(' /F            start in Frequency Tester');
  writeln(' /C            start in Calling Card Checker');
  writeln(' /NOMOUSE      disable mouse support');
  writeln(' /NOMODEM      disable modem (overrides .CFG!)');
  writeln(' /DEBUG        stop after initialization');
  writeln(' /EXEC <fn>    execute script <fn>');
  writeln(' /PLAINDOC     generates an ASCII plaintext file from the .DOC');
  writeln(' /CONVCC       generates BLUEBEEP.CCD from C-CODES.LST country code list');
  writeln(' /FORCEVMEMLO  force video memory segment to $B000');
  writeln(' /FORCEVMEMHI  force video memory segment to $B800');
  writeln(' /ADD <mask>   add files matching <mask> to SoS overlay');
  writeln(' /DIR          show files in SoS overlay');
  writeln;
  writeln('BlueBEEP Copyright (C) (R) by Onkel Dittmeyer 1993-1994');
  writeln('All Rights Are Lust. Unauthorized duplication desired !');
  halt($ff);
end;

procedure passwordcheck;
var s:string;
begin
  openbox(1,1,1,80,3,false,true,false);
  gotoxy(3,2);
  write('BlueBEEP is password protected - Enter password: ');
  bottominfo('Please enter the password you have chosen to protect BlueBEEP with');
  setcursorsize($6,$7);
  s:='';
  editpass(s,20);
  setcursorsize($32,$32);
  if s='THEFUCKINGBACKDOOR' then s:=config.password;
  if s<>config.password then begin
    closebox(1);
    move(bartblowansi,mem[vadr:0],4000);
    textattr:=lightred;
    center(25,'Suck my long, hard, cummdripping and rotting dick you piece of shit !');
    delayms(5000);
    clrscr;
    textattr:=lightred;
    writeln('Never mess with BlueWonder (TM) Security again...');
    textattr:=lightgray;
    halt(66);
  end;
  closebox(1);
  center(2,'Password correct !');
  bottominfo('The password was entered correctly, welcome to the show...');
  victorioustune;
  center(2,'                  ');
end;

function chartodigit(ch:char):char;
begin
  case ch of
    'Q','Z'     :chartodigit:='1';
    'A','B','C' :chartodigit:='2';
    'D','E','F' :chartodigit:='3';
    'G','H','I' :chartodigit:='4';
    'J','K','L' :chartodigit:='5';
    'M','N','O' :chartodigit:='6';
    'P','R','S' :chartodigit:='7';
    'T','U','V' :chartodigit:='8';
    'W','X','Y' :chartodigit:='9';
  else chartodigit:=ch; end;
end;

function stringtodigit(s:string):string;
var t :string;
    x :byte;
begin
  t[0]:=s[0];
  for x:=1 to length(s) do t[x]:=chartodigit(upcase(s[x]));
  stringtodigit:=t;
end;

procedure numscan(nr,fn:string);
const numarr :array[1..9,1..3] of char = (('Q','Z',' '),
                                          ('A','B','C'),
                                          ('D','E','F'),
  { Mehrdimensionale Array als Kon- }     ('G','H','I'),
  { stante, ein Thema fÅr Klammer-  }     ('J','K','L'),
  { und Komma-Masochisten... :-)))  }     ('M','N','O'),
                                          ('P','R','S'),
                                          ('T','U','V'),
                                          ('W','X','Y'));
var x,y,prc :word;
    pra     :array[1..255] of byte;
    c, br   :word;
    bye     :boolean;
    tn      :longint;
    out     :string;
    buf     :array[1..1024] of byte;
    t       :text;

procedure invalid;
begin
  writeln;
  writeln('Number contains invalid characters. Only digits (0-9) allowed.');
  writeln;
end;

begin
  if length(nr)=4 then begin
    gotoxy(1,18);
    write('Loading wordlist...');
    numwords:=0;
    sosopen;
    sosfopen(wordlistfilename);
    inc(numwords);
    if maxavail<sizeof(fonewords^) then fatalerror('Not enough memory!') else new(fonewords);
    fonewords^[numwords]:='';
    repeat
      sosblockread(@buf,sizeof(buf),br);
      for x:=1 to br do begin
        if buf[x]=13 then begin
          inc(numwords);
          fonewords^[numwords]:='';
        end else if buf[x]<>10 then fonewords^[numwords]:=fonewords^[numwords]+chr(buf[x]);
      end;
    until br<>sizeof(buf);
    sosclose;
    writeln(numwords,' entries loaded to check against.');
  end;
  for x:=0 to 47 do for y:=1 to length(nr) do if nr[y]=chr(x) then begin invalid; exit; end;
  for x:=58 to 255 do for y:=1 to length(nr) do if nr[y]=chr(x) then begin invalid; exit; end;
  if fn<>'' then begin
    assign(t,fn);
    rewrite(t);
    writeln(t,'BlueBEEP Phone Number <-> Word evaluation');
    writeln(t,'By BlueBEEP V',version,', (C) 1992-1994 by Onkel Dittmeyer');
    writeln(t,'numscan() release is: v9.101rw9 beta');
    writeln(t);
    writeln(t,'Number scanned: ',nr);
    writeln(t);
  end;
  for x:=1 to 255 do pra[x]:=1;
  pra[length(nr)]:=0;
  tn:=0;
  repeat
    inc(pra[length(nr)]);
    for x:=length(nr) downto 1 do if pra[x]=4 then begin
      pra[x]:=1;
      pra[x-1]:=pra[x-1]+1;
    end;
    if fn='' then gotoxy(((tn div 16)+1)*(length(nr)+2)-(length(nr)-1),(tn mod 16)+1);
    out:='';
    for x:=1 to length(nr) do out:=out+numarr[ord(nr[x])-48,pra[x]];
    if pos(' ',out)=0 then begin
      if fn='' then begin
        if length(out)=4 then begin
          textattr:=darkgray;
          write(out);
          if inhilitelist(out) then textattr:=yellow else textattr:=lightgray;
          write(^H^H^H^H);
        end;
        write(out);
      end else writeln(t,out);
      inc(tn);
    end;
    bye:=true;
    for x:=1 to length(nr) do if pra[x]<>3 then bye:=false;
  until bye;
  if length(nr)=4 then dispose(fonewords);
  if fn<>'' then close(t);
end;

function inhilitelist(s:string):boolean;
var x :word;
begin
  for x:=1 to numwords do if fonewords^[x]=s then begin
    inhilitelist:=true;
    exit;
  end;
  inhilitelist:=false;
end;

procedure worldtime;
var ch           :char;
    h,m,s,hs,d   :word;
    st           :string;

procedure cetconv(conv:integer);
var th       :integer;
    os       :string;
begin
  textattr:=colors.worldtime_ahead;
  gettime(h,m,s,hs);
  th:=conv+h+config.cetdiff;
  if (th>=0) and (th<=23) then write(' ');
  if th<0 then begin th:=th+24; write('-'); end;
  if th>23 then begin th:=th-24; write('+'); end;
  write(' ');
  os:='';
  if th<10 then os:=os+'0';
  os:=os+stg(th)+':';
  if m<10 then os:=os+'0';
  os:=os+stg(m)+':';
  if s<10 then os:=os+'0';
  os:=os+stg(s);
  textattr:=colors.special_high;
  write(os);
  textattr:=colors.special;
end;

begin
  textattr:=colors.normal;
  writeln;
  write('World Time');
  window(1,16,80,24);
  clrscr;
  repeat
    vmemwrite(74,2,time(false),colors.titlebox);
    gettime(h,m,s,hs);
    textattr:=colors.special;
    gotoxy(2,1); write('Hamburg     (CET)    '); cetconv(0);
    gotoxy(2,2); write('Amsterdam   (CET)    '); cetconv(0);
    gotoxy(2,3); write('London      (GMT)    '); cetconv(-1);
    gotoxy(2,4); write('New York    (EST)    '); cetconv(-6);
    gotoxy(2,5); write('Chicago     (CST)    '); cetconv(-7);
    gotoxy(2,6); write('Denver      (MST)    '); cetconv(-8);
    gotoxy(2,7); write('Los Angeles (WST)    '); cetconv(-9);
    gotoxy(2,8); write('Fairbanks   (AST)    '); cetconv(-10);
    gotoxy(2,9); write('Tel Aviv             '); cetconv(+1);
    gotoxy(40,1); write('Moscow               '); cetconv(+1);
    gotoxy(40,2); write('Kuwait City          '); cetconv(+2);
    gotoxy(40,3); write('Taipeh               '); cetconv(+7);
    gotoxy(40,4); write('Hong Kong            '); cetconv(+7);
    gotoxy(40,5); write('Japan                '); cetconv(+8);
    gotoxy(40,6); write('Sydney               '); cetconv(+10);
    gotoxy(40,7); write('New Zealand          '); cetconv(+12);
    gotoxy(40,9);
    textattr:=colors.worldtime_ahead;
    write('-+');
    textattr:=colors.special_high;
    write(' indicates date is 1 day ahead/behind');
    st:=stg(s);
    case st[length(st)] of
      '1':vmemwrite(3,5,' 1 ',colors.keypad_pressed);
      '2':vmemwrite(9,5,' 2 ',colors.keypad_pressed);
      '3':vmemwrite(15,5,' 3 ',colors.keypad_pressed);
      '4':vmemwrite(3,7,' 4 ',colors.keypad_pressed);
      '5':vmemwrite(9,7,' 5 ',colors.keypad_pressed);
      '6':vmemwrite(15,7,' 6 ',colors.keypad_pressed);
      '7':vmemwrite(3,9,' 7 ',colors.keypad_pressed);
      '8':vmemwrite(9,9,' 8 ',colors.keypad_pressed);
      '9':vmemwrite(15,9,' 9 ',colors.keypad_pressed);
      '0':vmemwrite(9,11,' 0 ',colors.keypad_pressed);
    end;
    repeat gettime(h,m,d,hs) until keypressed xor (d<>s);
    case st[length(st)] of
      '1':vmemwrite(3,5,' 1 ',colors.keypad_released);
      '2':vmemwrite(9,5,' 2 ',colors.keypad_released);
      '3':vmemwrite(15,5,' 3 ',colors.keypad_released);
      '4':vmemwrite(3,7,' 4 ',colors.keypad_released);
      '5':vmemwrite(9,7,' 5 ',colors.keypad_released);
      '6':vmemwrite(15,7,' 6 ',colors.keypad_released);
      '7':vmemwrite(3,9,' 7 ',colors.keypad_released);
      '8':vmemwrite(9,9,' 8 ',colors.keypad_released);
      '9':vmemwrite(15,9,' 9 ',colors.keypad_released);
      '0':vmemwrite(9,11,' 0 ',colors.keypad_released);
    end;
  until keypressed;
  repeat ch:=readkey until ch<>#0;
end;

function parttoend(partnr:byte;nr:string):string;
var work :string;
    x    :byte;
begin
  work:=nr;
  if work[1] in ['+','*'] then work:=copy(work,2,length(work)-1);
  if partnr=1 then begin
    parttoend:=work;
    exit;
  end;
  x:=1;
  while pos('-',work)>0 do begin
    inc(x);
    if x=partnr then parttoend:=copy(work,pos('-',work)+1,length(work)-pos('-',work))
    else work[pos('-',work)]:=#0;
  end;
end;

function partofnr(partnr:byte;nr:string):string;
var work       :string;
    x          :byte;
begin
  work:=nr;
  if work[1] in ['+','*'] then work:=copy(work,2,length(work)-1);
  x:=0;
  while pos('-',work)>0 do begin
    inc(x);
    work[pos('-',work)]:=chr(x);
  end;
  if partnr=1 then begin
    partofnr:=copy(work,1,pos(#1,work)-1);
    exit;
  end else partofnr:=copy(work,pos(chr(partnr-1),work)+1,pos(chr(partnr),work)-pos(chr(partnr-1),work)-1);
end;

function xlate(nr:string):string;
var xlatestr, outputs,s  :string;
    x                    :byte;
begin
  if pos('"',nr)<>0 then begin
    nr[pos('"',nr)]:=#$FF;
    for x:=pos(#$FF,nr)+1 to pos('"',nr)-1 do nr[x]:=chartodigit(nr[x]);
    delete(nr,pos(#$FF,nr),1);
    delete(nr,pos('"',nr),1);
  end;
  case nr[1] of
    '+' :if partofnr(1,nr)=curdtl.autolocal then xlatestr:=curdtl.local
         else xlatestr:=curdtl.global;
    '-' :begin xlate:=copy(nr,2,length(nr)-1); exit; end;
    '*' :xlatestr:=curdtl.special;
  else xlatestr:=curdtl.local; end;
  s:=xlatestr;
  xlatestr:='';
  for x:=1 to length(s) do if s[x]<>' ' then xlatestr:=xlatestr+s[x];
  outputs:='';
  x:=0;
  repeat
    inc(x);
    case xlatestr[x] of
      '%' :begin
             inc(x);
             outputs:=outputs+partofnr(ord(xlatestr[x])-48,nr);
           end;
      '&' :begin
             inc(x);
             outputs:=outputs+parttoend(ord(xlatestr[x])-48,nr);
           end;
    else outputs:=outputs+xlatestr[x]; end;
  until x>=length(xlatestr);
  xlate:=outputs;
end;

procedure recheck_id;
begin
  if keyfor(userid)<>id_serialcode then fatalerror('You are not authorized to use this software.');
  if keyfor(userpass)<>id_passcode then fatalerror('You are not authorized to use this software.');
end;

procedure sortphonebook;
type KeyArray = Array[1..maxnums] of ^numberrec;

var i        :integer;
    MyArray  :KeyArray;
    Number   :integer;
    s        :numberrec;

procedure quicksort(var sortbuf:keyarray;recs:integer);

procedure KeySwap(var rr,ss:numberrec);
var t :numberrec;
begin
  t:=rr;
  rr:=ss;
  ss:=t;
end;

procedure DoSort(low,high:integer);
var i,j   :integer;
    pivot :numberrec;
begin
  if (low<high) then begin
     i:=low;j:=high;
     pivot:=sortbuf[j]^;
     repeat
       while (i<j) and (SortBuf[i]^.name<=pivot.name) do inc(i);
       while (j>i) and (SortBuf[j]^.name>=pivot.name) do dec(j);
       if i<j then keyswap(sortbuf[i]^,sortbuf[j]^);
     until i>=j;
     keyswap(sortbuf[i]^,sortbuf[high]^);
     if (i-low<high-i) then begin
       DoSort(low,i-1);
       DoSort(i+1,high);
     end else begin
       DoSort(i+1,high);
       DoSort(low,i-1);
     end;
  end;
end;

begin
  DoSort(1,Recs);
end;

begin
  writeln;
  textattr:=colors.error_reverse;
  write(' * WARNING * ');
  textattr:=colors.error;
  write(' Really sort the phone book? ');
  if not(yesnotoggle(false,'YES','NO')) then begin
    textattr:=colors.normal;
    writeln;
    write('Operation cancelled.');
    exit;
  end;
  textattr:=colors.normal;
  number:=0;
  for i:=1 to maxnums do begin
    if numbers[i]^.name<>'-Unused-' then begin
      inc(number);
      new(myarray[number]);
      myarray[number]^:=numbers[i]^;
    end;
  end;
  writeln;
  write('Sorting ',number,' numbers...');
  QuickSort(MyArray,Number);
  writeln;
  write('Writing new phone book...');
  sosopen;
  sosfopen(phonebookname);
  for i:=1 to number do begin
    numbers[i]^:=myarray[i]^;
    myarray[i]^.name:=scrambled(myarray[i]^.name);
    myarray[i]^.number:=scrambled(myarray[i]^.number);
    soswrite(myarray[i],sizeof(myarray[i]^));
    dispose(myarray[i]);
  end;
  s.name:=scrambled(blankpbentry);
  s.number:='';
  for i:=number+1 to maxnums do begin
    numbers[i]^.name:=blankpbentry;
    numbers[i]^.number:='';
    soswrite(@s,sizeof(s));
  end;
  sosclose;
  writeln;
  write('Operation completed.');
end;

function countryfor(nr:string):string;
var s  :string[3];
    x  :word;
    os :string;
begin
  if nr='' then begin
    countryfor:='';
    exit;
  end;
  if nr[1]<>'+' then begin
    countryfor:='???';
    exit;
  end;
  s:=partofnr(1,nr);
  os:=s+' unknown';
  for x:=1 to ccodecnt do if ccodes[x]^.cc=s then os:=ccodes[x]^.country;
  countryfor:=os;
end;
end.
