unit types;

interface

const CurLf  = 'K';
      CurRt  = 'M';
      CurUp  = 'H';
      CurDn  = 'P';
      PgUp   = 'I';
      PgDn   = 'Q';
      Home   = 'G';
      Endk   = 'O';
      F1     = ';';
      F2     = '<';
      F3     = '=';
      F4     = '>';
      F5     = '?';
      F6     = '@';
      F7     = 'A';
      F8     = 'B';
      F9     = 'C';
      F10    = 'D';
      Ins    = 'R';
      Del    = 'S';
      Return = #13;
      Esc    = #27;

type ansi = array[0..3999] of char;
     bild = array[0..3999] of byte;

implementation

end.