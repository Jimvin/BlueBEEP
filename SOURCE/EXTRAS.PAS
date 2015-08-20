unit EXTRAS;
interface

uses types,optimer,bbunit,grwins,mouseio,vgagraph,video,bbp_vars,ferror;

const just_clear   = 0;
      pushoutleft  = 1;
      pushoutright = 2;
      pushoutdown  = 3;
      pushoutup    = 4;

function  bytefilesize(fn:string):longint;
function  charlot(lotchar:char;times:byte):string;
function  colorselect(initial:byte):byte;
function  date:string;
function  exist(dateiname:string):boolean;
function  getcursorsize :word;
function  parameter(s:string):boolean;
function  randomnr:string;
function  scrambled(s:string):string;
function  stg(w:word):string;
function  stg2(r:real):string;
function  striptrail(s:string):string;
function  time(secs:boolean):string;
function  uppercase(s:string):string;
function  wvalue(s:string):word;
function  yesnotoggle(default:boolean;choice1,choice2:string):boolean;
procedure bottominfo(s:string);
procedure center(y:integer;text:string);
procedure chat(s:string);
procedure clearscreen(method:byte);
procedure cursoroff;
procedure cursoron;
procedure cwrite(s:string);
procedure fadecenter(l:byte;s:string);
procedure fadewrite(s:string);
procedure fadewriteln(s:string);
procedure fwrite(line:integer;eingabe:string);
procedure iwrite(txt:string;itemize:boolean);
procedure logo(x:integer;y:integer;wort:string);
procedure run(prog:string);
procedure scls(zeitraum:integer);
procedure setcursorsize(custart, cuend :byte);
procedure showansi(a:ansi;how:byte);
procedure starten(programm:string);
procedure swrite(input:string);
procedure swriteln(input:string);
procedure tapenter(line:byte);
procedure twrite(input:string);
procedure twritexy(x,y:shortint;input:string);
procedure victorioustune;
procedure vmemwrite(x,y:integer;blah:string;color:byte);
procedure writevisbool(b:boolean;opt1,opt2:string);

implementation

uses dos,crt;

var regs        :Registers;
    CursorSave  :Word;

function striptrail(s:string):string;
var s2 :string;
begin
  s2:=s;
  while s2[length(s2)]=#32 do s2:=copy(s2,1,length(s2)-1);
  striptrail:=s2;
end;

procedure clearscreen(method:byte);
var lines :array[0..24] of array[0..159] of byte;
    x,y,z :word;
begin
  if method = just_clear then begin
    clrscr;
    exit;
  end;
  if method = pushoutleft then begin
    for x:=0 to 24 do move(mem[vadr:x*160],lines[x],160);
    for x:=1 to 79 do begin
      for y:=0 to 24 do move(lines[y][x*2],mem[vadr:160*y],160-(x*2));
      vsync;
    end;
    clrscr;
    exit;
  end;
  if method = pushoutright then begin
    for x:=0 to 24 do move(mem[vadr:x*160],lines[x],160);
    for x:=0 to 24 do for y:=158 downto 2 do lines[x][y]:=lines[x][y-2];
    for x:=0 to 24 do lines[x][0]:=32;
    for x:=0 to 24 do lines[x][1]:=0;
    for x:=0 to 79 do begin
      for y:=0 to 24 do move(lines[y],mem[vadr:160*y+(x*2)],160-(x*2));
      vsync;
    end;
    clrscr;
    exit;
  end;
  if method = pushoutdown then begin
    gotoxy(1,1);
    for x:=0 to 24 do begin
      insline;
      vsync;
    end;
    clrscr;
    exit;
  end;
  if method = pushoutup then begin
    gotoxy(1,1);
    for x:=0 to 24 do begin
      delline;
      vsync;
    end;
    clrscr;
    exit;
  end;
end;

function time(secs:boolean):string;
var h,m,s,hs:word;
    dummy:string;
begin
  dummy:='';
  gettime(h,m,s,hs);
  if h<10 then dummy:='0';
  dummy:=dummy+stg(h)+':';
  if m<10 then dummy:=dummy+'0';
  dummy:=dummy+stg(m);
  if secs then begin
    dummy:=dummy+':';
    if s<10 then dummy:=dummy+'0';
    dummy:=dummy+stg(s);
  end;
  time:=dummy;
