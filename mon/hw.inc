; hw.inc — I/O map of the motherboard
SIO_AD = 0x20				; SIO channel A data
SIO_AC = 0x21				; SIO channel A control
CTC_A = 0x30				; CTC channel A
LATCH = 0x38				; write only
CF_CARD = 0x40

; SIO registers: write the register number to WR0, then read or write the register
SIO_RR1 = 1				; read register 1: special receive conditions, all sent
SIO_WR3 = 3				; write register 3: receive parameters
SIO_WR4 = 4				; write register 4: clock mode, stop bits, parity
SIO_WR5 = 5				; write register 5: transmit parameters
SIO_WR0_CHRESET = 0x18			; SIO WR0: channel reset
SIO_TRANSMIT_BUFFER_EMPTY_BIT = 2
SIO_RECEIVE_CHAR_AVAILABLE_BIT = 0
SIO_RR1_ALL_SENT_BIT = 0

L_ROM_DIS = 0x01
L_LED = 0x80

; Memory map
KERNEL_ADDR = 0x0000			; where boot loads the kernel and run starts a program
