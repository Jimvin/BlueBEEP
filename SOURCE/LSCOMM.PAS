UNIT lscomm;

{Version 3.1    8/11/92 rob lerner}

{This unit is the communications port interrupt driver for the IBM-PC.
It handles handles all low-level i/o through the serial port.  It is
installed by calling Cominstall.  It deinstalls itself automatically
when the program exits, or you can deinstall it by calling Comdeinstall.

Donated to the public domain by Wayne E. Conrad, January, 1989.
If you have any problems or suggestions, please contact me at my BBS:

    Pascalaholics Anonymous
    (602) 484-9356
    2400 bps
    The home of WBBS
    Lots of source code

Modified on 8/11/92 for procedure names to be better aligned to function
rob lerner

}

INTERFACE

USES
  Dos;

CONST
  ComInstalled: Boolean = False;

TYPE
  Comparity = (ComNone, ComEven, ComOdd, ComZero, ComOne);


PROCEDURE ComFlushRx;
PROCEDURE ComFlushTx;
FUNCTION  Comcarrier: Boolean;
FUNCTION  ComRx: Char;
FUNCTION  ComTxReady: Boolean;
FUNCTION  ComTxEmpty: Boolean;
FUNCTION  ComRxEmpty: Boolean;
PROCEDURE ComTx (ch: Char);
PROCEDURE ComRxString (st: String);
PROCEDURE ComLowerDTR;
PROCEDURE ComRaiseDTR;
PROCEDURE ComSetSpeed (speed: Word);
PROCEDURE ComSetParity (parity: Comparity; stop_bits: Byte);
PROCEDURE ComInstall
  (
  portnum  : Word;
  VAR error: Word
  );
PROCEDURE Comdeinstall;


IMPLEMENTATION


{Summary of IBM-PC Asynchronous Adapter Registers.  From:
  Compute!'s Mapping the IBM PC and PCjr, by Russ Davis
  (Greensboro, North Carolina, 1985: COMPUTE! Publications, Inc.),
  pp. 290-292.

Addresses given are for COM1 and COM2, respectively.  The names given
in parentheses are the names used in this module.


3F8/2F8 (uart_data) Read: transmit buffer.  Write: receive buffer, or baud
rate divisor LSB if port 3FB, bit 7 = 1.

3F9/2F9 (uart_ier) Write: Interrupt enable register or baud rate divisor
MSB if port 3FB, bit 7 = 1.
PCjr baud rate divisor is different from other models;
clock input is 1.7895 megahertz rather than 1.8432 megahertz.
Interrupt enable register:
    bits 7-4  forced to 0
    bit 3     1=enable change-in-modem-status interrupt
    bit 2     1=enable line-status interrupt
    bit 1     1=enable transmit-register-empty interrupt
    bit 0     1=data-available interrupt

3FA/2FA (uart_iir) Interrupt identification register (prioritized)
     bits 7-3  forced to 0
     bits 2-1  00=change-in-modem-status (lowest)
     bits 2-1  01=transmit-register-empty (low)
     bits 2-1  10=data-available (high)
     bits 2-1  11=line status (highest)
     bit 0     1=no interrupt pending
     bit 0     0=interrupt pending

3FB/2FB (uart_lcr) Line control register
     bit 7  0=normal, 1=address baud rate divisor registers
     bit 6  0=break disabled, 1=enabled
     bit 5  0=don't force parity
            1=if bit 4-3=01 parity always 1
              if bit 4-3=11 parity always 0
              if bit 3=0 no parity
     bit 4  0=odd parity,1=even
     bit 3  0=no parity,1=parity
     bit 2  0=1 stop bit
            1=1.5 stop bits if 5 bits/character or
              2 stop bits if 6-8 bits/character
     bits 1-0  00=5 bits/character
               01=6 bits/character
               10=7 bits/character
               11=8 bits/character

     bits 5..3: 000 No parity
                001 Odd parity
                010 No parity
                011 Even parity
                100 No parity
                101 Parity always 1
                110 No parity
                111 Parity always 0


3FC/2FC (uart_mcr) Modem control register
     bits 7-5  forced to zero
     bit 4     0=normal, 1=loop back test
     bits 3-2  all PCs except PCjr
     bit 3     1=interrupts to system bus, user-designated output: OUT2
     bit 2     user-designated output, OUT1
     bit 1     1=activate rts
     bit 0     1=activate dtr

3FD/2FD (uart_lsr) Line status register
     bit 7  forced to 0
     bit 6  1=transmit shift register is empty
     bit 5  1=transmit hold register is empty
     bit 4  1=break received
     bit 3  1=framing error received
     bit 2  1=parity error received
     bit 1  1=overrun error received
     bit 0  1=data received

3FE/2FE (uart_msr) Modem status register
     bit 7  1=receive line signal detect
     bit 6  1=ring indicator (all PCs except PCjr)
     bit 5  1=dsr
     bit 4  1=cts
     bit 3  1=receive line signal detect has changed state
     bit 2  1=ring indicator has changed state (all PCs except PCjr)
     bit 1  1=dsr has changed state
     bit 0  1=cts has changed state

3FF/2FF (uart_spr) Scratch pad register.}


