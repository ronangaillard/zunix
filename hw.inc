; hw.inc — I/O map of the motherboard (see doc/io_map.md)
SIO_AD = 0x20				; SIO channel A data
SIO_AC = 0x21				; SIO channel A control
CTC_A = 0x30				; CTC channel A
LATCH = 0x38				; write only

SIO_WR0_CHRESET = 0x18			; SIO WR0: channel reset
SIO_TRANSMIT_BUFFER_EMPTY_BIT = 2
SIO_RECEIVE_CHAR_AVAILABLE_BIT = 0

L_ROM_DIS = 0x01
L_LED = 0x80
