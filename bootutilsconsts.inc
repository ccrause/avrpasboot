const
{$if defined(FPC_MCU_ATmega168) or defined(FPC_MCU_ATmega168A) or defined(FPC_MCU_ATmega168P) or defined(FPC_MCU_ATmega168PA) or defined(FPC_MCU_ATmega168PB)}
{$elseif defined(FPC_MCU_ATmega328) or defined(FPC_MCU_ATmega328P) or defined(FPC_MCU_ATmega328PB)}

  xEEPE = EEPE;
  xEEMPE = EEMPE;

  {$define xMCUSR := MCUSR}
  {$define xWDTCSR := WDTCSR}

var
  xSPMCSR : byte absolute $00+$57;

{$elseif defined (FPC_MCU_ATmega644) or defined (FPC_MCU_ATmega644P) or defined (FPC_MCU_ATmega644PA) or defined (FPC_MCU_ATmega644PB)}
{$elseif defined(FPC_MCU_ATtiny84) or defined(FPC_MCU_ATtiny84A)}
{$elseif defined(FPC_MCU_ATmega1280)}
{$elseif defined(FPC_MCU_ATmega88) or defined(FPC_MCU_ATmega88A) or defined(FPC_MCU_ATmega88P) or defined(FPC_MCU_ATmega88PA)  or defined(FPC_MCU_ATmega88PB)}
{$elseif defined(FPC_MCU_ATmega8) or defined(FPC_MCU_ATmega8A)}

  xEEPE = EEWE;
  xEEMPE = EEMWE;

  {$define xMCUSR := MCUCR}
  {$define xWDTCSR := WDTCR}

var
  xSPMCSR : byte absolute $00+$57;

{$endif}
