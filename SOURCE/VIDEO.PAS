unit video;

interface

const videocards :array[0..9] of string = ('NO','Hercules','CGA','Unknown',
                                           'EGA','EGA','Unknown','VGA',
                                           'VGA','Unknown');


var vadr   :word;              { Video memory adress for direct access }
    vcolor :boolean;           { Color video adapter?                  }
    card   :byte;              { Type of video card installed          }

implementation

begin
  asm
    mov ah,1ah
    xor al,al
    int 10h
    mov card,bl
  end;
  case card of
    0 :begin vcolor:=false; vadr:=0; end;     { No video card             }
    1 :begin vcolor:=false; vadr:=$B000; end; { Hercules w/mono screen    }
    2 :begin vcolor:=true; vadr:=$B800; end;  { CGA w/CGA screen          }
    3 :begin vcolor:=false; vadr:=0; end;     { reserved                  }
    4 :begin vcolor:=true; vadr:=$B800; end;  { EGA w/EGA or multi screen }
    5 :begin vcolor:=false; vadr:=$B800; end; { EGA w/mono screen         }
    6 :begin vcolor:=false; vadr:=0; end;     { reserved                  }
    7 :begin vcolor:=false; vadr:=$B800; end; { VGA w/analog mono screen  }
    8 :begin vcolor:=true; vadr:=$B800; end;  { VGA w/color screen        }
    9 :begin vcolor:=false; vadr:=0; end;     { reserved                  }
  end;
end.
