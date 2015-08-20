unit bbp_info;

interface

uses crt, video, bbp_vars, optimer, extras, grmenus, grwins,
     ferror, mouseio, types, sos;

procedure info;
procedure readtopictable(fn:string);

type topictype = record
                     topic, subtitle :string;
                     astart, aend    :word;
                   end;

var document    :array[1..maxdoclength] of ^string;
    doclength   :word;
    docname     :string;
    topictable  :array[1..20] of ^topictype;
    topiccount  :byte;

implementation

procedure readtextfile(topic:topictype);
const artpagelen = 16;
      file_maxlen = 1024;
var sfn                :string;
    total_lines        :word;
    t                  :text;
    curl,x,y,z,bar     :word;
    ch                 :char;
    tempstr            :string;

procedure readarticle_info;
var ch:char;
    sa:byte;
begin
  sa:=textattr;
  openbox(4,22,7,55,17,true,true,true);
  window(24,8,55,16);
  fadewriteln(' Mr. Doc. Reader Module v2.10');
  fadewriteln('------------------------------');
  fadewriteln('file_maxlen = '+stg(file_maxlen));
  fadewriteln('total_lines = '+stg(total_lines));
  fadewriteln('curl = '+stg(curl));
  fadewriteln('celerity_colorcodes = enabled');
  fadewriteln('percentage_bar = '+stg(bar));
  writeln;
  fadewrite('03/12/1993 (C) Onkel Dittmeyer');
  ch:=readkey;
  closebox(4);
  textattr:=sa;
end;

