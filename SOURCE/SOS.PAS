unit sos;

interface

uses dos;

const sosversion  = '0.00á';
      sosmaxfiles = 100;
      def_marker  = #27+'[2JSmart Overlay System V'+sosversion+#13+#10
                       +'Copyright (C) Onkel Dittmeyer 1994'+#13+#10
                       +'All Rights Reserved.'+#13+#10+#26;

type soshfilerec  = record
                        filename   :string[8];
                        ext        :string[3];
                        index, len :longint;
                     end;

type sos_header   = record
                        marker   :string;
                        descript :string[70];
                        numfiles :word;
                        crc      :longint;
                        nextfree :longint;
                        files    :array[1..sosmaxfiles] of soshfilerec;
                      end;

var sosf         :file;
    x            :longint;
    blankheader  :sos_header;
    blankfilerec :soshfilerec;
    buf          :array[1..1024] of byte;
    hdr          :sos_header;
    sos_busy     :boolean;
    sos_fopen    :boolean;
    sos_newfile  :boolean;
    sos_filepos  :longint;
    sos_hmodified:boolean;
    {-------------------------}
    masterfile   :string;            { - important stuff!!! - }
    masterindex  :longint;
    crec         :word;              { open record; 0 = none  }
    {-------------------------}

procedure sosopen;
procedure sosclose;
procedure sosfopen(fn:string);
procedure sosseek(seekpos:longint);
procedure sosread(target:pointer;count:word);
procedure soswrite(source:pointer;count:word);
function  sosexist(fn:string):boolean;
function  sosbfsize(fn:string):longint;
procedure sosfcreate(fn:string);
procedure addfile(sosfile,fn:string);
procedure extract(sosfile,fn:string);
procedure sosdir(sosfile:string);
procedure wildadd(sosfile,mask:string);
procedure sosblockread(target:pointer;count:word;var res:word);

implementation

procedure err(errcode:byte);
begin
  write('SOS server error #',errcode,': ');
  case errcode of
    1 :writeln('Server busy!');
    2 :writeln('Server not open!');
    3 :writeln('File already open!');
    4 :writeln('File not found in SOS overlay!');
    5 :writeln('Server open, File is not!');
    6 :writeln('File not found in SOS overlay during bfs check!');
  end;
  halt(30+errcode);
end;

function uc(s:string):string;
var x:byte;
    st:string;
begin
  st[0]:=s[0];
  for x:=1 to length(s) do st[x]:=upcase(s[x]);
  uc:=st;
end;

procedure sosopen;
begin
  if sos_busy then err(1) else sos_busy:=true;
  sos_hmodified:=false;
  assign(sosf,masterfile);
  {$I-} reset(sosf,1); {$I+}
  if ioresult<>0 then begin
    rewrite(sosf,1);
    blockwrite(sosf,blankheader,sizeof(blankheader));
    close(sosf);
    reset(sosf,1);
  end;
  seek(sosf,masterindex);
  {$I-} blockread(sosf,hdr,sizeof(hdr)); {$I+}
  if ioresult<>0 then begin
    blockwrite(sosf,blankheader,sizeof(blankheader));
    hdr:=blankheader;
    hdr.nextfree:=masterindex+sizeof(hdr);
  end;
end;

procedure sosclose;
begin
  if not(sos_busy) then err(2) else sos_busy:=false;
  crec:=0;
  sos_newfile:=false;
  sos_fopen:=false;
  if sos_hmodified then begin
    seek(sosf,masterindex);
    blockwrite(sosf,hdr,sizeof(hdr));
  end;
  close(sosf);
end;

procedure sosfopen(fn:string);
var x :word;
begin
  sos_filepos:=0;
  if not(sos_busy) then err(2);
  if sos_fopen then err(3) else sos_fopen:=true;
  sos_newfile:=false;
  crec:=0;
  for x:=1 to hdr.numfiles do with hdr.files[x] do
  if filename+'.'+ext=uc(fn) then crec:=x;
  if crec=0 then err(4);
  seek(sosf,masterindex+hdr.files[crec].index);
