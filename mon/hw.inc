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

; CompactFlash card (ATA registers, 8-bit bus)
CF_DATA = CF_CARD + 0x00		; data (read/write)
CF_ERROR_FEATURES = CF_CARD + 0x01	; error (read) / features (write)
CF_SECTOR_COUNT = CF_CARD + 0x02	; number of sectors to transfer
CF_LBA0 = CF_CARD + 0x03		; LBA bits 0-7
CF_LBA1 = CF_CARD + 0x04		; LBA bits 8-15
CF_LBA2 = CF_CARD + 0x05		; LBA bits 16-23
CF_LBA3 = CF_CARD + 0x06		; LBA bits 24-27 + drive/head + LBA mode (bit 6)
CF_STATUS_COMMAND = CF_CARD + 0x07	; status (read) / command (write)
CF_ALT_STATUS_CONTROL = CF_CARD + 0x08	; alternate status (read) / device control (write)

; status register bits
CF_BUSY_BIT = 7
CF_DRQ_BIT = 3
CF_ERR_BIT = 0

; commands
CF_COMMAND_READ = 0x20
CF_COMMAND_SET_FEATURES = 0xEF

; features
CF_FEATURE_8BIT_MODE = 0x01

; Latch bits
L_ROM_DIS = 0x01
L_LED = 0x80

; Memory map
KERNEL_ADDR = 0x0000			; where boot loads the kernel and run starts a program
