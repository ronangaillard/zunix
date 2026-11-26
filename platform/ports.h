/* I/O ports of the board (rev B) */
#ifndef PLATFORM_PORTS_H
#define PLATFORM_PORTS_H

__sfr __at(0x20) sio_ad; /* SIO channel A data */
__sfr __at(0x21) sio_ac; /* SIO channel A control: RR0 bit 0 = Rx ready, bit 2 = Tx empty */

/* CTC, one port per channel. Channels 0 and 1 count a 1.8432 MHz oscillator on CLK/TRG and
 * their ZC/TO outputs clock SIO channels A and B. */
__sfr __at(0x30) ctc_0; /* CTC channel 0: clock of SIO channel A */
__sfr __at(0x31) ctc_1; /* CTC channel 1: clock of SIO channel B */
__sfr __at(0x32) ctc_2; /* CTC channel 2 */
__sfr __at(0x33) ctc_3; /* CTC channel 3 */

#endif
