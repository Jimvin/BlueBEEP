{ --------------------------------------------------------------------------- }
{                                                                             }
{        BBP-BSLI was planned, coded and developed by Onkel Dittmeyer.        }
{                    Copyright (C) 1993 by Onkel Dittmeyer                    }
{                                                                             }
{                   This project was started March 1, 1993                    }
{                                                                             }
{ --------------------------------------------------------------------------- }

{$F-}                { declare calls to be NEAR }
{$G+}                { force gen. of 286 code   }
{$M 16384,0,640000}  { 16k stack, 640k heap     }

uses
  bbp_vars,   { Variables & Constants     }
  bbp_init,   { Initialization & Loading  }
  bbp_bsli,   { BSL Interpreter           }
  extras,     { EXIST() function etc      }
  crt;        { clrscr                    }

{ ******** CODE ************************************************************* }

begin
  writeln;
  writeln('BSLI v0.09á - BlueBEEP Script Language Interpreter (C) 1993 by Onkel Dittmeyer');
  writeln('              All rights reserved. May be distributed and used freely. AnnJoy!');
  writeln;
  if paramcount=0 then begin
    writeln('Usage: BSLI <scriptfile.bsl>');
    halt($ff);
  end;
  if not exist(paramstr(1)) then begin
    writeln('ERROR: Script file ',paramstr(1),' not found.');
    halt($ff);
  end;
  init('BSLI');
  loadscript(paramstr(1));
  for x:=1 to maxnums do dispose(numbers[x]);
  clrscr;
  halt(0);
end.

{ ******** END OF SOURCE FILE *********************************************** }
