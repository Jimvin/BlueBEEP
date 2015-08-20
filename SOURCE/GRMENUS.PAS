unit grmenus;
interface
uses grwins,crt,mouseio,video,extras,bbp_vars;
var menuitem  :array[1..23] of string[80];
    menuinfo  :array[1..23] of string[80];
    menucount :integer;
    skip      :boolean;
    curpos    :byte;
function menu(lux,luy,def:integer;shadow,save,usedesc,enskip,boxed:boolean):integer;
implementation

function menu(lux,luy,def:integer;shadow,save,usedesc,enskip,boxed:boolean):integer;
var x,wide,pos,lastpos :byte;
    ch                 :char;
    saveatt            :byte;
    clickposx,clickposy:integer;
begin
  skip:=false;
  wide:=0;
  for x:=1 to menucount do
    if length(menuitem[x])>wide then wide:=length(menuitem[x]);
  if boxed then openbox(99,lux,luy,lux+wide+5,luy+menucount+1,shadow,false,false);
  if not save then ignbox(99);
  for x:=1 to menucount do
    if x<>def then
    vmemwrite(lux+1,luy+x,'  '+menuitem[x]+charlot(' ',wide-length(menuitem[x])+2),colors.win_item);
  lastpos:=0;
  pos:=def;
  repeat
    if usedesc then begin
      saveatt:=textattr;
      textattr:=colors.infoline;
      gotoxy(1,25);
      write(' ',menuinfo[pos]);
      clreol;
      textattr:=saveatt;
    end;
    if (lastpos<>0) and (lastpos<>pos) then begin
      vmemwrite(lux+1,luy+lastpos,'  '+menuitem[lastpos],colors.win_item);
      for x:=lux+2+length(menuitem[lastpos]) to lux+wide+3 do
        vmemwrite(x+1,luy+lastpos,' ',colors.win_item);
    end;
    vmemwrite(lux+2,luy+pos,' '+menuitem[pos],colors.win_hilight);
    for x:=lux+2+length(menuitem[pos]) to lux+wide+2 do
      vmemwrite(x+1,luy+pos,' ',colors.win_hilight);
    vmemwrite(lux+1,luy+pos,'',colors.win_arrows);
    vmemwrite(lux+wide+4,luy+pos,'',colors.win_arrows);
    lastpos:=pos;
    if mousepresent then mouseon;
    if mousepresent then
    repeat until keypressed or (mouseleftclicked
      and (((mousey>luy) and (mousex>lux) and (mousex<lux+wide+5) and (mousey<luy+menucount+1)) or (mousey=2)))
      or mouserightclicked
    else repeat until keypressed;
    if mousepresent then mouseoff;
    if mousepresent then if mouserightclicked then begin
      repeat until not(mouserightclicked);
      ch:=#27;
    end;
    if mousepresent then if enskip then if mouseleftclicked then if mousey=2 then begin
      clickposx:=mousex;
      clickposy:=mousey;
      curpos:=((clickposx-3) div 15)+1;
      if curpos<1 then curpos:=1;
      if curpos>5 then curpos:=5;
      skip:=true;
      pos:=0;
      mouseon;
      repeat until not(mouseleftclicked);
      mouseoff;
      if save then closebox(99);
      menu:=0;
      exit;
    end;
    if mousepresent and mouseleftclicked then begin
      x:=mousey;
      if x-luy>0 then begin
        pos:=x-luy;
        if lastpos<>0 then begin
          vmemwrite(lux+1,luy+lastpos,'  '+menuitem[lastpos],colors.win_item);
          for x:=lux+2+length(menuitem[lastpos]) to lux+wide+3 do
            vmemwrite(x+1,luy+lastpos,' ',colors.win_item);
        end;
        vmemwrite(lux+2,luy+pos,' '+menuitem[pos],colors.win_hilight);
        for x:=lux+2+length(menuitem[pos]) to lux+wide+2 do
          vmemwrite(x+1,luy+pos,' ',colors.win_hilight);
        vmemwrite(lux+1,luy+pos,'',colors.win_arrows);
        vmemwrite(lux+wide+4,luy+pos,'',colors.win_arrows);
        if usedesc then begin
          saveatt:=textattr;
          textattr:=colors.infoline;
          gotoxy(1,25);
          write(' ',menuinfo[pos]);
          clreol;
          textattr:=saveatt;
        end;
        mouseon;
        repeat until not(mouseleftclicked);
        menu:=pos;
        mouseoff;
        if save and boxed then closebox(99);
        exit;
      end;
    end;
    if keypressed then ch:=readkey;
    if ch=#0 then ch:=readkey;
    case ch of
      'H':if pos>1 then dec(pos) else pos:=menucount;
      'P':if pos<menucount then inc(pos) else pos:=1;
      'I':pos:=1;
      'Q':pos:=menucount;
      'G':pos:=1;
      'O':pos:=menucount;
      'K':if enskip then begin if curpos>1 then dec(curpos) else curpos:=5; skip:=true; pos:=0; end;
      'M':if enskip then begin if curpos<5 then inc(curpos) else curpos:=1; skip:=true; pos:=0; end;
    end;
  until (ch in [#27,#13]) xor (skip);
  menu:=pos;
  if ch=#27 then menu:=0;
  if save and boxed then closebox(99);
end;

begin
  if paramstr(1)='/(C)' then begin
    writeln('GRMENUS.PAS  v1.60  Green-Shaded Menu Routines w/Mouse Support');
    writeln('             Copyright (C) 1993 by Onkel Dittmeyer / S.L.A.M');
    writeln;
    readln;
  end;
end.
