program simulateatmega328p;

{ avrdude programmer type (-c ) can be any of:
  arduino
  avrisp
  stk500v1

  Create virtual serial port for testing (Linux specific):
  socat -d -d pty,link=/tmp/vserial1,raw,echo=0 pty,link=/tmp/vserial2,raw,echo=0

  Call avrdude to read flash:
  avrdude -c arduino -p m328p -P /tmp/vserial2 -v -Uflash:r:flashdump.hex:i
  avrdude -c arduino -p m328p -P /tmp/vserial2 -v -Uflash:r:-:i

  Write to flash
  avrdude -c arduino -p m328p -P /tmp/vserial2 -v -Uflash:w:blink.hex:i

  Read fuses:
  avrdude -c avrisp -p m328p -P /tmp/vserial2 -v -Uefuse:r:-:h -U hfuse:r:-:h -U lfuse:r:-:h

}

uses
  serialobject, stk500;

const
  // eFuse bits
  BODLEVEL0 = 0;
  BODLEVEL1 = 1;
  BODLEVEL2 = 2;
  // hFuse bits
  BOOTRST = 0;
  BOOTSZ0 = 1;
  BOOTSZ1 = 2;
  EESAVE  = 3;
  WDTON   = 4;
  SPIEN   = 5;
  DWEN    = 6;
  RSTDSBL = 7;
  // lFuse bits
  CKSEL0 = 0;
  CKSEL1 = 1;
  CKSEL2 = 2;
  CKSEL3 = 3;
  SUT0   = 4;
  SUT1   = 5;
  CKOUT  = 6;
  CKDIV8 = 7;
  deviceID0 = $1E;
  deviceID1 = $95;
  deviceID2 = $0F;

  lockBitMask = $C0;  // Unused bits read as 1

var
  serial: TSerialObj;
  b, c: byte;
  buf: array[0..15] of byte;
  databuf: array [0..255] of byte;
  deviceParams: TDeviceParameters;
  deviceParamsEx: TDeviceParametersEx;
  address, size: word;

  // Device memories
  flash: array[0..32*1024-1] of byte;
  eeprom: array[0..1024] of byte;
  lockBits: byte = lockBitMask;
  // Defaults for m328p
  eFuse: byte = %11111001;
  hFuse: byte = %11011001;
  lFuse: byte = %01100010;
  calibration: byte = 123;

procedure dumpMem(source: PByte; size: byte);
var
  i: integer;
begin
  for i := 1 to size do
  begin
    write(HexStr(source[i-1], 2), ' ');
    if ((i mod 16) = 0) and (i > 0) then
      writeln;
  end;
  writeln;
end;

procedure writeDeviceParams(constref devParams: TDeviceParameters);
begin
  with devParams do
  begin
    writeln('  deviceCode: ', deviceCode);
    writeln('  revision: ', revision);
    write('  progType: ', 'Parallel/High-voltage');
    if progType = 0 then
      writeln(' & Serial')
    else
      writeln;
    writeln('  parallelMode: ', parallelMode);
    writeln('  polling: ', polling);
    writeln('  selfTimed: ', selfTimed);
    writeln('  lockBytes: ', lockBytes);
    writeln('  fuseBytes: ', fuseBytes);
    writeln('  flashpollval1: ', flashpollval1);
    writeln('  flashpollval2: ', flashpollval2);
    writeln('  eeprompollval1: ', eeprompollval1);
    writeln('  eeprompollval2: ', eeprompollval2);
    writeln('  pagesize: ', pagesizehigh shl 8 + pagesizelow);
    writeln('  eepromsize: ', eepromsizehigh shl 8 + eepromsizelow);
    writeln('  flashsize: $', HexStr(flashsize4 shl 24 + flashsize3 shl 16 + flashsize2 shl 8 + flashsize1, 4));
  end;
end;

procedure eraseChip;
begin
  FillByte(flash, sizeOf(flash), $FF);
  if hFuse and (1 shl EESAVE) > 0 then
    FillByte(eeprom, sizeOf(eeprom), $FF);
  lockBits := $FF;
end;

procedure checkAndReply;
var
  c: byte;
begin
  c := 0;
  if (serial.ReadByteTimeout(c, 250) > 0) and (c = Sync_CRC_EOP) then
  begin
    serial.Write(Resp_STK_INSYNC);
    serial.Write(Resp_STK_OK);
  end
  else
    serial.Write(Resp_STK_NOSYNC);
end;

// Wrap expected reply byte between Resp_STK_INSYNC and Resp_STK_OK
procedure checkAndReplyByte(b: byte);
var
  c: byte;
begin
  c := 0;
  if serial.ReadByteTimeout(c, 250) > 0 then
  begin
    serial.Write(Resp_STK_INSYNC);
    serial.Write(b);
    serial.Write(Resp_STK_OK);
  end
  else
    serial.Write(Resp_STK_NOSYNC);
end;

