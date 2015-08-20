unit ferror;

interface

procedure fatalerror(stuff:string);

implementation

uses crt,bbp_vars;

procedure fatalerror(stuff:string);
begin
  sound(700);
  delay(300);
  sound(500);
  delay(300);
  nosound;
  textattr:=colors.error;
  window(1,1,80,25);
  clrscr;
  textattr:=colors.error_reverse;
  write(' FATAL ERROR');
  clreol;
  textattr:=colors.error;
  writeln;
  writeln;
  writeln(stuff);
  writeln;
  writeln('Program terminated.');
  textattr:=lightgray;
  halt($ff);
end;
end.