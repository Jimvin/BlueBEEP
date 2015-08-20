{ --------------------------------------------------------------------------

                               SBVoice v2.15

     A collection of kick-ass routines to load, save, play and make .voc
   files with a soundblaster ct-voice driver. Based on voc2exe (c) 1990 by
  me. A whole lot of werk went into those routines, and they were gradually
  improved over the years. If you have to rip em off, give me proper credit.

                 Copyright (C) 1991-1995 by Onkel Dittmeyer

  -------------------------------------------------------------------------- }

unit SBVoice;
interface
type VOCHDR = record
                  id           :array[0..19] of char;
                  voice_offset,
                  version,
                  check_code   :word;
                end;
     blocktype=array[0..63999] of byte;
     voicefile=record
                   lastblock :byte;
                   lastlength:word;
                   data      :array[0..10] of ^blocktype;
                 end;

const driversize = 2493; { standard 1.0 ct-voice.drv is 2493 bytes.. }

var f                             :file;
    res,status                    :word;
    p                             :voicefile;
    size                          :longint;
    pofs,pseg,statusofs,statusseg :word;
    lastblock                     :byte;

function  DriverVersion:string;
function  InitBlaster(sbint,adress:word):byte;
procedure LoadVoice(vfile:string;var p:voicefile;start:longint);
procedure PlayVoice(p:voicefile);
procedure KillVoice(var p:voicefile);
procedure FixDriver(drvfile:string;drvpos:longint);
procedure FinishBlaster;
procedure RemoveDriver;
procedure Speaker(onoff:word);
procedure StopIO;
procedure SampleInput(buffer:pointer;buffersize:longint;samplerate:word);
procedure RecordVoice(szFilename:string;samplerate:word;time:word);

implementation

uses dos,crt,extras,optimer,ferror,sos;

type drivertype=array[0..3000] of byte;

var x      :integer;
    driver :^drivertype;

function st(x:integer):string;
var dummy :string;
begin
  str(x,dummy);
  st:=dummy;
end;

function DriverVersion:string;
var x,y   :byte;
    xs,ys :string;
begin
  asm
    mov bx,0
    call driver
    mov x,ah
    mov y,al
  end;
  str(x,xs);
  str(y,ys);
  DriverVersion:=xs+'.'+ys;
end;

function InitBlaster(sbint,adress:word):byte;
var err:word;
begin
  asm
    mov bx,1
    mov ax,adress
    call driver
    mov bx,2
    mov ax,sbint
    call driver
    mov bx,3
    call driver
    mov err,ax
  end;
  initblaster:=err;
end;

procedure FinishBlaster;
begin
  asm
    mov bx,9
    call driver
  end;
end;

procedure LoadVoice(vfile:string;var p:voicefile;start:longint);
begin
  if not sosexist(vfile) then fatalerror('Error opening sample ['+uppercase(vfile)+']: not in database!');
  size:=sosbfsize(vfile);
  sosopen;
  sosfopen(vfile);
  sosseek($1A+start);
  x:=-1;
  repeat
    inc(x);
    getmem(p.data[x],64000);
    sosblockread(p.data[x],64000,res);
  until res<>64000;
  sosclose;
  p.lastlength:=res;
  p.lastblock:=x;
end;

procedure KillVoice(var p:voicefile);
var x:byte;
begin
  for x:=0 to p.lastblock do dispose(p.data[x]);
end;

procedure PlayVoice(p:voicefile);
begin
  statusofs:=ofs(status); statusseg:=seg(status);
  asm
    mov bx,5
    mov es,statusseg
    mov di,statusofs
    call driver
  end;
  for x:=0 to p.lastblock do begin
    pofs:=ofs(p.data[x]^); pseg:=seg(p.data[x]^);
    asm
      mov bx,6
      mov es,pseg
      mov di,pofs
      call driver
    end;
  end;
end;

procedure FixDriver(drvfile:string;drvpos:longint);
begin
  if not sosexist(drvfile) then fatalerror('Sound Card Driver ['+uppercase(drvfile)+'] not in database!');
  sosopen;
  sosfopen(drvfile);
  sosseek(drvpos);
  getmem(driver,driversize);
  sosread(driver,driversize);
  sosclose;
end;

procedure RemoveDriver;
begin
  freemem(driver,driversize);
end;

procedure Speaker(onoff:word);
begin
  asm
    mov bx,4
    mov ax,onoff
    call driver
  end;
end;

procedure StopIO;
begin
  asm
    mov bx,8
    call driver
  end;
  if status<>0 then begin
    writeln('I/O IS UNSTOPPABLE! HERE GOES WERLD PEACE! #HACK IN uPRoAr! AaarghL!');
    halt($ff);
  end;
