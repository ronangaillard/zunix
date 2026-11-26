/* I/O ports of the board (rev B) */
#ifndef PLATFORM_PORTS_H
#define PLATFORM_PORTS_H

__sfr __at(0x20) sio_ad;   /* SIO channel A data */
__sfr __at(0x21) sio_ac;   /* SIO channel A control: RR0 bit 0 = Rx ready, bit 2 = Tx empty */

#endif
