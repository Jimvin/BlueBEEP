unit bbp_set;

interface

procedure setup;

implementation

uses bbp_vars, extras, crt, editrout, grmenus, grwins,
     video, bbp_proc, optimer, vgagraph, bbp_init, sos;

procedure setup;
var choice :byte;

procedure editdialsets;
var x    :byte;
    dset :dialsettype;
    res  :byte;
    save :array[1..4000] of byte;

procedure editset(setnr:byte);
var workset :dialsettype;
    res,x   :byte;
procedure edittone(var t:tonetype2;l:byte);
begin
  setcursorsize($6,$7);
  gotoxy(24,l); editword(t.one); gotoxy(24,l); write(t.one:4);
  gotoxy(32,l); editword(t.two); gotoxy(32,l); write(t.two:4);
  gotoxy(40,l); editword(t.three); gotoxy(40,l); write(t.three:4);
  gotoxy(48,l); editword(t.mark); gotoxy(48,l); write(t.mark:4);
  gotoxy(56,l); editword(t.space); gotoxy(56,l); write(t.space:4);
  setcursorsize($32,$32);
end;
procedure showtone(t:tonetype2;l:byte);
begin
  gotoxy(24,l); write(t.one:4);
  gotoxy(32,l); write(t.two:4);
  gotoxy(40,l); write(t.three:4);
  gotoxy(48,l); write(t.mark:4);
  gotoxy(56,l); write(t.space:4);
end;
begin
  sosopen;
  sosfopen(dsfilename);
  sosseek(sizeof(dialsettype)*(setnr-1));
  sosread(@workset,sizeof(workset));
  sosclose;
  res:=1;
  menuitem[1]:='Standard';
  menuitem[2]:='Description';
  menuitem[3]:='1';
  menuitem[4]:='2';
  menuitem[5]:='3';
  menuitem[6]:='4';
  menuitem[7]:='5';
  menuitem[8]:='6';
  menuitem[9]:='7';
  menuitem[10]:='8';
  menuitem[11]:='9';
  menuitem[12]:='0';
  menuitem[13]:='C11';
  menuitem[14]:='C12';
  menuitem[15]:='*';
  menuitem[16]:='#';
  menuitem[17]:='KP1';
  menuitem[18]:='KP2';
  menuitem[19]:='ST';
  menuitem[20]:='KP2E';
  menuitem[21]:='STE';
  menuitem[22]:='EO';
  menucount:=22;
  openbox(1,18,2,80,25,false,true,false);
  textattr:=colors.win_text_high;
  gotoxy(23,25); write('Freq1');
  gotoxy(31,25); write('Freq2');
  gotoxy(39,25); write('Freq3');
  gotoxy(48,25); write('Mark');
  gotoxy(55,25); write('Space');
  textattr:=colors.win_text;
  repeat
    gotoxy(1,1);
    textattr:=colors.titlebox_high;
    write(' Editing Dial Set: ',workset.standard);
    clreol;
    textattr:=colors.win_text;
    gotoxy(24,3); write(workset.standard);
    gotoxy(24,4); write(workset.description);
    for x:=1 to 9 do showtone(workset.tone[x],x+4);
    showtone(workset.tone[0],14);
    showtone(workset.c11,15);
    showtone(workset.c12,16);
    showtone(workset.stern,17);
    showtone(workset.raute,18);
    showtone(workset.kp1,19);
    showtone(workset.kp2,20);
    showtone(workset.st,21);
    showtone(workset.kp2e,22);
    showtone(workset.ste,23);
    showtone(workset.eo,24);
    res:=menu(1,2,res,false,false,false,false,true);
    case res of
      1 :begin
           gotoxy(24,3);
           setcursorsize($6,$7);
           edit(workset.standard,8);
           setcursorsize($32,$32);
         end;
      2 :begin
           gotoxy(24,4);
           setcursorsize($6,$7);
           edit(workset.description,55);
           setcursorsize($32,$32);
         end;
      3 :edittone(workset.tone[1],5);
      4 :edittone(workset.tone[2],6);
      5 :edittone(workset.tone[3],7);
      6 :edittone(workset.tone[4],8);
      7 :edittone(workset.tone[5],9);
      8 :edittone(workset.tone[6],10);
      9 :edittone(workset.tone[7],11);
     10 :edittone(workset.tone[8],12);
     11 :edittone(workset.tone[9],13);
     12 :edittone(workset.tone[0],14);
     13 :edittone(workset.c11,15);
     14 :edittone(workset.c12,16);
     15 :edittone(workset.stern,17);
     16 :edittone(workset.raute,18);
     17 :edittone(workset.kp1,19);
     18 :edittone(workset.kp2,20);
     19 :edittone(workset.st,21);
     20 :edittone(workset.kp2e,22);
     21 :edittone(workset.ste,23);
     22 :edittone(workset.eo,24);
    end;
  until res=0;
  closebox(1);
  sosopen;
  sosfopen(dsfilename);
  sosseek(sizeof(dialsettype)*(setnr-1));
  soswrite(@workset,sizeof(workset));
  sosclose;