begin
  writeln('Connecting to tmp/vserial1');
  serial := TSerialObj.Create;
  serial.OpenPort('/tmp/vserial1', 115200);

  // Initialize memories
  FillByte(flash, SizeOf(flash), $FF);
  FillByte(eeprom, SizeOf(eeprom), $FF);

  repeat
    b := 0;
    if serial.ReadByteTimeout(b, 250) = 1 then
    case b of
      Sync_CRC_EOP:
      begin
        serial.Write(Resp_STK_NOSYNC);
        writeln('Sync_CRC_EOP');
      end;

      //Cmnd_STK_GET_SYNC:
      //begin
      //  writeln('Cmnd_STK_GET_SYNC');
      //  checkAndReply;
      //end;

      {$ifndef arduino}
      Cmnd_STK_GET_SIGN_ON:
      begin
        writeln('Cmnd_STK_GET_SIGN_ON');
        c := 0;
        serial.ReadByteTimeout(c, 250);
        if c = Sync_CRC_EOP then
        begin
          serial.Write(Resp_STK_INSYNC);
          move(STK_SIGN_ON_MESSAGE, buf[0], length(STK_SIGN_ON_MESSAGE));
          serial.Write(buf[0], length(STK_SIGN_ON_MESSAGE));
          serial.Write(Resp_STK_OK);
        end
        else
          serial.Write(Resp_STK_NOSYNC);
      end;
      {$endif}

      {$ifndef arduino}
      Cmnd_STK_SET_PARAMETER:
      begin
        writeln('Cmnd_STK_SET_PARAMETER');
        if (serial.ReadTimeout(buf[0], 3, 1000) = 3) and
           (buf[2] = Sync_CRC_EOP) then
        begin
          serial.Write(Resp_STK_INSYNC);
          serial.Write(buf[0]);
          serial.Write(Resp_STK_FAILED); // indicate not supported
        end
        else
          serial.Write(Resp_STK_NOSYNC);
      end;
      {$endif}

      Cmnd_STK_GET_PARAMETER:
      begin
        writeln('Cmnd_STK_GET_PARAMETER');
        b := 0;
        if serial.ReadByteTimeout(b, 250) = 1 then
          case b of
            //Parm_STK_HW_VER:          checkAndReplyByte(2);
            Parm_STK_SW_MAJOR:        checkAndReplyByte(1);
            Parm_STK_SW_MINOR:        checkAndReplyByte(18);
            //Parm_STK_PROGMODE:        checkAndReplyByte(ord('S'));
          otherwise
            writeln('** Unhandled parameter $', HexStr(b, 2));
            checkAndReplyByte(3);
          end
        else
          serial.Write(Resp_STK_NOSYNC);
      end;

      Cmnd_STK_SET_DEVICE:
      begin
        writeln('Cmnd_STK_SET_DEVICE');
        if serial.ReadTimeout(deviceParams.bytes, SizeOf(deviceParams), 1000) = SizeOf(deviceParams) then
        begin
          checkAndReply;
          writeDeviceParams(deviceParams);
        end
        else
          serial.Write(Resp_STK_NOSYNC);
      end;

      Cmnd_STK_SET_DEVICE_EXT:
      begin
        writeln('Cmnd_STK_SET_DEVICE_EXT');
        if serial.ReadTimeout(deviceParamsEx.bytes, SizeOf(deviceParamsEx), 1000) = SizeOf(deviceParamsEx) then
          checkAndReply
        else
          serial.Write(Resp_STK_NOSYNC);
      end;

      Cmnd_STK_ENTER_PROGMODE:
      begin
        writeln('Cmnd_STK_ENTER_PROGMODE');
        checkAndReply;
      end;

      Cmnd_STK_LEAVE_PROGMODE:
      begin
        writeln('Cmnd_STK_LEAVE_PROGMODE');
        checkAndReply;
        //Break;  // Done, so exit loop
      end;

      Cmnd_STK_CHIP_ERASE:
      begin
        writeln('Cmnd_STK_CHIP_ERASE');
        c := 0;
        serial.ReadByteTimeout(c, 100);
        if c = Sync_CRC_EOP then
        begin
          serial.Write(Resp_STK_INSYNC);
          //eraseChip;
          serial.Write(Resp_STK_FAILED); // Resp_STK_OK;
        end
        else
          serial.Write(Resp_STK_NOSYNC);
      end;

      //Cmnd_STK_CHECK_AUTOINC
      //Cmnd_STK_CHECK_DEVICE

      Cmnd_STK_LOAD_ADDRESS:
      begin
        write('Cmnd_STK_LOAD_ADDRESS: $');
        serial.Read(buf[0], 2);
        address := buf[0] + word(buf[1])*256;
        address := address shl 1;
        writeln(HexStr(address, 4));
        checkAndReply;
      end;

      Cmnd_STK_UNIVERSAL:
      begin
        write('Cmnd_STK_UNIVERSAL: ');
        serial.Read(buf[0], 5);
        if buf[4] = Sync_CRC_EOP then
        begin
          serial.Write(Resp_STK_INSYNC);
          {$ifndef arduino}
          // Below is required for avrisp or stk500v1 support in avrdude
          // Not required by arduino mode
          if buf[0] = $30 then  // Read signature byte
          begin
            writeln('read signature byte: ', buf[2]);
            case buf[2] of
              0: serial.Write(deviceID0);
              1: serial.Write(deviceID1);
              2: serial.Write(deviceID2);
            otherwise
              writeln('** read signature byte: ', buf[2]);
              serial.Write(0);
            end;
          end
          // Support for fuse bits
          else if buf[0] = $50 then
          begin
            case buf[1] of
              0:
              begin
                writeln('read low fuse.');
                serial.Write(lFuse);  // Low fuse
              end;
              8:
              begin
                writeln('read extended fuse.');
                serial.Write(eFuse);  // Extended fuse
              end;
            otherwise
              writeln('** read fuse byte: ', buf[1]);
              serial.Write(0);
            end;
          end
          else if (buf[0] = $58) and (buf[1] = 8) then
          begin
            writeln('read high fuse.');
            serial.Write(hFuse);        // High fuse
          end
          else if (buf[0] = $AC) and (buf[1] = $80) then
          begin
            writeln('erase chip.');
            eraseChip;
            serial.write(0);
          end
          else if (buf[0] = $58) and (buf[1] = 0) then
          begin
            writeln('read lock bits.');
            serial.Write(lockBits);
          end
          else if (buf[0] = $AC) and (buf[1] = $E0) then
          begin
            writeln('write lock bits.');
            lockBits := buf[3] or lockBitMask;
            serial.Write(buf[3]);
          end
          else if (buf[0] = $38) and (buf[1] = $00) then
          begin
            writeln('read calibration byte.');
            serial.Write(calibration);
          end
          else
          begin
            writeln('** Unknown: $', HexStr(buf[0], 2), ':', HexStr(buf[1], 2), ':', HexStr(buf[2], 2), ':', HexStr(buf[3], 2));
            serial.Write(0);  // dummy reply
            serial.Write(Resp_STK_FAILED);
            continue;
          end;
          serial.Write(Resp_STK_OK);
          {$else arduino}
          serial.Write(0);
          serial.Write(Resp_STK_FAILED);
          {$endif ndef arduino}
        end
        else
          serial.Write(Resp_STK_NOSYNC);
      end;

      //Cmnd_STK_PROG_FLASH
      //Cmnd_STK_PROG_DATA
      //Cmnd_STK_PROG_FUSE

      Cmnd_STK_PROG_PAGE:
      begin
        write('Cmnd_STK_PROG_PAGE: ');
        serial.Read(buf[0], 3);
        size := word(buf[0])*256 + buf[1];
        writeln('sz: ', size, ', type = ', char(buf[2]));
        if serial.Read(databuf[0], size) = size then
        begin
          writeln('Data received:');
          if char(buf[2]) = 'F' then
          begin
            move(databuf[0], flash[address], size);
            dumpMem(@flash[address], size);
          end
          else
          begin
            move(databuf[0], eeprom[address], size);
            dumpMem(@eeprom[address], size);
          end;

          checkAndReply;
        end
        else
          serial.Write(Resp_STK_NOSYNC);
      end;

      //Cmnd_STK_PROG_FUSE_EXT
      //Cmnd_STK_READ_FLASH
      //Cmnd_STK_READ_DATA
      //Cmnd_STK_READ_FUSE
      //Cmnd_STK_READ_LOCK

      Cmnd_STK_READ_PAGE:
      begin
        write('Cmnd_STK_READ_PAGE: ');
        serial.Read(buf[0], 3);
        size := buf[0]*256 + buf[1];
        writeln('sz: ', size, ', type = ', char(buf[2]));

        c := 0;
        serial.ReadByteTimeout(c, 100);
        if c = Sync_CRC_EOP then
        begin
          serial.Write(Resp_STK_INSYNC);
          if char(buf[2]) = 'F' then
            serial.Write(flash[address], size)
          else
            serial.Write(eeprom[address], size);

          serial.Write(Resp_STK_OK);
        end
        else
          serial.Write(Resp_STK_NOSYNC);
      end;

      Cmnd_STK_READ_SIGN:
      begin
        writeln('Cmnd_STK_READ_SIGN');
        c := 0;
        serial.ReadByteTimeout(c, 250);
        if c = Sync_CRC_EOP then
        begin
          serial.Write(Resp_STK_INSYNC);
          serial.Write(deviceID0);
          serial.Write(deviceID1);
          serial.Write(deviceID2);
          serial.Write(Resp_STK_OK);
        end
        else
          serial.Write(Resp_STK_NOSYNC);
      end;

      //Cmnd_STK_READ_OSCCAL
      //Cmnd_STK_READ_FUSE_EXT
      //Cmnd_STK_READ_OSCCAL_EXT
    otherwise
      writeln('== Default reply for message : $', HexStr(qword(b), 2));
      checkAndReply;
    end;
  until false;

end.

