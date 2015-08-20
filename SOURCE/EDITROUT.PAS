unit editrout;

interface
uses crt,dos,extras,bbp_vars;
procedure editbase(var def:string;maxlen:byte;numbersonly,upcaseonly,hideinput:boolean);
procedure edit(var def:string;maxlen:byte);
procedure edituc(var def:string;maxlen:byte);
procedure editpass(var def:string;maxlen:byte);
procedure editint(var i:integer);
procedure editword(var w:word);
procedure editbyte(var b:byte);
procedure editli(var l:longint);
procedure editdate(var date:longint);

var hidechar,
    spacechar      :char;
    errortonefreq,
    errortonelen   :word;

implementation

procedure errorbeep;
begin
  sound(errortonefreq);
  delay(errortonelen);
  nosound;
end;

procedure editint(var i:integer);
var s:string;
    v:integer;
begin
  str(i,s);
  repeat
    editbase(s,6,false,false,false);
    val(s,i,v);
    if v<>0 then errorbeep;
  until v=0;
end;

procedure editword(var w:word);
var s:string;
    v:integer;
begin
  str(w,s);
  repeat
    editbase(s,5,true,false,false);
    val(s,w,v);
    if v<>0 then errorbeep;
  until v=0;
end;

procedure editbyte(var b:byte);
var s:string;
    v:integer;
begin
  str(b,s);
  repeat
    editbase(s,3,true,false,false);
    val(s,b,v);
  until v=0;
end;

procedure editli(var l:longint);
var s:string;
    v:integer;
begin
  str(l,s);
  repeat
    editbase(s,11,true,false,false);
    val(s,l,v);
  until v=0;
end;

procedure edituc(var def:string;maxlen:byte);
begin
  editbase(def,maxlen,false,true,false);
end;

procedure editpass(var def:string;maxlen:byte);
begin
  editbase(def,maxlen,false,true,true);
end;

procedure editdate(var date:longint);
function w2str(w:word):string;
var s:string;
begin
  str(w,s);
  if w<10 then s:='0'+s;
  w2str:=s;
end;
var dt:datetime;
    xs:word;
    v :integer;
    s :string;
    l :longint;
    w :word;
begin
  xs:=wherex;
  unpacktime(date,dt);
  textattr:=cyan;
  with dt do begin
    write(w2str(month),'/',w2str(day),'/',year,'  ',w2str(hour),':',w2str(min),':',w2str(sec));
    gotoxy(xs,wherey);
    s:=w2str(month); repeat edit(s,2); val(s,month,v); until v=0;
    write(w2str(month),'/');
    s:=w2str(day); repeat edit(s,2); val(s,day,v); until v=0;
    write(w2str(day),'/');
    s:=w2str(year); repeat edit(s,4); val(s,year,v); until v=0;
    write(w2str(year),'  ');
    s:=w2str(hour); repeat edit(s,2); val(s,hour,v); until v=0;
    write(w2str(hour),':');
    s:=w2str(min); repeat edit(s,2); val(s,min,v); until v=0;
    write(w2str(min),':');
    s:=w2str(sec); repeat edit(s,2); val(s,sec,v); until v=0;
    write(w2str(sec));
  end;
  gotoxy(xs,wherey);
  packtime(dt,date);
end;

procedure edit(var def:string;maxlen:byte);
begin
  editbase(def,maxlen,false,false,false);
end;

procedure editbase(var def:string;maxlen:byte;numbersonly,upcaseonly,hideinput:boolean);
var s,s2,s3     :string;
    ch          :char;
    pos,start,b :byte;
    x           :word;
    firstkey    :boolean;
    insflag     :boolean;
    savedcolor  :byte;
