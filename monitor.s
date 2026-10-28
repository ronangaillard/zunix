	.include	"hw.inc"

	.area	_HEADER (ABS)
	.org	0

	call	ledoff

	; Setup SIO
	ld	a, #0x18		; Channel A reset
	out	(SIO_AC), a

ledon:
	ld	a, #0x81
	out	(0x38), a
	ret

ledoff:
	ld	a, #0x01
	out	(0x38), a
	ret

wait:
	ld	bc, #0
1$:
	dec	bc
	ld	a, c
	or	a, b
	jp	nz, 1$
	ret
