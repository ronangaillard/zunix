; Z80 fixed addresses
; at reset the ROM is at 0x0000: copy _CODE (stored at 0x0100 in the ROM, see the Makefile) to the
; address it is linked for (0xE000, common RAM), then start it; init removes the ROM

CODE_ADDRESS_BEFORE_RELOCATE = 0x0100


	.area	_HEADER (ABS)

	.org	0
	ld	hl, #CODE_ADDRESS_BEFORE_RELOCATE
	ld	de, #s__CODE		; relocate address
	ld	bc, #l__CODE		; code length
	ldir
	jp	init

	.org	0x38			; IM 1: init runs with interrupts off, nothing to do yet
	ei
	reti

	.org	0x66			; NMI: cannot be masked, just return
	retn
