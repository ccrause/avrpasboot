{$if defined(FPC_MCU_ATmega48) or defined(FPC_MCU_ATmega48A) or defined(FPC_MCU_ATmega48P) or defined(FPC_MCU_ATmega48PA) or defined(FPC_MCU_ATmega48PB)
  or defined(FPC_MCU_ATmega88) or defined(FPC_MCU_ATmega88A) or defined(FPC_MCU_ATmega88P) or defined(FPC_MCU_ATmega88PA) or defined(FPC_MCU_ATmega88PB)
  or defined(FPC_MCU_ATmega168) or defined(FPC_MCU_ATmega168A) or defined(FPC_MCU_ATmega168P) or defined(FPC_MCU_ATmega168PA) or defined(FPC_MCU_ATmega168PB)
  or defined(FPC_MCU_ATmega328) or defined(FPC_MCU_ATmega328P) or defined(FPC_MCU_ATmega328PB)
  or defined(FPC_MCU_ATmega640) or defined(FPC_MCU_ATmega1280) or defined(FPC_MCU_ATmega1281) or defined(FPC_MCU_ATmega2560) or defined(FPC_MCU_ATmega2561)
  or defined (FPC_MCU_ATmega644) or defined (FPC_MCU_ATmega644P) or defined (FPC_MCU_ATmega644PA) or defined (FPC_MCU_ATmega644PB)}
const
  xU2X0   = U2X0;
  xRXEN0  = RXEN0;
  xTXEN0  = TXEN0;
  xRXC0   = RXC0;
  xUDRE0  = UDRE0;
  xUCSZ0  = UCSZ0;

  {$define xUBRR0H := UBRR0H}
  {$define xUBRR0L := UBRR0L}
  {$define xUCSR0A := UCSR0A}
  {$define xUCSR0B := UCSR0B}
  {$define xUCSR0C := UCSR0C}
  {$define xUDR0   := UDR0}

{$elseif defined(FPC_MCU_ATtiny84) or defined(FPC_MCU_ATtiny84A)
      or defined(FPC_MCU_ATmega8) or defined(FPC_MCU_ATmega8A)
      or defined(FPC_MCU_ATmega16) or defined(FPC_MCU_ATmega16A)
      or defined(FPC_MCU_ATmega32) or defined(FPC_MCU_ATmeg32A)
      or defined(FPC_MCU_ATmega64) or defined(FPC_MCU_ATmega64A)}
const
  xU2X0   = U2X;
  xRXEN0  = RXEN;
  xTXEN0  = TXEN;
  xRXC0   = RXC;
  xUDRE0  = UDRE;
  xUCSZ0  = UCSZ;

  {$define xUBRR0H := UBRRH}
  {$define xUBRR0L := UBRRL}
  {$define xUCSR0A := UCSRA}
  {$define xUCSR0B := UCSRB}
  {$define xUCSR0C := UCSRC}
  {$define xUDR0   := UDR}

{$endif}


