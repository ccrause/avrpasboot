program pasboot;

{ By default the bootloader supports the "stk500v1", "avrisp" and "arduino" programmer types
  of avrdude. This supports many of the commands according to document AVR061.

  By defining "arduino", a smaller subset of AVR061 commands are supported, similar
  to the optiboot project. This results in a smaller bootloader. This mode only
  supports the avrdude programmer type "arduino".
}

{$inline on}

uses
  stk500, intrinsics, bootutils, uart, delay;

const
  lockBitMask = $C0;  // Undefined bits should be written as 1 for future compatibility
  LEDpin = 5;

var
  // Note: if no RTL startup code is used, all variables will be uninitialized
  // so ensure all variables are assigned before use.
  b, c: byte;
  buf: array[0..15] of byte;
  databuf: array [0..flashPageSize-1] of byte;
  // Information not yet used, so could be removed in future
  deviceParams: TDeviceParameters;
  deviceParamsEx: TDeviceParametersEx;

  address, size, data, i: word;
  startupStatus: byte;
  LEDport: byte absolute PORTB;
  LEDDDR: byte absolute DDRB;

procedure uart_transmit_buffer(data: PByte; len: byte);
begin
  while len > 0 do
  begin
    uart_transmit(data^);
    inc(data);
    dec(len);
  end;
end;

procedure uart_receive_buffer(data: PByte; len: byte);
begin
  while len > 0 do
  begin
    data^ := uart_receive;
    inc(data);
    dec(len);
  end;
end;

procedure checkAndReply;
var
  c: byte;
begin
  c := uart_receive;
  if c = Sync_CRC_EOP then
  begin
    uart_transmit(Resp_STK_INSYNC);
    uart_transmit(Resp_STK_OK);
  end
  else
    uart_transmit(c);
end;

procedure checkAndReplyByte(b: byte);
var
  c: byte;
begin
  c := uart_receive;
  if c = Sync_CRC_EOP then
  begin
    uart_transmit(Resp_STK_INSYNC);
    uart_transmit(b);
    uart_transmit(Resp_STK_OK);
  end
  else
    uart_transmit(Resp_STK_NOSYNC);
end;

{$I bootutilsconsts.inc}

{$if declared(WDTOE)}
const
  WDCE = WDTOE; // atmega16 seems to be the exception
{$endif}

