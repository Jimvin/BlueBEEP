unit bbp_pom;

interface

procedure phreakoutmenu;
procedure phreakout;
procedure scanmode;
procedure redboxit;
procedure cardtalker;
procedure freqtester;
procedure cardchecker;

implementation

uses crt, extras, grwins, bbp_vars, editrout, video, types, ferror,
     bbp_proc, sbvoice, grmenus, bitmani, pdial, mouseio, optimer,
     bbunit, vgagraph, sos;

procedure editnumber(nr:word);
var s:string;
    save:byte;
    x:word;
begin
  textattr:=colors.normal;
  writeln;
  write('Editing Phone Number');
  window(1,1,80,25);
  setcursorsize($6,$7);
  save:=textattr; textattr:=colors.high;
  openbox(3,15,16,65,22,true,true,false);
  gotoxy(34,16);
  textattr:=colors.win_title;
  write(' Edit Number ');
  textattr:=colors.reverse;
  center(21,'    Use [0..9], *, #, ABCDEFGH for the number    ');
  textattr:=colors.win_text;
  gotoxy(19,18); write('Name: ',numbers[nr]^.name);
  gotoxy(17,19); write('Number: ',numbers[nr]^.number);
  s:=numbers[nr]^.name; gotoxy(25,18); edit(s,35); numbers[nr]^.name:=s;
  s:=numbers[nr]^.number; gotoxy(25,19); edituc(s,20); numbers[nr]^.number:=s;
  closebox(3);
  textattr:=save;
  setcursorsize($32,$32);
  sosopen;
  sosfopen(phonebookname);
  sosseek(sizeof(numberrec)*(nr-1));
  numbers[nr]^.name:=scrambled(numbers[nr]^.name);
  numbers[nr]^.number:=scrambled(numbers[nr]^.number);
  soswrite(numbers[nr],sizeof(numberrec));
  numbers[nr]^.name:=scrambled(numbers[nr]^.name);
  numbers[nr]^.number:=scrambled(numbers[nr]^.number);
  sosclose;
  window(18,14,79,14);
end;

procedure refreshnums;
var x:word;
begin
  window(1,16,80,24);
  for x:=1 to pagesize do begin
    if firstonpage-1+x=current then
      if numflags[firstonpage-1+x] then textattr:=colors.special_reverse_high
        else textattr:=colors.special_reverse
      else if numflags[firstonpage-1+x] then textattr:=colors.worldtime_ahead
    else textattr:=colors.special;
    gotoxy(1,x);
    if x+firstonpage-1<=maxnums then begin
      write(x+firstonpage-1:3,'  ');
      write(numbers[x+firstonpage-1]^.name);
      for y:=1 to 38-length(numbers[x+firstonpage-1]^.name) do write(' ');
      write(numbers[x+firstonpage-1]^.number);
      for y:=1 to 24-length(numbers[x+firstonpage-1]^.number) do write(' ');
      write(countryfor(numbers[x+firstonpage-1]^.number));
    end;
    clreol;
  end;
  textattr:=colors.normal;
  window(18,14,79,14);
end;

procedure scanmode;
var x                 :word;
    bufstring,bla,tmp :string;
    ch                :char;
begin
  move(mem[vadr:0],save,4000);
  textattr:=colors.normal;
  clrscr;
  openbox(1,1,1,80,3,false,true,false);
  openbox(2,1,23,80,25,false,true,false);
  textattr:=colors.win_text_high;
  center(2,'SCAN MODE');
  textattr:=colors.special_high; gotoxy(5,5); write('Scan String (see docs for details)');
  textattr:=colors.dark; for x:=1 to 50-wherex do write('.');
  textattr:=colors.high2; write(curscan.scanstring);
  textattr:=colors.special_high; gotoxy(5,6); write('Quick Macro');
  textattr:=colors.dark; for x:=1 to 50-wherex do write('.');
  textattr:=colors.high2; write(curscan.quickmacro);
  textattr:=colors.special_high; gotoxy(5,7); write('How many digits to scan');
  textattr:=colors.dark; for x:=1 to 50-wherex do write('.');
  textattr:=colors.high2; write(curscan.digits);
  textattr:=colors.special_high; gotoxy(5,8); write('Current scan is at');
  textattr:=colors.dark; for x:=1 to 50-wherex do write('.');
  textattr:=colors.high2; write(curscan.progress);
  textattr:=colors.special_high; gotoxy(5,9); write('Auto-Increase');
  textattr:=colors.dark; for x:=1 to 50-wherex do write('.');
  textattr:=colors.high2; write(onoff[curscan.ai]);
  textattr:=colors.special_high; gotoxy(5,10); write('Macro Redial Count (0=off)');
  textattr:=colors.dark; for x:=1 to 50-wherex do write('.');
  textattr:=colors.high2; write(curscan.redialcount);
  textattr:=colors.special_high; gotoxy(5,11); write('Macro Redial Count-Up');
  textattr:=colors.dark; for x:=1 to 50-wherex do write('.');
  textattr:=colors.high2; write(curscan.redialprog);
  textattr:=colors.special_high; gotoxy(5,12); write('Strip leading zeroes');
  textattr:=colors.dark; for x:=1 to 50-wherex do write('.');
  textattr:=colors.high2; if curscan.stripzeroes then write('Yes') else write('No');
  textbackground(colors.win_background);
  gotoxy(3,24);
  cwrite('|Y'^X^Y' |WInc/Dec  |YCR |WDial  |Y+ |WSend Break  |YF1 |WEdit settings  |YM |WDial Macro   |YESC |WQuit');
  repeat
    repeat vmemwrite(74,2,time(false),colors.win_text) until keypressed;
    ch:=upcase(readkey);
    if ch=#0 then ch:=readkey;
    case ch of
      CurUp :begin textattr:=colors.high2; inc(curscan.progress); gotoxy(50,8); write(curscan.progress,'  '); end;
      CurDn :begin textattr:=colors.high2; dec(curscan.progress); gotoxy(50,8); write(curscan.progress,'  '); end;
      '+'   :playtrunk(curtrunk,false);
      'M'   :begin
               gotoxy(3,16);
               clreol;
               gotoxy(3,15);
               dial(curscan.quickmacro,false,false,true);
             end;
      Return:begin
               textattr:=colors.normal;
               gotoxy(3,16);
               clreol;
               gotoxy(3,15);
               str(curscan.progress,bufstring);
               if not(curscan.stripzeroes) then
                 for x:=1 to curscan.digits-length(bufstring) do bufstring:='0'+bufstring;
               tmp:='';
               for x:=1 to length(curscan.scanstring) do begin
                 if curscan.scanstring[x]<>'X' then
                 tmp:=tmp+curscan.scanstring[x] else
                 tmp:=tmp+bufstring;
               end;
               dial(tmp,false,false,true);
               clreol;
               if curscan.ai then begin
                 textattr:=colors.high2;
                 inc(curscan.progress);
                 gotoxy(50,8);
                 write(curscan.progress,'  ');
               end;
               if curscan.redialcount<>0 then begin
                 textattr:=colors.high2;
                 inc(curscan.redialprog);
                 gotoxy(50,11);
                 write(curscan.redialprog,'  ');
                 if curscan.redialprog=curscan.redialcount then begin
                   curscan.redialprog:=0;
                   gotoxy(3,16);
                   clreol;
                   gotoxy(3,15);
                   dial(curscan.quickmacro,false,false,true);
                   textattr:=colors.high2;
                   gotoxy(50,11);
                   write(curscan.redialprog,'  ');
                 end;
               end;
             end;
      F1    :begin
               setcursorsize($6,$7);
               gotoxy(50,5); edit(curscan.scanstring,27);
               gotoxy(50,6); edit(curscan.quickmacro,27);
               gotoxy(50,7); editli(curscan.digits);
               gotoxy(50,8); editli(curscan.progress);
               if curscan.ai then bla:='Y' else bla:='N';
               gotoxy(50,9);
               write('Auto-Increase? ');
               setcursorsize($32,$32);
               curscan.ai:=yesnotoggle(curscan.ai,'Yes','No');
               setcursorsize($6,$7);
               gotoxy(50,9); write(onoff[curscan.ai]); clreol;
               gotoxy(50,10); editli(curscan.redialcount);
               gotoxy(50,11); editli(curscan.redialprog);
               setcursorsize($32,$32);
               gotoxy(50,12); write('Strip''em? '); curscan.stripzeroes:=yesnotoggle(curscan.stripzeroes,'Yes','No');
               gotoxy(50,12); if curscan.stripzeroes then write('Yes') else write('No');
               clreol;
             end;
    end;
  until ch=#27;
  sosopen;
  sosfopen(scanfilename);
  soswrite(@curscan,sizeof(curscan));
  sosclose;
  closebox(2);
  closebox(1);
  move(save,mem[vadr:0],4000);
end;

procedure phreakout;
var ch       :char;
    save,bks :array[1..4000] of byte;
    mx,my    :integer;
    spkey    :boolean;
    testbyte :byte;
    v        :voicefile;
    s        :string;
    i,x      :word;

procedure selecttrunk;
var res       :byte;
    worktrunk :trunktype;
    x         :word;
begin
  setcursorsize($32,$32);
  textattr:=colors.normal;
  writeln;
  write('Selecting new trunk');
  window(1,1,80,25);
  res:=config.curtrunk;
  sosopen;
  sosfopen(trunkfilename);
  for x:=1 to maxtrunks do begin
    sosread(@worktrunk,sizeof(worktrunk));
    menuitem[x]:=worktrunk.name;
    menuinfo[x]:=worktrunk.description;
  end;
  sosclose;
  menucount:=maxtrunks;
  res:=menu(1,4,res,true,true,true,false,true);
  if res<>0 then begin
    config.curtrunk:=res;
    sosopen;
    sosfopen(trunkfilename);
    sosseek(sizeof(trunktype)*(res-1));
    sosread(@curtrunk,sizeof(curtrunk));
    sosclose;
    for x:=18 to 28 do vmemwrite(x,2,' ',colors.titlebox);
    vmemwrite(18,2,curtrunk.name,colors.titlebox);
    window(18,14,79,14);
    write('Trunk: ',curtrunk.name,', ',curtrunk.description);
    clreol;
  end else begin
    window(18,14,79,14);
  end;
  setcursorsize($6,$7);