end;
begin
  move(mem[vadr:0],save,4000);
  res:=config.curdset;
  repeat
    sosopen;
    sosfopen(dsfilename);
    for x:=1 to maxdialsets do begin
      sosread(@dset,sizeof(dset));
      menuitem[x]:=dset.standard;
      menuinfo[x]:=dset.description;
    end;
    sosclose;
    menucount:=maxdialsets;
    res:=menu(1,4,res,false,false,true,false,true);
    if res<>0 then editset(res);
  until res=0;
  move(save,mem[vadr:0],4000);
end;

procedure edittrunks;
var worktrunk :trunktype;
    save      :array[1..4000] of byte;
    res       :byte;
procedure edittrunk(trunknr:byte);
var worktrunk:trunktype;
    res      :byte;
procedure edittone(tonenr:byte);
begin
  setcursorsize($6,$7);
  with worktrunk.tone[tonenr] do begin
    gotoxy(39,10+tonenr); editword(one); gotoxy(39,10+tonenr); write(one:4);
    gotoxy(47,10+tonenr); editword(two); gotoxy(47,10+tonenr); write(two:4);
    gotoxy(56,10+tonenr); editword(three); gotoxy(56,10+tonenr); write(three:4);
    gotoxy(65,10+tonenr); editword(len); gotoxy(65,10+tonenr); write(len:4);
  end;
  gotoxy(72,10+tonenr); editword(worktrunk.pause[tonenr]);
  gotoxy(72,10+tonenr); write(worktrunk.pause[tonenr]:4);
  setcursorsize($32,$32);
end;

begin
  res:=1;
  sosopen;
  sosfopen(trunkfilename);
  sosseek(sizeof(trunktype)*(trunknr-1));
  sosread(@worktrunk,sizeof(worktrunk));
  sosclose;
  menuitem[1]:='Name';
  menuitem[2]:='Description';
  menuitem[3]:='Tone #01';
  menuitem[4]:='Tone #02';
  menuitem[5]:='Tone #03';
  menuitem[6]:='Tone #04';
  menuitem[7]:='Tone #05';
  menuitem[8]:='Tone #06';
  menuitem[9]:='Tone #07';
  menuitem[10]:='Tone #08';
  menuitem[11]:='Tone #09';
  menuitem[12]:='Tone #10';
  menuitem[13]:='Play trunk';
  menuinfo[1]:='Edit trunk''s name';
  menuinfo[2]:='Edit trunk''s description, or a short note';
  menuinfo[3]:='Edit 1st tone';
  menuinfo[4]:='Edit 2nd tone';
  menuinfo[5]:='Edit 3rd tone';
  menuinfo[6]:='Edit 4th tone';
  menuinfo[7]:='Edit 5th tone';
  menuinfo[8]:='Edit 6th tone';
  menuinfo[9]:='Edit 7th tone';
  menuinfo[10]:='Edit 8th tone';
  menuinfo[11]:='Edit 9th tone';
  menuinfo[12]:='Edit 10th tone';
  menuinfo[13]:='Play trunk for testing purposes, or just to get the "sound of boxing" :)';
  menucount:=13;
  openbox(5,35,8,77,22,true,true,false);
  textattr:=colors.win_text_high;
  gotoxy(38,22); write('Freq1');
  gotoxy(46,22); write('Freq2');
  gotoxy(55,22); write('Freq3');
  gotoxy(64,22); write('Length');
  gotoxy(72,22); write('Pause');
  textattr:=colors.win_text;
  gotoxy(39,9);  write(worktrunk.name);
  gotoxy(39,10); write(worktrunk.description);
  for x:=1 to 10 do begin
    gotoxy(39,x+10);
    with worktrunk.tone[x] do write(one:4,'    ',two:4,'     ',three:4,'     ',len:4,'   ',worktrunk.pause[x]:4);
  end;
  repeat
    res:=menu(18,8,res,false,false,true,false,true);
    case res of
      1:begin
          gotoxy(39,9);
          setcursorsize($6,$7);
          edit(worktrunk.name,8);
          setcursorsize($32,$32);
        end;
      2:begin
          gotoxy(39,10);
          setcursorsize($6,$7);
          edit(worktrunk.description,30);
          setcursorsize($32,$32);
        end;
      3..12:edittone(res-2);
      13:begin
           gotoxy(39,21);
           write('                               ');
           gotoxy(39,21);
           playtrunk(worktrunk,false);
         end;
      end;
      if res<>0 then if res=13 then res:=1 else inc(res);
  until res=0;
  closebox(5);
  sosopen;
  sosfopen(trunkfilename);
  sosseek(sizeof(trunktype)*(trunknr-1));
  soswrite(@worktrunk,sizeof(worktrunk));
  sosclose;