end;

function date:string;
var y,m,d,dum:word;
    dummy:string;
begin
  getdate(y,m,d,dum);
  dummy:='';
  if m<10 then dummy:='0';
  dummy:=dummy+stg(m)+'-';
  if d<10 then dummy:=dummy+'0';
  dummy:=dummy+stg(d)+'-'+copy(stg(y),3,2);
  date:=dummy;
end;

procedure chat(s:string);
var x:byte;
begin
  textattr:=lightgray;
  for x:=1 to length(s) do begin
    write(s[x]);
    delayms(random(140)+50);
  end;
  writeln;
  writeln;
  textattr:=cyan;
end;

procedure run(prog:string);
var s:string;
    r:registers;
begin
  s:=prog+#00;
  r.ax:=$4b00;
  r.ds:=seg(s[1]);
  r.dx:=ofs(s[1]);
  intr($21,r);
end;

procedure SCls(zeitraum:integer);
var ox,oy,ux,uy :integer;
const zeichen=' ';
procedure wumm(olx,oly,urx,ury:integer);
var wummx:integer;
begin
  gotoxy(olx,oly);
  for wummx:=oly to ury do begin gotoxy(urx,wummx); write(zeichen); delayms(zeitraum); end;
  for wummx:=urx downto olx do begin gotoxy(wummx,ury); write(zeichen); delayms(zeitraum); end;
  for wummx:=ury downto oly do begin gotoxy(olx,wummx); write(zeichen); delayms(zeitraum); end;
  gotoxy(olx,oly);
  for wummx:=1 to urx-olx do begin write(zeichen); delayms(zeitraum); end;
end;
begin
  ox:=1; oy:=1;
  ux:=79; uy:=24;
  while ox<13 do begin
   wumm(ox,oy,ux,uy);
   inc(ox); inc(oy);
   dec(ux); dec(uy);
  end;
  clrscr;
end;


Procedure Starten(Programm:string);
begin
if Programm <> '' then
    begin
      SwapVectors;
      Exec(GetEnv('COMSPEC'), '/C ' + Programm);
      SwapVectors;
      if DosError <> 0 then begin
        normvideo;
        clrscr;
        WriteLn('Kommandointerpreter fehlt oder ist defekt !');
        Halt(2);
       End;
    end;
end;

procedure TWriteXY(x,y:shortint;input:string);

var l,a   :integer;
    copied:string[1];

begin
  gotoxy(x,y);
  l:=length(input);
    for a:=1 to l do
      begin
        copied:=copy(input,a,1);
        if copied=' ' then
          begin
            write(' ');
            delayms(75);
          end
            else
              begin
                write(copied);
                sound(560);
                delayms(5);
                nosound;
                delayms(75);
              end;
      end;
end;


procedure TWrite(input:string);

var l,a   :integer;
    copied:string[1];

begin
  l:=length(input);
    for a:=1 to l do
      begin
        copied:=copy(input,a,1);
        if copied=' ' then
          begin
            write(' ');
            delayms(75);
          end
            else
              begin
                write(copied);
                sound(560); { Normal: 560 }
                delayms(5); { Normal: 5 }
                nosound;
                delayms(75); { Normal: 75 }
              end;
      end;
end;

procedure box(ulx,uly,lrx,lry:integer;shadow:boolean);
var hl,vl,x,xb,oc:integer;
begin
      oc:=textattr;
      if ulx<1 then halt(1);
      if uly<1 then halt(1);
      if lrx>80 then halt(1);
      if lry>25 then halt(1);
      lry:=lry+1;
      lrx:=lrx+1;
      hl:=lrx-ulx-2;
      vl:=lry-uly-2;
      gotoxy(ulx,uly);
      write(chr(201));
      for x:=1 to hl do write(chr(205));
      write(chr(187));
        for x:=1 to vl do
          begin
            gotoxy(ulx,uly+x);
            write(chr(186));
            for xb:=1 to hl do write(' ');
            write(chr(186));
          end;
      gotoxy(ulx,lry-1);
      write(chr(200));
      for x:=1 to hl do write(chr(205));
      write(chr(188));
      if shadow then
        begin
          textcolor(black);
          gotoxy(ulx+2,lry);
          for x:=1 to hl+2 do write(chr(219));
            for x:=uly+1 to lry do
              begin
                gotoxy(lrx,x);
                write('ÛÛ');
              end;
        end;
  textattr:=oc;
