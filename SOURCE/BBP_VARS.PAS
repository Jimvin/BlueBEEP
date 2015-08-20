{ ------------------------------------------------------------------------ }
{                                                                          }
{             BlueBEEP global type, constant and variable segment          }
{                                                                          }
{            All structures copyright (C) Onkel Dittmeyer 1993-1995        }
{                             All Rights Reserved.                         }
{                                                                          }
{ ------------------------------------------------------------------------ }

unit bbp_vars;

interface

uses types;

const maininfotext     : array[1..5] of string =
                         ('Set up BlueBEEP, edit trunks, dial sets, etc.',
                          'Tools like import / export phone directory, etc.',
                          'Rave hard! Get to work! PHREAK OUT!',
                          'Information about BlueBEEP',
                          'Leave BlueBEEP');
      onoff            : array[false..true] of string = ('OFF','ON ');
      publicversion    = TRUE;  { set this FALSE when you release a áeta ver }
      releasedate      = 'Saturday, April 1st, 1995';
      internetadress   = 'onkeld@planet.net';
      pbk_defrec_name  = 'Joey''s Pizza'; { initial phonebook record, name   }
      pbk_defrec_num   = '+49-40-777095'; { initial phonebook record, number }
      exesize          = 75287;           { important for SOS server !!!     }
      id_serialcode    = 0;               { user-id and pass checksums       }
      id_passcode      = 0;
      check_userid     = FALSE;           { set to true to have it all chk'd }
      version          = '1.00';          { guess this is self-explaining :) }
      maxtrunks        = 19;              { max # of trunks                  }
      maxnums          = 500;             { max # of phonebook entries       }
      maxdialsets      = 19;              { max # of dial sets               }
      maxcompanies     = 19;              { max # of companies for ccc       }
      maxdtlsets       = 19;              { max # of dial translations       }
      maxdoclength     = 1500;            { max line number for doc system   }
      maxcountrycodes  = 150;             { max number of country codes      }
      maxfwords        = 5000;            { max number of fonewordlist entr. }
      pbentrynamelen   = 35;              { length of pbk name entry         }
      pbentrynumlen    = 20;              { length of pbk number entry       }
      trunkfilename    = 'BLUEBEEP.TRK';  { name for trunk file              }
      dsfilename       = 'BLUEBEEP.SET';  { name for dial set file           }
      cfgfilename      = 'BLUEBEEP.CFG';  { name for config file             }
      phonebookname    = 'BLUEBEEP.PBK';  { name for phone book file         }
      scanfilename     = 'BLUEBEEP.SCN';  { name for scanning file           }
      redboxfilename   = 'BLUEBEEP.RBX';  { name for red box freq file       }
      freqtestfilename = 'BLUEBEEP.FQT';  { name for freq test file          }
      pulsedialfilename= 'BLUEBEEP.PLS';  { name for pulse dialing file      }
      cccfilename      = 'BLUEBEEP.CCC';  { name for cc checker file         }
      ccctempfilename  = 'CPROCESS.CCC';  { name for cc checker temp file    }
      colorfilename    = 'BLUEBEEP.CLR';  { name for screen color file       }
      wordlistfilename = 'BLUEBEEP.WLS';  { name for wordlist file           }
      dtlfilename      = 'BLUEBEEP.DTL';  { name for dial translation file   }
      ccodefilename    = 'BLUEBEEP.CCD';  { name for country code database   }
      tempfilename     = 'BLUEBEEP.TMP';  { name for various temp files      }
      bosskeyfilename  = 'BOSSKEY.SCR';   { name for bosskey scrimage        }
      pagesize         = 9;               { page length in action screen     }
      speedstepsize    = 0.05;            { dial speed switch step size      }
      blankpbentry     = '-Unused-';      { blank phone book entry string    }
      oldpbooksize     = 36000;           { size of the old phone book fmt.  }

{ ******** INCLUDE ANSI PIX ************************************************ }

{$I BBP_LOGO.INC}           { BlueBEEP Logo for the opening screen           }
{$I BBP_BART.INC}           { Bart Simpson "sucks dicks" ansi                }
{$I BBP_TKOM.INC}           { Telekom Logo                                   }

{ ******** TYPE DEFINITIONS ************************************************ }

type vgascreen    = array[0..63999] of byte; { for star bullshit }
     tonetype     = record
                        one   :word;     { Frequency #1 }
                        two   :word;     { Frequency #2 }
                        three :word;     { Frequency #3 }
                        len   :word;     { Length of tone }
                      end;

     tonetype2    = record
                        one   :word;     { Frequency #1 }
                        two   :word;     { Frequency #2 }
                        three :word;     { Frequency #3 }
                        mark  :word;     { Mark Time    }
                        space :word;     { Space Time   }
                      end;

     dialsettype  = record
                        standard,description        :string;
                        tone                        :array[0..9] of tonetype2;
                        kp1, kp2, st, raute, stern,
                        kp2e, ste, eo, c11, c12     :tonetype2;
                     end;
     configtype   = record
                        version    :string;  { Verision number of *creator*}
                        password   :string;  { BlueBEEP Password           }
                        dialspeed  :real;    { Dialing speed               }
                        firstonpage,         { First rec on page in acmode }
                        curtrunk,            { Currently selected trunk    }
                        curdset,             { Currently selected dial set }
                        curnum,              { Currently selected number   }
                        curcompany,          { Currently used CCC company  }
                        timesused  :longint; { How many times BB! was used }
                        gotblaster :boolean; { Got SB or only AdLib ?      }
                        sbint, sbaddr :word; { Sound Blaster Parameters    }
                        curcard,             { Current Card # for Talker   }
                        curcallto   :string; { Current Fone # for Talker   }
                        switchback  :byte;   { Toggle the play/rec bit y/n }
                        flipkeypad,          { flip keypad in action mode  }
                        ccc_manually:boolean;{ sample ccc or decide man.   }
                        modem       :boolean;{ modem present at all ?      }
                        modemport,           { modem COM port              }
                        modemspeed  :word;   { modem DTE speed             }
                        phonesystem :boolean;{ true = t-tone, false = pulse}
                        modeminit   :string; { modem init string           }
                        modemdatabits,       { modem data bits             }
                        modemparity,         { modem parity                }
                        modemstopbits :byte; { modem stop bits             }
                        touchpad   :boolean; { use the touch-mode on pad   }
                        commaperiod :word;   { Comma delay period for dial }
                        cetdiff    :integer; { difference to CET time zone }
                        activedtl   :byte;   { currently used DTL record   }
                      end;

     oldnumberrec = record name, number :string[35]; end;

     numberrec    = record
                        name   :string[pbentrynamelen];
                        number :string[pbentrynumlen];
                      end;

     trunktype    = record
                        name,description :string;  { Name, desc of trunk      }
                        tone             :array[1..10] of tonetype;
                        pause            :array[1..10] of word;
                      end;
     scantype     = record
                        scanstring       :string;  { before/after scandigits  }
                        quickmacro       :string;  { quick macro              }
                        digits,progress  :longint; { how many digits to scan  }
                        ai               :boolean; { Auto-Increase flag       }
                        redialcount      :longint; { redial macro atr. X tries}
                        redialprog       :longint; { redial temp countdown    }
                        stripzeroes      :boolean; { strip leading zeroes     }
                      end;

     oldtlonumrec = record
                        number :string[25];        { TLO 0.1-0.9 phone book   }
                        descrip:string[30];        { format definition        }
                      end;

     newtlonumrec = record
                        number :string[30];        { TLO 1.0 phone book       }
                        descrip:string[30];        { format definition        }
                      end;

     redboxtype   = record
                        acts1, acts2,              { redbox ACTS frequencies  }
                        ipts1, ipts2,              { redbox IPTS frequencies  }
                        nonacts       :word;       { redbox Non-ACTS freq.    }
                      end;

     freqtesttype = record
                        freq11, freq12, freq13, len1, del1,   { freqtest vars }
                        freq21, freq22, freq23, len2 :word;   { and .FQT file }
                        numbertotest                 :string; { format        }
                        stepsize                     :word;   { definition !  }
                      end;

    pulsedialtype = record
                        waitfordt, pulse_mark,       { pulsedial variables    }
                        pulse_space, pulse_interdig, { and BLUEBEEP.PLS file  }
                        portadress, hookbit,         { format definitions     }
                        playrecbit, phonebit,
                        accesstime, hanguptime :word;
                      end;

    ccc_companytype=record                           { comps for cardchecker  }
                        name,number :string;         { name & # of company    }
                        numberfirst :boolean;        { wants # 1st like AT&T  }
                        startseq    :string;         { start seq. norm. blnk  }
                        endseq      :string;         { following seq e.g. "#" }
                        numdelay    :word;           { delay between # & card#}
                        comeuptime  :word;           { del. for tlc. to cm. up}
                        recorddelay :word;           { time 'till smpl. starts}
                        sampletime  :word;           { sample time in ms      }
                        samplerate  :word;           { rate to sample at (Hz) }
                      end;

    dtltype       = record                           { * Dial Translation *   }
                        name,                        { DTL name for entry     }
                        note,                        { DTL notes for entry    }
                        local,                       { Local dialformat stg   }
                        global,                      { Int'l "+" dtl string   }
                        special,                     { special dialformat stg }
                        autolocal :string;           { AutoLocal county code  }
                      end;

    colortype = record
                    normal,
                    high,
                    high2,
                    super_high,
                    dark,
                    error,
                    error_reverse,
                    reverse,
                    reverse_high,
                    special,
                    special_high,
                    special_dark,
                    special_reverse,
                    special_reverse_high,
                    status,
                    status_high,
                    win_border_1,
                    win_border_2,
                    win_border_3,
                    win_text,
                    win_text_high,
                    win_hilight,
                    win_hilight_high,
                    win_item,
                    win_arrows,
                    win_fill,
                    win_error,
                    win_title,
                    win_background,
                    knob_active,
                    knob_inactive,
                    shadow,
                    help_normal,
                    help_high,
                    help_border_1,
                    help_border_2,
                    help_border_3,
                    help_title,
                    help_index,
                    help_selected_index,
                    inputfield,
                    infoline,
                    infoline_high,
                    progressbar,
                    keypad_pressed,
                    keypad_released,
                    titlebox,
                    titlebox_border,
                    titlebox_high,
                    titlebox_inverse,
                    titlebox_title,
                    worldtime_ahead :byte;
                  end;

type ccodetype = record
                     cc      :string[3];
                     country :string[12];
                   end;

type fwordtype = array[1..maxfwords] of string[4];

{ ******** VARIABLE DEFINITION BLOCK FOR THE GLOBAL BLUEBEEP PROJECT ******* }

var itemcount, oldattr  :byte;                    { Item counter for hormenu }
    item                :array[1..10] of string;  { the items for hormenu    }
    x,y,z               :word;                    { temporary runtime vars   }
    result, oldx, oldy  :byte;                    { result of hormenu here   }
    dossave             :^ansi;
    oldphonebook        :file of oldnumberrec;    { BlueBEEP <= V0.07 format }
    oldtlobook          :file of oldtlonumrec;    { old TLO phonebook filevar}
    newtlobook          :file of newtlonumrec;    { new TLO phonebook filevar}
    ccctempfile         :text;                    { whatever rgne            }
    config              :configtype;              { Current config set       }
    curds               :dialsettype;             { Currently used dial set  }
    curtrunk            :trunktype;               { Current trunk            }
    curscan             :scantype;                { Current Scan             }
    curnum,lastnum      :numberrec;               { ????? used WHERE!?!?!?   }
    curredbox           :redboxtype;              { Current Red Box          }
    curfreqtest         :freqtesttype;            { Current Frequency Test   }
    curpulsedial        :pulsedialtype;           { Current Pulse Dial Sets  }
    curccc              :ccc_companytype;         { Current CC checker set   }
    curdtl              :dtltype;                 { Current dial translation }
    numbers             :array[1..maxnums] of ^numberrec; { vars for numbers }
    numflags            :array[1..maxnums] of boolean; { vars for # flags    }
    ccodes              :array[1..maxcountrycodes] of ^ccodetype; { c-codes! }
    ccodecnt            :word;                    { how many country codes?  }
    firstonpage,current :word;                    { stuff for number select. }
    ch                  :char;                    { temp. key variable       }
    save                :array[1..4000] of byte;  { temp. savescreen var     }
    mousepresent        :boolean;                 { ms. presence set in init }
    extendedfeatures    :boolean;                 { enable extended feats    }
    keycode,handle      :string;                  { for security shitstuff   }
    colors              :colortype;               { color database for scnrs }
    userid, userpass    :string;                  { User ID for serialized V }
    fonewords           :^fwordtype;              { 4-digit combo buffer     }
    numwords            :word;                    { # of words in phoneword  }

    { NOTE: Local variables s (string) and x, i (byte/word/int) are used for }
    {       loops and temporarily operations.                                }


implementation end.