end;
begin
  move(mem[vadr:0],save,4000);
  res:=config.curtrunk;
  repeat
    sosopen;
    sosfopen(trunkfilename);
    for x:=1 to maxtrunks do begin
      sosread(@worktrunk,sizeof(worktrunk));
      menuitem[x]:=worktrunk.name;
      menuinfo[x]:=worktrunk.description;
    end;
    sosclose;
    menucount:=maxtrunks;
    res:=menu(1,4,res,true,false,true,false,true);
    if res<>0 then edittrunk(res);
  until res=0;
  move(save,mem[vadr:0],4000);
end;

procedure editredbox;
var choice:byte;
begin
  choice:=1;
  menuitem[1]:='ACTS';
  menuitem[2]:='IPTS';
  menuitem[3]:='Non-ACTS';
  menuinfo[1]:='Edit ACTS Coin Signalling Frequencies';
  menuinfo[2]:='Edit IPTS Coin Signalling Frequencies';
  menuinfo[3]:='Edit Non-ACTS Coin Signalling Frequencies';
  menucount:=3;
  openbox(2,15,4,30,8,true,true,false);
  repeat
    textattr:=colors.win_text;
    gotoxy(18,5); write(curredbox.acts1:4);
    gotoxy(25,5); write(curredbox.acts2:4);
    gotoxy(18,6); write(curredbox.ipts1:4);
    gotoxy(25,6); write(curredbox.ipts2:4);
    gotoxy(18,7); write(curredbox.nonacts:4);
    choice:=menu(1,4,choice,false,false,true,false,true);
    case choice of
      1:begin
          setcursorsize($6,$7);
          gotoxy(18,5); editword(curredbox.acts1);
          gotoxy(18,5); write(curredbox.acts1:4);
          gotoxy(25,5); editword(curredbox.acts2);
          gotoxy(25,5); write(curredbox.acts2:4);
          setcursorsize($32,$32);
        end;
      2:begin
          setcursorsize($6,$7);
          gotoxy(18,6); editword(curredbox.ipts1);
          gotoxy(18,6); write(curredbox.ipts1:4);
          gotoxy(25,6); editword(curredbox.ipts2);
          gotoxy(25,6); write(curredbox.ipts2:4);
          setcursorsize($32,$32);
        end;
      3:begin
          setcursorsize($6,$7);
          gotoxy(18,7); editword(curredbox.nonacts);
          gotoxy(18,7); write(curredbox.nonacts:4);
          setcursorsize($32,$32);
        end;
      end;
  until choice=0;
  closebox(2);
  sosopen;
  sosfopen(redboxfilename);
  soswrite(@curredbox,sizeof(curredbox));
  sosclose;
end;

procedure passprotect;
var s,s2:string;
begin
  openbox(1,10,5,70,11,true,true,false);
  textattr:=colors.win_title;
  center(5,'Password Protection');
  gotoxy(15,7);
  textattr:=colors.win_text;
  if config.password<>'' then begin
    write('Old password: ');
    s:='';
    bottominfo('Enter the old (current) password for BlueBEEP!');
    setcursorsize($6,$7); editpass(s,20); setcursorsize($32,$32);
    if s<>config.password then begin
      sound(200); delayms(2000); nosound;
      closebox(1);
      exit;
    end;
  end else writeln('Old password: <NONE>');
  gotoxy(15,8);
  write('New password: ');
  s:='';
  bottominfo('Enter the new password for BlueBEEP! or press <ENTER> for none');
  setcursorsize($6,$7);
  editpass(s,20);
  gotoxy(16,9);
  write('Enter again: ');
  s2:='';
  bottominfo('Re-Enter the new password or press <ENTER> for none');
  editpass(s2,20);
  setcursorsize($32,$32);
  if s<>s2 then begin
    center(11,'They dont match!');
    delayms(1000);
    closebox(1);
    exit;
  end;
  config.password:=s;
  closebox(1);
  writeconfig;
end;

procedure sbconfig;
var choice:byte;
begin
  choice:=1;
  menuitem[1]:='SoundBlaster present';
  menuitem[2]:='SoundBlaster Interrupt';
  menuitem[3]:='SoundBlaster Adress';
  menuinfo[1]:='<RETURN> to toggle Soundblaster Presence';
  menuinfo[2]:='<RETURN> to choose Sound Blaster DMA Interrupt';
  menuinfo[3]:='<RETURN> to choose Sound Blaster I/O Adress';
  menucount:=3;
  openbox(2,29,4,67,8,true,true,false);
  repeat
    textattr:=colors.knob_inactive;
    gotoxy(31,5); write(' Yes   No ');
    gotoxy(31,6); write(' 2   3   5   7 ');
    gotoxy(31,7); write(' 220   230   240   250   260   270 ');
    if config.gotblaster then vmemwrite(31,5,' Yes ',colors.knob_active)
      else vmemwrite(37,5,' No ',colors.knob_active);
    if config.sbint=2 then vmemwrite(31,6,' 2 ',colors.knob_active);
    if config.sbint=3 then vmemwrite(35,6,' 3 ',colors.knob_active);
    if config.sbint=5 then vmemwrite(39,6,' 5 ',colors.knob_active);
    if config.sbint=7 then vmemwrite(43,6,' 7 ',colors.knob_active);
    if config.sbaddr=$220 then vmemwrite(31,7,' 220 ',colors.knob_active);
    if config.sbaddr=$230 then vmemwrite(37,7,' 230 ',colors.knob_active);
    if config.sbaddr=$240 then vmemwrite(43,7,' 240 ',colors.knob_active);
    if config.sbaddr=$250 then vmemwrite(49,7,' 250 ',colors.knob_active);
    if config.sbaddr=$260 then vmemwrite(55,7,' 260 ',colors.knob_active);
    if config.sbaddr=$270 then vmemwrite(61,7,' 270 ',colors.knob_active);
    choice:=menu(1,4,choice,false,false,true,false,true);
    case choice of
      1:config.gotblaster:=not(config.gotblaster);
      2:case config.sbint of
          2 :config.sbint:=3;
          3 :config.sbint:=5;
          5 :config.sbint:=7;
          7 :config.sbint:=2;
        end;
      3:if config.sbaddr<$270 then inc(config.sbaddr,$10) else config.sbaddr:=$220;
    end;
  until choice=0;
  writeconfig;
  closebox(2);
