; Z80 fixed addresses
; Makefile: _CODE at 0x0100, _DATA at 0x8000

	.area	_HEADER (ABS)

	.org	0
	jp	init

	.org	0x38			; IM 1: init runs with interrupts off, nothing to do yet
	ei
	reti

	.org	0x66			; NMI: cannot be masked, just return
	retn