{Maximum port number (minimum is 1) }

CONST
  max_port = 4;


{Base i/o address for each COM port}

CONST
  uart_base: ARRAY [1..max_port] OF Integer = ($3F8, $2F8, $3E8, $2E8);


{Interrupt numbers for each COM port}

CONST
  intnums: ARRAY [1..max_port] OF Byte = ($0C, $0B, $0C, $0B);


{i8259 interrupt levels for each port}

CONST
  i8259levels: ARRAY [1..max_port] OF Byte = (4, 3, 4, 3);


{This variable is TRUE if the interrupt driver has been installed, or FALSE
if it hasn't.  It's used to prevent installing twice or deinstalling when not
installed.}



{UART i/o addresses.  Values depend upon which COMM port is selected.}

VAR
  uart_data: Word;             {Data register}
  uart_ier : Word;             {Interrupt enable register}
  uart_iir : Word;             {Interrupt identification register}
  uart_lcr : Word;             {Line control register}
  uart_mcr : Word;             {Modem control register}
  uart_lsr : Word;             {Line status register}
  uart_msr : Word;             {Modem status register}
  uart_spr : Word;             {Scratch pad register}


{Original contents of IER and MCR registers.  Used to restore UART
to whatever state it was in before this driver was loaded.}

VAR
  old_ier: Byte;
  old_mcr: Byte;


{Original contents of interrupt vector.  Used to restore the vector when
the interrupt driver is deinstalled.}

VAR
  old_vector: Pointer;