end;

procedure pulsedialconfig;
var choice:byte;
procedure modify(y:byte;var data:word);
begin
  setcursorsize($6,$7);
  gotoxy(36,y); editword(data);
  gotoxy(36,y); write(data:5);
  setcursorsize($32,$32);
end;
begin
  choice:=1;
  menuitem[1]:='Dialtone Wait';
  menuitem[2]:='Digit Mark Time';
  menuitem[3]:='Digit Space Time';
  menuitem[4]:='Inter-Digit Delay';
  menuitem[5]:='I/O Port Adress';
  menuitem[6]:='Hookbit Position';
  menuitem[7]:='Play/Rec Bit Pos.';
  menuitem[8]:='Phone Bit Pos.';
  menuitem[9]:='Play/Rec Relay access time';
  menuitem[10]:='Hangup Time';
  menuinfo[1]:='Time to wait for dialtone after going on-hook in ms';
  menuinfo[2]:='Digit Mark Time in miliseconds';
  menuinfo[3]:='Digit Space Time in miliseconds';
  menuinfo[4]:='Inter-Digit Delay (delay between numbers)';
  menuinfo[5]:='I/O Port Adress of your BlueBEEP hardware device';
  menuinfo[6]:='Which bit is the hook relay on your device (0-7)';
  menuinfo[7]:='Which bit is the play/record bit on your device (0-7)';
  menuinfo[8]:='Which bit is the phone enable/disable bit on your device (0-7)';
  menuinfo[9]:='Play/Record Toggle Relay Access Time in milliseconds';
  menuinfo[10]:='How long to hang up before redialing';
  menucount:=10;
  openbox(2,33,4,42,15,true,true,false);
  textattr:=colors.win_text;
  gotoxy(36,5); write(curpulsedial.waitfordt:5);
  gotoxy(36,6); write(curpulsedial.pulse_mark:5);
  gotoxy(36,7); write(curpulsedial.pulse_space:5);
  gotoxy(36,8); write(curpulsedial.pulse_interdig:5);
  gotoxy(36,9); write(curpulsedial.portadress:5);
  gotoxy(36,10); write(curpulsedial.hookbit:5);
  gotoxy(36,11); write(curpulsedial.playrecbit:5);
  gotoxy(36,12); write(curpulsedial.phonebit:5);
  gotoxy(36,13); write(curpulsedial.accesstime:5);
  gotoxy(36,14); write(curpulsedial.hanguptime:5);
  repeat
    choice:=menu(1,4,choice,false,false,true,false,true);
    case choice of
      1:modify(5,curpulsedial.waitfordt);
      2:modify(6,curpulsedial.pulse_mark);
      3:modify(7,curpulsedial.pulse_space);
      4:modify(8,curpulsedial.pulse_interdig);
      5:modify(9,curpulsedial.portadress);
      6:modify(10,curpulsedial.hookbit);
      7:modify(11,curpulsedial.playrecbit);
      8:modify(12,curpulsedial.phonebit);
      9:modify(13,curpulsedial.accesstime);
     10:modify(14,curpulsedial.hanguptime);
    end;
  until choice=0;
  closebox(2);
  pdial.waitfordt:=curpulsedial.waitfordt;
  pdial.pulse_mark:=curpulsedial.pulse_mark;
  pdial.pulse_space:=curpulsedial.pulse_space;
  pdial.pulse_interdig:=curpulsedial.pulse_interdig;
  pdial.portadress:=curpulsedial.portadress;
  pdial.hookbit:=curpulsedial.hookbit;
  pdial.playrecbit:=curpulsedial.playrecbit;
  pdial.phonebit:=curpulsedial.phonebit;
  sosopen;
  sosfopen(pulsedialfilename);
  soswrite(@curpulsedial,sizeof(curpulsedial));
  sosclose;
end;