end;

procedure sosseek(seekpos:longint);
begin
  if not(sos_busy) then err(2);
  if not(sos_fopen) then err(5);
  seek(sosf,masterindex+hdr.files[crec].index+seekpos);
  sos_filepos:=seekpos;
end;

procedure sosread(target:pointer;count:word);
begin
  if not(sos_busy) then err(2);
  if not(sos_fopen) then err(5);
  blockread(sosf,target^,count);
  inc(sos_filepos,count);
end;

procedure sosblockread(target:pointer;count:word;var res:word);
var w :word;
begin
  if not(sos_busy) then err(2);
  if not(sos_fopen) then err(5);
  if (hdr.files[crec].len-sos_filepos)>=count then begin
    blockread(sosf,target^,count);
    res:=count;
    inc(sos_filepos,count);
  end else begin
    w:=hdr.files[crec].len-sos_filepos;
    blockread(sosf,target^,w);
    res:=w;
    inc(sos_filepos,w);
  end;
end;

procedure soswrite(source:pointer;count:word);
begin
  if not(sos_busy) then err(2);
  if not(sos_fopen) then err(5);
  blockwrite(sosf,source^,count);
  inc(sos_filepos,count);
  if sos_newfile then begin
    inc(hdr.files[crec].len,count);
    inc(hdr.nextfree,count);
    sos_hmodified:=true;
  end;
end;

function sosexist(fn:string):boolean;
var x :word;
begin
  sosopen;
  for x:=1 to hdr.numfiles do with hdr.files[x] do
  if filename+'.'+ext=uc(fn) then begin
    sosclose;
    sosexist:=true;
    exit;
  end;
  sosexist:=false;
  sosclose;
end;

function sosbfsize(fn:string):longint;
var x :word;
begin
  sosopen;
  for x:=1 to hdr.numfiles do with hdr.files[x] do
  if filename+'.'+ext=uc(fn) then begin
    sosclose;
    sosbfsize:=hdr.files[x].len;
    exit;
  end;
  err(6);
  sosclose;
end;

procedure sosfcreate(fn:string);
begin
  if not(sos_busy) then err(2);
  with hdr do begin
    inc(numfiles);
    files[numfiles].filename:=copy(fn,1,pos('.',fn)-1);
    files[numfiles].ext:=copy(fn,pos('.',fn)+1,length(fn)-pos('.',fn));
    files[numfiles].index:=nextfree;
  end;
  seek(sosf,hdr.nextfree+masterindex);
  sos_newfile:=true;
  sos_fopen:=true;
  crec:=hdr.numfiles;
  sos_filepos:=0;
  sos_hmodified:=true;
end;

procedure addfile(sosfile,fn:string);
var inf    :file;
    br, bw :word;
begin
  fn:=uc(fn);
  write('adding ',fn,' to ',sosfile);
  assign(sosf,sosfile);
  {$I-} reset(sosf,1); {$I+}
  if ioresult<>0 then begin
    write(' [new file]');
    rewrite(sosf,1);
    blockwrite(sosf,blankheader,sizeof(blankheader));
    close(sosf);
    reset(sosf,1);
  end;
  seek(sosf,masterindex);
  {$I-} blockread(sosf,hdr,sizeof(hdr)); {$I+}
  if ioresult<>0 then begin
    blockwrite(sosf,blankheader,sizeof(blankheader));
    hdr:=blankheader;
    hdr.nextfree:=masterindex+sizeof(hdr);
  end;
  with hdr do begin
    inc(numfiles);
    files[numfiles].filename:=copy(fn,1,pos('.',fn)-1);
    files[numfiles].ext:=copy(fn,pos('.',fn)+1,length(fn)-pos('.',fn));
    files[numfiles].index:=nextfree;
  end;
  seek(sosf,hdr.nextfree+masterindex);
  assign(inf,fn);
  reset(inf,1);
  hdr.files[hdr.numfiles].len:=filesize(inf);
  repeat
    blockread(inf,buf,sizeof(buf),br);
    blockwrite(sosf,buf,br,bw);
  until (br=0) or (br<>bw);
  close(inf);
  inc(hdr.nextfree,hdr.files[hdr.numfiles].len);
  seek(sosf,masterindex);
  blockwrite(sosf,hdr,sizeof(hdr));
  close(sosf);
  writeln(' -OK');
