unit stk500;

interface

//**** ATMEL AVR - A P P L I C A T I O N   N O T E  ************************
//*
//* Title:		AVR061 - STK500 Communication Protocol
//* Filename:		command.h
//* Version:		1.0
//* Last updated:	09.09.2002
//*
//* Support E-mail:	avr@atmel.com
//*
//**************************************************************************

// *****************[ STK Message constants ]***************************

const
  STK_SIGN_ON_MESSAGE       = 'AVR STK';   // Sign on string for Cmnd_STK_GET_SIGN_ON
// *****************[ STK Response constants ]***************************
  Resp_STK_OK               = $10;
  Resp_STK_FAILED           = $11;
  Resp_STK_UNKNOWN          = $12;
  Resp_STK_NODEVICE         = $13;
  Resp_STK_INSYNC           = $14;
  Resp_STK_NOSYNC           = $15;

  Resp_ADC_CHANNEL_ERROR    = $16;
  Resp_ADC_MEASURE_OK       = $17;
  Resp_PWM_CHANNEL_ERROR    = $18;
  Resp_PWM_ADJUST_OK        = $19;

// *****************[ STK Special constants ]***************************
  Sync_CRC_EOP              = $20;  // 'SPACE'

// *****************[ STK Command constants ]***************************
  Cmnd_STK_GET_SYNC         = $30;  // '0'
  Cmnd_STK_GET_SIGN_ON      = $31;  // '1'
  Cmnd_STK_RESET            = $32;  // '2', not mentioned in AVR061
  Cmnd_STK_SINGLE_CLOCK     = $33;  // '3', not mentioned in AVR061
  Cmnd_STK_STORE_PARAMETERS = $34;  // '4', not mentioned in AVR061

  Cmnd_STK_SET_PARAMETER    = $40;  // '@'
  Cmnd_STK_GET_PARAMETER    = $41;  // 'A'
  Cmnd_STK_SET_DEVICE       = $42;  // 'B'
  Cmnd_STK_GET_DEVICE       = $43;  // 'C', not mentioned in AVR061
  Cmnd_STK_GET_STATUS       = $44;  // 'D', not mentioned in AVR061
  Cmnd_STK_SET_DEVICE_EXT   = $45;  // 'E'

  Cmnd_STK_ENTER_PROGMODE   = $50;  // 'P'
  Cmnd_STK_LEAVE_PROGMODE   = $51;  // 'Q'
  Cmnd_STK_CHIP_ERASE       = $52;  // 'R'
  Cmnd_STK_CHECK_AUTOINC    = $53;  // 'S'
  Cmnd_STK_CHECK_DEVICE     = $54;  // 'T', not mentioned in AVR061
  Cmnd_STK_LOAD_ADDRESS     = $55;  // 'U'
  Cmnd_STK_UNIVERSAL        = $56;  // 'V'

  Cmnd_STK_PROG_FLASH       = $60;  // '`'
  Cmnd_STK_PROG_DATA        = $61;  // 'a'
  Cmnd_STK_PROG_FUSE        = $62;  // 'b'
  Cmnd_STK_PROG_LOCK        = $63;  // 'c'
  Cmnd_STK_PROG_PAGE        = $64;  // 'd'
  Cmnd_STK_PROG_FUSE_EXT    = $65;  // 'e'

  Cmnd_STK_READ_FLASH       = $70;  // 'p'
  Cmnd_STK_READ_DATA        = $71;  // 'q'
  Cmnd_STK_READ_FUSE        = $72;  // 'r'
  Cmnd_STK_READ_LOCK        = $73;  // 's'
  Cmnd_STK_READ_PAGE        = $74;  // 't'
  Cmnd_STK_READ_SIGN        = $75;  // 'u'
  Cmnd_STK_READ_OSCCAL      = $76;  // 'v'
  Cmnd_STK_READ_FUSE_EXT    = $77;  // 'w'
  Cmnd_STK_READ_OSCCAL_EXT  = $78;  // 'x'

// *****************[ STK Parameter constants ]***************************
  Parm_STK_HW_VER           = $80;  // ' ' - R
  Parm_STK_SW_MAJOR         = $81;  // ' ' - R
  Parm_STK_SW_MINOR         = $82;  // ' ' - R
  Parm_STK_LEDS             = $83;  // ' ' - R/W
  Parm_STK_VTARGET          = $84;  // ' ' - R/W
  Parm_STK_VADJUST          = $85;  // ' ' - R/W
  Parm_STK_OSC_PSCALE       = $86;  // ' ' - R/W
  Parm_STK_OSC_CMATCH       = $87;  // ' ' - R/W
  Parm_STK_RESET_DURATION   = $88;  // ' ' - R/W
  Parm_STK_SCK_DURATION     = $89;  // ' ' - R/W

  Parm_STK_BUFSIZEL         = $90;  // ' ' - R/W, Range {0..255}
  Parm_STK_BUFSIZEH         = $91;  // ' ' - R/W, Range {0..255}
  Parm_STK_DEVICE           = $92;  // ' ' - R/W, Range {0..255}
  Parm_STK_PROGMODE         = $93;  // ' ' - 'P' or 'S'
  Parm_STK_PARAMODE         = $94;  // ' ' - TRUE or FALSE
  Parm_STK_POLLING          = $95;  // ' ' - TRUE or FALSE
  Parm_STK_SELFTIMED        = $96;  // ' ' - TRUE or FALSE

// *****************[ STK status bit definitions ]***************************
 Stat_STK_INSYNC            = $01;  // INSYNC status bit, '1' - INSYNC
 Stat_STK_PROGMODE          = $02;  // Programming mode,  '1' - PROGMODE
 Stat_STK_STANDALONE        = $04;  // Standalone mode,   '1' - SM mode
 Stat_STK_RESET             = $08;  // RESET button,      '1' - Pushed
 Stat_STK_PROGRAM           = $10;  // Program button, '   1' - Pushed
 Stat_STK_LEDG              = $20;  // Green LED status,  '1' - Lit
 Stat_STK_LEDR              = $40;  // Red LED status,    '1' - Lit
 Stat_STK_LEDBLINK          = $80;  // LED blink ON/OFF,  '1' - Blink

type
  TDeviceParameters = record
    case boolean of
      false:
        (deviceCode: byte;
        revision: byte;
        progType: byte;
        parallelMode: byte;
        polling: byte;
        selfTimed: byte;
        lockBytes: byte;
        fuseBytes: byte;
        flashpollval1: byte;
        flashpollval2: byte;
        eeprompollval1: byte;
        eeprompollval2: byte;
        pagesizehigh: byte;
        pagesizelow: byte;
        eepromsizehigh: byte;
        eepromsizelow: byte;
        flashsize4,
        flashsize3,
        flashsize2,
        flashsize1: byte;);
      true:
        (bytes: array[0..19] of byte;);
  end;

  TDeviceParametersEx = record
    case boolean of
      false:
        (commandsize,
        eeprompagesize,
        signalpagel,
        signalbs2,
        dummy: byte;);
      true:
        (bytes: array[0..4] of byte;);
  end;

implementation

end.