begin
  startupStatus := xMCUSR;
  xMCUSR := 0;
  // Disable watchdog
  avr_cli;
  avr_wdr;
  xMCUSR := xMCUSR and ($FF xor (1 shl WDRF));
  xWDTCSR := (1 shl WDCE) or (1 shl WDE);
  xWDTCSR := 0;
  SREG := 0;

  { Read reset cause
    If reset cause = 0 it means application code ran into bootloader, so probably
    no valid application, so start bootloader anyway.
    If not external reset, start application.
    TODO: Check if there is valid code at application start before jumping there.
          Currently bootloader gets started anyway, just a little later...
  }
  if (startupStatus > 0) and ((startupStatus and (1 shl EXTRF)) = 0) then
  begin
    // Brief LED flash
    LEDDDR := 1 shl LEDpin;
    LEDport := 1 shl LEDpin;
    delay_ms(100);
    LEDport := 0;
    LEDDDR := 0;
    asm
      {$ifdef CPUAVR_HAS_JMP_CALL}jmp 0{$else}rjmp 0{$endif}
    end;
  end;

  // Set watchdog to 2s timeout
  // this enables the watchdog interrupt which is used to start the main application
  avr_cli;
  avr_wdr;
  xMCUSR := xMCUSR and ($FF xor (1 shl WDRF));
  xWDTCSR := (1 shl WDCE) or (1 shl WDE);
  xWDTCSR := (1 shl WDE) or 7; // 2s timeout
  SREG := 0;

  LEDDDR := 1 shl LEDpin;
  LEDport := 1 shl LEDpin;
  delay_ms(100);
  LEDport := 0;
  delay_ms(100);
  LEDport := 1 shl LEDpin;
  delay_ms(100);
  LEDport := 0;

  uart_init;

  repeat
    b := uart_receive;
    // Reset watchdog
    avr_wdr;
    case b of
      Sync_CRC_EOP: uart_transmit(Resp_STK_NOSYNC);

      //Cmnd_STK_GET_SYNC:

      {$ifndef arduino}
      Cmnd_STK_GET_SIGN_ON:
      begin
        c := uart_receive;
        if c = Sync_CRC_EOP then
        begin
          uart_transmit(Resp_STK_INSYNC);
          move(STK_SIGN_ON_MESSAGE, buf[0], length(STK_SIGN_ON_MESSAGE));
          uart_transmit_buffer(@buf[0], length(STK_SIGN_ON_MESSAGE));
          uart_transmit(Resp_STK_OK);
        end
        else
          uart_transmit(Resp_STK_NOSYNC);
      end;
      {$endif}

      {$ifndef arduino}
      Cmnd_STK_SET_PARAMETER:
      begin
        uart_receive_buffer(@buf[0], 3);
        if buf[2] = Sync_CRC_EOP then
        begin
          uart_transmit(Resp_STK_INSYNC);
          uart_transmit(buf[0]);
          uart_transmit(Resp_STK_FAILED); // indicate not supported
        end
        else
          uart_transmit(Resp_STK_NOSYNC);
      end;
      {$endif}

      Cmnd_STK_GET_PARAMETER:
      begin
        b := uart_receive;
        case b of
          //Parm_STK_HW_VER:          checkAndReplyByte(2);
          Parm_STK_SW_MAJOR:        checkAndReplyByte(1);
          Parm_STK_SW_MINOR:        checkAndReplyByte(18);
          //Parm_STK_PROGMODE:        checkAndReplyByte(ord('S'));
        else
          checkAndReplyByte(3);
        end;
      end;

      Cmnd_STK_SET_DEVICE:
      begin
        // Data not used, so currently it could just be discarded
        uart_receive_buffer(@deviceParams.bytes[0], SizeOf(deviceParams));
        checkAndReply;
      end;

      Cmnd_STK_SET_DEVICE_EXT:
      begin
        // Data not used, so currently it could just be discarded
        uart_receive_buffer(@deviceParamsEx.bytes[0], SizeOf(deviceParamsEx));
        checkAndReply;
      end;

      //Cmnd_STK_ENTER_PROGMODE: nothing specific to do

      Cmnd_STK_LEAVE_PROGMODE:
      begin
        // Set watchdog to shortest timeout (16ms)
        xWDTCSR := (1 shl WDCE) or (1 shl WDE);
        xWDTCSR := (1 shl WDE) or 0;
        checkAndReply;
      end;

      Cmnd_STK_CHIP_ERASE:
      begin
        c := uart_receive;
        if c = Sync_CRC_EOP then
        begin
          uart_transmit(Resp_STK_INSYNC);
          uart_transmit(Resp_STK_FAILED); // indicate not supported
        end
        else
          uart_transmit(Resp_STK_NOSYNC);
      end;

      //Cmnd_STK_CHECK_AUTOINC
      //Cmnd_STK_CHECK_DEVICE

      Cmnd_STK_LOAD_ADDRESS:
      begin
        uart_receive_buffer(@buf[0], 2);
        address := buf[0] + word(buf[1]) shl 8;
        {$if declared(RAMPZ)}
        if (address and $8000) = 0 then
          RAMPZ := RAMPZ and $FE
        else
          RAMPZ := RAMPZ or 1;
        {$endif}
        // Convert from word to byte address
        address := address shl 1;
        checkAndReply;
      end;

      Cmnd_STK_UNIVERSAL:
      begin
        uart_receive_buffer(@buf[0], 5);
        if buf[4] = Sync_CRC_EOP then
        begin
          uart_transmit(Resp_STK_INSYNC);
          {$ifndef arduino}
          if buf[0] = $30 then  // Read signature byte
          begin
            case buf[2] of
              // We can only read the signature with the AVRs that have SIGRD bit in SPMCR.
              // For all others we use predefined signaures like AVR-GCC does.
              {$if defined(FPC_MCU_ATmega8) or defined(FPC_MCU_ATmega8A)}
              0: uart_transmit(SIGNATURE_0);
              1: uart_transmit(SIGNATURE_1);
              2: uart_transmit(SIGNATURE_2);
              {$else}
              0: uart_transmit(readSignatureCalibrationByte(deviceSignature1_Z));
              1: uart_transmit(readSignatureCalibrationByte(deviceSignature2_Z));
              2: uart_transmit(readSignatureCalibrationByte(deviceSignature3_Z));
              {$endif}
            otherwise
              uart_transmit(0);
            end;
          end
          else
          {$endif}

          {$if declared(RAMPZ)}
          // Handle extended address byte
          if buf[0] = $4D then
          begin
            RAMPZ := (RAMPZ and 1) or (buf[2] shl 1); // convert from word address to byte address
            uart_transmit(0);
          end{$ifndef arduino} else {$else};{$endif}
          {$endif declared(RAMPZ)}

          {$ifndef arduino}
          // Support for fuse bits
          if buf[0] = $50 then
          begin
            case buf[1] of
              0: uart_transmit(readFuseLockBits(deviceFuseLow_Z));
              8: uart_transmit(readFuseLockBits(deviceFuseExt_Z));
            otherwise
              uart_transmit(0);
            end;
          end
          else if (buf[0] = $58) and (buf[1] = 8) then
            uart_transmit(readFuseLockBits(deviceFuseHigh_Z))
          else if (buf[0] = $AC) and (buf[1] = $80) then
          begin
            //eraseChip;  Erasure of all memory not supported. Memory is erased just before being written n page or byte level.
            // Note: this implies that old data cannot be deleted unless it is overwritten by new data.
            uart_transmit(0);
          end
          else if (buf[0] = $58) and (buf[1] = 0) then
            uart_transmit(readFuseLockBits(deviceLockbits_Z))
          else if (buf[0] = $AC) and (buf[1] = $E0) then
          begin
            writeLockBits(buf[3] or lockBitMask);
            uart_transmit(buf[3]);
          end
          else if (buf[0] = $38) and (buf[1] = $00) then
            uart_transmit(readSignatureCalibrationByte(deviceOscCal_Z))
          else
            uart_transmit(0);  // dummy reply
          uart_transmit(Resp_STK_OK);
          {$else arduino}
          uart_transmit(0);
          uart_transmit(Resp_STK_FAILED);
          {$endif ndef arduino}
        end
        else
          uart_transmit(Resp_STK_NOSYNC);
      end;

      //Cmnd_STK_PROG_FLASH
      //Cmnd_STK_PROG_DATA
      //Cmnd_STK_PROG_FUSE

      Cmnd_STK_PROG_PAGE:
      begin
        uart_receive_buffer(@buf[0], 3);
        size := (word(buf[0]) shl 8) + buf[1];   // TODO: Check if size is larger that page size?
        // If page size > 128 (i.e. 256),
        // break read into 2
        if size > 128 then
        begin
          uart_receive_buffer(@databuf[0], 128);
          uart_receive_buffer(@databuf[128], 128);
        end
        else
          uart_receive_buffer(@databuf[0], size);
        begin
          if char(buf[2]) = 'F' then
          begin
            flashPageErase(address);
            spm_busy_wait;
            i := 0;
            while i < size do
            begin
              data := databuf[i] + (word(databuf[i + 1]) shl 8);
              flashPageFill(address + i, data);
              inc(i, 2);
            end;
            flashPageWrite(address);
            spm_busy_wait;
            {$if declared(RWWSRE)}
            enableRWW;
            {$endif}
          end
          else // program EEPROM
          begin
            for i := 0 to size-1 do
              EEPROMWriteByte(address + i, databuf[i]);
          end;

          checkAndReply;
        end
      end;

      //Cmnd_STK_PROG_FUSE_EXT
      //Cmnd_STK_READ_FLASH
      //Cmnd_STK_READ_DATA
      //Cmnd_STK_READ_FUSE
      //Cmnd_STK_READ_LOCK

      Cmnd_STK_READ_PAGE:
      begin
        uart_receive_buffer(@buf[0], 3);
        size := (word(buf[0]) shl 8) + buf[1];

        c := uart_receive;
        if c = Sync_CRC_EOP then
        begin
          uart_transmit(Resp_STK_INSYNC);
          if char(buf[2]) = 'F' then
          begin
            for i := 0 to size-1 do
              uart_transmit(flashReadByte(address + i));
          end
          else // read EEPROM
          begin
            for i := 0 to size-1 do
              uart_transmit(EEPROMReadByte(address + i));
          end;

          uart_transmit(Resp_STK_OK);
        end
        else
          uart_transmit(Resp_STK_NOSYNC);
      end;

      Cmnd_STK_READ_SIGN:
      begin
        c := uart_receive;
        if c = Sync_CRC_EOP then
        begin
          uart_transmit(Resp_STK_INSYNC);
          // We can only read the signature with the AVRs that have SIGRD bit in SPMCR.
          // For all others we use predefined signaures like AVR-GCC does.
          {$if defined(FPC_MCU_ATmega8) or defined(FPC_MCU_ATmega8A)}
          uart_transmit(SIGNATURE_0);
          uart_transmit(SIGNATURE_1);
          uart_transmit(SIGNATURE_2);
          {$else}
          uart_transmit(readSignatureCalibrationByte(deviceSignature1_Z));
          uart_transmit(readSignatureCalibrationByte(deviceSignature2_Z));
          uart_transmit(readSignatureCalibrationByte(deviceSignature3_Z));
          {$endif}
          uart_transmit(Resp_STK_OK);
        end
        else
          uart_transmit(Resp_STK_NOSYNC);
      end;

      //Cmnd_STK_READ_OSCCAL
      //Cmnd_STK_READ_FUSE_EXT
      //Cmnd_STK_READ_OSCCAL_EXT
    otherwise
      checkAndReply;
    end;
  until false;
end.