end;

procedure sampleinput(buffer:pointer;buffersize:longint;samplerate:word);
var es_tmp,di_tmp,dx_tmp,cx_tmp :word;
    bstemp                      :longint;
begin
  statusofs:=ofs(status); statusseg:=seg(status);
  asm
    mov bx,5
    mov es,statusseg
    mov di,statusofs
    call driver
  end;
  bstemp:=buffersize;
  es_tmp:=seg(buffer^);
  di_tmp:=ofs(buffer^);
  cx_tmp:=memw[seg(bstemp):ofs(bstemp)];
  dx_tmp:=memw[seg(bstemp):ofs(bstemp)+2];
  asm
    mov bx,7
    mov ax,samplerate
    mov dx,dx_tmp
    mov cx,cx_tmp
    mov es,es_tmp
    mov di,di_tmp
    call driver
  end;
end;

function WriteToFile(var f:file;lpBuf:pointer;lsize:longint):boolean;
type PtrRec = record lo,hi:word; end;
var wByteToWrite,wByteWritten,wTemp :word;
begin
  WriteToFile:=True;
  wTemp:=0;
  repeat
    wByteToWrite:=$8000;
    if lSize<$8000 then wByteToWrite:=Word(lSize);
    BlockWrite(F,lpBuf^,wByteToWrite,wByteWritten);
    if wByteWritten<>wByteToWrite then begin
      writeln('d00d... l1k3 y0uR hDd is fU11 0r s0meTh1nG... tHaT sUx d00d.');
      WriteToFile := False;
      lSize := 0;
    end else begin
      wTemp:=wTemp+wByteWritten;
      PtrRec(lpBuf).lo:=PtrRec(lpBuf).lo+wByteWritten;
      if not Boolean(Hi(wTemp)) then PtrRec(lpBuf).hi:=PtrRec(lpBuf).hi+$1000;
      lSize:=lSize-wByteWritten;
    end;
  until not boolean(Lo(word(lSize)));
end;

function Recording(lpBuf:pointer;lpBufSize:longint;samplerate:word;time:word):Boolean;
begin
  Recording:=False;
  speaker(0);
  sampleinput(lpBuf,lpBufSize,samplerate);
  Recording:=True;
  if time=0 then repeat until keypressed xor (status<>$ffff) else delayms(time);
  stopio;
end;

procedure SaveVoiceFile(szFilename:string;lpBuf:pointer);
var  F                :file;
    lVoiceSize, lTemp :longint;
    header            :VOCHDR;
    dummy             :boolean;
    S                 :String[20];
begin
  S:='Creative Voice File';
  move( S[1], header.id,20);
  header.id[19]:=#26;
  header.voice_offset:=SizeOf(VOCHDR);
  header.version:=$010a;
  header.check_code:=$1129;
  {$I-}
  Assign(F,szFilename);
  Rewrite(F,1);
  {$I+}
  if IOResult=0 then begin
    if WriteToFile(F,@header,longint(SizeOf(VOCHDR))) then begin
      lVoiceSize:=longint(pointer(longint(lpBuf)+1)^);
      lVoiceSize:=lVoiceSize and $00ffffff;
      { add 5 bytes for the bloack header and terminating block }
      lVoiceSize:=lVoiceSize+5;
      dummy:=WriteToFile(F,lpBuf,lVoiceSize);
    end;
    Close(F);
  end else writeln('Create ',szFilename,' error.');
end;

procedure RecordVoice(szFilename:string;samplerate:word;time:word);
var lpVoiceBuf, lpTmpPtr, lpMarkPtr :pointer;
                           lBufSize :longint;
begin
  { allocate memory 128 KB memory }
  Mark(lpMarkPtr);
  GetMem(lpVoiceBuf,$ffff);
  GetMem(lpTmpPtr,$ffff);
  if (lpVoiceBuf<>nil) and (lpTmpPtr<>nil) then begin
      lBufSize := $ffff + $ffff;
      if Recording(lpVoiceBuf,lBufSize,samplerate,time) then
        SaveVoiceFile(szFilename,lpVoiceBuf);
  end else writeln('Memory allocation error ...');
  { release allocated memory }
  Release(lpMarkPtr);
end;

begin
  if paramstr(1)='/(C)' then begin
    writeln('SBVOICE.PAS  v2.15  SoundBlaster VOC and Driver Load/Play/Rec Stuff');
    writeln('                    Copyright (C) 1991-1995 by Onkel Dittmeyer');
    writeln;
    readln;
  end;
end.