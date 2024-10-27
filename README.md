# avrpasboot
A STK500v1 compatible serial bootloader for classic AVR controllers (atmega328p and similar), written in Pascal.  

By default the bootloader supports the _stk500v1_, _avrisp_ and _arduino_ programmer types of avrdude. This supports many of the commands according to document [AVR061](https://www.microchip.com/en-us/application-notes/an2525). By setting a compile time definition **arduino**, a smaller subset of AVR061 commands are supported, similar to the [Optiboot](https://github.com/Optiboot/optiboot) project. This results in a smaller bootloader. This mode only supports the avrdude programmer type _arduino_.  

Tested on atmega328p, atmega2560 and atmega8, but should in principle be compatible with any controller with a subarch of avr4, avr5, avr51 or avr6.  The primary limitation is whether the bootloader can fit into the availble boot space.  

## Configuration of fuses and compiler definitions
The BOOTRST fuse needs to be programmed so that the bootloader code will execute after a reset. The BOOTSZ0/1 fuses needs to be set to a large enough value to fit the bootloader code. The starting address of the bootloader code needs to be specified to the linker using the `--sectionstart` option. Linker options can be passed to the compiler using the `-k` option, e.g: `-k --section-start=.text=0x1800`. The start of the bootloader code is determined by the BOOTSZ0/1 settings.  

On controllers with less than 16 kB of flash memory, a symbol `rebootstart` is required as target for the rjmp instruction to start the user application.  This can be specified as follows: `-k "--defsym rebootstart=0"`.

To get started, fuse settings and the bootloader needs to be programmed using an ISP programmer such as [USBASP](https://www.fischl.de/usbasp/).

Note that FPC 3.3.1 have options to discard some (or all) of the startup code.  This feature is useful because it reduces code size. The bootloader contains custom startup code that provides the minimum functionality required by the bootloader code.

## simulatebootloader
This is a PC project which simulates the bootloader behaviour. The main purpose is to aid in debugging protocol related logic. To test this, one needs to create a pair of virtual serial ports through which [avrdude](https://github.com/avrdudes/avrdude) can interact. On Linux, the command `socat -d -d pty,link=/tmp/vserial1,raw,echo=0 pty,link=/tmp/vserial2,raw,echo=0` can be used to create this.  On Windows, a tools such as [com0com](https://sourceforge.net/projects/com0com/) could be used.
