	.include	"hw.inc"

	.area	_HEADER (ABS)
	.org	0

init:

	call	ledoff

	; Setup CTC
	ld	a, #0x47		; Reset and counter mode
	out	(CTC_A), a
	ld	a, #1			; N = 1
	out	(CTC_A), a

	; Setup SIO
	ld	a, #0x18		; Channel A reset
	out	(SIO_AC), a
	ld	a, #0x18		; Channel A reset
	out	(SIO_AC), a

	ld	a, #0x04		; Select 4th register
	out	(SIO_AC), a
	ld	a, #0x44		; x16 ( -> 115200 bauds) with stop bit
	out	(SIO_AC), a


	ld	a, #0x05		; Select 5th register
	out	(SIO_AC), a
	ld	a, #0x68		; send 8 bits by char & enable transmit
	out	(SIO_AC), a

	ld	a, #0x03		; Select 3rd register
	out	(SIO_AC), a
	ld	a, #0xC1		; receive 8 bits by char & enable reception
	out	(SIO_AC), a

	; Write 'coucou'

	ld	a, #'c'
	out	(SIO_AD), a
	call	wait
	ld	a, #'o'
	out	(SIO_AD), a
	call	wait
	ld	a, #'u'
	out	(SIO_AD), a
	call	wait
	ld	a, #'c'
	out	(SIO_AD), a
	call	wait
	ld	a, #'o'
	out	(SIO_AD), a
	call	wait
	ld	a, #'u'
	out	(SIO_AD), a
	call	wait
	ld	a, #'\n'
	out	(SIO_AD), a

	call	wait
	call	wait
	call	wait
	call	wait
	call	wait

	jp	init



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