procedure colorconfig;
var choice:byte;
begin
  choice:=1;
  menuitem[1]:='Gringo Green';
  menuitem[2]:='Bastard Blue';
  menuitem[3]:='Rushing Red';
  menuitem[4]:='Magenta Madness';
  menuitem[5]:='Lord Disembowelment';
  menuitem[6]:='Black & White';
  menuinfo[1]:='Select "Gringo Green" color set (default) - Old Fashioned!';
  menuinfo[2]:='Select "Bastard Blue" color set - Sea of Love';
  menuinfo[3]:='Select "Rushing Red" color set - for the satanic friends';
  menuinfo[4]:='Select "Magenta Madness" color set - looks pretty cool..';
  menuinfo[5]:='Select the "Lord Disemboweltment" color set... Heh Heh Heh..';
  menuinfo[6]:='Select the Black & White color settings, if you have a mono screen';
  menucount:=6;
  repeat
    choice:=menu(1,4,choice,true,true,true,false,true);
    case choice of
      1:with colors do begin
          normal               := green;
          high                 := lightgreen;
          high2                := yellow;
          super_high           := white;
          dark                 := darkgray;
          error                := white;
          error_reverse        := red*16+white;
          reverse              := green*16+white;
          reverse_high         := green*16+yellow;
          special              := cyan;
          special_high         := lightcyan;
          special_dark         := darkgray;
          special_reverse      := cyan*16+white;
          special_reverse_high := cyan*16+yellow;
          status               := green*16+white;
          status_high          := green*16+yellow;
          win_border_1         := white;
          win_border_2         := lightgreen;
          win_border_3         := green;
          win_text             := lightgreen;
          win_text_high        := yellow;
          win_hilight          := green*16+white;
          win_hilight_high     := green*16+yellow;
          win_item             := yellow;
          win_arrows           := green*16+lightgreen;
          win_fill             := cyan;
          win_error            := lightred;
          win_title            := yellow;
          win_background       := black;
          knob_active          := green*16+white;
          knob_inactive        := lightgreen;
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
          infoline             := green*16+white;
          infoline_high        := green*16+yellow;
          progressbar          := blue*16+white;
          keypad_pressed       := green*16+white;
          keypad_released      := lightgreen;
          titlebox             := green*16;
          titlebox_border      := green*16+lightgreen;
          titlebox_high        := green*16+white;
          titlebox_inverse     := lightgreen;
          titlebox_title       := green*16+yellow;
          worldtime_ahead      := yellow;
          startup;
        end;
      2:with colors do begin
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
          startup;
        end;
      3:with colors do begin
          normal               := red;
          high                 := lightred;
          high2                := white;
          super_high           := white;
          dark                 := darkgray;
          error                := white;
          error_reverse        := red*16+white;
          reverse              := red*16+white;
          reverse_high         := red*16+yellow;
          special              := cyan;
          special_high         := lightcyan;
          special_dark         := darkgray;
          special_reverse      := cyan*16+white;
          special_reverse_high := cyan*16+yellow;
          status               := red*16+white;
          status_high          := red*16+yellow;
          win_border_1         := white;
          win_border_2         := lightred;
          win_border_3         := red;
          win_text             := lightred;
          win_text_high        := white;
          win_hilight          := red*16+white;
          win_hilight_high     := red*16+yellow;
          win_item             := white;
          win_arrows           := red*16+lightred;
          win_fill             := red;
          win_error            := lightred;
          win_title            := lightred;
          win_background       := black;
          knob_active          := red*16+white;
          knob_inactive        := lightred;
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
          infoline             := red*16+white;
          infoline_high        := red*16+yellow;
          progressbar          := blue*16+white;
          keypad_pressed       := red*16+white;
          keypad_released      := lightred;
          titlebox             := red*16;
          titlebox_border      := red*16+lightred;
          titlebox_high        := red*16+white;
          titlebox_inverse     := lightred;
          titlebox_title       := red*16+yellow;
          worldtime_ahead      := yellow;
          startup;
        end;
        4: with colors do begin
          normal               := magenta;
          high                 := lightmagenta;
          high2                := white;
          super_high           := white;
          dark                 := darkgray;
          error                := white;
          error_reverse        := red*16+white;
          reverse              := magenta*16+white;
          reverse_high         := magenta*16+yellow;
          special              := cyan;
          special_high         := lightcyan;
          special_dark         := darkgray;
          special_reverse      := cyan*16+white;
          special_reverse_high := cyan*16+yellow;
          status               := magenta*16+white;
          status_high          := magenta*16+yellow;
          win_border_1         := white;
          win_border_2         := lightmagenta;
          win_border_3         := magenta;
          win_text             := lightmagenta;
          win_text_high        := lightcyan;
          win_hilight          := magenta*16+white;
          win_hilight_high     := magenta*16+yellow;
          win_item             := white;
          win_arrows           := magenta*16+lightmagenta;
          win_fill             := blue;
          win_error            := lightred;
          win_title            := lightcyan;
          win_background       := black;
          knob_active          := magenta*16+white;
          knob_inactive        := white;
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
          infoline             := magenta*16+white;
          infoline_high        := magenta*16+yellow;
          progressbar          := magenta*16+white;
          keypad_pressed       := magenta*16+white;
          keypad_released      := lightcyan;
          titlebox             := magenta*16;
          titlebox_border      := magenta*16+lightmagenta;
          titlebox_high        := magenta*16+white;
          titlebox_inverse     := lightblue;
          titlebox_title       := magenta*16+yellow;
          worldtime_ahead      := yellow;
          startup;
        end;
        5: with colors do begin
          normal               := black;
          high                 := black;
          high2                := black;
          super_high           := black;
          dark                 := black;
          error                := black;
          error_reverse        := black;
          reverse              := black;
          reverse_high         := black;
          special              := black;
          special_high         := black;
          special_dark         := black;
          special_reverse      := black;
          special_reverse_high := black;
          status               := black;
          status_high          := black;
          win_border_1         := black;
          win_border_2         := black;
          win_border_3         := black;
          win_text             := black;
          win_text_high        := black;
          win_hilight          := black;
          win_hilight_high     := black;
          win_item             := black;
          win_arrows           := black;
          win_fill             := black;
          win_error            := black;
          win_title            := black;
          win_background       := black;
          knob_active          := black;
          knob_inactive        := black;
          shadow               := black;
          help_normal          := black;
          help_high            := black;
          help_border_1        := black;
          help_border_2        := black;
          help_border_3        := black;
          help_title           := black;
          help_index           := black;
          help_selected_index  := black;
          inputfield           := black;
          infoline             := black;
          infoline_high        := black;
          progressbar          := black;
          keypad_pressed       := black;
          keypad_released      := black;
          titlebox             := black;
          titlebox_border      := black;
          titlebox_high        := black;
          titlebox_inverse     := black;
          titlebox_title       := black;
          worldtime_ahead      := black;
          startup;
        end;
        6: with colors do begin
          normal               := lightgray;
          high                 := white;
          high2                := white;
          super_high           := white;
          dark                 := darkgray;
          error                := white;
          error_reverse        := white*16+black-blink;
          reverse              := white*16+black-blink;
          reverse_high         := white*16+black-blink;
          special              := lightgray;
          special_high         := white;
          special_dark         := darkgray;
          special_reverse      := white*16+black-blink;
          special_reverse_high := white*16+black-blink;
          status               := white*16+black-blink;
          status_high          := white*16+black-blink;
          win_border_1         := lightgray;
          win_border_2         := lightgray;
          win_border_3         := lightgray;
          win_text             := white*16+black-blink;
          win_text_high        := white*16+white-blink;
          win_hilight          := white*16+black-blink;
          win_hilight_high     := white*16+white-blink;
          win_item             := white;
          win_arrows           := white*16+white-blink;
          win_fill             := lightgray;
          win_error            := white;
          win_title            := white*16+white-blink;
          win_background       := white*16;
          knob_active          := white*16+black-blink;
          knob_inactive        := white;
          shadow               := darkgray;
          help_normal          := lightgray;
          help_high            := white;
          help_border_1        := lightgray;
          help_border_2        := lightgray;
          help_border_3        := lightgray;
          help_title           := white;
          help_index           := white*16+black-blink;
          help_selected_index  := white*16+white-blink;
          inputfield           := white*16+black-blink;
          infoline             := white*16+black-blink;
          infoline_high        := white*16+white-blink;
          progressbar          := white*16+black-blink;
          keypad_pressed       := white*16+black-blink;
          keypad_released      := white;
          titlebox             := white*16+black-blink;
          titlebox_border      := white*16+white-blink;
          titlebox_high        := white*16+white-blink;
          titlebox_inverse     := white;
          titlebox_title       := white*16+white-blink;
          worldtime_ahead      := white;
          startup;
        end;
    end;
  until choice=0;
  sosopen;
  sosfopen(colorfilename);
  soswrite(@colors,sizeof(colors));
  sosclose;
