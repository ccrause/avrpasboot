{$if defined(FPC_MCU_ATmega48) or defined(FPC_MCU_ATmega48A) or defined(FPC_MCU_ATmega48P) or defined(FPC_MCU_ATmega48PA) or defined(FPC_MCU_ATmega48PB)
  or defined(FPC_MCU_ATmega88) or defined(FPC_MCU_ATmega88A) or defined(FPC_MCU_ATmega88P) or defined(FPC_MCU_ATmega88PA) or defined(FPC_MCU_ATmega88PB)
  or defined(FPC_MCU_ATmega168) or defined(FPC_MCU_ATmega168A) or defined(FPC_MCU_ATmega168P) or defined(FPC_MCU_ATmega168PA) or defined(FPC_MCU_ATmega168PB)
  or defined(FPC_MCU_ATmega328) or defined(FPC_MCU_ATmega328P) or defined(FPC_MCU_ATmega328PB)
  or defined(FPC_MCU_ATmega640) or defined(FPC_MCU_ATmega1280) or defined(FPC_MCU_ATmega1281) or defined(FPC_MCU_ATmega2560) or defined(FPC_MCU_ATmega2561)
  or defined(FPC_MCU_ATmega644) or defined (FPC_MCU_ATmega644P) or defined (FPC_MCU_ATmega644PA) or defined (FPC_MCU_ATmega644PB)
  or defined(FPC_MCU_ATtiny48) or defined(FPC_MCU_ATtiny88)}
const
  xEEPE = EEPE;
  xEEMPE = EEMPE;

  {$define xMCUSR := MCUSR}
  {$define xWDTCSR := WDTCSR}

var
  xSPMCSR : byte absolute $00+$57;

{$elseif defined(FPC_MCU_ATtiny84) or defined(FPC_MCU_ATtiny84A)
      or defined(FPC_MCU_ATmega8) or defined(FPC_MCU_ATmega8A)
      or defined(FPC_MCU_ATmega16) or defined(FPC_MCU_ATmega16A)
      or defined(FPC_MCU_ATmega32) or defined(FPC_MCU_ATmeg32A)
      or defined(FPC_MCU_ATmega64) or defined(FPC_MCU_ATmega64A)}
const
  xEEPE = EEWE;
  xEEMPE = EEMWE;

  {$define xMCUSR := MCUCSR}
  {$define xWDTCSR := WDTCR}

var
  xSPMCSR : byte absolute $00+$57;

{$elseif defined(FPC_MCU_ATtiny25) or defined(FPC_MCU_ATtiny45) or defined(FPC_MCU_ATtiny85)
      or defined(FPC_MCU_ATtiny2313) or defined(FPC_MCU_ATtiny2313A) or defined(FPC_MCU_ATtiny4313)}
const
  xEEPE = EEPE;
  xEEMPE = EEMPE;

  {$define xMCUSR := MCUSR}
  {$define xWDTCSR := WDTCR}

var
  xSPMCSR : byte absolute $00+$57;

{$elseif defined(FPC_MCU_ATtiny24) or defined(FPC_MCU_ATtiny24A)
      or defined(FPC_MCU_ATtiny44) or defined(FPC_MCU_ATtiny44A)}
const
  xEEPE = EEPE;
  xEEMPE = EEMPE;

  {$define xMCUSR := MCUSR}
  {$define xWDTCSR := WDTCSR}

var
  xSPMCSR : byte absolute $00+$57;

{$elseif defined(FPC_MCU_ATtiny13) or defined(FPC_MCU_ATtiny13A) or defined(FPC_MCU_ATtiny85)}
const
  xEEPE = EEWE;
  xEEMPE = EEMWE;

  {$define xMCUSR := MCUCR}
  {$define xWDTCSR := WDTCR}

var
  xSPMCSR : byte absolute $00+$57;

{$endif}