begin
  savedcolor:=textattr;
  insflag:=false;
  firstkey:=true;
  if upcaseonly then s:=uppercase(def) else s:=def;
  start:=wherex-1;
  pos:=length(s)+1;
  textattr:=colors.inputfield;
  if s<>'' then if hideinput then for x:=1 to length(s) do write(hidechar) else write(s);
  for x:=1 to maxlen-length(s) do write(spacechar);
  repeat
    gotoxy(start+pos,wherey);
    if insflag then setcursorsize($1,$7) else setcursorsize($6,$7);
    ch:=readkey;
    if upcaseonly then ch:=upcase(ch);
    if numbersonly then
      while not(ch in ['0','1','2','3','4','5','6','7','8','9','.',^X,^H,#0,#13,#27]) do begin
        errorbeep;
        ch:=readkey;
      end;
    if ch=^X then begin
      s:='';
      pos:=1;
      gotoxy(start+1,wherey);
      write(s);
      for x:=1 to maxlen-length(s) do write(spacechar);
    end;
    if (ch=^H) and (pos<length(s)+1) and (pos>1) then begin
      for x:=pos-1 to length(s)-1 do s[x]:=s[x+1];
      dec(pos);
      b:=ord(s[0]); dec(b); s[0]:=chr(b);
      gotoxy(start+1,wherey);
      write(s);
      for x:=1 to maxlen-length(s) do write(spacechar);
    end;
    if (ch=^H) and (pos=length(s)+1) and (pos>1) then begin
      write(^H+spacechar+^H);
      dec(pos);
      b:=ord(s[0]); dec(b); s[0]:=chr(b);
      if firstkey then firstkey:=false;
    end;
    if ch=#0 then begin
      {ch:=readkey;
      write(ch);
      halt;}
      ch:=readkey;
      if ch='G' then pos:=1;
      if ch='O' then pos:=length(s)+1;
      if ch='R' then insflag:=not(insflag);

      if (ch='S') and (pos<=length(s)) then begin
        for x:=pos to length(s)-1 do s[x]:=s[x+1];
        b:=ord(s[0]); dec(b); s[0]:=chr(b);
        gotoxy(start+1,wherey);
        write(s);
        for x:=1 to maxlen-length(s) do write(spacechar);
      end;

      if (ch='K') and (pos>1) then begin
        write(^H);
        dec(pos);
      end;
      if (ch='M') and (pos<=length(s)) then begin
        inc(pos);
        write(s[pos-1]);
      end;
      ch:=#0;
      firstkey:=false;
    end else if (pos<=maxlen) and (not(ch in [^X,^H,#13,#27])) then begin
      if insflag then begin
        if length(s)=maxlen then errorbeep else begin
          s2:=ch;
          s3:=copy(s,1,pos-1)+s2+copy(s,pos,length(s)-pos+1);
          s:=s3;
          gotoxy(start+1,wherey);
          if s<>'' then if hideinput then for x:=1 to length(s) do write(hidechar) else write(s);
          inc(pos);
          for x:=1 to maxlen-length(s) do write(spacechar);
          firstkey:=false;
        end;
      end else begin
        if firstkey then begin
          s:='';
          pos:=1;
          gotoxy(start+1,wherey);
          {if hideinput then for x:=1 to length(s) do write(hidechar) else write(s);}
          for x:=1 to maxlen-length(s) do write(spacechar);
          gotoxy(start+1,wherey);
          firstkey:=false;
        end;
        if hideinput then write(hidechar) else write(ch);
        inc(pos);
        if pos>length(s)+1 then begin
          b:=ord(s[0]); inc(b); s[0]:=chr(b);
        end;
        s[pos-1]:=ch;
      end;
    end;
    if (pos>=maxlen) and firstkey and (not(ch in [^X,^H,#13,#27])) then begin
      if firstkey then begin
        s:='';
        pos:=1;
        gotoxy(start+1,wherey);
        {write(s);}
        for x:=1 to maxlen-length(s) do write(spacechar);
        gotoxy(start+1,wherey);
        firstkey:=false;
      end;
      if hideinput then write(hidechar) else write(ch);
      inc(pos);
      if pos>length(s)+1 then begin
        b:=ord(s[0]); inc(b); s[0]:=chr(b);
      end;
      s[pos-1]:=ch;
    end;
  until ch in [#13,#27];
  if ch=#13 then def:=s;
  textattr:=savedcolor;
  gotoxy(start+1,wherey);
  if def<>'' then if hideinput then for x:=1 to length(def) do write(hidechar)
    else write(def);
  for x:=1 to maxlen-length(def) do write(' ');
  gotoxy(start+1,wherey);
end;

begin
  if paramstr(1)='/(C)' then begin
    writeln('EDITROUT.PAS - v1.51 - (C) Onkel Dittmeyer / S.L.A.M.');
    writeln('             Flexible line editing toolbox');
    readln;
  end;
  hidechar:='þ';
  spacechar:=' ';
  errortonefreq:=300;
  errortonelen:=200;
end.
