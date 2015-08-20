uses sos;
var res :word;
    buf :array[1..3000] of byte;
    f   :file;
begin
  if paramcount=0 then begin
    writeln;
    writeln('sostool - sos library manager, (c) onkeld 1994');
    writeln;
    writeln('syntax: sostool cmd archive index [filename]');
    writeln;
    writeln('cmd:');
    writeln;
    writeln('d - directory of library');
    writeln('a - add file to library');
    writeln('x - xtract file from lib');
    writeln;
    halt($ff);
  end;
  sos.masterfile:=paramstr(2);
  val(paramstr(3),sos.masterindex,res);
  if res<>0 then begin writeln('invalid masterindex.'); halt; end;
  if paramstr(1)='d' then sosdir(paramstr(2));
  if paramstr(1)='a' then wildadd(paramstr(2),paramstr(4));
  if paramstr(1)='x' then extract(paramstr(2),paramstr(4));
end.
