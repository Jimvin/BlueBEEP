uses dos;
const fixstr1 = #27+'[2JCopyright (C) ';
      fixstr2 = ' by Onkel Dittmeyer'+#26;

var f :file;
    s :string;

function Stg(w:word):String;
var s:string;
begin
  str(w,s);
  stg:=s;
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

begin
  assign(f,paramstr(1));
  reset(f,1);
  seek(f,30);
  s[0]:=#6;
  blockread(f,s[1],6);
  if s<>'PKLITE' then begin
    close(f);
    writeln('cant fix --> not lited');
    halt($ff);
  end;
  s:=fixstr1+date+fixstr2;
  writeln('fixing ',length(s),' byte lite(c)note...');
  seek(f,30);
  blockwrite(f,s[1],length(s));
  close(f);
end.