end;

procedure Center(y:integer;text:string);

var laenge,x:integer;
    a      :real;

begin
  laenge:=length(text);
  a:=40-(laenge/2);
  x:=round(a);
  gotoxy(x,y);
  write(text);
end;

procedure SWrite(input:string);

var l,a   :integer;
    copied:string[1];

begin
  l:=length(input);
    for a:=1 to l do
      begin
        copied:=copy(input,a,1);
        write(copied);
        delayms(20);
      end;
end;

procedure SWriteLn(input:string);
begin
  SWrite(input);
  WriteLn;
end;

function GetCursorSize: word;
  begin
    with regs do
      begin
        ah:= 3;
        bh:= 0;
        intr($10, regs);
        GetCursorsize:= cx;
      end;
  end;

procedure SetCursorSize(CuStart, CuEnd: Byte);
  begin
    with regs do
      begin
        ah:= 1;
        ch:= CuStart;
        cl:= CuEnd;
        intr($10, regs);
      end;
  end;

procedure CursorOff;
  begin
    SetCursorSize($20, $20);
  end;

procedure CursorOn;
  begin
    SetCursorSize(hi(CursorSave), lo(CursorSave));
  end;

function Exist(Dateiname:string):boolean;
var f:file;
begin
  assign(f,dateiname);
  {$I-} Reset(f); {$I+}
  if ioresult=0 then begin
    close(f);
    exist:=dateiname<>'';
  end else
    exist:=FALSE;
end;

function Stg(w:word):String;
var s:string;
begin
  str(w,s);
  stg:=s;
end;

function UpperCase(s:string):string;
var Counter: Word;
begin
  if s='' then begin
    uppercase:='';
    exit;
  end;
  for Counter := 1 to Length(S) do
    S[Counter] := UpCase(S[Counter]);
  UpperCase := S;
end;

procedure LogoChar(xp,yp:integer;c:char);
var x,y,index,bits:integer;
begin
  for y:=0 to 7 do
    begin
      for x:=0 to 7 do
        begin
          bits:=Mem[$F000:$FB6E+(8*(ord(C)-32))+y];
          gotoxy(xp+x,yp+y);
          if (bits and (1 shl (7-x)))<>0 then write(chr(219));
        end;
      end;
    writeln;
  end;

procedure Logo(x,y:Integer;Wort:string);
var i,xp,yp:integer;
begin
  xp:=0;yp:=0;
  for i:=1 to length(wort) do
    begin
      LogoChar(x+xp,y,wort[I]);
      xp:=xp+8
    end;
  yp:=yp+8;
end;

procedure FWrite(line:integer;eingabe:string);
type Zeichentyp=record Zeichen:char; Getippt:boolean; end;
var z       :array[1..35] of zeichentyp;
    x       :integer;
    taste   :char;
    geraten :boolean;
begin
  for x:=1 to length(eingabe) do z[x].zeichen:=eingabe[x];
  for x:=length(eingabe)+1 to 35 do z[x].zeichen:=' ';
  for x:=1 to 35 do z[x].getippt:=false;
  taste:=chr(64);
  repeat
    delayms(40);
    taste:=chr(ord(taste)+1);
    for x:=1 to length(eingabe) do if taste=z[x].zeichen then z[x].getippt:=true;
    gotoxy(40-(length(eingabe) div 2),line);
    for x:=1 to length(eingabe) do if z[x].getippt then write(z[x].zeichen)
      else write(' ');
  until ord(taste)>91;
end;

procedure fadewrite(s:string);
var x:byte;
    c:char;
begin
  for x:=1 to length(s) do begin
    if x<=length(s) then begin textattr:=blue; write(s[x]); end;
    if x<=length(s)-1 then begin textattr:=lightblue; write(s[x+1]); end;
    if x<=length(s)-2 then begin textattr:=lightcyan; write(s[x+2]); end;
    if x<=length(s)-3 then begin textattr:=white; write(s[x+3]); end;
    delayms(50);
    if x<=length(s)-3 then write(^H^H^H) else
     if x<=length(s)-2 then write(^H^H) else
     if x<=length(s)-1 then write(^H);
  end;