end;

procedure cardcheckerconfig;
begin end; { this got destroyed in the big winter 1993 crash.
             i am too lazy to write a new setup at this point -
             follow the other examples and write one for yourself.
             the card checker is an obsolete feature now, anyway.
                               - od 03/20/95 }

procedure modemconfig;
var choice :byte;
begin
  openbox(2,21,4,64,13,true,true,false);
  menuitem[1]:='Modem present';
  menuitem[2]:='Modem COM port';
  menuitem[3]:='Modem speed';
  menuitem[4]:='Phone System';
  menuitem[5]:='Init String';
  menuitem[6]:='Data Bits';
  menuitem[7]:='Parity';
  menuitem[8]:='Stop Bits';
  menuinfo[1]:='Modem presence, should BlueBEEP use it or not';
  menuinfo[2]:='Modem COM port';
  menuinfo[3]:='Modem speed';
  menuinfo[4]:='Phone System, either rotary (analog) or touch tone (DTMF digital switch)';
  menuinfo[5]:='Initialization string; blank=only reset port, "|" = cr, "~" = pause';
  menuinfo[6]:='Data Bits';
  menuinfo[7]:='Parity';
  menuinfo[8]:='Stop Bits';
  menucount:=8;
  choice:=1;
  gotoxy(24,6); write(config.modemport:4);
  gotoxy(24,7); write(config.modemspeed:5);
  gotoxy(24,9); write(config.modeminit);
  repeat
    if config.modem then begin
      vmemwrite(24,5,' Yes ',colors.knob_active);
      vmemwrite(30,5,' No ',colors.knob_inactive);
    end else begin
      vmemwrite(24,5,' Yes ',colors.knob_inactive);
      vmemwrite(30,5,' No ',colors.knob_active);
    end;
    if config.phonesystem then begin
      vmemwrite(24,8,' Touch-Tone ',colors.knob_active);
      vmemwrite(37,8,' Rotary ',colors.knob_inactive);
    end else begin
      vmemwrite(24,8,' Touch-Tone ',colors.knob_inactive);
      vmemwrite(37,8,' Rotary ',colors.knob_active);
    end;
    if config.modemdatabits=7 then begin
      vmemwrite(24,10,' 7 ',colors.knob_active);
      vmemwrite(28,10,' 8 ',colors.knob_inactive);
    end else begin
      vmemwrite(24,10,' 7 ',colors.knob_inactive);
      vmemwrite(28,10,' 8 ',colors.knob_active);
    end;
    gotoxy(24,11);write(' None   Even   Odd   Zero   One ');
    textattr:=colors.win_text;
    case config.modemparity of
      0 :vmemwrite(24,11,' None ',colors.knob_active);
      1 :vmemwrite(31,11,' Even ',colors.knob_active);
      2 :vmemwrite(38,11,' Odd ',colors.knob_active);
      3 :vmemwrite(44,11,' Zero ',colors.knob_active);
      4 :vmemwrite(51,11,' One ',colors.knob_active);
    end;
    vmemwrite(24,12,' 1 ',colors.knob_active);
    choice:=menu(1,4,choice,false,false,true,false,true);
    case choice of
      1:begin
          config.modem:=not(config.modem);
        end;
      2:begin
          setcursorsize($6,$7);
          gotoxy(24,6); editword(config.modemport);
          gotoxy(24,6); write(config.modemport:4);
          setcursorsize($32,$32);
        end;
      3:begin
          setcursorsize($6,$7);
          gotoxy(24,7); editword(config.modemspeed);
          gotoxy(24,7); write(config.modemspeed:5);
          setcursorsize($32,$32);
        end;
      4:begin
          config.phonesystem:=not(config.phonesystem);
        end;
      5:begin;
          setcursorsize($6,$7);
          gotoxy(24,9); edit(config.modeminit,40);
          gotoxy(24,9); write(config.modeminit);
          setcursorsize($32,$32);
        end;
      6:begin
          if config.modemdatabits=7 then config.modemdatabits:=8 else
            config.modemdatabits:=7;
        end;
      7:begin
          if config.modemparity=4 then config.modemparity:=0
            else inc(config.modemparity);
        end;
      end;
  until choice=0;
  writeconfig;
  closebox(2);