{Original contents of interrupt controller mask.  Used to restore the
bit pertaining to the comm controller we're using.}

VAR
  old_i8259_mask: Byte;


{Bit mask for i8259 interrupt controller}

VAR
  i8259bit: Byte;


{Interrupt vector number}

VAR
  intnum: Byte;


{Receive queue.  Received characters are held here until retrieved by
ComRx.}

CONST
  rx_queue_size = 128;   {Change to suit}
VAR
  rx_queue: ARRAY [1..rx_queue_size] OF Byte;
  rx_in   : Word;        {Index of where to store next character}
  rx_out  : Word;        {Index of where to retrieve next character}
  rx_chars: Word;        {Number of chars in queue}


{Transmit queue.  Characters to be transmitted are held here until the
UART is ready to transmit them.}

CONST
  tx_queue_size = 16;    {Change to suit}
VAR
  tx_queue: ARRAY [1..tx_queue_size] OF Byte;
  tx_in   : Integer;     {Index of where to store next character}
  tx_out  : Integer;     {Index of where to retrieve next character}
  tx_chars: integer;     {Number of chars in queue}


{This variable is used to save the next link in the "exit procedure" chain.}

VAR
  exit_save: Pointer;

PROCEDURE disable_interrupts;
INLINE
  (
  $FA    {CLI}
  );

PROCEDURE enable_interrupts;
INLINE
  (
  $FB    {STI}
  );




{Interrupt driver.  The UART is programmed to cause an interrupt whenever
a character has been received or when the UART is ready to transmit another
character.}

{$R-,S-}
PROCEDURE Cominterrupt_driver; INTERRUPT;

VAR
  ch   : Char;
  iir  : Byte;
  dummy: Byte;

BEGIN

  {While bit 0 of the interrupt identification register is 0, there is an
  interrupt to process}

  iir := Port [uart_iir];

  WHILE NOT Odd (iir) DO
    BEGIN

    CASE iir SHR 1 OF

      {iir = 100b: Received data available.  Get the character, and if
      the buffer isn't full, then save it.  If the buffer is full,
      then ignore it.}

      2:
        BEGIN
        ch := Char (Port [uart_data] );
        IF (rx_chars <= rx_queue_size) THEN
          BEGIN
          rx_queue [rx_in] := Ord (ch);
          Inc (rx_in);
          IF rx_in > rx_queue_size THEN
            rx_in := 1;
          rx_chars := Succ (rx_chars);
          END;
        END;

      {iir = 010b: Transmit register empty.  If the transmit buffer
      is empty, then disable the transmitter to prevent any more
      transmit interrupts.  Otherwise, send the character.

      The test of the line-status-register is to see if the transmit
      holding register is truly empty.  Some UARTS seem to cause transmit
      interrupts when the holding register isn't empty, causing transmitted
      characters to be lost.}

      1:
        IF (tx_chars <= 0) THEN
          Port [uart_ier] := Port [uart_ier] AND NOT 2
        ELSE
          IF Odd (Port [uart_lsr] SHR 5) THEN
            BEGIN
            Port [uart_data] := tx_queue [tx_out];
            Inc (tx_out);
            IF tx_out > tx_queue_size THEN
              tx_out := 1;
            Dec (tx_chars);
            END;

      {iir = 001b: Change in modem status.  We don't expect this interrupt,
      but if one ever occurs we need to read the line status to reset it
      and prevent an endless loop.}

      0:
        dummy := Port [uart_msr];

      {iir = 111b: Change in line status.  We don't expect this interrupt,
      but if one ever occurs we need to read the line status to reset it
      and prevent an endless loop.}

      3:
        dummy := Port [uart_lsr];

      END;

    iir := Port [uart_iir];
    END;

  {Tell the interrupt controller that we're done with this interrupt}

  Port [$20] := $20;

END;
{$R+,S+}


{Flush (empty) the receive buffer.}

PROCEDURE ComFlushRx;
BEGIN
  disable_interrupts;
  rx_chars := 0;
  rx_in    := 1;
  rx_out   := 1;
  enable_interrupts;
END;


{Flush (empty) transmit buffer.}

PROCEDURE ComFlushTx;
BEGIN
  disable_interrupts;
  tx_chars := 0;
  tx_in    := 1;
  tx_out   := 1;
  enable_interrupts;
END;


{This function returns TRUE if a carrier is present.}

FUNCTION Comcarrier: Boolean;
BEGIN
  Comcarrier := ComInstalled AND Odd (Port [uart_msr] SHR 7);
END;


{Get a character from the receive buffer.  If the buffer is empty, return
a NULL (#0).}

FUNCTION ComRx: Char;
BEGIN
  IF NOT ComInstalled OR (rx_chars = 0) THEN
    ComRx := #0
  ELSE
    BEGIN
    disable_interrupts;
    ComRx := Chr (rx_queue [rx_out] );
    Inc (rx_out);
    IF rx_out > rx_queue_size THEN
      rx_out := 1;
    Dec (rx_chars);
    enable_interrupts;
    END;
END;


{This function returns True if ComTx can accept a character.}

FUNCTION ComTxReady: Boolean;
BEGIN
  ComTxReady := (tx_chars < tx_queue_size) OR NOT ComInstalled;
END;


{This function returns True if the transmit buffer is empty.}

FUNCTION ComTxEmpty: Boolean;
BEGIN
  ComTxEmpty := (tx_chars = 0) OR NOT ComInstalled;
END;


{This function returns True if the receive buffer is empty.}

FUNCTION ComRxEmpty: Boolean;
BEGIN
  ComRxEmpty := (rx_chars = 0) OR NOT ComInstalled;
END;


{Send a character.  Waits until the transmit buffer isn't full, then puts
the character into it.  The interrupt driver will send the character
once the character is at the head of the transmit queue and a transmit
interrupt occurs.}

PROCEDURE ComTx (ch: Char);
BEGIN
  IF ComInstalled THEN
    BEGIN
    REPEAT UNTIL ComTxReady;
    disable_interrupts;
    tx_queue [tx_in] := Ord (ch);
    IF tx_in < tx_queue_size THEN
      Inc (tx_in)
    ELSE
      tx_in := 1;
    Inc (tx_chars);
    Port [uart_ier] := Port [uart_ier] OR 2;
    enable_interrupts;
    END;
END;


{Send a whole string}

PROCEDURE ComRxString (st: String);
VAR
  i: Byte;
BEGIN
  FOR i := 1 TO Length (st) DO
    ComTx (st [i] );
END;


{Lower (deactivate) the DTR line.  Causes most modems to hang up.}

PROCEDURE ComLowerDTR;
BEGIN
  IF ComInstalled THEN
    BEGIN
    disable_interrupts;
    Port [uart_mcr] := Port [uart_mcr] AND NOT 1;
    enable_interrupts;
    END;
END;


{Raise (activate) the DTR line.}

PROCEDURE ComRaiseDTR;
BEGIN
  IF ComInstalled THEN
    BEGIN
    disable_interrupts;
    Port [uart_mcr] := Port [uart_mcr] OR 1;
    enable_interrupts;
    END;
END;


{Set the baud rate.  Accepts any speed between 2 and 65535.  However,
I am not sure that extremely high speeds (those above 19200) will
always work, since the baud rate divisor will be six or less, where a
difference of one can represent a difference in baud rate of
3840 bits per second or more.}

PROCEDURE ComSetSpeed (speed: Word);
VAR
  divisor: Word;
BEGIN
  IF ComInstalled THEN
    BEGIN
    IF speed < 2 THEN speed := 2;
    divisor := 115200 DIV speed;
    disable_interrupts;
    Port  [uart_lcr]  := Port [uart_lcr] OR $80;
    Portw [uart_data] := divisor;
    Port  [uart_lcr]  := Port [uart_lcr] AND NOT $80;
    enable_interrupts;
    END;
END;


{Set the parity and stop bits as follows:

  Comnone    8 data bits, no parity
  Comeven    7 data bits, even parity
  Comodd     7 data bits, odd parity
  Comzero    7 data bits, parity always zero
  Comone     7 data bits, parity always one}

PROCEDURE ComSetParity (parity: Comparity; stop_bits: Byte);
VAR
  lcr: Byte;
BEGIN
  CASE parity OF
    Comnone: lcr := $00 OR $03;
    Comeven: lcr := $18 OR $02;
    Comodd : lcr := $08 OR $02;
    Comzero: lcr := $38 OR $02;
    Comone : lcr := $28 OR $02;
    END;
  IF stop_bits = 2 THEN
    lcr := lcr OR $04;
  disable_interrupts;
  Port [uart_lcr] := Port [uart_lcr] AND $40 OR lcr;
  enable_interrupts;
END;

{Install the communications driver.  Portnum should be 1..max_port.
Error codes returned are:

  0 - No error
  1 - Invalid port number
  2 - UART for that port is not present
  3 - Already installed, new installation ignored}

PROCEDURE ComInstall
  (
  portnum  : Word;
  VAR error: Word
  );
VAR
  ier: Byte;
BEGIN
  IF ComInstalled THEN
    error := 3
  ELSE
    IF (portnum < 1) OR (portnum > max_port) THEN
      error := 1
    ELSE
      BEGIN

      {Set i/o addresses and other hardware specifics for selected port}

      uart_data := uart_base [portnum];
      uart_ier  := uart_data + 1;
      uart_iir  := uart_data + 2;
      uart_lcr  := uart_data + 3;
      uart_mcr  := uart_data + 4;
      uart_lsr  := uart_data + 5;
      uart_msr  := uart_data + 6;
      uart_spr  := uart_data + 7;
      intnum    := intnums [portnum];
      i8259bit  := 1 SHL i8259levels [portnum];

      {Return error if hardware not installed}

      old_ier := Port [uart_ier];
      Port [uart_ier] := 0;
      IF Port [uart_ier] <> 0 THEN
        error := 2
      ELSE
        BEGIN
        error := 0;

        {Save original interrupt controller mask, then disable the
        interrupt controller for this interrupt.}

        disable_interrupts;
        old_i8259_mask := Port [$21];
        Port [$21] := old_i8259_mask OR i8259bit;
        enable_interrupts;

        {Clear the transmit and receive queues}

        ComFlushTx;
        ComFlushRx;

        {Save current interrupt vector, then set the interrupt vector to
        the address of our interrupt driver.}

        GetIntVec (intnum, old_vector);
        SetIntVec (intnum, @Cominterrupt_driver);
        ComInstalled := True;

        {Set parity to none, turn off BREAK signal, and make sure
        we're not addressing the baud rate registers.}

        Port [uart_lcr] := 3;

        {Save original contents of modem control register, then enable
        interrupts to system bus and activate RTS.  Leave DTR the way
        it was.}

        disable_interrupts;
        old_mcr := Port [uart_mcr];
        Port [uart_mcr] := $A OR (old_mcr AND 1);
        enable_interrupts;

        {Enable interrupt on data-available.  The interrupt for
        transmit-ready is enabled when a character is put into the
        transmit queue, and disabled when the transmit queue is empty.}

        Port [uart_ier] := 1;

        {Enable the interrupt controller for this interrupt.}

        disable_interrupts;
        Port [$21] := Port [$21] AND NOT i8259bit;
        enable_interrupts;

        END;
      END;
END;


{Deinstall the interrupt driver completely.  It doesn't change the baud rate
or mess with DTR; it tries to leave the interrupt vectors and enables and
everything else as it was when the driver was installed.

This procedure MUST be called by the exit procedure of this module before
the program exits to DOS, or the interrupt driver will still
be attached to its vector -- the next communications interrupt that came
along would jump to the interrupt driver which is no longer protected and
may have been written over.}


PROCEDURE Comdeinstall;
BEGIN
  IF ComInstalled THEN
    BEGIN

    ComInstalled := False;

    {Restore Modem-Control-Register and Interrupt-Enable-Register.}

    Port [uart_mcr] := old_mcr;
    Port [uart_ier] := old_ier;

    {Restore appropriate bit of interrupt controller's mask}

    disable_interrupts;
    Port [$21] := Port [$21] AND NOT i8259bit OR
     old_i8259_mask AND i8259bit;
    enable_interrupts;

    {Reset the interrupt vector}

    SetIntVec (intnum, old_vector);

    END;
END;


{This procedure is called when the program exits for any reason.  It
deinstalls the interrupt driver.}

{$F+} PROCEDURE exit_procedure; {$F-}
BEGIN
  Comdeinstall;
  ExitProc := exit_save;
END;


{This installs the exit procedure.}

BEGIN
  exit_save:=ExitProc;
  ExitProc:=@exit_procedure;
  if paramstr(1)='/(C)' then begin
    writeln('LSCOMM.PAS  V1.00  LightSpeed(TM) Comm Driver for Modem I/O');
    writeln('            Copyright (C) 1993 by Onkel Dittmeyer of SLAM !');
    writeln;
    readln;
  end;
END.
