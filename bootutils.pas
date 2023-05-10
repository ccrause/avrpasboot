unit bootutils;

{$inline on}

interface

const
  RAMSTART  = $100;
  NRWWSTART = $7000;
  flashPageSize = 128;
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

procedure spm_busy_wait; inline;
procedure eeprom_busy_wait; inline;

function readSignatureCalibrationByte(const index: byte): byte;

function readFuseLockBits(const index: byte): byte;
procedure writeLockBits(const lockBits: byte);

procedure enableRWW;

// Byte sized address
// For >64K flash size RAMPZ should be preconfigured,
// thus address is the low 16 bits of the address
function flashReadByte(const addr: uint16): byte;
procedure flashPageErase(const address: uint16);
procedure flashPageFill(const address, data: uint16);
procedure flashPageWrite(const address: uint16);

function EEPROMReadByte(const addr: uint16): byte;
procedure EEPROMWriteByte(const addr: uint16; const data: byte);

implementation

procedure spm_busy_wait; inline;
begin
  repeat
  until (SPMCSR and (1 shl SELFPRGEN)) = 0;
end;

procedure eeprom_busy_wait; inline;
begin
  repeat
  until (EECR and (1 shl EEPE)) = 0;
end;

function readSignatureCalibrationByte(const index: byte): byte; assembler; nostackframe;
const
  SIGRD = 5;
  SigReadSPM = (1 shl SIGRD) or (1 shl SELFPRGEN);
asm
  ldi r31, 0
  mov r30, r24
  ldi r24, SigReadSPM
  out SPMCSR+(-32), r24
  lpm r24, Z
end;

function readFuseLockBits(const index: byte): byte; assembler; nostackframe;
const
  BLBReadSPM = (1 shl BLBSET) or (1 shl SELFPRGEN);
asm
  mov r30, r24
  ldi r31, 0
  ldi r24, BLBReadSPM
  out SPMCSR+(-32), r24
  lpm r24, Z
end;

procedure writeLockBits(const lockBits: byte); assembler; nostackframe;
const
  BLBWriteSPM = (1 shl BLBSET) or (1 shl SELFPRGEN);
asm
  mov r0, r24
  ldi r24, BLBWriteSPM
  out SPMCSR+(-32), r24
  spm
end;

procedure enableRWW; assembler; nostackframe;
const
  RWWEnableSPM = (1 shl RWWSRE) or (1 shl SELFPRGEN);
asm
  ldi r24, RWWEnableSPM
  out SPMCSR+(-32), r24
  spm
end;

function flashReadByte(const addr: uint16): byte; assembler; nostackframe;
asm
  movw r30, r24
  lpm r24, Z
end;

procedure flashPageErase(const address: uint16); assembler; nostackframe;
const
  pageEraseSPM = (1 shl PGERS) or (1 shl SELFPRGEN);
asm
  movw r30, r24
  ldi r24, pageEraseSPM
  out SPMCSR+(-32), r24
  spm
end;

procedure flashPageFill(const address, data: uint16); assembler; nostackframe;
const
  pageFillSPM = (1 shl SELFPRGEN);
asm
  movw r0, r22
  movw r30, r24
  ldi r24, pageFillSPM
  out SPMCSR+(-32), r24
  spm
  clr r1
end;

procedure flashPageWrite(const address: uint16); assembler; nostackframe;
const
  pageWriteSPM = (1 shl PGWRT) or (1 shl SELFPRGEN);
asm
  movw r30, r24
  ldi r24, pageWriteSPM
  out SPMCSR+(-32), r24
  spm
end;

// TODO: Perhaps also change addr parameter to byte size if EEAR is not declared.
function EEPROMReadByte(const addr: uint16): byte;
begin
  eeprom_busy_wait;
  EEAR := addr;
  EECR := (1 shl EERE);
  Result := EEDR;
end;

procedure EEPROMWriteByte(const addr: uint16; const data: byte);
begin
  eeprom_busy_wait;
  EEAR := addr;
  EEDR := data;
  EECR := (1 shl EEMPE);
  EECR := (1 shl EEPE);
end;

end.

