# avrpasboot
A STK500v1 compatible serial bootloader for classic AVR controllers (atmega328p and similar), written in Pascal.  

By default the bootloader supports the _stk500v1_, _avrisp_ and _arduino_ programmer types of avrdude. This supports many of the commands according to document [AVR061](https://www.microchip.com/en-us/application-notes/an2525). By setting a compile time definition **arduino**, a smaller subset of AVR061 commands are supported, similar to the [optiboot](https://github.com/Optiboot/optiboot) project. This results in a smaller bootloader. This mode only supports the avrdude programmer type _arduino_.  

Tested on atmega328p and atmega2560, but should in principle be compatible with any controller with a subarch of avr4, avr5, avr51 or avr6.

## simulatebootloader
This is a PC project which simulates the bootloader behaviour. The main purpose is to aid in debugging protocol related logic. To test this, one needs to create a pair of virtual serial ports through which [avrdude](https://github.com/avrdudes/avrdude) can interact. On Linux, the command `socat -d -d pty,link=/tmp/vserial1,raw,echo=0 pty,link=/tmp/vserial2,raw,echo=0` can be used to create this.  On Windows, a tools such as [com0com](https://sourceforge.net/projects/com0com/) could be used.
