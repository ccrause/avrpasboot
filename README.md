# avrpasboot
A STK500v1 compatible serial bootloader for the atmega328p controller, written in Pascal. The bootloader supports the _stk500v1_, _avrisp_ and _arduino_ programmer types of avrdude. This supports many of the commands according to document [AVR061](https://www.microchip.com/en-us/application-notes/an2525).  

This branch contains a straight forward implementation of the commands necessary for a bootloader. Very little was done to minimize code size, the intent is rather to make this easy to follow.

## simulatebootloader
This is a PC project which simulates the bootloader behaviour. The main purpose is to aid in debugging protocol related logic. To test this, one needs to create a pair of virtual serial ports through which [avrdude](https://github.com/avrdudes/avrdude) can interact. On Linux, the command `socat -d -d pty,link=/tmp/vserial1,raw,echo=0 pty,link=/tmp/vserial2,raw,echo=0` can be used to create this.  On Windows, a tools such as [com0com](https://sourceforge.net/projects/com0com/) could be used.
