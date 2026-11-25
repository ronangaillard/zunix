; Storage on the CompactFlash card (ATA registers, 8-bit bus)

	.include	"hw.inc"

; number of status reads before giving up (about 0.3 s at 10 MHz; 0 = 65536)
CF_TIMEOUT = 0

	.area	_CODE

; wait_not_busy: wait until the CF card is not busy anymore
; (no card: the bus floats at 0xFF, so BUSY stays set until the timeout)
;   out: carry = 0: A = CF status
;        carry = 1: timeout
;   destroys: BC
wait_not_busy:
	ld	bc, #CF_TIMEOUT
1$:
	in	a, (CF_STATUS_COMMAND)
	bit	#CF_BUSY_BIT, a		; is the CF card busy?
	jr	z, 2$			; jump when not busy
	dec	bc
	ld	a, b
	or	a, c
	jr	nz, 1$
	scf				; timeout
	ret
2$:
	or	a, a			; clear carry flag: not busy, A unchanged
	ret

; wait_data_ready: wait until the CF card has data to transfer (DRQ), or reports an error (ERR)
;   out: carry = 0: A = CF status
;        carry = 1: the card reports an error, or timeout
;   destroys: BC
wait_data_ready:
	ld	bc, #CF_TIMEOUT
1$:
	in	a, (CF_STATUS_COMMAND)
	bit	#CF_ERR_BIT, a		; error?
	jr	nz, 3$
	bit	#CF_DRQ_BIT, a		; is data ready?
	jr	nz, 2$
	dec	bc
	ld	a, b
	or	a, c
	jr	nz, 1$
3$:
	scf				; error or timeout
	ret
2$:
	or	a, a			; clear carry flag: data ready, A unchanged
	ret

; init_storage: switch the CF card to 8-bit data transfers
;   out: carry = 1: no answer from the card (no card?)
;   destroys: A, BC
init_storage::
	call	wait_not_busy
	ret	c			; no card: read_sector will fail too, mount will tell
	ld	a, #CF_FEATURE_8BIT_MODE
	out	(CF_ERROR_FEATURES), a	; set 8-bit mode
	ld	a, #CF_COMMAND_SET_FEATURES
	out	(CF_STATUS_COMMAND), a
	or	a, a			; clear carry flag
	ret

; read_sector: read one 512-byte sector from the CF card
;   in:  DE = address of the LBA (4 bytes, little-endian, only bits 0-27 used)
;        HL = address of the destination buffer (512 bytes)
;   out: carry = 0: HL = address just after the buffer
;        carry = 1: no card, timeout or error reported by the card (HL unchanged)
;   destroys: A, BC, DE
read_sector::
	call	wait_not_busy
	ret	c			; no card?
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
	ret	c
	call	wait_data_ready
	ret	c			; the card reports an error (sector out of range...)
	ld	c, #CF_DATA
	ld	b, #0
	inir
	inir
	or	a, a			; clear carry flag: sector read
	ret
