unit bootutils;

{$inline on}

interface

const
  SIGNATURE_0 = $1E;
{$if defined(FPC_MCU_ATmega8) or defined(FPC_MCU_ATmega8A)}
  RAMSTART  = $100;
  NRWWSTART = $1C00;
  // We can only read the signature with the AVRs that have SIGRD bit in SPMCR.
  // For all others we use predefined signatures like AVR-GCC does.
  SIGNATURE_1 = $93;
  SIGNATURE_2 = $07;
{$elseif defined(FPC_MCU_ATmega88) or defined(FPC_MCU_ATmega88A) or defined(FPC_MCU_ATmega88P) or defined(FPC_MCU_ATmega88PA)  or defined(FPC_MCU_ATmega88PB)}
  RAMSTART  = $100;
  NRWWSTART = $1800;
  SIGNATURE_1 = $93;
  {$if defined(FPC_MCU_ATmega88) or defined(FPC_MCU_ATmega88A)}
    SIGNATURE_2 = $0A;
  {$elseif defined(FPC_MCU_ATmega88PA)}
    SIGNATURE_2 = $0F;
  {$elseif defined(FPC_MCU_ATmega88PB)}
    SIGNATURE_2 = $16;
  {$endif}
{$elseif defined(FPC_MCU_ATmega168) or defined(FPC_MCU_ATmega168A) or defined(FPC_MCU_ATmega168P) or defined(FPC_MCU_ATmega168PA) or defined(FPC_MCU_ATmega168PB)}
  RAMSTART  = $100;
  NRWWSTART = $3800;
  SIGNATURE_1 = $94;
  {$if defined(FPC_MCU_ATmega168) or defined(FPC_MCU_ATmega168A)}
    SIGNATURE_2 = $06;
  {$elseif defined(FPC_MCU_ATmega168PA)}
    SIGNATURE_2 = $0B;
  {$elseif defined(FPC_MCU_ATmega168PB)}
    SIGNATURE_2 = $15;
  {$endif}
{$elseif defined(FPC_MCU_ATmega328) or defined(FPC_MCU_ATmega328P) or defined(FPC_MCU_ATmega328PB)}
  RAMSTART  = $100;
  NRWWSTART = $7000;
  SIGNATURE_1 = $95;
  {$if defined(FPC_MCU_ATmega328)}
    SIGNATURE_2 = $14;
  {$elseif defined(FPC_MCU_ATmega328P)}
    SIGNATURE_2 = $0F;
  {$elseif defined(FPC_MCU_ATmega328PB)}
    SIGNATURE_2 = $16;
  {$endif}
{$elseif defined (FPC_MCU_ATmega644) or defined (FPC_MCU_ATmega644P) or defined (FPC_MCU_ATmega644PA) or defined (FPC_MCU_ATmega644PB)}
  RAMSTART  = $100;
  NRWWSTART = $E000;
  SIGNATURE_1 = $96;
  {$if defined(FPC_MCU_ATmega644) or defined(FPC_MCU_ATmega644A)}
    SIGNATURE_2 = $09;
  {$elseif defined(FPC_MCU_ATmega644PA)}
    SIGNATURE_2 = $0A;
  {$endif}
{$elseif defined(FPC_MCU_ATmega1280)}
  RAMSTART  = $200;
  NRWWSTART = $E000;
{$elseif defined(FPC_MCU_ATtiny84) or defined(FPC_MCU_ATtiny84A)}
  RAMSTART  = $100;
  NRWWSTART = $0000;
{$endif}

  // Z register values to read signature/calibration info
  deviceSignature1_Z = 0;
  deviceSignature2_Z = 2;
  deviceSignature3_Z = 4;
  deviceOscCal_Z = 1;
  // Z register values to read fuse/lockbits info
  deviceFuseLow_Z = 0;
  deviceFuseHigh_Z = 3;
  deviceFuseExt_Z = 2;
  deviceLockbits_Z = 1;

{$if defined(CPUAVR6) or defined(CPUAVR51)}
  flashPageSize = 256;
{$elseif defined(CPUAVR5)}
  {$if (FPC_FLASHSIZE > 32768) or defined(FPC_MCU_AT90CAN32) or defined(FPC_MCU_AT90CAN64)}
  flashPageSize = 256;
  {$else}
  flashPageSize = 128;
  {$endif}
{$elseif defined(CPUAVR4)}
  {$if defined(FPC_MCU_ATA6285) or defined(FPC_MCU_ATA6286)}
  flashPageSize = 128;
  {$else}
  flashPageSize = 64;
  {$endif}
{$elseif defined(CPUAVR35)}
  {$if defined(FPC_MCU_ATTINY1634)}
  flashPageSize = 32;
  {$else}
  flashPageSize = 128;
  {$endif}
{$elseif defined(CPUAVR25)}
  {$if defined(FPC_MCU_ATTINY87)}
  flashPageSize = 128;
  {$elseif FPC_FLASHSIZE >= 4096}
  flashPageSize = 64;
  {$else}
  flashPageSize = 32;
  {$endif}
{$endif}

type
  TEEPROMAddress = {$if FPC_EEPROMSIZE > 256}uint16{$else}byte{$endif};