end;

procedure dtlconfig;
var workrec :dtltype;
    res     :byte;

procedure editdtl(nr:byte);
var choice    :byte;
    workrec   :dtltype;
begin
  sosopen;
  sosfopen(dtlfilename);
  sosseek(sizeof(dtltype)*(nr-1));
  sosread(@workrec,sizeof(workrec));
  sosclose;
  choice:=1;
  menuitem[1]:='Entry Name';
  menuitem[2]:='Entry Note';
  menuitem[3]:='Local Xlation';
  menuitem[4]:='Global Xlation';
  menuitem[5]:='Special Xlation';
  menuitem[6]:='AutoLocal CC';
  menuinfo[1]:='You may enter any name for this trunk';
  menuinfo[2]:='Use this field for any notes if required';
  menuinfo[3]:='Edit translation for local, unprefixed calls';
  menuinfo[4]:='Edit translation for global, "+"-prefixed calls';
  menuinfo[5]:='Edit translation for special, "*"-prefixed calls';
  menuinfo[6]:='Enter the country code for this xlation to be local (blank=strip none)';
  menucount:=6;
  openbox(2,22,4,52,11,true,true,false);
  textattr:=colors.win_text;
  gotoxy(24,5); write(workrec.name);
  gotoxy(24,6); write(workrec.note);
  gotoxy(24,7); write(workrec.local);
  gotoxy(24,8); write(workrec.global);
  gotoxy(24,9); write(workrec.special);
  gotoxy(24,10); write(workrec.autolocal);
  choice:=1;
  repeat
    choice:=menu(1,4,choice,false,false,true,false,true);
    case choice of
      1:begin
          setcursorsize($6,$7);
          gotoxy(24,5); edit(workrec.name,28);
          setcursorsize($32,$32);
        end;
      2:begin
          setcursorsize($6,$7);
          gotoxy(24,6); edit(workrec.note,28);
          setcursorsize($32,$32);
        end;
      3:begin
          setcursorsize($6,$7);
          gotoxy(24,7); edit(workrec.local,28);
          setcursorsize($32,$32);
        end;
      4:begin
          setcursorsize($6,$7);
          gotoxy(24,8); edit(workrec.global,28);
          setcursorsize($32,$32);
        end;
      5:begin
          setcursorsize($6,$7);
          gotoxy(24,9); edit(workrec.special,28);
          setcursorsize($32,$32);
        end;
      6:begin
          setcursorsize($6,$7);
          gotoxy(24,10); edit(workrec.autolocal,3);
          setcursorsize($32,$32);
        end;
      end;
  until choice=0;
  closebox(2);
  sosopen;
  sosfopen(dtlfilename);
  sosseek(sizeof(dtltype)*(nr-1));
  soswrite(@workrec,sizeof(workrec));
  sosclose;