begin
  openbox(1,1,1,80,3,false,true,false);
  openbox(3,1,23,80,25,false,true,false);
  textbackground(colors.win_background);
  gotoxy(3,24); cwrite('|Y'^X^Y' |WScroll        |YPgUp/PgDn |WPage Fl');
                cwrite('|Wip       |YHome/End |WBegin/End       |YESC |WQuit');
  gotoxy(55,2); cwrite('|WReading: |Y'+topic.topic);
  gotoxy(3,2); cwrite('|1|W                           |0|G       0%');
  openbox(2,1,4,80,4+artpagelen+2,false,true,false);
  curl:=1;
  total_lines:=topic.aend-topic.astart;
  window(4,5,78,4+artpagelen+1);
  repeat
    bar:=round(100/(total_lines-artpagelen)*curl) div 2+2;
    z:=textattr;
    window(3,2,80,2);
    gotoxy(1,1);
    textattr:=colors.progressbar;
    for x:=1 to bar div 2 do write('Û');
    if bar mod 2=1 then write('Ý');
    for x:=1 to 26-bar div 2 do write(' ');
    if bar mod 2=0 then write(' ');
    if round(100/(total_lines-artpagelen)*curl)=100 then write(^H'Û');
    textattr:=colors.win_text;
    write('     ',100/(total_lines-artpagelen)*curl:3:0,'%  ');
    textattr:=z;
    window(4,5,78,21);
    for x:=curl to curl+artpagelen do begin
      gotoxy(1,x-curl+1);
      textattr:=colors.win_background*16+cyan;
      if x<=total_lines then cwrite(document[x+topic.astart]^);
      clreol;
    end;
    if mousepresent then repeat until keypressed or mouseleftclicked or mouserightclicked
    else repeat until keypressed;
    if mouseleftclicked and mouserightclicked and mousepresent then begin
      repeat until not(mouseleftclicked) and not(mouserightclicked);
      window(1,1,80,25);
      closebox(3);
      closebox(2);
      closebox(1);
      exit;
    end;
    if mouseleftclicked and mousepresent then begin
      delayms(5);
      if curl<(total_lines-artpagelen) then inc(curl);
    end;
    if mouserightclicked and mousepresent then begin
      delayms(5);
      if curl>1 then dec(curl);
    end;
    if keypressed then begin
      repeat ch:=readkey until ch in [#27,#0];
      if ch=#0 then ch:=readkey;
      case ch of
        CurUp:if curl>1 then dec(curl);
        CurDn:if curl<(total_lines-artpagelen) then inc(curl);
        PgUp :if curl>artpagelen then dec(curl,artpagelen) else curl:=1;
        PgDn :if curl<(total_lines-(artpagelen*2)) then inc(curl,artpagelen) else curl:=total_lines-artpagelen;
        Home :curl:=1;
        Endk :curl:=total_lines-artpagelen;
        F1   :readarticle_info;
      end;
      if curl>total_lines-artpagelen then begin
        curl:=total_lines-artpagelen;
        sound(1000);
        delayms(100);
        nosound;
      end;
    end;
  until ch=#27;
  window(1,1,80,25);
  closebox(3);
  closebox(2);
  closebox(1);
end;

procedure readtopictable(fn:string);
var t   :text;
    buf :array[1..1024] of byte;
    br  :word;
begin
  if not sosexist(fn) then fatalerror('Document file '+fn+' not found in database.');
  topiccount:=0;
  doclength:=0;
  sosopen;
  sosfopen(fn);
  inc(doclength);
  new(document[doclength]);
  document[doclength]^:='';
  repeat
    sosblockread(@buf,sizeof(buf),br);
    for x:=1 to br do begin
      if buf[x]=13 then begin
        inc(doclength);
        new(document[doclength]);
        document[doclength]^:='';
      end else if buf[x]<>10 then document[doclength]^:=document[doclength]^+chr(buf[x]);
    end;
  until br<>sizeof(buf);
  sosclose;
  x:=0;
  repeat inc(x) until copy(document[x]^,1,length('.DOCUMENT'))='.DOCUMENT';
  docname:=copy(document[x]^,length('.DOCUMENT')+2,length(document[x]^)-length('.DOCUMENT'));
  x:=0;
  repeat
    inc(x);
    if copy(document[x]^,1,length('.TOPIC'))='.TOPIC' then begin
      inc(topiccount);
      new(topictable[topiccount]);
      topictable[topiccount]^.topic:=copy(document[x]^,length('.TOPIC')+2,length(document[x]^)-length('.TOPIC'));
      topictable[topiccount]^.astart:=x+1;
      repeat inc(x) until copy(document[x]^,1,length('.SUBTITLE'))='.SUBTITLE';
      topictable[topiccount]^.subtitle:=copy(document[x]^,length('.SUBTITLE')+2,length(document[x]^)-length('.SUBTITLE'));
      repeat inc(x) until copy(document[x]^,1,length('.END'))='.END';
      topictable[topiccount]^.aend:=x-1;
    end;
  until x=doclength;
end;

procedure topicread(fn:string);
var s           :string;
    x,result    :word;
    saveatt     :byte;
begin
  saveatt:=colors.win_item;
  colors.win_item:=lightcyan;
  move(mem[vadr:0],save,4000);
  openbox(5,1,1,80,3,false,true,false);   ignbox(5);
  openbox(6,1,4,80,22,false,true,false);  ignbox(6);
  openbox(7,1,23,80,25,false,true,false); ignbox(7);
  gotoxy(3,2);
  cwrite('|WDocEngine V2.o1                             Document: |YLoading...');
  gotoxy(3,24);
  cwrite('|YUp/Down |WChoose paragraph      |YENTER |WRead desired paragraph      |YESC |WBail Out');
  readtopictable(fn);
  vmemwrite(57,2,docname,yellow);
  for x:=1 to topiccount do menuitem[x]:=topictable[x]^.topic;
  for x:=1 to topiccount do vmemwrite(27,4+x,topictable[x]^.subtitle,cyan);
  menucount:=topiccount;
  result:=1;
  repeat
    result:=menu(2,4,result,true,true,false,false,false);
    if result<>0 then readtextfile(topictable[result]^);
  until result=0;
  for x:=1 to topiccount do dispose(topictable[x]);
  for x:=1 to doclength do dispose(document[x]);
  move(save,mem[vadr:0],4000);
  colors.win_item:=saveatt;
end;

procedure generatekey;
begin
  openbox(17,10,6,70,13,true,true,true);
  vmemwrite(30,6,' Generate PGP key ',colors.win_title);
  window(12,7,69,12);
  textattr:=colors.win_text;
  clrscr;
  writeln('Writing key to ONKELD.KEY...');
  sos.extract(masterfile,'ONKELD.KEY');
  writeln('SOSexport done!');
  victorioustune;
  window(1,1,80,25);
  tapenter(13);
  closebox(17);
end;

procedure info;
var choice:byte;
    save:array[1..4000] of byte;
begin
  choice:=1;
  repeat
    menuitem[1]:='Read Documentation';
    menuitem[2]:='Generate PGP key';
    menuinfo[1]:='Read the BLUEBEEP.DOC documentation file for BlueBEEP!';
    menuinfo[2]:='Generate Onkel Dittmeyer''s 1024-bit PGP key on disk';
    menucount:=2;
    choice:=menu(51,4,choice,true,true,true,true,true);
    case choice of
      1 :topicread('BLUEBEEP.DOC');
      2 :generatekey;
    end;
  until choice=0;
end;
end.
