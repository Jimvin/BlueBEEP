var t,b:text;
    line,s,errmsg,edfile,scol:string;
    f:file of byte;
    x,col:byte;

begin
  assign(t,'error');
  reset(t);
  while not eof(t) do begin
    readln(t,s);
    if pos('Error ',s)<>0 then begin
      edfile:=copy(s,1,pos('(',s)-1);
      line:=copy(s,pos('(',s)+1,pos(')',s)-pos('(',s)-1);
      errmsg:='*** '+copy(s,pos(': ',s)+2,length(s)-pos(': ',s)-1)+' ***';
      for x:=1 to length(errmsg) do if errmsg[x]='"' then errmsg[x]:='''';
      readln(t);
      readln(t,s);
      col:=pos('^',s);
      str(col,scol);
      close(t);
      assign(b,'reed.bat');
      rewrite(b);
      writeln(b,'SPFPC /E ',edfile,' /L(',line,',',scol,') /N"',errmsg,'"');
      close(b);
      writeln('error - reloading...');
      halt($FF);
    end;
  end;
  assign(f,'exe\'+paramstr(1)+'.exe');
  reset(f);
  writeln('exe is ',filesize(f),' bytes');
  close(f);
end.