end;

begin
  move(mem[vadr:0],save,4000);
  res:=config.activedtl;
  repeat
    sosopen;
    sosfopen(dtlfilename);
    for x:=1 to maxdtlsets do begin
      sosread(@workrec,sizeof(workrec));
      menuitem[x]:=workrec.name;
      menuinfo[x]:=workrec.note;
    end;
    sosclose;
    menucount:=maxdtlsets;
    res:=menu(1,4,res,true,false,true,false,true);
    if res<>0 then editdtl(res);
  until res=0;
  move(save,mem[vadr:0],4000);
end;

procedure otherconfig;
var choice:byte;
begin
  choice:=1;
  menuitem[1]:='Flip Keypad';
  menuitem[2]:='Touchy Pad';
  menuitem[3]:='Comma Delay';
  menuitem[4]:='Time Zone';
  menuinfo[1]:='Flip the touch tone keypad in Action Mode upside down';
  menuinfo[2]:='Have the tones pressed while the key is pressed, like a phone keypad';
  menuinfo[3]:='How long BlueBEEP should delay if it finds a comma in a dialing string';
  menuinfo[4]:='Difference to Central European time, e.g. NY = 6, LA = 9, Sydney = -10';
  menucount:=4;
  openbox(2,18,4,31,9,true,true,false);
  gotoxy(20,7); write(config.commaperiod:5);
  gotoxy(20,8); write(config.cetdiff:5);
  repeat
    textattr:=colors.high;
    gotoxy(20,5); writevisbool(config.flipkeypad,'Yes','No');
    gotoxy(20,6); writevisbool(config.touchpad,'Yes','No');
    choice:=menu(1,4,choice,false,false,true,false,true);
    case choice of
      1:config.flipkeypad:=not(config.flipkeypad);
      2:config.touchpad:=not(config.touchpad);
      3:begin
          setcursorsize($6,$7);
          gotoxy(20,7); editword(config.commaperiod);
          gotoxy(20,7); write(config.commaperiod:5);
          setcursorsize($32,$32);
        end;
      4:begin
          setcursorsize($6,$7);
          gotoxy(20,8); editint(config.cetdiff);
          gotoxy(20,8); write(config.cetdiff:5);
          setcursorsize($32,$32);
        end;
    end;
  until choice=0;
  writeconfig;
  closebox(2);
end;

begin
  choice:=1;
  repeat
    menuitem[1]:='Edit Dial Sets';
    menuitem[2]:='Edit Trunks';
    menuitem[3]:='Edit Red Box';
    menuitem[4]:='Password protection';
    menuitem[5]:='Soundblaster Card';
    menuitem[6]:='Pulse Dialing';
    menuitem[7]:='Colors';
    menuitem[8]:='Card Checker';
    menuitem[9]:='Modem setup';
    menuitem[10]:='Dial Xlation';
    menuitem[11]:='Other options';
    menuinfo[1]:='Edit the frequencies of the tones used for dialing';
    menuinfo[2]:='Edit the trunk frequencies';
    menuinfo[3]:='Edit the Red Box frequencies';
    menuinfo[4]:='Password protect BlueBEEP, turn it off or change password';
    menuinfo[5]:='Soundblaster needs to be set up OK for the CardTalker';
    menuinfo[6]:='Pulse Dialing Setup via BlueBEEP hardware device';
    menuinfo[7]:='Change the colors and the way BlueBEEP looks to you';
    menuinfo[8]:='Configure the company setups for the calling card checker';
    menuinfo[9]:='Set up your modem''s hardware info, baud rate, etc.';
    menuinfo[10]:='Set up the dial translation/routing for all trunks';
    menuinfo[11]:='Other options';
    menucount:=11;
    choice:=menu(1,4,choice,true,true,true,true,true);
    case choice of
      1: editdialsets;
      2: edittrunks;
      3: editredbox;
      4: passprotect;
      5: sbconfig;
      6: pulsedialconfig;
      7: colorconfig;
      8: cardcheckerconfig;
      9: modemconfig;
     10: dtlconfig;
     11: otherconfig;
    end;
  until choice=0;
end;
end.