end;

procedure extract(sosfile,fn:string);
var filename     :string[8];
    ext          :string[3];
    x            :word;
    found        :boolean;
    btogo        :longint;
    outf         :file;
    br           :word;

begin
  fn:=uc(fn);
  found:=false;
  writeln('extracting ',fn,' from ',sosfile,'...');
  assign(sosf,sosfile);
  reset(sosf,1);
  seek(sosf,masterindex);
  blockread(sosf,hdr,sizeof(hdr));
  filename:=copy(fn,1,pos('.',fn)-1);
  ext:=copy(fn,pos('.',fn)+1,length(fn)-pos('.',fn));
  for x:=1 to hdr.numfiles do
    if (filename=hdr.files[x].filename) and (ext=hdr.files[x].ext) then begin
    found:=true;
    writeln('found at #',x,': writing into file...');
    seek(sosf,hdr.files[x].index+masterindex);
    btogo:=hdr.files[x].len;
    assign(outf,fn);
    rewrite(outf,1);
    repeat
      if btogo>sizeof(buf) then blockread(sosf,buf,sizeof(buf),br)
        else blockread(sosf,buf,btogo,br);
      blockwrite(outf,buf,br);
      dec(btogo,br);
    until btogo=0;
    close(outf);
  end;
  close(sosf);
  if not(found) then writeln('nothing found matching ',fn);
end;

procedure sosdir(sosfile:string);
var x,y,fshown :word;
begin
  fshown:=6;
  assign(sosf,sosfile);
  reset(sosf,1);
  seek(sosf,masterindex);
  blockread(sosf,hdr,sizeof(hdr));
  close(sosf);
  writeln;
  writeln('   Title: ',hdr.descript);
  writeln('NextFree: ',hdr.nextfree);
  writeln('Assuming an ',sosmaxfiles,' record index table.');
  writeln;
  write('Index table        ');
  writeln(masterindex:10,'   ',sizeof(hdr):10);
  for x:=1 to hdr.numfiles do begin
    with hdr.files[x] do begin
      inc(fshown);
      write(filename);  for y:=1 to 10-length(filename) do write(' ');
      write(ext);       for y:=1 to 6 do write(' ');
      writeln(index:10,'   ',len:10);
      if fshown=24 then begin
        write('[ENTER to continue]');
        readln;
        fshown:=0;
      end;
    end;
  end;
  writeln;
  writeln(hdr.numfiles,' file(s) in SOSfile.');
end;

procedure init;
begin
  with blankfilerec do begin
    filename:='';
    ext:='';
    index:=0;
    len:=0;
  end;
  with blankheader do begin
    marker:=def_marker;
    descript:='BlueBEEP All-In-1 Smart Overlay System [SOS] - Data File';
    numfiles:=0;
    crc:=0;
    nextfree:=sizeof(blankheader);
    for x:=1 to sosmaxfiles do files[x]:=blankfilerec;
  end;
  sos_busy:=false;
  sos_fopen:=false;
  sos_newfile:=false;
  crec:=0;
end;

procedure wildadd(sosfile,mask:string);
var sr :searchrec;
    fc :longint;
begin
  fc:=0;
  findfirst(mask,anyfile,sr);
  while doserror=0 do begin
    if (sr.attr<>directory) then if (sr.name<>uc(sosfile)) then begin
      inc(fc);
      addfile(sosfile,sr.name);
    end;
    findnext(sr);
  end;
  writeln;
  writeln(fc,' file(s) added.');
end;

begin
  init;
  if paramstr(1)='/(C)' then begin
    write(def_marker);
    readln;
  end;
end.