end;

procedure selectset;
var res     :byte;
    workset :dialsettype;
    x       :word;
begin
  setcursorsize($32,$32);
  textattr:=colors.normal;
  writeln;
  write('Selecting new Dial Set');
  window(1,1,80,25);
  res:=config.curdset;
  sosopen;
  sosfopen(dsfilename);
  for x:=1 to maxdialsets do begin
    sosread(@workset,sizeof(workset));
    menuitem[x]:=workset.standard;
    menuinfo[x]:=workset.description;
  end;
  sosclose;
  menucount:=maxdialsets;
  res:=menu(1,4,res,true,true,true,false,true);
  if res<>0 then begin
    config.curdset:=res;
    sosopen;
    sosfopen(dsfilename);
    sosseek(sizeof(dialsettype)*(res-1));
    sosread(@curds,sizeof(curds));
    sosclose;
    for x:=72 to 79 do vmemwrite(x,8,' ',colors.high);
    vmemwrite(72,8,curds.standard,colors.high);
    window(18,14,79,14);
    clrscr;
    write('Dialset: ',curds.standard,', ',curds.description);
    clreol;
  end else begin
    window(18,14,79,14);
    clrscr;
  end;
  setcursorsize($6,$7);
end;

procedure selectdtl;
var res     :byte;
    workrec :dtltype;
    x       :word;
begin
  setcursorsize($32,$32);
  textattr:=colors.normal;
  writeln;
  write('Selecting new dial translation');
  window(1,1,80,25);
  res:=config.activedtl;
  sosopen;
  sosfopen(dtlfilename);
  for x:=1 to maxdtlsets do begin
    sosread(@workrec,sizeof(workrec));
    menuitem[x]:=workrec.name;
    menuinfo[x]:=workrec.note;
  end;
  sosclose;
  menucount:=maxdtlsets;
  res:=menu(1,4,res,true,true,true,false,true);
  if res<>0 then begin
    config.activedtl:=res;
    sosopen;
    sosfopen(dtlfilename);
    sosseek(sizeof(dtltype)*(res-1));
    sosread(@curdtl,sizeof(curdtl));
    sosclose;
    for x:=44 to 61 do vmemwrite(x,8,' ',colors.high);
    vmemwrite(44,8,curdtl.name,colors.high);
    window(18,14,79,14);
    clrscr;
    write('Dial Translation: ',curdtl.name,', ',curdtl.note);
    clreol;
  end else begin
    window(18,14,79,14);
    clrscr;
  end;
  setcursorsize($6,$7);
end;

procedure insertentry;
var x:word;
begin
  window(18,14,79,13);
  clrscr;
  if numbers[maxnums]^.name<>'-Unused-' then begin
    textattr:=colors.error_reverse;
    write(' * WARNING * ');
    textattr:=colors.error;
    write(' Entry #',maxnums,' will be pushed out, do it?');
    if not(yesnotoggle(false,'YES','NO')) then begin
      textattr:=colors.normal;
      writeln;
      write('Operation cancelled.');
      exit;
    end;
  end;
  textattr:=colors.normal;
  write('Inserting blank entry at position #',current,'...');
  for x:=maxnums downto current+1 do numbers[x]^:=numbers[x-1]^;
  numbers[current]^.number:='';
  numbers[current]^.name:='-Unused-';
  refreshnums;
  textattr:=colors.normal;
  write('Rewriting phone book after entry insert...');
  sosopen;
  sosfopen(phonebookname);
  for x:=1 to maxnums do begin
    numbers[x]^.name:=scrambled(numbers[x]^.name);
    numbers[x]^.number:=scrambled(numbers[x]^.number);
    soswrite(numbers[x],sizeof(numberrec));
    numbers[x]^.name:=scrambled(numbers[x]^.name);
    numbers[x]^.number:=scrambled(numbers[x]^.number);
  end;
  sosclose;
  write('OK');
end;

procedure deleteentry;
var x :word;
begin
  window(18,14,79,14);
  clrscr;
  if numbers[current]^.name<>'-Unused-' then begin
    textattr:=colors.error_reverse;
    write(' * WARNING * ');
    textattr:=colors.error;
    write(' Delete phonebook entry #',current,' ? ');
    if not(yesnotoggle(false,'YES','NO')) then begin
      textattr:=colors.normal;
      writeln;
      write('Operation cancelled.');
      exit;
    end;
  end;
  textattr:=colors.normal;
  write('Deleting number #',current,'...');
  for x:=current to maxnums-1 do numbers[x]^:=numbers[x+1]^;
  numbers[maxnums]^.number:='';
  numbers[maxnums]^.name:='-Unused-';
  refreshnums;
  textattr:=colors.normal;
  write('Rewriting new phone book after deletion...');
  sosopen;
  sosfopen(phonebookname);
  for x:=1 to maxnums do begin
    numbers[x]^.name:=scrambled(numbers[x]^.name);
    numbers[x]^.number:=scrambled(numbers[x]^.number);
    soswrite(numbers[x],sizeof(numberrec));
    numbers[x]^.name:=scrambled(numbers[x]^.name);
    numbers[x]^.number:=scrambled(numbers[x]^.number);
  end;
  sosclose;
  write('OK');
end;

procedure pleasewait;
begin
  textattr:=colors.normal;
  writeln;
  if not(config.gotblaster) then begin
    write('SoundBlaster not installed correctly!');
    exit;
  end;
  write('Saying "Please wait"');
  switchon(true);
  fixdriver('CT-VOICE.DRV',0);
  if initblaster(config.sbint,config.sbaddr)<>0 then
    fatalerror('SB Init Failure!');
  loadvoice('wait.voc',v,0);
  playvoice(v);
  repeat until status=0;
  killvoice(v);
  switchoff(true);
  removedriver;
end;

procedure recordquick;
begin
  textattr:=colors.normal;
  writeln;
  if not(config.gotblaster) then begin
    write('SoundBlaster not installed correctly!');
    exit;
  end;
  write('Recording Quick Sample, press any key to end...');
  fixdriver('CT-VOICE.DRV',0);
  if initblaster(config.sbint,config.sbaddr)<>0 then
    fatalerror('SB Init Failure!');
  recordvoice('QUICK.VOC',12000,0);
  removedriver;
end;

procedure replayquick;
begin
  textattr:=colors.normal;
  writeln;
  if not(config.gotblaster) then begin
    write('SoundBlaster not installed correctly!');
    exit;
  end;
  write('Replaying Quick Sample...');
  switchon(true);
  fixdriver('CT-VOICE.DRV',0);
  if initblaster(config.sbint,config.sbaddr)<>0 then
    fatalerror('SB Init Failure!');
  loadvoice('quick.voc',v,0);
  playvoice(v);
  repeat until status=0;
  killvoice(v);
  switchoff(true);
  removedriver;
end;

procedure searchphonebook;
var s :string;
    i :word;
begin
  textattr:=colors.normal;
  writeln;
  write('Search for:');
  s:='';
  edituc(s,40);
  if s='' then begin
    writeln;
    write('Operation cancelled.');
    exit;
  end;
  i:=1;
  writeln;
  textattr:=colors.normal;
  write('Searching for ');
  textattr:=colors.high;
  write(s);
  textattr:=colors.normal;
  write('...');
  while not ((pos(s,uppercase(numbers[i]^.name))<>0) or (i>(maxnums-1))) do inc(i);
  if (i=maxnums) and (pos(s,uppercase(numbers[i]^.name))=0) then begin
    textattr:=colors.error;
    writeln;
    write('Nothing found.');
  end else begin
    writeln;
    write('Match found at position #',i);
    firstonpage:=i;
    current:=i;
    refreshnums;
  end;
end;

