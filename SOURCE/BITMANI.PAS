unit bitmani;

interface
uses crt;

type Bit_FieldTYP = ARRAY [0..1249] OF byte;
     Bit_FieldPTR = ^Bit_FieldTYP;

const bit :array[0..15] of word = (1,2,4,8,16,32,64,128,256,512,1024,
                                   2048,4096,8192,16384,32768);

function  GesetztInbyte(BitNr:byte;Testbyte:byte):boolean;
function  GesetztInFeld(BitNr:word;BitFeld:Bit_FieldPTR):boolean;
function  GesetztInword(BitNr:byte;Testword:word):boolean;
procedure SetBitInbyte(BitNr:byte;var Testbyte:byte);
procedure SetBitInword(BitNr:byte;var Testword:word);
procedure SetBitInFeld(BitNr:word;BitFeld:Bit_FieldPtr);
procedure ClrBitInbyte(BitNr:byte;var Testbyte:byte);
procedure ClrBitInword(BitNr:byte;var Testword:word);
procedure ClrBitInFeld(BitNr:word;BitFeld:Bit_FieldPtr);
procedure SwapBit(BitNr:byte; var Testbyte:byte);

implementation

procedure SetBitInbyte(BitNr:byte; var Testbyte:byte);
begin
  Testbyte:=Testbyte or bit[BitNr];
end;

procedure SetBitInword(BitNr:byte; var Testword:word);
begin
  Testword:=Testword or bit[BitNr];
end;

procedure SetBitInFeld(BitNr:word; BitFeld:Bit_FieldPtr);
begin
  BitFeld^[BitNr DIV 8]:=BitFeld^[BitNr DIV 8] or bit[BitNr and 7];
end;

procedure ClrBitInbyte(BitNr:byte;var Testbyte:byte);
begin
  Testbyte:=Testbyte and NOT bit[BitNr];
end;

procedure ClrBitInword(BitNr:byte; var Testword:word);
begin
  Testword:=Testword and NOT bit[BitNr];
end;

procedure ClrBitInFeld(BitNr:word; BitFeld:Bit_FieldPtr);
begin
  BitFeld^[BitNr DIV 8] :=
  BitFeld^[BitNr DIV 8] and NOT bit[BitNr and 7];
end;

function GesetztInbyte(BitNr,Testbyte:byte):boolean;
begin
  GesetztInbyte:=0 <> (Testbyte and bit[BitNr]);
end;

function GesetztInFeld(BitNr:word; BitFeld:Bit_FieldPTR):boolean;
begin
  GesetztInFeld:=0 <> (BitFeld^[BitNr DIV 8] and bit[BitNr and 7]);
end;

function GesetztInword(BitNr:byte;Testword:word):boolean;
begin
  GesetztInword:=0<>(Testword and bit[BitNr]);
end;

procedure SwapBit(BitNr:byte; var Testbyte:byte);
var Tempbyte :byte;
begin
  Tempbyte:=Testbyte;
  IF GesetztInbyte(BitNr,Tempbyte) then ClrBitInbyte(BitNr,Tempbyte)
    else SetBitInbyte(BitNr,Tempbyte);
  Testbyte:=Tempbyte;
end;

begin
  if paramstr(1)='/(C)' then begin
    writeln('BITMANI.PAS  v1.00  Bit Manipulation routines and functions');
    writeln('                    Copyright (C) 1993 by Onkel Dittmeyer/SLAM');
    writeln;
    readln;
  end;
end.