end;

procedure fadewriteln(s:string);
begin
  fadewrite(s);
  writeln;
end;

procedure fadecenter(L:byte;s:string);
begin
  gotoxy(40-(length(s) div 2),l);
  fadewrite(s);
end;

procedure tapenter(line:byte);
const atts:array[1..20] of byte=(darkgray,green,lightgreen,white,lightgreen,
                                green,darkgray,blue,lightblue,lightcyan,
                                white,lightcyan,lightblue,blue,darkgray,
                                red,lightred,white,lightred,red);
var ch:char;
    x :byte;
begin
  repeat
    for x:=1 to 20 do begin
      if not keypressed then begin
        gotoxy(35,line);
        textattr:=atts[x];
        write(' Tap ENTER ');
        delayms(100);
      end;
    end;
    if keypressed then ch:=readkey;
  until ch=#13;
end;

procedure showansi(a:ansi;how:byte);
var tr      :array[1..2000] of boolean;
    x,y,all :word;
    sa      :ansi;

begin
  move(mem[vadr:0],sa,4000);
  case how of
    1:begin
        for x:=1 to 2000 do tr[x]:=false;
        all:=2000;
        repeat
          repeat y:=random(2000) until tr[y]=false;
          tr[y]:=true;
          dec(all);
          mem[vadr:y*2]:=ord(a[y*2]);
          mem[vadr:y*2+1]:=ord(a[y*2+1]);
          delayms(1);
        until all<=2;
        move(a,mem[vadr:0],4000);
        tapenter(25);
        for x:=1 to 2000 do tr[x]:=false;
        all:=2000;
        repeat
          repeat y:=random(2000) until tr[y]=false;
          tr[y]:=true;
          dec(all);
          mem[vadr:y*2]:=ord(sa[y*2]);
          mem[vadr:y*2+1]:=ord(sa[y*2+1]);
          delayms(1);
        until all<=2;
        move(sa,mem[vadr:0],4000);
      end;
    end;
end;

procedure vmemwrite(x,y:integer;blah:string;color:byte);
var i:word;
begin
  for i:=1 to length(blah) do mem[vadr:2*((y-1)*80+(x-2)+i)]:=ord(blah[i]);
  for i:=1 to length(blah) do mem[vadr:2*((y-1)*80+(x-2)+i)+1]:=color;
end;

function yesnotoggle(default:boolean;choice1,choice2:string):boolean;
var b,decision   :boolean;
    ch           :char;
    x,saveattr   :byte;
