uses hexout;
function getchecksum(fn:string):longint;
type buftype = array[1..32000] of byte;
var p, sum, bsum   :longint;
    fs             :longint;
    toggle         :boolean;
    br,x           :word;
    buf            :^buftype;
    f              :file;
begin
  sum:=1000000;
  bsum:=0;
  toggle:=true;
  assign(f,fn);
  reset(f,1);
  fs:=filesize(f);
  p:=0;
  new(buf);
  repeat
    write('.');
    blockread(f,buf^,sizeof(buf^),br);
    for x:=1 to br do begin
      inc(p);
      bsum:=bsum+buf^[x];
      if toggle then sum:=sum+(buf^[x]*p) else sum:=sum-(buf^[x]*p);
      {toggle:=not(toggle);}
    end;
  until br<>sizeof(buf^);
  close(f);
  dispose(buf);
  getchecksum:=sum+bsum+p;
end;

begin
  write('Checking integrity of ',paramstr(1));
  writeln(hexl(getchecksum(paramstr(1))),'h');
end.
