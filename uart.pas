unit uart;

interface

// Specify baud rate via command line define BAUD
// If BAUD is not defined, it will default to 115200 if hardware UART is used,
// else if will default to 9600 for software UART
procedure uart_init;

// Blocking functions
procedure uart_transmit(const data: byte); overload;
function uart_receive: byte;

implementation

{$I uartconsts.inc}

{$if defined(xUBRR0H)}
{$ifndef BAUD}
  {$define BAUD:=115200}
{$endif}
procedure uart_init;
const
  UBRRValue = (((F_CPU + 4*BAUD) shr 3) div BAUD)-1;
begin
  xUBRR0H := UBRRValue shr 8;
  xUBRR0L := byte(UBRRValue);

  // Set U2X bit
  xUCSR0A := xUCSR0A or (1 shl xU2X0);

  // Enable receiver and transmitter
  xUCSR0B := (1 shl xRXEN0) or (1 shl xTXEN0);

  // Set frame format: 8data, 1stop bit, no parity
  xUCSR0C := {$if declared(URSEL)}(1 shl URSEL) or{$endif} (3 shl xUCSZ0);
end;

procedure uart_transmit(const data: byte);
begin
  // Wait for empty transmit buffer
  while ((xUCSR0A and (1 shl xUDRE0)) = 0) do;

  // Put data into buffer, sends the data
  xUDR0 := data;
end;

function uart_receive: byte;
begin
  // Wait for data to be received
  while ((xUCSR0A and (1 shl xRXC0)) = 0) do;

  // Get and return received data from buffer
  result := xUDR0;
end;

{$else defined(xUBRR0H)}
{$ifndef BAUD}
  {$define BAUD:=9600}
{$endif}

const
  RXPin     = 1;
  RXPinMask = (1 shl RXPin);
  TXPin     = 2;
  TXPinMask = (1 shl TXPin);

var
  RXDDR:  byte absolute DDRB;
  RXPORT: byte absolute PORTB;
  RXPINS: byte absolute PINB;
  TXDDR:  byte absolute DDRB;
  TXPORT: byte absolute PORTB;

// Bitbanged UART
procedure uart_init;
begin
  RXDDR := RXDDR and not RXPinMask;  // Input
  RXPORT := RXPORT or RXPinMask;     // Pullup

  TXDDR := TXDDR or TXPinMask;       // Output
  TXPORT := TXPORT or TXPinMask;     // High
end;

const
  TXDelay = (F_CPU + (BAUD div 2)) div BAUD;
  // If TXDelayCount > 255 then use word size counter
{$if TXDelay > 773}
  {$info 'Using word size counter for TX delay'}
  {$define wordSizeTXCounter = 1}
  TXDelayCount = (TXDelay - 9 + 2) div 4;
{$else}
  {$if TXDelay < 9}
  {$Error 'Baud rate too high for TX'}
  {$endif}
  TXDelayCount = (TXDelay - 8 + 2) div 3;
{$endif}

// TODO: check if SBIW instruction is available, else use sbi/sbci combination
//       if word sized counter is needed

procedure uart_transmit(const data: byte); assembler; nostackframe;
label
  setoutputbit, startdelay, delayloop, setoutputbitlow;
asm
  // r26 - bit delay count low
  // r27 - bit delay count high
  // r24 - output data
  // r25 - bit counter -> 1 start bit + 8 data bits + 1 stop bit = 10 bits
  ldi r25, 10
  // Complement data, UART logic is inverted
  com r24                                        // 1
  sec                                            // 1

  setoutputbit:
  brcc setoutputbitlow                           // 2, else 1
  cbi TXPORT+(-32), TXPin                        // 1
  rjmp startdelay                                // 2
  setoutputbitlow:
  sbi TXPORT+(-32), TXPin                        // 1
  nop                                            // 1

  // 1 or 2 cycles after setting pin
  startdelay:
  ldi r26, lo8(TXDelayCount)                     // 1
  {$ifdef wordSizeTXCounter}
  ldi r27, hi8(TXDelayCount)                     // 1
  {$endif}
  delayloop:
  {$ifdef wordSizeTXCounter}
  sbiw r26, 1                                    // 1
  {$else}
  subi r26, 1                                    // 1
  {$endif}
  brne delayloop                                 // 2

  lsr r24                                        // 1
  dec r25                                        // 1
  brne setoutputbit                              // 2
  // cycle count from setoutputbit
  // if wordSizeTXCounter
  // 4 + 2 + (TXDelayCount*4 - 1) + 4 = 9 + TXDelayCount*4
  // else
  // 4 + 1 + (TXDelayCount*3 - 1) + 4 = 8 + TXDelayCount*3
end;

const
  // delays required in CPU clock cycles
  RXDelay1_5 = (((3*F_CPU + (BAUD div 2)) div BAUD) + 1) div 2;
  RXDelay    = (F_CPU + (BAUD div 2)) div BAUD;
  // Switch to word if LoopCount1_5 > 255
  {$if RXDelay1_5 > 770}
    {$info 'Switching to word size counter for bit delay'}
    {$define wordSizeRXCounter}
    LoopCount1_5 = (RXDelay1_5 - 7 + 2) div 4;
    LoopCount = (RXDelay - 7 + 2) div 4;
  {$else}
    {$if RXDelay < 7}
    {$Error 'Baud rate too high for RX'}
    {$endif}
    LoopCount1_5 = (RXDelay1_5 - 5 + 2) div 3;
    LoopCount = (RXDelay - 6 + 2) div 3;
  {$endif}

// NB: only use call clobbered registers r18..r27,r30,r31
function uart_receive: byte; assembler; nostackframe;
label
  wait, RX;
asm
  // r24 - Result
  // r30 - Delay loop counter
  // r31 - Optional delay loop counter high byte

  // Inherent lag of wait loop 2 to 4 cycles, assume 3 on average
  wait:                                          // CPU cycle count per instruction line
  sbic PINB+(-32), RXPin                         // 1 if false, 2 when skipping
  rjmp wait                                      // 2

  // Initialize end of byte indicator bit
  ldi r24, 0x80                                  // 1
  // Load loop counter for 1.5 bit delay
  ldi r30, lo8(LoopCount1_5)                     // 1
  {$ifdef wordSizeRXCounter}
  ldi r31, hi8(LoopCount1_5)                     // 1
  {$endif}

  RX:
  {$ifdef wordSizeRXCounter}
  sbiw r30, 1                                    // 2
  {$else}
  subi r30, 1                                    // 1
  {$endif}
  brne RX                                        // 2 for branch, 1 to exit

  // Initialize bit time
  ldi r30, lo8(LoopCount)                        // 1
  {$ifdef wordSizeRXCounter}
  ldi r31, hi8(LoopCount)                        // 1
  {$endif}
  // Tally from pin change up to here if wordSizeCounter:
  //   3 + 3 + 4*LoopCount1_5 - 1 + 2 = 7 + 4*LoopCount1_5;
  // else
  //   3 + 2 + 3*LoopCount1_5 - 1 + 1 = 5 + 3*LoopCount1_5;

  sbic RXPINS+(-32), RXPin                       // 2 for skip, else 1
  sec                                            // 1
  // Shift bit into result
  ror r24                                        // 1
  brcc RX                                        // 2 for branch, else 1
  // Tally from RX: up to here if wordSizeCounter
  //   4*LoopCount-1 + 7
  // else
  //   3*LoopCount-1 + 6;

  // Ignore stop bit
end;

{$endif defined(xUBRR0H)}

end.
