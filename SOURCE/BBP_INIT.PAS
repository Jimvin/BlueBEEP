unit bbp_init;

interface

procedure init(project:string);
procedure startup;

implementation

uses crt, video, bbp_vars, extras, pdial, bbunit, lscomm, grwins, ferror,
     bbp_proc, mouseio, bbp_pom, {bbp_term,} bbp_bsli, optimer, grmenus,
     editrout, dos, bbp_conv, sos;

procedure say(s:string);
begin
  if parameter('/DEBUG') then begin
    writeln(s);
    exit;
  end;
  gotoxy(1,23);
  clreol;
  gotoxy(40-(length(s) div 2),23);
  write(s);
end;

procedure loadconfig;
var dumbset :bbp_vars.configtype;
begin
  with dumbset do begin
    version:=version;                   { creator's version number           }
    password:='';                       { default no password                }
    firstonpage:=1;                     { for action mode number selection   }
    curtrunk:=1;                        { reset all to default values       }
    curdset:=1;                         { in action mode, dialset, trunk,    }
    curnum:=1;                          { number etc.                        }
    curcompany:=1;                      { default ccc company = 1            }
    timesused:=0;                       { default times used = zero !        }
    dialspeed:=1.00;                    { default dialspeed factor 1.00      }
    gotblaster:=false;                  { default no sound blaster present   }
    sbint:=$7;                          { default sb interrupt 7h            }
    sbaddr:=$220;                       { default sb i/o adress 220h         }
    curcard:='123-456-7890-1234';       { default card # for card talker     }
    curcallto:='201-857-2666';          { default target # for card talker   }
    switchback:=0;                      { default switchback = 0 (off)       }
    flipkeypad:=TRUE;                   { default kepad flip = on            }
    ccc_manually:=FALSE;                { default ccc automatic = on         }
    modem:=FALSE;                       { default modem present = NO         }
    modemport:=1;                       { default modem com port = 1         }
    modemspeed:=38400;                  { default modem speed = 38400 bps    }
    phonesystem:=FALSE;                 { default phone system = rotary      }
    modeminit:='';                      { default modem init string = nuttin }
    modemdatabits:=8;                   { default modem data bits = 8        }
    modemparity:=0;                     { default modem parity = none        }
    modemstopbits:=1;                   { default modem stop bits = 1        }
    touchpad:=true;                     { default pad "touching" on !        }
    commaperiod:=500;                   { default comma delay = 500 ms       }
    cetdiff:=0;                         { default timezone = 0               }
    activedtl:=1;                       { default DTL to be used --> off rec }
  end;
  if not sosexist(cfgfilename) then begin  { create new file here               }
    sosopen;
    sosfcreate(cfgfilename);
    soswrite(@dumbset,sizeof(dumbset));
    sosclose;
  end;
  if sosbfsize(cfgfilename)<>sizeof(configtype) then fatalerror('Incompatible config file ('+cfgfilename+').');
  sosopen;                               { load configuration }
  sosfopen(cfgfilename);
  sosread(@config,sizeof(config));
  sosclose;
  config.password:=scrambled(config.password); { de-crypt password           }
end;

procedure loaddialsets;
var dumbset  :dialsettype;
    dumbtone :tonetype2;
    x        :byte;
begin
  with dumbtone do begin
    one:=0;
    two:=0;
    three:=0;
    mark:=0;
    space:=0;
  end;
  with dumbset do begin
    standard:=blankpbentry;
    description:='Describe Dial Set here';
    for x:=0 to 9 do tone[x]:=dumbtone;
    kp1:=dumbtone;
    kp2:=dumbtone;
    st:=dumbtone;
    c11:=dumbtone;
    c12:=dumbtone;
    kp2e:=dumbtone;
    ste:=dumbtone;
    eo:=dumbtone;
    raute:=dumbtone;
    stern:=dumbtone;
  end;
  if not sosexist(dsfilename) then begin
    sosopen;
    sosfcreate(dsfilename);
    for x:=1 to maxdialsets do soswrite(@dumbset,sizeof(dumbset));
    sosclose;
  end;
  if sosbfsize(dsfilename)<>sizeof(dialsettype)*maxdialsets then fatalerror('Incompatible dial set file ('+dsfilename+').');
  sosopen;
  sosfopen(dsfilename);
  sosseek(sizeof(dialsettype)*(config.curdset-1));
  sosread(@curds,sizeof(curds));
  sosclose;
end;

procedure loadtrunks;
var dumbtone  :tonetype;
    dumbtrunk :trunktype;
    x         :byte;
begin
  with dumbtone do begin
    one:=0;
    two:=0;
    three:=0;
    len:=0;
  end;
  for x:=1 to 10 do dumbtrunk.tone[x]:=dumbtone;
  for x:=1 to 10 do dumbtrunk.pause[x]:=0;
  dumbtrunk.name:=blankpbentry;
  dumbtrunk.description:='Describe trunk here';
  if not sosexist(trunkfilename) then begin
    sosopen;
    sosfcreate(trunkfilename);
    for x:=1 to maxtrunks do soswrite(@dumbtrunk,sizeof(dumbtrunk));
    sosclose;
  end;
  if sosbfsize(trunkfilename)<>sizeof(trunktype)*maxtrunks then fatalerror('Incompatible trunk file ('+trunkfilename+').');
  sosopen;
  sosfopen(trunkfilename);
  sosseek(sizeof(trunktype)*(config.curtrunk-1));
  sosread(@curtrunk,sizeof(curtrunk));
  sosclose;
end;

procedure loadscan;
var dumbrec:scantype;
    x      :word;
begin
  with dumbrec do begin
    scanstring:='X#,,X#';
    quickmacro:=',,,,1111#,,1111#,,,**7';
    digits:=4;
    progress:=0;
    ai:=true;
    redialcount:=2;
    redialprog:=0;
    stripzeroes:=false;
  end;
  if not sosexist(scanfilename) then begin
    say('Creating new scan file');
    sosopen;
    sosfcreate(scanfilename);
    soswrite(@dumbrec,sizeof(dumbrec));
    sosclose;
  end;
  if sosbfsize(scanfilename)<>sizeof(scantype) then fatalerror('Incompatible scan file ('+scanfilename+').');
  sosopen;
  sosfopen(scanfilename);
  sosread(@curscan,sizeof(curscan));
  sosclose;
end;

procedure loadphonebook;
var dumbrec, defrec, newrec :numberrec;
    oldrec                  :oldnumberrec;
    x                       :word;
    s                       :string;
begin
  dumbrec.name:=scrambled(blankpbentry);
  dumbrec.number:='';
  defrec.name:=scrambled(pbk_defrec_name);
  defrec.number:=scrambled(pbk_defrec_num);
  if not sosexist(phonebookname) then begin
    say('Creating new phone book');
    sosopen;
    sosfcreate(phonebookname);
    soswrite(@defrec,sizeof(defrec));
    for x:=1 to maxnums-1 do soswrite(@dumbrec,sizeof(dumbrec));
    sosclose;
  end;
  {if sosbfsize(phonebookname)=oldpbooksize then begin
    say('Old (BlueBEEP V0.07 or older) phone book detected');
    say('Converting to new format');
    assign(oldphonebook,phonebookname);
    reset(oldphonebook);
    assign(phonebook,tempfilename); DOLATER
    rewrite(phonebook);
    for x:=1 to maxnums do begin
      read(oldphonebook,oldrec);
      newrec.name:=oldrec.name;
      s:=oldrec.number;
      newrec.number:=s;
      write(phonebook,newrec);
    end;
    close(oldphonebook);
    close(phonebook);
    erase(oldphonebook);
    rename(phonebook,phonebookname);
  end;}
  say('Allocating memory');
  for x:=1 to maxnums do new(numbers[x]);
  say('Loading Phone Book');
  if sosbfsize(phonebookname)<>sizeof(numberrec)*maxnums then
    fatalerror('Incompatible phone book file ('+phonebookname+').');
  sosopen;
  sosfopen(phonebookname);
  for x:=1 to maxnums do sosread(numbers[x],sizeof(numberrec));
  sosclose;
  say('Unscrambling phone book');
  for x:=1 to maxnums do begin
    numbers[x]^.number:=scrambled(numbers[x]^.number);
    numbers[x]^.name:=scrambled(numbers[x]^.name);
  end;
  curnum:=numbers[config.curnum]^;
end;

procedure loadredbox;
var dumbrec:redboxtype;
begin
  with dumbrec do begin
    acts1:=1700;                    { red box default values }
    acts2:=2200;
    ipts1:=1500;
    ipts2:=2200;
    nonacts:=2200;
  end;
  if not sosexist(redboxfilename) then begin
    say('Creating new Red Box file');
    sosopen;
    sosfcreate(redboxfilename);
    soswrite(@dumbrec,sizeof(dumbrec));
    sosclose;
  end;
  if sosbfsize(redboxfilename)<>sizeof(redboxtype) then fatalerror('Incompatible red box file ('+redboxfilename+').');
  sosopen;
  sosfopen(redboxfilename);
  sosread(@curredbox,sizeof(curredbox));
  sosclose;
end;

procedure loadfreqtest;
var dumbrec :freqtesttype;
begin
  with dumbrec do begin
    freq11:=0;                    { wipe out - these are the default   }
    freq12:=0;                    { values if no .fqt file is found    }
    freq13:=0;                    { and a new one has to be created    }
    len1:=0;
    del1:=0;
    freq21:=0;
    freq22:=0;
    freq23:=0;
    len2:=0;
    stepsize:=5;
    numbertotest:='';
  end;
  if not sosexist(freqtestfilename) then begin
    say('Creating new freq test file');
    sosopen;
    sosfcreate(freqtestfilename);
    soswrite(@dumbrec,sizeof(dumbrec));
    sosclose;
  end;
  if sosbfsize(freqtestfilename)<>sizeof(freqtesttype) then
    fatalerror('Incompatible freq tester file ('+freqtestfilename+').');
  sosopen;
  sosfopen(freqtestfilename);
  sosread(@curfreqtest,sizeof(curfreqtest));
  sosclose;
end;

procedure loadpulsedial;
var dumbrec :pulsedialtype;
begin
  with dumbrec do begin
    waitfordt:=1000;
    pulse_mark:=50;
    pulse_space:=50;
    pulse_interdig:=500;
    portadress:=$378;
    hookbit:=0;
    playrecbit:=1;
    phonebit:=2;
    accesstime:=100;
    hanguptime:=1000;
  end;
  if not sosexist(pulsedialfilename) then begin
    say('Creating new pulse dialing file');
    sosopen;
    sosfcreate(pulsedialfilename);
    soswrite(@dumbrec,sizeof(dumbrec));
    sosclose;
  end;
  if sosbfsize(pulsedialfilename)<>sizeof(pulsedialtype) then
    fatalerror('Incompatible pulse dialer file ('+pulsedialfilename+').');
  sosopen;
  sosfopen(pulsedialfilename);
  sosread(@curpulsedial,sizeof(curpulsedial));
  sosclose;
  pdial.waitfordt:=curpulsedial.waitfordt;
  pdial.pulse_mark:=curpulsedial.pulse_mark;
  pdial.pulse_space:=curpulsedial.pulse_space;
  pdial.pulse_interdig:=curpulsedial.pulse_interdig;
  pdial.portadress:=curpulsedial.portadress;
  pdial.hookbit:=curpulsedial.hookbit;
  pdial.playrecbit:=curpulsedial.playrecbit;
  pdial.phonebit:=curpulsedial.phonebit;
end;

procedure loadccc;
var dumbset  :ccc_companytype;
    x        :byte;
begin
  with dumbset do begin
    name:=blankpbentry;
    number:='';
    numberfirst:=false;
    startseq:='';
    endseq:='';
    numdelay:=0;
    comeuptime:=0;
    recorddelay:=0;
    samplerate:=8000;
    sampletime:=0;
  end;
  if not sosexist(cccfilename) then begin
    say('Creating new Card Checker data');
    sosopen;
    sosfcreate(cccfilename);
    for x:=1 to maxcompanies do soswrite(@dumbset,sizeof(dumbset));
    sosclose;
  end;
  if sosbfsize(cccfilename)<>sizeof(ccc_companytype)*maxcompanies then
    fatalerror('Incompatible Calling Card Checker file ('+cccfilename+').');
  sosopen;
  sosfopen(cccfilename);
  sosseek(sizeof(ccc_companytype)*(config.curcompany-1));
  sosread(@curccc,sizeof(curccc));
  sosclose;
end;

procedure loadcolors;
var dumbset  :colortype;
begin
  with dumbset do begin
    normal               := blue;
    high                 := lightblue;
    high2                := white;
    super_high           := white;
    dark                 := darkgray;
    error                := white;
    error_reverse        := red*16+white;
    reverse              := blue*16+white;
    reverse_high         := blue*16+yellow;
    special              := cyan;
    special_high         := lightcyan;
    special_dark         := darkgray;
    special_reverse      := cyan*16+white;
    special_reverse_high := cyan*16+yellow;
    status               := blue*16+white;
    status_high          := blue*16+yellow;
    win_border_1         := lightcyan;
    win_border_2         := lightblue;
    win_border_3         := blue;
    win_text             := lightblue;
    win_text_high        := lightcyan;
    win_hilight          := blue*16+white;
    win_hilight_high     := blue*16+yellow;
    win_item             := lightcyan;
    win_arrows           := blue*16+lightblue;
    win_fill             := blue;
    win_error            := lightred;
    win_title            := lightcyan;
    win_background       := black;
    knob_active          := blue*16+white;
    knob_inactive        := lightblue;
    shadow               := darkgray;
    help_normal          := blue*16+white;
    help_high            := blue*16+yellow;
    help_border_1        := blue*16+lightblue;
    help_border_2        := blue*16+lightblue;
    help_border_3        := blue*16+lightblue;
    help_title           := blue*16+lightred;
    help_index           := cyan*16+black;
    help_selected_index  := cyan*16+white;
    inputfield           := cyan*16+white;
    infoline             := blue*16+white;
    infoline_high        := blue*16+yellow;
    progressbar          := blue*16+white;
    keypad_pressed       := blue*16+white;
    keypad_released      := lightcyan;
    titlebox             := blue*16;
    titlebox_border      := blue*16+lightblue;
    titlebox_high        := blue*16+white;
    titlebox_inverse     := lightblue;
    titlebox_title       := blue*16+yellow;
    worldtime_ahead      := yellow;
  end;
  if not sosexist(colorfilename) then begin
    say('Creating new color file');
    sosopen;
    sosfcreate(colorfilename);
    soswrite(@dumbset,sizeof(dumbset));
    sosclose;
  end;
  if sosbfsize(colorfilename)<>sizeof(colortype) then fatalerror('Incompatible color file ('+colorfilename+').');
  sosopen;
  sosfopen(colorfilename);
  sosread(@colors,sizeof(colors));
  sosclose;
end;

procedure showvideo;
begin
  if parameter('/FORCEVMEMLO') then begin
    {say('Video memory forced to $B000');}
    vadr:=$B000;
    exit;
  end;
  if parameter('/FORCEVMEMHI') then begin
    {say('Video memory forced to $B800');}
    vadr:=$B800;
    exit;
  end;
  {say('Detected '+videocards[card]+' adapter w/');
  if vcolor then write('color') else write('mono');
  write(' scrn, video seg @ ');
  if vadr=$B800 then write('$B800') else write('$B000');}
end;

procedure loaddtl;
var dumbset  :dtltype;
    x        :byte;
begin
  with dumbset do begin
    name:='OFF';
    note:='Do not convert number at all';
    local:='&1';            { Make dumb defaults                 }
    global:='&1';
    special:='&1';
    autolocal:='';
  end;
  if not sosexist(dtlfilename) then begin
    say('Creating new Dial Translation file');
    sosopen;
    sosfcreate(dtlfilename);
    soswrite(@dumbset,sizeof(dumbset));
    with dumbset do begin
      name:='-Unused-';
      note:='Describe translation here';
      local:='';
      global:='';
      special:='';
      autolocal:='';
    end;
    for x:=1 to maxdtlsets-1 do soswrite(@dumbset,sizeof(dumbset));
    sosclose;
  end;
  if sosbfsize(dtlfilename)<>(maxdtlsets*sizeof(dtltype)) then
    fatalerror('Incompatible Dial Translation file ('+dtlfilename+').');
  sosopen;
  sosfopen(dtlfilename);
  sosseek(sizeof(dtltype)*(config.activedtl-1));
  sosread(@curdtl,sizeof(curdtl));
  sosclose;
end;

procedure loadccodes;
var x :word;
begin
  if not sosexist(ccodefilename) then
    fatalerror('Country Code database ['+ccodefilename+'] not found! Recompile & add.');
  ccodecnt:=round(sosbfsize(ccodefilename)/sizeof(ccodetype));
  sosopen;
  sosfopen(ccodefilename);
  for x:=1 to ccodecnt do begin
    new(ccodes[x]);
    sosread(ccodes[x],sizeof(ccodetype));
  end;
  sosclose;
end;

procedure initnumflags;
var x:word;
begin
  for x:=1 to maxnums do numflags[x]:=false;
end;

procedure init(project:string);
begin
  checkbreak:=false;
  oldattr:=textattr;
  showvideo;
  new(dossave);
  move(mem[vadr:0],dossave^,4000);
  oldx:=wherex; oldy:=wherey;
  colors.error:=white;                 { In case of error on initialisation,  }
  colors.error_reverse:=red*16+white;  { show error messages in default color }
  colors.infoline:=blue*16+white;      { set infoline default color           }
  colors.inputfield:=yellow;
  textattr:=cyan;
  setcursorsize($32,$32);
  writeln('Welcome to BlueBEEP v',version,' (C) 1993-1994 by Onkel Dittmeyer');
  writeln;
  writeln('Preinitialization in process!');
  sos.masterfile:=fexpand(paramstr(0));
  sos.masterindex:=exesize;
  writeln('Executable file at ',sos.masterfile);
  writeln('Overlay index at offset ',sos.masterindex);
  if parameter('/?') then paraminfo;
  if parameter('/PLAINDOC') then convertdocs;
  if parameter('/CONVCC') then convertccodes;
  if parameter('/ADD') then begin wildadd(sos.masterfile,paramstr(2)); halt; end;
  if parameter('/DIR') then begin sosdir(sos.masterfile); halt; end;
  clrscr;
  if check_userid then begin
    userid:=getenv('BBP_UID');
    userpass:=uppercase(getenv('BBP_UPW'));
    if userid='' then begin
      writeln('You''re about loading up a NON-PUBLIC BETA RELEASE of ',project);
      writeln;
      writeln('A beta test key is required in order to start it up.');
      writeln;
      writeln('Your user ID was not found in the environment, please enter it now.');
      writeln('Note: You can also put your ID into the environment by typing SET BBP_UID=<id>');
      writeln('at the DOS prompt. For the password use SET BBP_UPW=<pw>.');
      writeln;
      write(' User ID: ');
      userid:='';
      edit(userid,40);
      writeln;
    end;
    if userpass='' then begin
      write('Password: ');
      editpass(userpass,40);
      writeln;
    end;
    recheck_id;
  end;
  for x:=24 downto 3 do begin
    move(beeplogo[160*3],mem[vadr:x*160],4000-(x*160));
    delayms(10);
  end;
  move(beeplogo,mem[vadr:0],4000);
  bottominfo(' BlueBEEP is initializing, please hold...');
  textattr:=lightcyan;
  center(17,'BlueBEEP! v     ');
  center(18,'Copyright (C) 1993-1994 by Onkel Dittmeyer');
  center(19,'All Rights Are Lust!');
  center(21,'Released: '+releasedate);
  textattr:=lightcyan;
  gotoxy(43,17);
  write(version);
  setcursorsize($6,$7);
  say(project+' firing up on '+date+' at '+time(true));
  say('Free heap memory '+stg(memavail)+', maxavail block '+stg(maxavail)+' bytes');
  say('Initializing Sound Card');        soundinit;
  say('Loading Configuration');          loadconfig;
  say('Loading Dial Sets');              loaddialsets;
  say('Loading Trunks');                 loadtrunks;
  say('Initializing phonetags');         initnumflags;
  loadphonebook;
  say('Loading Scan');                   loadscan;
  say('Loading Red Box');                loadredbox;
  say('Loading Frequency Test');         loadfreqtest;
  say('Loading Pulse Dialer');           loadpulsedial;
  say('Loading Card Checker');           loadccc;
  say('Loading Colors');                 loadcolors;
  say('Loading Dial Translation'); loaddtl;
  say('Loading Country Codes');          loadccodes;
  if parameter('/NOMODEM') then begin
    say('Modem FORCED off');
    config.modem:=false;
  end;
  if config.modem then begin
    say('Initializing Modem           ');
    initmodem;
  end;
  if parameter('/NOMOUSE') then begin
    say('Mouse FORCED off');
    mousepresent:=false;
  end else begin
    say('Detecting Mouse');
    mousepresent:=initmouse;
    if mousepresent then mouseoff;
  end;
  if not(parameter('/NOMOUSE')) then
    if mousepresent then say('Mouse driver detected')
      else say('Mouse driver not detected');
  say('Initialisation Complete at '+time(true));
  if parameter('/DEBUG') then begin
    write('Press [ENTER]...');
    readln;
  end;
  if paramcount>0 then if config.password<>'' then begin
    writeln;
    writeln('Can''t use command line parameters when password protection');
    writeln('is ON. Start BlueBEEP without parms and remove password lock.');
    writeln;
    halt(0);
  end;
  say('" Hire Onkel Dittmeyer " release - Check docs for details.');
  bottominfo(' BlueBEEP is initializing, please hold... OKAY!');
end;

procedure startup;
begin
  curpos:=1;
  textattr:=yellow;
  setcursorsize($32,$32);
  if parameter('/A') then phreakout;
  if parameter('/S') then scanmode;
  if parameter('/R') then redboxit;
  if parameter('/T') then cardtalker;
  if parameter('/F') then freqtester;
  if parameter('/C') then cardchecker;
  {if parameter('/TERM') then tinyterm;}
  if parameter('/EXEC') then loadscript(uppercase(paramstr(2)));
  openbox(1,1,1,80,3,false,true,true);
  ignbox(1);
  if config.password<>'' then passwordcheck;
  if mousepresent then mouserange(1,1,80,25);
  item[1]:=' ~S~etup         ';
  item[2]:=' ~T~ools         ';
  item[3]:=' ~P~HREAK OUT!   ';
  item[4]:=' ~I~nfo          ';
  item[5]:=' ~Q~uit       ';
  itemcount:=5;
  skip:=false;
  for x:=1 to 5 do begin
    gotoxy(((x-1)*(80 div itemcount))+3,2);
    iwrite(item[x],x=curpos);
  end;
end;
end.