begin
  decision:=false;
  saveattr:=textattr;
  b:=default;
  if b then begin
    textattr:=colors.knob_active;
    write(' ',choice1,' ');
    textattr:=colors.knob_inactive;
    write('  ',choice2,' ');
    for x:=1 to length(choice1)+length(choice2)+5 do write(^H);
  end else begin
    textattr:=colors.knob_inactive;
    write(' ',choice1,'  ');
    textattr:=colors.knob_active;
    write(' ',choice2,' ');
    for x:=1 to length(choice1)+length(choice2)+5 do write(^H);
  end;
  repeat
    repeat ch:=upcase(readkey) until ch in [#13,#27,#0,'Y','N'];
    if ch=#0 then ch:=readkey;
    case ch of
      CurLf,CurRt :b:=not(b);
      'Y'         :begin b:=true; decision:=true; end;
      'N',#27     :begin b:=false; decision:=true; exit; end;
      #13         :decision:=true;
    end;
    if b then begin
      textattr:=colors.knob_active;
      write(' ',choice1,' ');
      textattr:=colors.knob_inactive;
      write('  ',choice2,' ');
      for x:=1 to length(choice1)+length(choice2)+5 do write(^H);
    end else begin
      textattr:=colors.knob_inactive;
      write(' ',choice1,'  ');
      textattr:=colors.knob_active;
      write(' ',choice2,' ');
      for x:=1 to length(choice1)+length(choice2)+5 do write(^H);
    end;
  until decision;
  yesnotoggle:=b;
  textattr:=saveattr;
end;

function stg2(r:real):string;
var s:string;
begin
  str(r:0:2,s);
  stg2:=s;
end;

function scrambled(s:string):string;
var x  :byte;
    s2 :string;
begin
  if s='' then begin
    scrambled:='';
    exit;
  end;
  s2[0]:=s[0];
  for x:=1 to length(s) do s2[x]:=chr(255-ord(s[x]));
  scrambled:=s2;
end;

function parameter(s:string):boolean;
var x:byte;
    b:boolean;
begin
  b:=false;
  for x:=1 to paramcount do begin
    if uppercase(s)=uppercase(paramstr(x)) then b:=true;
  end;
  parameter:=b;
end;

procedure writevisbool(b:boolean;opt1,opt2:string);
var saveattr :byte;
begin
  saveattr:=textattr;
  if b then textattr:=colors.knob_active else textattr:=colors.knob_inactive;
  write(' ',opt1,' ');
  textattr:=colors.knob_inactive;
  write(' ');
  if b then textattr:=colors.knob_inactive else textattr:=colors.knob_active;
  write(' ',opt2,' ');
  textattr:=saveattr;
end;

function randomnr:string;
const areacodes : array[1..10] of string=('201','202','212','313','405','515',
                                          '619','702','703','706');
var s:string;
    x:byte;
begin
  s:='XXXXXXX';
  randomize;
  for x:=1 to 7 do s[x]:=chr(random(10)+48);
  s:=areacodes[random(10)+1]+s;
  randomnr:=s;
end;

procedure bottominfo(s:string);
var save,x,y:byte;
begin
  save:=textattr;
  x:=wherex; y:=wherey;
  textattr:=colors.infoline;
  gotoxy(1,25);
  write(' ',s);
  clreol;
  textattr:=save;
  gotoxy(x,y);
end;

procedure victorioustune;
var x:byte;
begin
  for x:=1 to 3 do begin
    sound(1250);
    delayms(50);
    nosound;
    delayms(50);
  end;
  sound(1660);
  delayms(50);
  nosound;
  delayms(200);
  sound(1250);
  delayms(50);
  nosound;
  delayms(50);
  sound(1660);
  delayms(200);
  nosound;
end;

procedure cwrite(s:string);
var saveattr,x,pos :byte;
begin
  saveattr:=textattr;
  pos:=1;
  while pos<=length(s) do begin
    if s[pos]='|' then begin
      inc(pos);
      case s[pos] of
        'b' :textcolor(blue);
        'B' :textcolor(lightblue);
        'g' :textcolor(green);
        'G' :textcolor(lightgreen);
        'c' :textcolor(cyan);
        'C' :textcolor(lightcyan);
        'r' :textcolor(red);
        'R' :textcolor(lightred);
        'm' :textcolor(magenta);
        'M' :textcolor(lightmagenta);
        'y' :textcolor(brown);
        'Y' :textcolor(yellow);
        'w' :textcolor(lightgray);
        'W' :textcolor(white);
        'd' :textcolor(darkgray);
        '0' :textbackground(black);
        '1' :textbackground(1);
        '2' :textbackground(2);
        '3' :textbackground(3);
        '4' :textbackground(4);
        '5' :textbackground(5);
        '6' :textbackground(6);
        '7' :textbackground(7);
      else begin
        clrscr;
        writeln('Fatal Error in procedure cwrite() ! No colorcode after | !');
        halt($FF);
      end; end;
    end else write(s[pos]);
    inc(pos);
  end;
  textattr:=saveattr;
end;

function wvalue(s:string):word;
var v :word;
    c :integer;
begin
  val(s,v,c);
  if c<>0 then v:=0;
  wvalue:=v;
end;

function charlot(lotchar:char;times:byte):string;
var tmp:string;
    x  :byte;
begin
  tmp:='';
  for x:=1 to times do tmp:=tmp+lotchar;
  charlot:=tmp;
end;

procedure iwrite(txt:string;itemize:boolean);
var x:byte;
    h,lh:boolean;
begin
  h:=false;
  lh:=true;
  for x:=1 to length(txt) do begin
    if h<>lh then begin
      lh:=h;
      if itemize then if h then textattr:=colors.win_hilight_high
        else textattr:=colors.win_hilight
      else if h then textattr:=colors.win_text_high
        else textattr:=colors.win_text;
    end;
    if txt[x]='~' then h:=not(h) else write(txt[x]);
  end;
end;

function bytefilesize(fn:string):longint;
var f :file;
begin
  assign(f,fn);
  {$I-} reset(f,1); {$I+}
  if ioresult<>0 then begin
    bytefilesize:=-1;
    exit;
  end;
  bytefilesize:=filesize(f);
  close(f);
end;

function colorselect(initial:byte):byte;
const xbase = 14;
      ybase = 4;

      colorname :array[0..15] of string=('Black','Blue','Green','Cyan','Red',
                                         'Magenta','Brown','Gray','Dark Gray',
                                         'Light Blue','Light Green','Light Cyan',
                                         'Light Red','Light Magenta','Yellow',
                                         'White');
var x,y,posx,posy,lposx,lposy :byte;
    ch                        :char;

procedure reloc(x,y:byte);
begin
  gotoxy(x+xbase,y+ybase);
end;

begin
  openbox(111,xbase,ybase-1,xbase+50,ybase+19,true,true,true);
  posx:=initial div 16;
  posy:=initial mod 16;
  for x:=0 to 7 do for y:=0 to 15 do begin
    reloc((x+1)*5,y+1);
    textattr:=x*16+y;
    write(' þ ');
  end;
  lposx:=0; lposy:=0;
  repeat
    if (posx=posy) then begin
      textattr:=white;
      reloc(1,18);
      write('<invisible>         ');
    end else begin
      textattr:=posx*16+posy;
      reloc(1,18);
      write(' Yet Another Sample ');
    end;
    textattr:=white;
    reloc(25,18); write(colorname[posy],' on ',colorname[posx]);
    for x:=1 to 20-length(colorname[posx])-length(colorname[posy]) do write(' ');
    reloc((lposx+1)*5-1,lposy); write(' ');
    reloc((lposx+1)*5+3,lposy); write(' ');
    reloc((lposx+1)*5-1,lposy+1); write(' ');
    reloc((lposx+1)*5+3,lposy+1); write(' ');
    reloc((lposx+1)*5-1,lposy+2); write(' ');
    reloc((lposx+1)*5+3,lposy+2); write(' ');
    if lposy>0 then begin
      textattr:=lposx*16+lposy-1;
      reloc((lposx+1)*5,lposy); write(' þ ');
    end else begin
      textattr:=white;
      reloc((lposx+1)*5,lposy); write('   ');
    end;
    textattr:=lposx*16+lposy;
    reloc((lposx+1)*5,lposy+1); write(' þ ');
    if lposy<15 then begin
      textattr:=lposx*16+lposy+1;
      reloc((lposx+1)*5,lposy+2); write(' þ ');
    end else begin
      textattr:=white;
      reloc((lposx+1)*5,lposy+2); write('   ');
    end;

    textattr:=white;
    reloc((posx+1)*5-1,posy); write('ÚÄÄÄ¿');
    reloc((posx+1)*5-1,posy+1); write('³');
    reloc((posx+1)*5+3,posy+1); write('³');
    reloc((posx+1)*5-1,posy+2); write('ÀÄÄÄÙ');
    textattr:=posx*16;
    reloc((posx+1)*5,posy+1); write('Ý');
    reloc((posx+1)*5+2,posy+1); write('Þ');
    lposx:=posx; lposy:=posy;
    colorselect:=posx*16+posy;
    repeat ch:=readkey until ch in [#0,#27,#13];
    if ch=#0 then ch:=readkey;
    case ch of
      CurUp :if posy>0 then dec(posy) else posy:=15;
      CurDn :if posy<15 then inc(posy) else posy:=0;
      CurLf :if posx>0 then dec(posx) else posx:=7;
      CurRt :if posx<7 then inc(posx) else posx:=0;
    end;
  until ch in [#27,#13];
  if ch=#27 then colorselect:=initial;
  closebox(111);
end;

begin
  mousepresent:=false;
  if paramstr(1)='/(C)' then begin
    writeln('EXTRAS.PAS - v2.00 - (C) Onkel Dittmeyer / S.L.A.M.');
    writeln('           General Purpose Pascal Utilities (TP 7.0)');
    readln;
  end;
end.
