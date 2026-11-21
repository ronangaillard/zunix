; Storage on the CompactFlash card (ATA registers, 8-bit bus)

	.include	"hw.inc"

; CF registers
CF_DATA = CF_CARD + 0x00		; data (read/write)
CF_ERROR_FEATURES = CF_CARD + 0x01	; error (read) / features (write)
CF_SECTOR_COUNT = CF_CARD + 0x02	; number of sectors to transfer
CF_LBA0 = CF_CARD + 0x03		; LBA bits 0-7
CF_LBA1 = CF_CARD + 0x04		; LBA bits 8-15
CF_LBA2 = CF_CARD + 0x05		; LBA bits 16-23
CF_LBA3 = CF_CARD + 0x06		; LBA bits 24-27 + drive/head + LBA mode (bit 6)
CF_STATUS_COMMAND = CF_CARD + 0x07	; status (read) / command (write)
CF_ALT_STATUS_CONTROL = CF_CARD + 0x08	; alternate status (read) / device control (write)

; CF flags
CF_BUSY_BIT = 7
CF_DRQ_BIT = 3

; Commands
CF_COMMAND_READ = 0x20
CF_COMMAND_SET_FEATURES = 0xEF

; Features
CF_FEATURE_8BIT_MODE = 0x01

	.area	_CODE

; wait_not_busy: wait until the CF card is not busy anymore
;   out: A = CF status
wait_not_busy:
	in	a, (CF_STATUS_COMMAND)
	bit	#CF_BUSY_BIT, a		; is the CF card busy?
	jp	nz, wait_not_busy
	ret

; wait_data_ready: wait until the CF card has data to transfer (DRQ)
;   out: A = CF status
wait_data_ready:
	in	a, (CF_STATUS_COMMAND)
	bit	#CF_DRQ_BIT, a		; is data ready?
	jp	z, wait_data_ready
	ret

; init_storage: switch the CF card to 8-bit data transfers
;   destroys: A
init_storage::
	call	wait_not_busy
	ld	a, #CF_FEATURE_8BIT_MODE
	out	(CF_ERROR_FEATURES), a	; set 8-bit mode
	ld	a, #CF_COMMAND_SET_FEATURES
	out	(CF_STATUS_COMMAND), a
	ret

; read_sector: read one 512-byte sector from the CF card
;   in:  DE = address of the LBA (4 bytes, little-endian, only bits 0-27 used)
;        HL = address of the destination buffer (512 bytes)
;   out: HL = address just after the buffer
;   destroys: A, BC, DE
read_sector::
	call	wait_not_busy
	ld	a, #1
	out	(CF_SECTOR_COUNT), a	; number of sectors to read
	ld	a, (de)
	out	(CF_LBA0), a
	inc	de
	ld	a, (de)
	out	(CF_LBA1), a
	inc	de
	ld	a, (de)
	out	(CF_LBA2), a
	inc	de
	ld	a, (de)
	and	a, #0x0F
	or	a, #0xE0
	out	(CF_LBA3), a
	ld	a, #CF_COMMAND_READ
	out	(CF_STATUS_COMMAND), a	; read command
	call	wait_not_busy
	call	wait_data_ready
	ld	c, #CF_DATA
	ld	b, #0
	inir
	inir
	ret
