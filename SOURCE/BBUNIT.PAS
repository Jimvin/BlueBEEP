unit bbunit;

interface
procedure soundio(address,data: word);
procedure soundinit;
procedure soundplay(freq1,freq2,freq3,len: word);
procedure soundstart(freq1,freq2,freq3:word);
procedure soundstop;

implementation
uses optimer;

procedure soundio(address,data: word);
begin
  port[$388] := address;  delayms(1); {* Adressregister ausgeben      *}
  port[$389] := data;     delayms(1); {* Daten ausgeben               *}
end;

procedure soundinit;
var lop : byte;
begin
  for lop := 0 to 255 do soundio(lop,0);   {* Alle Register resetten       *}
  soundio($20,$01);                        {* Modulator Multiple K1        *}
  soundio($21,$01);                        {* Modulator Multiple K2        *}
  soundio($22,$01);
  soundio($40,$FF);                        {* Modulator Attenuation K1     *}
  soundio($41,$FF);                        {* Modulator Attenuation K2     *}
  soundio($42,$FF);
  soundio($60,$FF);                        {* Modulator Attack/Decay K1    *}
  soundio($61,$FF);                        {* Modulator Attack/Decay K2    *}
  soundio($62,$FF);
  soundio($80,$00);                        {* Modulator Sustain/Release K1 *}
  soundio($81,$00);                        {* Modulator Sustain/Release K2 *}
  soundio($82,$00);
  soundio($23,$01);                        {* Carrier Multiple K1          *}
  soundio($24,$01);                        {* Carrier Multiple K2          *}
  soundio($25,$01);
  soundio($43,$00);                        {* Carrier Attenuation K1       *}
  soundio($44,$00);                        {* Carrier Attenuation K2       *}
  soundio($45,$00);
  soundio($63,$F0);                        {* A/D K1                       *}
  soundio($64,$F0);                        {* A/D K2                       *}
  soundio($65,$F0);
  soundio($83,$00);                        {* S/R K1                       *}
  soundio($84,$00);                        {* S/R K2                       *}
  soundio($85,$00);
end;

procedure soundplay(freq1,freq2,freq3,len:word);
var freqr1,                                {* Frequenz Real Kanal 1        *}
    freqr2,
    freqr3 : real;                         {* Frequenz Real Kanal 2        *}
begin
  if freq1 = freq2 then freq2 := 0;        {* Resonanz verhindern          *}
  freqr1 := freq1/6.103515625;             {* Frequenz K1 errechnen        *}
  freq1  := round(freqr1);                 {* Als Word runden              *}
  freqr2 := freq2/6.103515625;             {* Frequenz K2 errechnen        *}
  freq2  := round(freqr2);                 {* Als Word runden              *}
  freqr3 := freq3/6.103515625;
  freq3  := round(freqr3);
  soundio($B0,(60 or hi(freq1)));          {* Hibits K1 ausgeben           *}
  soundio($B1,(60 or hi(freq2)));          {* Hibits K2 ausgeben           *}
  soundio($B2,(60 or hi(freq3)));
  soundio($A0,lo(freq1));                  {* Lowbyte K1 ausgeben          *}
  soundio($A1,lo(freq2));                  {* Lowbyte K2 ausgeben          *}
  soundio($A2,lo(freq3));
  delayms(len);                            {* Ausgabedauer in ms           *}
  soundio($B0,00);                         {* Kanal 1 ausschalten          *}
  soundio($B1,00);                         {* Kanal 2 ausschalten          *}
  soundio($B2,00);
  soundio($A0,00);                         {* Kanal 1 ausschalten          *}
  soundio($A1,00);                         {* Kanal 2 ausschalten          *}
  soundio($A2,00);
end;

procedure soundstart(freq1,freq2,freq3:word);
var freqr1,                                {* Frequenz Real Kanal 1        *}
    freqr2,
    freqr3 : real;                         {* Frequenz Real Kanal 2        *}
begin
  if freq1 = freq2 then freq2 := 0;        {* Resonanz verhindern          *}
  freqr1 := freq1/6.103515625;             {* Frequenz K1 errechnen        *}
  freq1  := round(freqr1);                 {* Als Word runden              *}
  freqr2 := freq2/6.103515625;             {* Frequenz K2 errechnen        *}
  freq2  := round(freqr2);                 {* Als Word runden              *}
  freqr3 := freq3/6.103515625;
  freq3  := round(freqr3);
  soundio($B0,(60 or hi(freq1)));          {* Hibits K1 ausgeben           *}
  soundio($B1,(60 or hi(freq2)));          {* Hibits K2 ausgeben           *}
  soundio($B2,(60 or hi(freq3)));
  soundio($A0,lo(freq1));                  {* Lowbyte K1 ausgeben          *}
  soundio($A1,lo(freq2));                  {* Lowbyte K2 ausgeben          *}
  soundio($A2,lo(freq3));
end;

procedure soundstop;
begin
  soundio($B0,00);                         {* Kanal 1 ausschalten          *}
  soundio($B1,00);                         {* Kanal 2 ausschalten          *}
  soundio($B2,00);
  soundio($A0,00);                         {* Kanal 1 ausschalten          *}
  soundio($A1,00);                         {* Kanal 2 ausschalten          *}
  soundio($A2,00);
end;


end.
