/* I/O ports of the board (rev B)
 *
 * The board's side of the contracts of the generic drivers in dev/: each driver includes this
 * file as "board.h", with no directory, and the Makefile's -I makes that name point here. The
 * names it expects are listed in its header (dev/sio.h for the SIO); another board would have
 * its own board.h with the same names and its own addresses. Files of platform/ are part of the
 * board and may include it as "platform/board.h".
 */
#ifndef PLATFORM_BOARD_H
#define PLATFORM_BOARD_H

__sfr __at(0x20) sio_ad; /* SIO channel A data */
__sfr __at(0x21) sio_ac; /* SIO channel A control */
__sfr __at(0x22) sio_bd; /* SIO channel B data */
__sfr __at(0x23) sio_bc; /* SIO channel B control */

/* CTC, one port per channel. Channels 0 and 1 count a 1.8432 MHz oscillator on CLK/TRG and
 * their ZC/TO outputs clock SIO channels A and B. */
__sfr __at(0x30) ctc_0; /* CTC channel 0: clock of SIO channel A */
__sfr __at(0x31) ctc_1; /* CTC channel 1: clock of SIO channel B */
__sfr __at(0x32) ctc_2; /* CTC channel 2 */
__sfr __at(0x33) ctc_3; /* CTC channel 3 */

#endif
