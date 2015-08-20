unit bbp_conv;

interface

procedure convertccodes;
procedure convertdocs;

implementation

uses bbp_vars, bbp_info, crt;

procedure convertccodes;
var t        :text;
    s        :string;
    currec   :ccodetype;
    target   :file of ccodetype;
    numcodes :word;
begin
  writeln('BLUEBEEP CONVCC - Converting C-CODE.LST into country code database');
  writeln;
  writeln('start converting...');
  assign(t,'C-CODE.LST');
  reset(t);
  assign(target,ccodefilename);
  rewrite(target);
  numcodes:=0;
  while not eof(t) do begin
    readln(t,s);
    if (s[1]<>';') and (s<>'') then begin
      inc(numcodes);
      currec.cc:=copy(s,1,pos(' ',s)-1);
      s:=copy(s,4,length(s)-3);
      while s[1]=' ' do s:=copy(s,2,length(s)-1);
      while s[length(s)]=' ' do s:=copy(s,1,length(s)-1);
      currec.country:=s;
      write(target,currec);
    end;
  end;
  close(t);
  close(target);
  writeln(numcodes,' country codes converted.');
  halt($FF);
end;

procedure convertdocs;
const inname  = 'BLUEBEEP.DOC';
      outname = 'BLUEBEEP.TXT';
var t          :text;
    x,y        :word;
    s          :string;

begin
  colors.error:=white;
  colors.error_reverse:=red*16+white;
  writeln;
  writeln('BLUEBEEP PLAINDOC - Converting documentation into plaintext ASCII txt');
  writeln;
  writeln('Action: Converting ',inname,' to ',outname);
  writeln('Opening ',inname,' to build topic table');
  readtopictable(inname);
  writeln('Build of topic table completed');
  writeln('Stripping color codes out of ',doclength,' lines');
  for x:=1 to doclength do begin
    s:='';
    y:=0;
    while length(document[x]^)>y do begin
      inc(y);
      if document[x]^[y]='|' then inc(y) else s:=s+document[x]^[y];
    end;
    document[x]^:=s;
  end;
  writeln('Opening output file ',outname);
  assign(t,outname);
  rewrite(t);
  for y:=1 to 79 do write(t,'Ä');
  writeln(t);
  writeln(t,' ',docname,' - Table of Contents');
  for y:=1 to 79 do write(t,'Ä');
  writeln(t);
  writeln(t);
  for x:=1 to topiccount do begin
    write(t,'  ',x:2,') ',topictable[x]^.topic);
    for y:=1 to 70-length(topictable[x]^.topic)-length(topictable[x]^.subtitle)
      do write(t,'.');
    writeln(t,topictable[x]^.subtitle);
  end;
  writeln(t);
  writeln(t,'      Total ',topiccount,' topic(s)');
  writeln(t);
  writeln(t,'Converted using PLAINDOC V1.00 from a Dr. Reader document');
  writeln(t);
  for x:=1 to topiccount do begin
    write('Writing topic to output file: ',topictable[x]^.topic,'                 ',#13);
    for y:=1 to 79 do write(t,'Ä');
    writeln(t);
    writeln(t,' ',topictable[x]^.topic,' - ',topictable[x]^.subtitle);
    for y:=1 to 79 do write(t,'Ä');
    writeln(t);
    for y:=topictable[x]^.astart+1 to topictable[x]^.aend do writeln(t,'  ',document[y]^);
    writeln(t);
  end;
  write(#10);
  writeln('Closing files & freeing memory');
  writeln(t);
  for y:=1 to 79 do write(t,'Ä');
  writeln(t);
  writeln(t,' End of document                                       PLAINDOC (C) 1993 by OD');
  for y:=1 to 79 do write(t,'Ä');
  writeln(t);
  close(t);
  for x:=1 to doclength do dispose(document[x]);
  writeln('Operation complete - ',outname,' successfully created on disk.');
  halt(0);
end;
end.