procedure vtdialchar(character:char);
var ch:char;
begin
  ch:=character;
  if ch='Å' then ch:='ö';
  if ch='Ñ' then ch:='é';
  if ch='î' then ch:='ô';
  if not(ch in [#13,^H,'#']) then write(ch);
  case ch of
    'A' :dial('10',true,false,false);
    'B' :dial('11',true,false,false);
    'C' :dial('12',true,false,false);
    'D' :dial('13',true,false,false);
    'E' :dial('14',true,false,false);
    'F' :dial('15',true,false,false);
    'G' :dial('16',true,false,false);
    'H' :dial('17',true,false,false);
    'I' :dial('18',true,false,false);
    'J' :dial('19',true,false,false);
    'K' :dial('20',true,false,false);
    'L' :dial('21',true,false,false);
    'M' :dial('22',true,false,false);
    'N' :dial('23',true,false,false);
    'O' :dial('24',true,false,false);
    'P' :dial('25',true,false,false);
    'Q' :dial('26',true,false,false);
    'R' :dial('27',true,false,false);
    'S' :dial('28',true,false,false);
    'T' :dial('29',true,false,false);
    'U' :dial('30',true,false,false);
    'V' :dial('31',true,false,false);
    'W' :dial('39',true,false,false);
    'X' :dial('32',true,false,false);
    'Y' :dial('33',true,false,false);
    'Z' :dial('34',true,false,false);
    #13 :begin dial('*0',true,false,false); writeln; end;
    '0' :dial('0*',true,false,false);
    '1' :dial('1*',true,false,false);
    '2' :dial('2*',true,false,false);
    '3' :dial('3*',true,false,false);
    '4' :dial('4*',true,false,false);
    '5' :dial('5*',true,false,false);
    '6' :dial('6*',true,false,false);
    '7' :dial('7*',true,false,false);
    '8' :dial('8*',true,false,false);
    '9' :dial('9*',true,false,false);
    ' ' :dial('55',true,false,false);
    'ö' :dial('35',true,false,false);
    'é' :dial('36',true,false,false);
    'ô' :dial('37',true,false,false);
    '.' :dial('40',true,false,false);
    ',' :dial('41',true,false,false);
    '?' :dial('42',true,false,false);
    '!' :dial('43',true,false,false);
    '"' :dial('44',true,false,false);
    '-' :dial('45',true,false,false);
    '&' :dial('46',true,false,false);
    '+' :dial('47',true,false,false);
    ':' :dial('47',true,false,false);
    ^H  :begin write(^H' '^H); dial('**',true,false,false); end;
    '#' :begin
           textattr:=colors.special_high;
           writeln(' <OK>');
           dial('#',true,false,false);
           textattr:=colors.special;
         end;
  else begin
    textattr:=colors.dark;
    write(^H,ch);
    textattr:=colors.special;
  end; end;
end;

procedure vtdialfile;
var fn :string;
    t  :text;
    x  :byte;
begin
  textattr:=colors.special_high;
  write('Filename to Xmit: ');
  fn:='MYAD.TXT';
  edituc(fn,40);
  writeln;
  writeln;
  setcursorsize($1,$7);
  if not exist(fn) then begin
    writeln('[File not found]');
    textattr:=colors.special;
    exit;
  end;
  writeln('[Xmitting '+fn+']');
  textattr:=colors.special;
  assign(t,fn);
  reset(t);
  while not eof(t) do begin
    readln(t,s);
    for x:=1 to length(s) do vtdialchar(upcase(s[x]));
    vtdialchar(#13);
  end;
  close(t);
  textattr:=colors.special_high;
  writeln('[Xmit done]');
  textattr:=colors.special;
end;

procedure vtdialer;
var ch:char;
begin
  writeln;
  write('SAT.1 Videotext Ad Dialer - A Dittmeyer Invention!');
  window(1,16,80,24);
  textattr:=colors.special_high;
  clrscr;
  writeln;
  writeln('SAT.1-TEXT KLEINANZEIGEN-DIALER - ESC to quit');
  writeln;
  writeln('Use F1 to Xmit a text file.');
  writeln;
  setcursorsize($1,$7);
  textattr:=colors.special;
  repeat
    ch:=upcase(readkey);
    if ch=#0 then begin
      ch:=readkey;
      textattr:=colors.special_high;
      case ch of
        'H' :begin write(#24); dial('*2',true,false,false); end;
        'P' :begin write(#25); dial('*8',true,false,false); end;
        'K' :begin write(#27); dial('*4',true,false,false); end;
        'M' :begin write(#26); dial('*6',true,false,false); end;
        F1  :vtdialfile;
      else begin
        textattr:=colors.dark;
        write('^',ch);
      end; end;
      textattr:=colors.special;
    end else vtdialchar(ch);
  until ch=#27;
  setcursorsize($32,$32);
  clrscr;
  refreshnums;
end;

begin
  if check_userid then recheck_id;
  move(mem[vadr:0],save,4000);
  setcursorsize($32,$32);
  textattr:=colors.normal;
  clrscr;
  openbox(1,1,1,80,3,false,false,false);   ignbox(1);
  openbox(1,1,4,19,12,false,false,false);  ignbox(1);
  openbox(1,19,4,80,12,false,false,false); ignbox(1);
  openbox(1,1,12,80,15,false,false,false); ignbox(1);
  for x:=0 to 239 do mem[vadr:x*2+1]:=colors.titlebox_border;
  for x:=2 to 78 do mem[vadr:160+(x*2+1)]:=colors.titlebox_high;
  textattr:=colors.titlebox_title;
  center(1,' BlueBEEP! Action Mode ');
  vmemwrite(19,4,'¬',colors.win_border_1);
  vmemwrite(16,12,'ƒƒ',colors.win_border_2);
  vmemwrite(18,12,'ƒ¡ƒ',colors.win_border_1);
  vmemwrite(21,12,'ƒƒ',colors.win_border_2);
  vmemwrite(1,12,'√',colors.win_border_1);
  vmemwrite(80,12,'¥',colors.win_border_1);
  vmemwrite(3,13,'Device Status:',colors.high);
  vmemwrite(3,14,'Dialer Status:',colors.high);
  vmemwrite(26,10,'Trunk',colors.normal);
  vmemwrite(26,11,'Dial Set',colors.normal);
  vmemwrite(21,8,'M/S:',colors.normal);
  vmemwrite(38,8,'Xlat:',colors.normal);
  vmemwrite(62,8,'Dial Set:',colors.normal);
  vmemwrite(44,10,'Dial Speed',colors.normal);
  vmemwrite(44,11,'Send Number',colors.normal);
  vmemwrite(64,10,'Blast Exit',colors.normal);
  vmemwrite(64,11,'Edit Number',colors.normal);
  vmemwrite(2,5,'     ≥     ≥',colors.dark);
  vmemwrite(2,6,'ƒƒƒƒƒ≈ƒƒƒƒƒ≈ƒƒƒƒƒ',colors.dark);
  vmemwrite(2,7,'     ≥     ≥',colors.dark);
  vmemwrite(2,8,'ƒƒƒƒƒ≈ƒƒƒƒƒ≈ƒƒƒƒƒ',colors.dark);
  vmemwrite(2,9,'     ≥     ≥',colors.dark);
  vmemwrite(2,10,'ƒƒƒƒƒ≈ƒƒƒƒƒ≈ƒƒƒƒƒ',colors.dark);
  vmemwrite(2,11,'     ≥     ≥',colors.dark);
  vmemwrite(4,5,'1',colors.keypad_released);
  vmemwrite(10,5,'2',colors.keypad_released);
  vmemwrite(16,5,'3',colors.keypad_released);
  vmemwrite(4,7,'4',colors.keypad_released);
  vmemwrite(10,7,'5',colors.keypad_released);
  vmemwrite(16,7,'6',colors.keypad_released);
  vmemwrite(4,9,'7',colors.keypad_released);
  vmemwrite(10,9,'8',colors.keypad_released);
  vmemwrite(16,9,'9',colors.keypad_released);
  vmemwrite(4,11,'*',colors.keypad_released);
  vmemwrite(10,11,'0',colors.keypad_released);
  vmemwrite(16,11,'#',colors.keypad_released);
  vmemwrite(20,5,'     ≥     ≥    ≥      ≥     ≥     ≥     ≥    ≥     ≥      ',colors.dark);
  vmemwrite(20,6,'ƒƒAƒƒ¡ƒƒBƒƒ¡ƒCƒƒ¡ƒƒDƒƒƒ¡ƒƒEƒƒ¡ƒƒFƒƒ¡ƒƒGƒƒ¡ƒHƒƒŸ     ¿ƒƒ + ƒƒ',colors.dark);
  vmemwrite(21,5,'KP1',colors.keypad_released);
  vmemwrite(27,5,'KP2',colors.keypad_released);
  vmemwrite(33,5,'ST',colors.keypad_released);
  vmemwrite(38,5,'KP2E',colors.keypad_released);
  vmemwrite(45,5,'STE',colors.keypad_released);
  vmemwrite(51,5,'C11',colors.keypad_released);
  vmemwrite(57,5,'C12',colors.keypad_released);
  vmemwrite(63,5,'EO',colors.keypad_released);
  vmemwrite(74,5,'BREAK',colors.keypad_released);
  vmemwrite(21,10,'[',colors.dark);
  vmemwrite(22,10,'F1',colors.super_high);
  vmemwrite(24,10,']',colors.dark);
  vmemwrite(21,11,'[',colors.dark);
  vmemwrite(22,11,'F2',colors.super_high);
  vmemwrite(24,11,']',colors.dark);
  vmemwrite(39,10,'[',colors.dark);
  vmemwrite(40,10,#27+#26,colors.super_high);
  vmemwrite(42,10,']',colors.dark);
  vmemwrite(39,11,'[',colors.dark);
  vmemwrite(40,11,'CR',colors.super_high);
  vmemwrite(42,11,']',colors.dark);
  vmemwrite(58,10,'[',colors.dark);
  vmemwrite(59,10,'F10',colors.super_high);
  vmemwrite(62,10,']',colors.dark);
  vmemwrite(58,11,'[',colors.dark);
  vmemwrite(59,11,'SPC',colors.super_high);
  vmemwrite(62,11,']',colors.dark);
  vmemwrite(3,2,'Current trunk:',colors.titlebox_high);
  vmemwrite(62,2,'Local Time:',colors.titlebox_high);
  textattr:=colors.status;
  gotoxy(1,25);
  write(' BlueBEEP! v');
  clreol;
  if mousepresent then begin
    gotoxy(26,25);
    cwrite('|'+stg(colors.status div 16)+'|d[|WScroll Up|d]   [|WScroll Down|d]');
  end;
  gotoxy(67,25);
  cwrite('|'+stg(colors.status div 16)+'|d[|YESC|d] to quit');
  window(1,15,80,15+pagesize);
  vmemwrite(26,8,stg2(config.dialspeed)+'x ',colors.high);
  vmemwrite(44,8,curdtl.name,colors.high);
  vmemwrite(72,8,curds.standard,colors.high);
  vmemwrite(18,2,curtrunk.name,colors.titlebox);
  vmemwrite(13,25,version,colors.status);
  x:=port[pdial.portadress];
  if gesetztinbyte(hookbit,x) then vmemwrite(18,13,' ON-HOOK ',colors.keypad_pressed)
    else vmemwrite(18,13,' ON-HOOK ',colors.keypad_released);
  if gesetztinbyte(playrecbit,x) then begin
    vmemwrite(28,13,' PLAY ',colors.keypad_released);
    vmemwrite(35,13,' REC ',colors.keypad_pressed);
  end else begin
    vmemwrite(28,13,' PLAY ',colors.keypad_pressed);
    vmemwrite(35,13,' REC ',colors.keypad_released);
  end;
  vmemwrite(49,13,' DIAL ',colors.keypad_released);
  if config.switchback=0 then begin
    vmemwrite(59,13,' NONE ',colors.keypad_pressed);
    vmemwrite(66,13,' REC ',colors.keypad_released);
    vmemwrite(72,13,' PHONE ',colors.keypad_released);
  end;
  if config.switchback=1 then begin
    vmemwrite(59,13,' NONE ',colors.keypad_released);
    vmemwrite(66,13,' REC ',colors.keypad_pressed);
    vmemwrite(72,13,' PHONE ',colors.keypad_released);
  end;
  if config.switchback=2 then begin
    vmemwrite(59,13,' NONE ',colors.keypad_released);
    vmemwrite(66,13,' REC ',colors.keypad_released);
    vmemwrite(72,13,' PHONE ',colors.keypad_pressed);
  end;
  if not(gesetztinbyte(phonebit,x)) then vmemwrite(41,13,' PHONE ',colors.keypad_pressed)
    else vmemwrite(41,13,' PHONE ',colors.keypad_released);
  firstonpage:=config.firstonpage;
  current:=config.curnum;
  refreshnums;
  textattr:=colors.normal;
  writeln;
  write('Welcome to BlueBEEP V',version,' - "Ready To Rock, Commander Data?"');
  repeat
    spkey:=false;
    setcursorsize($32,$32);
    if mousepresent then mouseon;
    if mousepresent then
    repeat vmemwrite(74,2,time(false),colors.titlebox) until keypressed or mouseleftclicked or mouserightclicked
    else repeat vmemwrite(74,2,time(false),colors.titlebox) until keypressed;
    if mousepresent then mouseoff;
    if mousepresent and mouserightclicked then begin
      ch:=#27;
      repeat until not(mouserightclicked);
    end;
    if mousepresent and mouseleftclicked then begin
      ch:='-';
      mx:=mousex; my:=mousey;
      if config.flipkeypad then begin
        if (mx>1) and (mx<7) and (my=5) then ch:='7';
        if (mx>7) and (mx<13) and (my=5) then ch:='8';
        if (mx>13) and (mx<19) and (my=5) then ch:='9';
        if (mx>1) and (mx<7) and (my=7) then ch:='4';
        if (mx>7) and (mx<13) and (my=7) then ch:='5';
        if (mx>13) and (mx<19) and (my=7) then ch:='6';
        if (mx>1) and (mx<7) and (my=9) then ch:='1';
        if (mx>7) and (mx<13) and (my=9) then ch:='2';
        if (mx>13) and (mx<19) and (my=9) then ch:='3';
      end else begin
        if (mx>1) and (mx<7) and (my=5) then ch:='1';
        if (mx>7) and (mx<13) and (my=5) then ch:='2';
        if (mx>13) and (mx<19) and (my=5) then ch:='3';
        if (mx>1) and (mx<7) and (my=7) then ch:='4';
        if (mx>7) and (mx<13) and (my=7) then ch:='5';
        if (mx>13) and (mx<19) and (my=7) then ch:='6';
        if (mx>1) and (mx<7) and (my=9) then ch:='7';
        if (mx>7) and (mx<13) and (my=9) then ch:='8';
        if (mx>13) and (mx<19) and (my=9) then ch:='9';
      end;
      if (mx>1) and (mx<7) and (my=11) then ch:='*';
      if (mx>7) and (mx<13) and (my=11) then ch:='0';
      if (mx>13) and (mx<19) and (my=11) then ch:='#';
      if (mx>19) and (mx<25) and (my=5) then ch:='A';
      if (mx>25) and (mx<31) and (my=5) then ch:='B';
      if (mx>31) and (mx<36) and (my=5) then ch:='C';
      if (mx>36) and (mx<43) and (my=5) then ch:='D';
      if (mx>43) and (mx<49) and (my=5) then ch:='E';
      if (mx>49) and (mx<55) and (my=5) then ch:='F';
      if (mx>55) and (mx<61) and (my=5) then ch:='G';
      if (mx>61) and (mx<66) and (my=5) then ch:='H';
      if (mx>72) and (mx<80) and (my=5) then ch:='+';
      if (mx>20) and (mx<25) and (my=10) then begin ch:=F1; spkey:=true; end;
      if (mx>20) and (mx<25) and (my=11) then begin ch:=F2; spkey:=true; end;
      if (mx>38) and (mx<41) and (my=10) then begin ch:=CurLf; spkey:=true; end;
      if (mx>40) and (mx<43) and (my=10) then begin ch:=CurRt; spkey:=true; end;
      if (mx>38) and (mx<43) and (my=11) then ch:=#13;
      if (mx>57) and (mx<63) and (my=10) then begin ch:=F10; spkey:=true; end;
      if (mx>57) and (mx<63) and (my=11) then ch:=' ';;
      if (mx>66) and (mx<72) and (my=25) then ch:=#27;
      if (mx>17) and (mx<27) and (my=13) then begin ch:=F5; spkey:=true; end;
      if (mx>27) and (mx<40) and (my=13) then begin ch:=F6; spkey:=true; end;
      if (mx>40) and (mx<53) and (my=13) then begin ch:=F7; spkey:=true; end;
      if (mx>58) and (mx<80) and (my=13) then begin ch:=#50; spkey:=true; end;
      if (mx>48) and (mx<55) and (my=13) then begin ch:='P'; spkey:=false; end;
      if (my>15) and (my<25) then begin
        current:=firstonpage+(my-16);
        refreshnums;
      end;
      if (mx>25) and (mx<37) and (my=25) then while mouseleftclicked do begin
        if current>1 then begin
          dec(current);
          if current<firstonpage then dec(firstonpage);
          refreshnums;
        end;
      end;
      if (mx>39) and (mx<53) and (my=25) then while mouseleftclicked do begin
        if current<maxnums then begin
          inc(current);
          if current-firstonpage>=pagesize then inc(firstonpage);
          refreshnums;
        end;
      end;
    end;
    if keypressed then begin
      ch:=upcase(readkey);
      if ch=#0 then begin
        ch:=readkey;
        spkey:=true;
      end;
    end;
    if spkey then case ch of
      CurDn:if current<maxnums then begin
              inc(current);
              if current-firstonpage>=pagesize then inc(firstonpage);
              refreshnums;
            end;
      CurUp:if current>1 then begin
              dec(current);
              if current<firstonpage then dec(firstonpage);
              refreshnums;
            end;
      PgUp :begin
              if current>pagesize+1 then begin
                dec(current,pagesize-1);
                if firstonpage>pagesize then dec(firstonpage,pagesize-1)
                  else firstonpage:=1;
              end else begin
                firstonpage:=1;
                current:=1;
              end;
              refreshnums;
            end;
      PgDn :begin
              if current<maxnums-pagesize then begin
                inc(current,pagesize-1);
                inc(firstonpage,pagesize-1);
              end else begin
                firstonpage:=maxnums-pagesize+1;
                current:=maxnums;
              end;
              refreshnums;
            end;
      Home :begin current:=1; firstonpage:=1; refreshnums; end;
      Endk :begin firstonpage:=maxnums-pagesize+1; current:=maxnums; refreshnums; end;
      CurRt:begin
              if config.dialspeed<100 then config.dialspeed:=config.dialspeed+speedstepsize;
              vmemwrite(26,8,stg2(config.dialspeed)+'x ',colors.high);
            end;
      CurLf :begin
               if config.dialspeed>=speedstepsize then config.dialspeed:=config.dialspeed-speedstepsize;
               vmemwrite(26,8,stg2(config.dialspeed)+'x ',colors.high);
             end;
      Ins   :InsertEntry;
      Del   :DeleteEntry;
      F1    :selecttrunk;
      F2    :selectset;
      F3    :selectdtl;
      F5    :begin
               textattr:=colors.normal;
               writeln;
               write('Toggling Device Hook Condition...');
               testbyte:=port[pdial.portadress];
               if gesetztinbyte(hookbit,testbyte) then clrportbit(hookbit,true)
                 else setportbit(hookbit,true);
             end;
      F6    :begin
               textattr:=colors.normal;
               writeln;
               write('Toggling Device Play/Record Bit Condition...');
               testbyte:=port[pdial.portadress];
               if gesetztinbyte(playrecbit,testbyte) then clrportbit(playrecbit,true)
                 else setportbit(playrecbit,true);
             end;
      F7    :begin
               textattr:=colors.normal;
               writeln;
               write('Toggling Phone Online Condition...');
               testbyte:=port[pdial.portadress];
               if gesetztinbyte(phonebit,testbyte) then clrportbit(phonebit,true)
                 else setportbit(phonebit,true);
             end;
      F8    :begin
               textattr:=colors.normal;
               writeln;
               write('Total hangup...');
               clrportbit(hookbit,true);
               setportbit(phonebit,true);
               clrportbit(playrecbit,true);
             end;
      F9    :vtdialer;
      F10   :begin
               config.curnum:=current;
               config.firstonpage:=firstonpage;
               imoutie;
             end;
      #50   :begin                        { #0+#50 = ALT-M }
               textattr:=colors.normal;
               writeln;
               write('Turning Device Mode to ');
               textattr:=colors.high;
               if config.switchback<2 then inc(config.switchback,1) else config.switchback:=0;
               case config.switchback of
                 0 :write('NONE');
                 1 :write('REC');
                 2 :write('PHONE');
               end;
               if config.switchback=0 then begin
                 vmemwrite(59,13,' NONE ',colors.knob_active);
                 vmemwrite(66,13,' REC ',colors.knob_inactive);
                 vmemwrite(72,13,' PHONE ',colors.knob_inactive);
               end;
               if config.switchback=1 then begin
                 vmemwrite(59,13,' NONE ',colors.knob_inactive);
                 vmemwrite(66,13,' REC ',colors.knob_active);
                 vmemwrite(72,13,' PHONE ',colors.knob_inactive);
               end;
               if config.switchback=2 then begin
                 vmemwrite(59,13,' NONE ',colors.knob_inactive);
                 vmemwrite(66,13,' REC ',colors.knob_inactive);
                 vmemwrite(72,13,' PHONE ',colors.knob_active);
               end;
             end;
      #17   :begin worldtime; refreshnums; end;
      #31   :begin sortphonebook; refreshnums; end;
      '0'   :begin { ALT-B }
               move(mem[vadr:0],bks,4000);
               sosopen;
               sosfopen(bosskeyfilename);
               sosread(@mem[vadr:0],4000);
               sosclose;
               setcursorsize($6,$7);
               window(1,1,80,25);
               textattr:=lightgreen;
               gotoxy(14,2);
               readln;
               setcursorsize($32,$32);
               move(bks,mem[vadr:0],4000);
               window(18,14,79,14);
               textattr:=colors.normal;
               writeln;
               write('Puhh.. Boss is gone, huh?');
             end;
      end;
      if not(spkey) then begin
        if config.flipkeypad then case ch of
          '7' :ch:='1';
          '8' :ch:='2';
          '9' :ch:='3';
          '1' :ch:='7';
          '2' :ch:='8';
          '3' :ch:='9';
          '.' :ch:='#';
          ',' :ch:='#';
        end;
        case ch of
          ' ':begin editnumber(current); refreshnums; end;
          '1':dial('1',true,config.touchpad,true);
          '2':dial('2',true,config.touchpad,true);
          '3':dial('3',true,config.touchpad,true);
          '4':dial('4',true,config.touchpad,true);
          '5':dial('5',true,config.touchpad,true);
          '6':dial('6',true,config.touchpad,true);
          '7':dial('7',true,config.touchpad,true);
          '8':dial('8',true,config.touchpad,true);
          '9':dial('9',true,config.touchpad,true);
          '0':dial('0',true,config.touchpad,true);
          '*':dial('*',true,config.touchpad,true);
          '#':dial('#',true,config.touchpad,true);
          'A':dial('A',true,config.touchpad,true);
          'B':dial('B',true,config.touchpad,true);
          'C':dial('C',true,config.touchpad,true);
          'D':dial('D',true,config.touchpad,true);
          'E':dial('E',true,config.touchpad,true);
          'F':dial('F',true,config.touchpad,true);
          'G':dial('G',true,config.touchpad,true);
          'H':dial('H',true,config.touchpad,true);
          'W':pleasewait;
          '+':playtrunk(curtrunk,true);
          #13:dial(xlate(numbers[current]^.number),true,false,true);
          'P':begin
                vmemwrite(49,13,' DIAL ',colors.knob_active);
                setportbit(phonebit,true);
                clrportbit(playrecbit,true);
                textattr:=colors.normal;
                writeln;
                write('Hanging up...');
                clrportbit(playrecbit,true);
                clrportbit(hookbit,true);
                delayms(curpulsedial.hanguptime);
                writeln;
                write('Waiting for dialtone...');
                setportbit(pdial.hookbit,true);
                delayms(pdial.waitfordt);
                writeln;
                write('Pulse-Dialing: ');
                dialpulse(numbers[current]^.number,true);
                switchoff(true);
                vmemwrite(49,13,' DIAL ',colors.knob_inactive);
              end;
          'M':begin modemdial(numbers[current]^.number); refreshnums; end;
          'I':begin
                textattr:=colors.normal;
                writeln;
                write('Debug Info: MemAvail ',memavail,', MaxAvail ',maxavail);
              end;
          'S':searchphonebook;
          'Q':recordquick;
          'R':replayquick;
          'T':begin
                numflags[current]:=not(numflags[current]);
                if current<maxnums then begin
                  inc(current);
                  if current-firstonpage>=pagesize then inc(firstonpage);
                end;
                refreshnums;
              end;
      end;
    end;
    if mousepresent and mouseleftclicked then repeat until not(mouseleftclicked);
  until ch=#27;
  config.curnum:=current;
  config.firstonpage:=firstonpage;
  window(1,1,80,25);
  setcursorsize($32,$32);
  move(save,mem[vadr:0],4000);
end;

procedure redboxit;
var x,y,z      :word;
    ch         :char;
    mx,my      :integer;
    mousepress :boolean;
    scammed    :real;
procedure scam;
begin
  scammed:=scammed+0.05;
  gotoxy(37,20);
  textattr:=colors.special_high;
  write('$',scammed:0:2);
end;
procedure playredbox(tone1,tone2,coin:word);
var x:word;
begin
  if coin=1 then begin
    scam;
    soundplay(tone1,tone2,0,50);
    delayms(50);
    exit;
  end;
  if coin=2 then begin
    for x:=1 to 2 do begin
      scam;
      soundplay(tone1,tone2,0,50);
      delayms(50);
    end;
    exit;
  end;
  if coin=3 then begin
    for x:=1 to 5 do begin
      scam;
      soundplay(tone1,tone2,0,30);
      delayms(25);
    end;
    exit;
  end;
end;
begin
  mousepress:=false;
  move(mem[vadr:0],save,4000);
  bottominfo('BlueBEEP! Red BoX Mode');
  window(1,4,80,24);
  clrscr;
  openbox(1,3,8,21,10,false,true,false);
  openbox(2,3,10,21,16,false,true,false);
  openbox(3,21,8,30,10,false,true,false);
  openbox(4,21,10,30,16,false,true,false);
  vmemwrite(21,8,'¬',colors.win_border_1);
  vmemwrite(3,10,'√',colors.win_border_1);
  vmemwrite(21,10,'≈',colors.win_border_1);
  vmemwrite(21,16,'¡',colors.win_border_1);
  vmemwrite(30,10,'¥',colors.win_border_1);
  vmemwrite(4,11,'     ≥     ≥',colors.dark);
  vmemwrite(4,12,'ƒƒƒƒƒ≈ƒƒƒƒƒ≈ƒƒƒƒƒ',colors.dark);
  vmemwrite(4,13,'     ≥     ≥     ',colors.dark);
  vmemwrite(4,14,'ƒƒƒƒƒ≈ƒƒƒƒƒ≈ƒƒƒƒƒ',colors.dark);
  vmemwrite(4,15,'     ≥     ≥     ',colors.dark);
  vmemwrite(6,11,'1',colors.keypad_released);
  vmemwrite(12,11,'2',colors.keypad_released);
  vmemwrite(18,11,'3',colors.keypad_released);
  vmemwrite(6,13,'4',colors.keypad_released);
  vmemwrite(12,13,'5',colors.keypad_released);
  vmemwrite(18,13,'6',colors.keypad_released);
  vmemwrite(6,15,'7',colors.keypad_released);
  vmemwrite(12,15,'8',colors.keypad_released);
  vmemwrite(18,15,'9',colors.keypad_released);
  vmemwrite(23,9,'ReDBoX',colors.high2);
  vmemwrite(24,11,'ACTS',colors.high);
  vmemwrite(24,13,'IPTS',colors.high);
  vmemwrite(23,15,'N-ACTS',colors.high);
  vmemwrite(4,9,' 5õ    10õ   25õ',colors.high);
  vmemwrite(9,9,'≥',colors.dark);
  vmemwrite(15,9,'≥',colors.dark);
  vmemwrite(22,12,'ƒƒƒƒƒƒƒƒ',colors.dark);
  vmemwrite(22,14,'ƒƒƒƒƒƒƒƒ',colors.dark);
  textattr:=colors.high;
  gotoxy(45,5); write('Red Box Mode');
  gotoxy(35,7); write('Try 1-9 for various coins and companies.');
  gotoxy(35,8); write('This should do fine in North America and');
  gotoxy(35,9); write('and Canada.');
  gotoxy(35,10);write('If anyone has suggestions on this part of');
  gotoxy(35,11);write('BlueBEEP!, please let me know.');
  gotoxy(38,13);write('Press [R] to reset the cash counter');
  gotoxy(38,14);write('Press [ESC] to exit Red Box Mode');
  scammed:=0;
  textattr:=colors.special;
  gotoxy(21,20);
  write('Amount $cammed: ');
  textattr:=colors.special_high;
  gotoxy(37,20);
  write('$0.00');
  repeat
    if mousepresent then mouseon;
    if mousepresent then repeat until keypressed or mouseleftclicked or mouserightclicked
    else repeat until keypressed;
    mx:=mousex; my:=mousey;
    if mousepresent then mouseoff;
    if mouseleftclicked and mousepresent then begin
      ch:=' ';
      if (mx>=4) and (mx<=8) and (my=11) then ch:='1';
      if (mx>=10) and (mx<=14) and (my=11) then ch:='2';
      if (mx>=16) and (mx<=20) and (my=11) then ch:='3';
      if (mx>=4) and (mx<=8) and (my=13) then ch:='4';
      if (mx>=10) and (mx<=14) and (my=13) then ch:='5';
      if (mx>=16) and (mx<=20) and (my=13) then ch:='6';
      if (mx>=4) and (mx<=8) and (my=15) then ch:='7';
      if (mx>=10) and (mx<=14) and (my=15) then ch:='8';
      if (mx>=16) and (mx<=20) and (my=15) then ch:='9';
      mousepress:=true;
    end;
    if mouserightclicked and mousepresent then begin
      ch:=#27;
      repeat until not(mouserightclicked);
    end;
    if keypressed then repeat ch:=upcase(readkey) until ch in ['1','2','3','4','5','6','7','8','9',#27,'R'];
    case ch of
      '1' :begin
             vmemwrite(5,11,' 1 ',colors.keypad_pressed);
             playredbox(curredbox.acts1,curredbox.acts2,1);
             vmemwrite(5,11,' 1 ',colors.keypad_released);
           end;
      '2' :begin
             vmemwrite(11,11,' 2 ',colors.keypad_pressed);
             playredbox(curredbox.acts1,curredbox.acts2,2);
             vmemwrite(11,11,' 2 ',colors.keypad_released);
           end;
      '3' :begin
             vmemwrite(17,11,' 3 ',colors.keypad_pressed);
             playredbox(curredbox.acts1,curredbox.acts2,3);
             vmemwrite(17,11,' 3 ',colors.keypad_released);
           end;
      '4' :begin
             vmemwrite(5,13,' 4 ',colors.keypad_pressed);
             playredbox(curredbox.ipts1,curredbox.ipts2,1);
             vmemwrite(5,13,' 4 ',colors.keypad_released);
           end;
      '5' :begin
             vmemwrite(11,13,' 5 ',colors.keypad_pressed);
             playredbox(curredbox.ipts1,curredbox.ipts2,2);
             vmemwrite(11,13,' 5 ',colors.keypad_released);
           end;
      '6' :begin
             vmemwrite(17,13,' 6 ',colors.keypad_pressed);
             playredbox(curredbox.ipts1,curredbox.ipts2,3);
             vmemwrite(17,13,' 6 ',colors.keypad_released);
           end;
      '7' :begin
             vmemwrite(5,15,' 7 ',colors.keypad_pressed);
             playredbox(curredbox.nonacts,0,1);
             vmemwrite(5,15,' 7 ',colors.keypad_released);
           end;
      '8' :begin
             vmemwrite(11,15,' 8 ',colors.keypad_pressed);
             playredbox(curredbox.nonacts,0,2);
             vmemwrite(11,15,' 8 ',colors.keypad_released);
           end;
      '9' :begin
             vmemwrite(17,15,' 9 ',colors.keypad_pressed);
             playredbox(curredbox.nonacts,0,3);
             vmemwrite(17,15,' 9 ',colors.keypad_released);
           end;
      'R' :begin
             scammed:=0;
             textattr:=colors.special_high;
             gotoxy(37,20);
             write('$0.00   ');
           end;
    end;
    if mousepress and mousepresent then repeat until not (mouseleftclicked);
    mousepress:=false;
  until ch=#27;
  closebox(4);
  closebox(3);
  closebox(2);
  closebox(1);
  window(1,1,80,25);
  move(save,mem[vadr:0],4000);
end;

procedure cardtalker;
var voice                      :voicefile;
    ch                         :char;
    x,oldx,oldy                :word;
procedure talksample(samplefile,message:string);
var voice:voicefile;
begin
  switchon(true);
  loadvoice(samplefile,voice,0);
  playvoice(voice);
  write(message);
  repeat until status=0;
  writeln;
  killvoice(voice);
  switchoff(true);
end;
procedure talknumber(s:string);
var x:byte;
procedure talkdigit(ch:char;low:boolean);
begin
  write(ch);
  if low then begin
    case ch of
      '1' :loadvoice('lowone.voc',voice,0);
      '2' :loadvoice('lowtwo.voc',voice,0);
      '3' :loadvoice('lowthree.voc',voice,0);
      '4' :loadvoice('lowfour.voc',voice,0);
      '5' :loadvoice('lowfive.voc',voice,0);
      '6' :loadvoice('lowsix.voc',voice,0);
      '7' :loadvoice('lowseven.voc',voice,0);
      '8' :loadvoice('loweight.voc',voice,0);
      '9' :loadvoice('lownine.voc',voice,0);
      '0' :loadvoice('lowzero.voc',voice,0);
    end;
  end else begin
    case ch of
      '1' :loadvoice('hione.voc',voice,0);
      '2' :loadvoice('hitwo.voc',voice,0);
      '3' :loadvoice('hithree.voc',voice,0);
      '4' :loadvoice('hifour.voc',voice,0);
      '5' :loadvoice('hifive.voc',voice,0);
      '6' :loadvoice('hisix.voc',voice,0);
      '7' :loadvoice('hiseven.voc',voice,0);
      '8' :loadvoice('hieight.voc',voice,0);
      '9' :loadvoice('hinine.voc',voice,0);
      '0' :loadvoice('hizero.voc',voice,0);
    end;
  end;
  playvoice(voice);
  repeat until status=0;
  delayms(150);
  killvoice(voice);
end;
begin
  switchon(true);
  for x:=1 to length(s)-1 do begin
    if s[x+1]='-' then begin
      talkdigit(s[x],true);
      inc(x);
      write('-');
    end else begin
      talkdigit(s[x],false);
    end;
  end;
  talkdigit(s[length(s)],true);
  switchoff(true);
  writeln;
end;
begin
  setcursorsize($6,$7);
  move(mem[vadr:0],save,4000);
  clrscr;
  openbox(1,1,1,80,3,false,false,false);   ignbox(1);
  openbox(1,1,4,36,10,false,false,false);  ignbox(1);
  openbox(1,1,10,36,15,false,false,false); ignbox(1);
  openbox(1,36,4,80,15,false,false,false); ignbox(1);
  vmemwrite(1,10,#195,colors.win_border_1);
  vmemwrite(36,4,#194,colors.win_border_1);
  vmemwrite(36,15,#193,colors.win_border_1);
  vmemwrite(36,9,#179,colors.win_border_2);
  vmemwrite(36,10,#180,colors.win_border_1);
  vmemwrite(36,11,#179,colors.win_border_2);
  for x:=0 to 239 do mem[vadr:x*2+1]:=colors.titlebox_border;
  for x:=2 to 78 do mem[vadr:160+(x*2+1)]:=colors.titlebox_high;
  gotoxy(1,25);
  textattr:=colors.status;
  write(' BlueBEEP! v      Card Talker');
  clreol;
  vmemwrite(13,25,version,colors.status);
  vmemwrite(62,2,'Local Time:',colors.titlebox_high);
  textattr:=colors.titlebox_title;
  center(1,' BlueBEEP! CardTalker ');
  textattr:=colors.high2;
  vmemwrite(44,5,'I''d like to make a call ... AT&T',colors.normal);
  vmemwrite(44,6,'I''d like to make a call ... MCI',colors.normal);
  vmemwrite(44,7,'I''d like to make a call ... Sprint',colors.normal);
  vmemwrite(44,8,'The Number I''m calling to is...',colors.normal);
  vmemwrite(44,9,'Talk Card Number',colors.normal);
  vmemwrite(44,10,'Talk Number you''re calling to',colors.normal);
  vmemwrite(44,11,'User Defined Sample #1 (USER1.VOC)',colors.normal);
  vmemwrite(44,12,'User Defined Sample #2 (USER2.VOC)',colors.normal);
  vmemwrite(44,13,'Change Card Number',colors.normal);
  vmemwrite(44,14,'Change Phone Number',colors.normal);
  for x:=5 to 13 do vmemwrite(39,x,'[',colors.dark);
  vmemwrite(38,14,'[',colors.dark);
  for x:=5 to 14 do vmemwrite(42,x,']',colors.dark);
  for x:=1 to 9 do vmemwrite(40,4+x,'F'+stg(x),colors.super_high);
  vmemwrite(39,14,'F10',colors.super_high);
  vmemwrite(3,12,'Loaded Card #:',colors.normal);
  vmemwrite(3,13,'Loaded Fone #:',colors.normal);
  vmemwrite(18,12,config.curcard,colors.high);
  vmemwrite(18,13,config.curcallto,colors.high);
  textattr:=colors.high;
  window(3,5,34,9);
  if config.gotblaster=false then begin
    writeln('Need Soundblaster for this!');
    writeln('If you have one, set it up');
    writeln('in the Setup/Blaster menu !');
    writeln('Press <ENTER>...');
    repeat ch:=readkey until ch=#13;
    window(1,1,80,25);
    move(save,mem[vadr:0],4000);
    setcursorsize($32,$32);
    exit;
  end;
  writeln('Loading SB driver...');
  fixdriver('CT-VOICE.DRV',0);
  writeln('Initializing card...');
  if initblaster(config.sbint,config.sbaddr)=0 then writeln('Initialize OK.') else begin
    writeln('BLASTER INIT FAILURE!');
    writeln('Check your settings !');
    writeln('Or BUY A BLASTER !');
    writeln('Press <ENTER>...');
    repeat ch:=readkey until ch=#13;
    writeln('Removing driver...');
    removedriver;
    window(1,1,80,25);
    move(save,mem[vadr:0],4000);
    setcursorsize($32,$32);
    exit;
  end;
  writeln('Init Done.');
  repeat
    ch:=' ';
    if mousepresent then mouserange(37,5,79,14);
    if mousepresent then mouseon;
    if mousepresent then
    repeat vmemwrite(74,2,time(false),colors.titlebox) until keypressed or mouseleftclicked or mouserightclicked
    else repeat vmemwrite(74,2,time(false),colors.titlebox) until keypressed;
    if mousepresent then mouseoff;
    if mousepresent and mouserightclicked then begin
      ch:=#27;
      repeat until not(mouserightclicked);
    end;
    if mousepresent and mouseleftclicked then begin
      case mousey of
        5  :ch:=F1;
        6  :ch:=F2;
        7  :ch:=F3;
        8  :ch:=F4;
        9  :ch:=F5;
        10 :ch:=F6;
        11 :ch:=F7;
        12 :ch:=F8;
        13 :ch:=F9;
        14 :ch:=F10;
      end;
    end;
    if keypressed then ch:=readkey;
    case ch of
      F1 :talksample('usinatt.voc','Wanna use my AT&T calling card');
      F2 :talksample('usinmci.voc','Wanna use my MCI calling card');
      F3 :talksample('usinspr.voc','Wanna use my Sprint phonecard');
      F4 :talksample('numcall.voc','The number I''m calling is');
      F5 :talknumber(config.curcard);
      F6 :talknumber(config.curcallto);
      F7 :talksample('user1.voc','User Defined Sample #1');
      F8 :talksample('user2.voc','User Defined Sample #2');
      F9 :begin
            oldx:=wherex; oldy:=wherey;
            window(1,1,80,25);
            gotoxy(18,12);
            edit(config.curcard,17);
            window(3,5,34,9);
            gotoxy(oldx,oldy);
            textattr:=colors.high;
            writeln('New card # entered');
          end;
      F10:begin
            oldx:=wherex; oldy:=wherey;
            window(1,1,80,25);
            gotoxy(18,13);
            edit(config.curcallto,17);
            window(3,5,34,9);
            gotoxy(oldx,oldy);
            textattr:=colors.high;
            writeln('New phone # entered');
          end;
    end;
  until ch=#27;
  writeln('Removing driver...');
  removedriver;
  window(1,1,80,25);
  if mousepresent then mouserange(1,1,80,25);
  move(save,mem[vadr:0],4000);
  setcursorsize($32,$32);
end;

procedure freqtester;
var ch         :char;
    temptrunk  :trunktype;
procedure savetrunk;
var comp,desc        :string;
    save,x,pos,res   :byte;
    t,worktrunk      :trunktype;
begin
  pos:=0; res:=1;
  save:=textattr;
  textattr:=colors.win_text;
  openbox(13,15,10,65,18,true,true,false);
  center(10,'Save Trunk');
  gotoxy(18,12); write('    Company:');
  gotoxy(18,13); write('Description:');
  gotoxy(18,14); write('   Position:');
  textattr:=colors.win_text_high;
  comp:=''; desc:='';
  gotoxy(31,12); edituc(comp,8);
  gotoxy(31,13); edit(desc,30);
  sosopen;
  sosfopen(trunkfilename);
  for x:=1 to maxtrunks do begin
    sosread(@worktrunk,sizeof(worktrunk));
    menuitem[x]:=worktrunk.name;
    menuinfo[x]:=worktrunk.description;
  end;
  sosclose;
  menucount:=maxtrunks;
  setcursorsize($32,$32);
  res:=menu(1,4,res,true,true,true,false,true);
  pos:=res;
  gotoxy(31,14); write('#',pos);
  gotoxy(34,16);
  if yesnotoggle(true,'OK','CANCEL') then begin
    t:=temptrunk;
    t.name:=comp;
    t.description:=desc;
    sosopen;
    sosfopen(trunkfilename);
    sosseek(sizeof(trunktype)*(pos-1));
    soswrite(@t,sizeof(t));
    sosclose;
  end;
  closebox(13);
  setcursorsize($32,$32);
  textattr:=save;
end;

procedure editfreqs;
procedure modify(x,y:byte;var data:word);
begin
  gotoxy(x,y);
  editword(data);
  gotoxy(x,y);
  textattr:=colors.high;
  write(data:5);
end;
begin
  with curfreqtest do begin
    modify(5,5,freq11);
    modify(11,5,freq12);
    modify(17,5,freq13);
    modify(23,5,len1);
    modify(29,5,del1);
    modify(5,6,freq21);
    modify(11,6,freq22);
    modify(17,6,freq23);
    modify(23,6,len2);
  end;
  setcursorsize($32,$32);
end;

begin
  move(mem[vadr:0],save,4000);
  textattr:=colors.normal;
  clrscr;
  openbox(10,1,1,80,3,false,true,false);
  openbox(11,1,23,80,25,false,true,false);
  gotoxy(3,24);
  textattr:=colors.win_text;;
  cwrite('|WCurrent Test#: |Y'+curfreqtest.numbertotest);
  gotoxy(50,24); cwrite('|WStep Size:');
  gotoxy(68,24); cwrite('|YESC |Wto exit');
  gotoxy(3,2); write('Frequency Tester');
  for x:=1 to 10 do begin
    temptrunk.tone[x].one:=0;           { reset trunk variables in order to  }
    temptrunk.tone[x].two:=0;           { avoid trash while playing trunk    }
    temptrunk.tone[x].three:=0;
    temptrunk.tone[x].len:=0;
    temptrunk.pause[x]:=0;
  end;
  repeat
    with curfreqtest do begin
      temptrunk.tone[1].one:=freq11;    {  *  Dump all the garbage from    * }
      temptrunk.tone[1].two:=freq12;    {  *  curfreqtest into a trunk     * }
      temptrunk.tone[1].three:=freq13;  {  *  variable for playtrunk()     * }
      temptrunk.tone[1].len:=len1;
      temptrunk.tone[2].one:=freq21;
      temptrunk.tone[2].two:=freq22;
      temptrunk.tone[2].three:=freq23;
      temptrunk.tone[2].len:=len2;
      temptrunk.pause[1]:=del1;
      textattr:=colors.high;
      gotoxy(5,5); write(freq11:5,'/',freq12:5,'/',freq13:5,'/',len1:5,'/',del1:5);
      gotoxy(5,6); write(freq21:5,'/',freq22:5,'/',freq23:5,'/',len2:5);
      textattr:=colors.win_text_high;
      gotoxy(61,24);
      write(stepsize,'  ');
      textattr:=colors.win_text;
      repeat vmemwrite(74,2,time(false),colors.win_text) until keypressed;
      ch:=upcase(readkey);
      if ch=#0 then begin
        ch:=readkey;
        case ch of
          F1 :stepsize:=1;
          F2 :stepsize:=3;
          F3 :stepsize:=5;
          F4 :stepsize:=20;
          F5 :playtrunk(curtrunk,false);
          F6 :savetrunk;
          F7 :editfreqs;
          F8 :begin
                freq11:=2400; freq12:=2600; freq13:=0; len1:=150; del1:=100;
                freq21:=2400; freq22:=0;    freq23:=0; len2:=100;
              end;
          F9 :begin freq11:=0; freq12:=0; freq13:=0; len1:=0; del1:=0; end;
          F10:begin freq21:=0; freq22:=0; freq23:=0; len2:=0; end;
        end;
      end else begin
        case ch of
          '1' :inc(freq11,stepsize);
          '2' :inc(freq12,stepsize);
          '3' :inc(freq13,stepsize);
          '4' :inc(len1,stepsize);
          '5' :inc(del1,stepsize);
          'Q' :if freq11>=stepsize then dec(freq11,stepsize) else freq11:=0;
          'W' :if freq12>=stepsize then dec(freq12,stepsize) else freq12:=0;
          'E' :if freq13>=stepsize then dec(freq13,stepsize) else freq13:=0;
          'R' :if len1>=stepsize then dec(len1,stepsize) else len1:=0;
          'T' :if del1>=stepsize then dec(del1,stepsize) else del1:=0;
          '+' :playtrunk(temptrunk,false);
          'A' :inc(freq21,stepsize);
          'S' :inc(freq22,stepsize);
          'D' :inc(freq23,stepsize);
          'F' :inc(len2,stepsize);
          'Y' :if freq21>=stepsize then dec(freq21,stepsize) else freq21:=0;
          'X' :if freq22>=stepsize then dec(freq22,stepsize) else freq22:=0;
          'C' :if freq23>=stepsize then dec(freq23,stepsize) else freq23:=0;
          'V' :if len2>=stepsize then dec(len2,stepsize) else len2:=0;
          ' ' :begin
                  gotoxy(18,24);
                  edituc(numbertotest,30);
                  gotoxy(18,24);
                  textattr:=colors.win_text_high;
                  write(numbertotest);
                  setcursorsize($32,$32);
                  textattr:=colors.high;
                end;
          #13 :begin
                 textattr:=colors.high;
                 gotoxy(1,21);
                 clreol;
                 gotoxy(1,20);
                 dial(numbertotest,false,false,true);
                 textattr:=colors.high;
               end;
        end;
      end;
    end;
  until ch=#27;
  closebox(11);
  closebox(10);
  sosopen;
  sosfopen(freqtestfilename);
  soswrite(@curfreqtest,sizeof(curfreqtest));
  sosclose;
  move(save,mem[vadr:0],4000);
end;

procedure cardchecker;
var x,total              :word;
    t                    :text;
    s,filename,nfilename :string;
    ch                   :char;
    exkey                :boolean;
    f                    :file;
    vcn,vd,vt,vf         :string;
    v                    :voicefile;
procedure checkcard(cardnumber,filename:string;notefile:string);
var fn     :string;
    x      :word;
    total  :word;
    t      :text;
begin
  fn:='';
  for x:=1 to 8-length(filename) do fn:=fn+'0';     { pad with zeroes        }
  fn:=fn+filename+'.VOC';
  if config.ccc_manually then write('Checking Card: ',cardnumber,' manual at ')
  else write('Checking Card: ',cardnumber,', ',fn,' at ');
  writeln(curccc.name);
  switchon(false);
  write('Waiting for dialtone...');
  setportbit(pdial.hookbit,false);
  delayms(pdial.waitfordt);
  writeln;
  write('Pulse-Dialing: ');
  dialpulse(curccc.number,false);
  writeln;
  switchoff(false);
  writeln('Waiting for remote pickup...');
  delayms(curccc.comeuptime);
  if curccc.numberfirst then begin
    write('Dialing Target Number...');
    clrportbit(playrecbit,false);
    dial(randomnr+'#',false,false,true);
    setportbit(playrecbit,false);
    writeln;
    delayms(curccc.numdelay);
  end;
  write('Dialing Card Number...');
  switchon(false);
  dial(curccc.startseq+cardnumber+curccc.endseq,false,false,true);
  switchoff(false);
  writeln;
  writeln('Waiting for reaction...');
  delayms(curccc.recorddelay);
  if not config.ccc_manually then begin
    writeln('Sampling ',curccc.sampletime,' ms to ',fn,'...');
    recordvoice(fn,curccc.samplerate,curccc.sampletime);
  end else delayms(curccc.sampletime);
  writeln('Hanging up...');
  clrportbit(hookbit,false);
  switchon(false);
  delayms(curpulsedial.hanguptime);
  if config.ccc_manually then begin
    write('Card alive (Y/N) ?');
    repeat ch:=upcase(readkey) until ch in ['Y','N'];
    assign(t,notefile);
    if exist(notefile) then append(t) else rewrite(t);
    write(t,cardnumber+'  '+date+' '+time(true)+'  '+curccc.name+' ');
    if ch='Y' then writeln(t,'OK') else writeln(t,'DEAD');
    textattr:=colors.high;
    if ch='Y' then writeln(' Yea!') else writeln(' Nop...');
    textattr:=colors.normal;
    close(t);
  end else begin
    assign(ccctempfile,ccctempfilename);
    if exist(ccctempfilename) then append(ccctempfile) else rewrite(ccctempfile);
    writeln(ccctempfile,cardnumber);
    writeln(ccctempfile,date);
    writeln(ccctempfile,time(true));
    writeln(ccctempfile,fn);
    close(ccctempfile);
  end;
end;
begin
  move(mem[vadr:0],save,4000);
  filename:='CHKLIST.TXT';
  nfilename:='CHKNOTE.TXT';
  textattr:=colors.normal;
  clrscr;
  openbox(40,1,1,80,3,false,true,false);  ignbox(40);
  openbox(41,1,4,80,8,false,true,false);  ignbox(41);
  openbox(42,1,9,80,24,false,true,false); ignbox(42);
  gotoxy(1,25);
  textattr:=colors.status;
  clreol;
  write(' BlueBEEP! v',version,' Calling Card Checker');
  textattr:=colors.win_text;
  gotoxy(3,2);
  write('Calling Card Checker');
  textattr:=lightgreen;
  gotoxy(3,5);  write('Checking Card     of');
  gotoxy(3,6);  write('Calling Card List File: ');
  gotoxy(3,7);  write('Result note file      : ');
  gotoxy(27,6); edituc(filename,50);
  gotoxy(27,7); edituc(nfilename,50);
  setcursorsize($32,$32);
  repeat
    if config.ccc_manually then begin
      vmemwrite(50,6,' MANUAL ',green*16+white);
      vmemwrite(59,6,' AUTOMATIC ',lightgreen);
    end else begin
      vmemwrite(50,6,' MANUAL ',lightgreen);
     vmemwrite(59,6,' AUTOMATIC ',green*16+white);
    end;
    repeat ch:=upcase(readkey) until ch in ['M','A',#13,#0];
    if ch=#0 then begin
      exkey:=true;
      ch:=readkey;
    end else exkey:=false;
    if not exkey then case ch of
      'M' :config.ccc_manually:=true;
      'A' :config.ccc_manually:=false;
    end else config.ccc_manually:=not(config.ccc_manually);
    if config.ccc_manually then begin
      vmemwrite(50,6,' MANUAL ',green*16+white);
      vmemwrite(59,6,' AUTOMATIC ',lightgreen);
    end else begin
      vmemwrite(50,6,' MANUAL ',lightgreen);
     vmemwrite(59,6,' AUTOMATIC ',green*16+white);
    end;
  until (ch in [#13,'M','A']) and (not exkey);
  setcursorsize($6,$7);
  window(3,10,78,23);
  textattr:=green;
  if filename<>'RESUME' then begin
    writeln('Checking input file...');
    assign(t,filename);
    reset(t);
    total:=0;
    while not eof(t) do begin
      readln(t,s);
      if (s[1]<>';') and (s<>'') and (length(s)=14) then inc(total);
      vmemwrite(24,5,stg(total),yellow);
    end;
    close(t);
  end else writeln('*** Resume Mode');
  write('Loading Sound Driver...');
  fixdriver('CT-VOICE.DRV',0);
  writeln('OK');
  write('Initializing sound blaster...');
  if initblaster(config.sbint,config.sbaddr)<>0 then fatalerror('Blaster Init Failed');
  writeln('OK');
  if filename<>'RESUME' then begin
    assign(t,filename);
    reset(t);
    x:=0;
    ch:=#13;
    if exist(ccctempfilename) then begin
      assign(f,ccctempfilename);
      erase(f);
    end;
    while not eof(t) or (ch=#27) do begin
      readln(t,s);
      if keypressed then ch:=readkey;
      if (s[1]<>';') and (s<>'') and (length(s)=14) then begin
        inc(x);
        vmemwrite(17,5,stg(x),yellow);
        checkcard(s,stg(x),nfilename);
      end;
    end;
    close(t);
    textattr:=lightgreen;
    writeln;
    writeln(x,' cards checked - Press [ENTER] to proceed...');
    repeat ch:=readkey until ch=#13;
  end;
  if not(config.ccc_manually) then begin
    speaker(1);
    writeln;
    writeln('*** Card Sample Verification');
    writeln;
    textattr:=green;
    assign(ccctempfile,ccctempfilename);
    reset(ccctempfile);
    while not eof(ccctempfile) do begin
      readln(ccctempfile,vcn);
      readln(ccctempfile,vd);
      readln(ccctempfile,vt);
      readln(ccctempfile,vf);
      write('Verifying ',vcn,'...');
      loadvoice(vf,v,0);
      write(^H^H^H', alive (Y/N/R) ?');
      repeat
        playvoice(v);
        repeat until (status=0) or keypressed;
        repeat ch:=upcase(readkey) until ch in ['Y','N','R'];
      until ch<>'R';
      stopio;
      killvoice(v);
      assign(t,nfilename);
      if exist(nfilename) then append(t) else rewrite(t);
      write(t,vcn+'  '+vd+' '+vt+'  '+curccc.name+' ');
      if ch='Y' then writeln(t,'OK') else writeln(t,'DEAD');
      textattr:=lightgreen;
      if ch='Y' then writeln(' Yea!') else writeln(' Nop...');
      textattr:=green;
      close(t);
    end;
    writeln;
    textattr:=lightgreen;
    writeln('*** All done, press [ENTER]');
    repeat ch:=readkey until ch=#13;
  end;
  textattr:=green;
  writeln('De-Installing sound driver...');
  removedriver;
  move(save,mem[vadr:0],4000);
  window(1,1,80,25);
  setcursorsize($32,$32);
end;

procedure foneword;
var choice :char;

procedure wordtonumber;
var s:string;
    b:byte;
begin
  s:='';
  writeln(' Word --> Number');
  writeln;
  write('Which word:');
  b:=textattr;
  edituc(s,60);
  textattr:=b;
  writeln;
  writeln;
  writeln('The number for that word would be ',stringtodigit(s));
  writeln;
end;

procedure findwordsfornumber;
var s,fn:string;
begin
  s:='';
  writeln(' # --> Words');
  writeln;
  write('Which number:');
  edituc(s,60);
  if pos('0',s)<>0 then begin
    writeln;
    writeln;
    writeln('The number you entered contains a zero, which is not defined as');
    writeln('a letter. We are sorry to say but we cannot proceed with this one.');
    exit;
  end;
  if length(s)>4 then begin
    writeln;
    writeln;
    writeln('The number you entered is longer than 4 digits, and the results of');
    writeln('the evaluation will not fit on the screen. Please specify a file');
    writeln('where we can write the results to.');
    writeln;
    write('Filename: ');
    fn:='results.txt';
    edituc(fn,12);
    writeln;
    writeln;
    write('Processing...');
    numscan(s,fn);
    writeln('Done.');
    writeln;
  end else begin
    clrscr;
    numscan(s,'');
    textattr:=colors.high;
    gotoxy(1,18);
  end;
end;

begin
  openbox(10,1,1,80,3,false,true,false);
  openbox(11,1,4,80,25,false,true,false);
  vmemwrite(3,2,'PHONE WORD - Word to Number converter, Number to word finder, for USA fones',colors.win_text_high);
  textattr:=colors.high;
  window(3,5,78,24);
  clrscr;
  repeat
    writeln;
    write('(W)ord to Number, (F)ind words for number, (Q)uit ?');
    repeat choice:=upcase(readkey) until choice in ['W','F','Q'];
    case choice of
      'W' :wordtonumber;
      'F' :findwordsfornumber;
      'Q' :writeln(' Quit!');
    end;
  until choice='Q';
  closebox(11);
  closebox(10);
  window(1,1,80,25);
  setcursorsize($32,$32);
end;

procedure phreakoutmenu;
var choice:Byte;
begin
  choice:=1;
  repeat
    menuitem[1]:='Action Mode';
    menuitem[2]:='Scanner';
    menuitem[3]:='Red Box';
    menuitem[4]:='CardTalker';
    menuitem[5]:='FreqTester';
    menuitem[6]:='Card Checker';
    menuitem[7]:='PhoneWord';
    menuinfo[1]:='Go to the main dialer program (command line option /A)';
    menuinfo[2]:='Scan routings / PBXes / phone numbers';
    menuinfo[3]:='Red Box payphone coin signalling - for our ameriKKKan friends';
    menuinfo[4]:='Calling Card Talker, if you are too lazy to talk on your own...';
    menuinfo[5]:='Frequency Tester - For freq finding purposes';
    menuinfo[6]:='Calling Card checker to check big amounts of Calling Cards';
    menuinfo[7]:='TouchTone Character & Number Finder, try it its really neat!';
    menucount:=7;
    choice:=menu(35,4,choice,true,true,true,true,true);
    case choice of
      1: phreakout;
      2: scanmode;
      3: redboxit;
      4: cardtalker;
      5: freqtester;
      6: cardchecker;
      7: foneword;
    end;
  until choice=0;
end;
end.
