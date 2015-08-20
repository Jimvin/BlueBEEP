{ --------------------------------------------------------------------------- }
{                                                                             }
{        BlueBEEP was planned, coded and developed by Onkel Dittmeyer.        }
{                 Copyright (C) 1993-1994 by Onkel Dittmeyer                  }
{                            All rights reserved                              }
{                                                                             }
{                   This project was started March 1, 1993                    }
{                                                                             }
{ --------------------------------------------------------------------------- }

{ requires to compile: Turbo Pascal 6.0 or later, sys6a system.tpu, sostool
                       overlay merger, optional lzexe or pklite.
                       for compilation procedure see built.bat. }

{ requires to run:     286+ w/ 580k+ of available ram and approx. 1 mb disk
                       space. optional: color display, mouse. to run properly,
                       a adlib or (better) soundblaster card is suggested. }

{ PLEASE DO NOT CIRCULATE THIS SOURCE CODE WITHOUT PRIOR CONSENT OF ME OR GOD }

{$F-}                { declare calls to be NEAR }
{$G+}                { force gen. of 286 code   }
{$R-}                { disable range checking   }
{$M 16384,0,640000}  { 16k stack, 640k heap     }

uses
  bbp_vars,   { Variables & Constants     }
  bbp_init,   { Initialization & Loading  }
  bbp_set,    { Setup functions, cfg file }
  bbp_tool,   { Tools, file i/o           }
  bbp_info,   { Infomenu, documentation   }
  bbp_pom,    { Main Stuff, dialer iface  }
  bbp_proc,   { Procedures, Functions...  }
  grmenus;    { Green Menus --> curpos    }

{ ******** CODE ************************************************************* }

begin
  init('BlueBEEP');
  startup;
  repeat
    result:=hormenu(2);
    result:=curpos;
    case result of
      1:setup;
      2:tools;
      3:phreakoutmenu;
      4:info;
      5:quit;
    end;
  until false;
end.

{ ******** END OF SOURCE FILE *********************************************** }