procedure spm_busy_wait; inline;
procedure eeprom_busy_wait; inline;

{$if not declared(SIGNATURE_2) or not defined(arduino)}
// Only read signatures if not predefined
function readSignatureCalibrationByte(const index: byte): byte;
{$endif}

function readFuseLockBits(const index: byte): byte;
procedure writeLockBits(const lockBits: byte);

{$if declared(RWWSRE)}
procedure enableRWW;
{$endif}

// Byte sized address
// For >64K flash size RAMPZ should be preconfigured,
// thus address is the low 16 bits of the address
function flashReadByte(const addr: uint16): byte;
procedure flashPageErase(const address: uint16);
procedure flashPageFill(const address, data: uint16);
procedure flashPageWrite(const address: uint16);

{$ifndef arduino}
function EEPROMReadByte(const addr: TEEPROMAddress): byte;
procedure EEPROMWriteByte(const addr: TEEPROMAddress; const data: byte);
{$endif}

implementation

const
// Mapping between different naming conventions
  SPMenable = {$if declared(SPMEN)}SPMEN{$elseif declared(SELFPRGEN)}SELFPRGEN{$else}0{$endif};

{$I bootutilsconsts.inc}

procedure spm_busy_wait; inline;
begin
  repeat
  until (xSPMCSR and (1 shl SPMenable)) = 0;
end;

procedure eeprom_busy_wait; inline;
begin
  repeat
  until (EECR and (1 shl xEEPE)) = 0;
end;

{$if not declared(SIGNATURE_2) or not defined(arduino)}
function readSignatureCalibrationByte(const index: byte): byte; assembler; nostackframe;
const
  SIGRD = 5;
  SigReadSPM = (1 shl SIGRD) or (1 shl SPMenable);
asm
  ldi r31, 0
  mov r30, r24
  ldi r24, SigReadSPM
  out xSPMCSR+(-32), r24
  lpm r24, Z
end;
{$endif}

function readFuseLockBits(const index: byte): byte; assembler; nostackframe;
const
  {$if declared(RFLB)}
    {$define BLBSET:=RFLB}
  {$endif}
  BLBReadSPM = (1 shl BLBSET) or (1 shl SPMenable);
asm
  mov r30, r24
  ldi r31, 0
  ldi r24, BLBReadSPM
  out xSPMCSR+(-32), r24
  lpm r24, Z
end;

procedure writeLockBits(const lockBits: byte); assembler; nostackframe;
const
  BLBWriteSPM = (1 shl BLBSET) or (1 shl SPMenable);
asm
  mov r0, r24
  ldi r24, BLBWriteSPM
  out xSPMCSR+(-32), r24
  spm
end;

{$if declared(RWWSRE)}
procedure enableRWW; assembler; nostackframe;
const
  RWWEnableSPM = (1 shl RWWSRE) or (1 shl SPMenable);
asm
  ldi r24, RWWEnableSPM
  out xSPMCSR+(-32), r24
  spm
end;
{$endif}

function flashReadByte(const addr: uint16): byte; assembler; nostackframe;
asm
  movw r30, r24
  {$ifdef CPUAVR_HAS_ELPM}
  elpm r24, Z
  {$else}
  lpm r24, Z
  {$endif CPUAVR_HAS_ELPM}
end;

procedure flashPageErase(const address: uint16); assembler; nostackframe;
const
  {$if declared(CTPB)}
    {$define PGERS:=CTPB}
  {$endif}
  pageEraseSPM = (1 shl PGERS) or (1 shl SPMenable);
asm
  movw r30, r24
  ldi r24, pageEraseSPM
  out xSPMCSR+(-32), r24
  spm
end;

procedure flashPageFill(const address, data: uint16); assembler; nostackframe;
const
  pageFillSPM = (1 shl SPMenable);
asm
  movw r0, r22
  movw r30, r24
  ldi r24, pageFillSPM
  out xSPMCSR+(-32), r24
  spm
  clr r1
end;

procedure flashPageWrite(const address: uint16); assembler; nostackframe;
const
  pageWriteSPM = (1 shl PGWRT) or (1 shl SPMenable);
asm
  movw r30, r24
  ldi r24, pageWriteSPM
  out xSPMCSR+(-32), r24
  spm
end;

{$ifndef arduino}
// TODO: Perhaps also change addr parameter to byte size if EEAR is not declared.
function EEPROMReadByte(const addr: TEEPROMAddress): byte;
begin
  eeprom_busy_wait;
  {$if FPC_EEPROMSIZE > 256}
  EEAR := addr;
  {$elseif declared(EEARL)}
  EEARL := addr;
  {$else}
  EEAR := addr;
  {$endif}
  EECR := (1 shl EERE);
  Result := EEDR;
end;

procedure EEPROMWriteByte(const addr: TEEPROMAddress; const data: byte);
begin
  eeprom_busy_wait;
  {$if FPC_EEPROMSIZE > 256}
  EEAR := addr;
  {$elseif declared(EEARL)}
  EEARL := addr;
  {$else}
  EEAR := addr;
  {$endif}
  EEDR := data;
  EECR := (1 shl xEEMPE);
  EECR := (1 shl xEEPE);
end;
{$endif}

end.

