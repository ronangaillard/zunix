; Hardware setup

	.include	"hw.inc"

	.area	_CODE

init::
	di				; disable interrupts
	ld	sp, #0x0000		; set the stack at the top of the RAM

	call	ledoff

	; Setup CTC

	ld	a, #0x47		; reset and counter mode
	out	(CTC_A), a
	ld	a, #1			; N = 1
	out	(CTC_A), a

	; Setup SIO

1$:					; wait for previous transmission to be finished
	ld	a, #1			; select RR1
	out	(SIO_AC), a
	in	a, (SIO_AC)
	bit	0, a			; all sent?
	jr	z, 1$

	ld	a, #SIO_WR0_CHRESET	; channel A reset
	out	(SIO_AC), a
	ld	a, #SIO_WR0_CHRESET	; channel A reset
	out	(SIO_AC), a

	ld	a, #0x04		; select 4th register
	out	(SIO_AC), a
	ld	a, #0x44		; x16 ( -> 115200 bauds) with stop bit
	out	(SIO_AC), a

	ld	a, #0x05		; select 5th register
	out	(SIO_AC), a
	ld	a, #0x68		; send 8 bits by char & enable transmit
	out	(SIO_AC), a

	ld	a, #0x03		; select 3rd register
	out	(SIO_AC), a
	ld	a, #0xC1		; receive 8 bits by char & enable reception
	out	(SIO_AC), a

	jp	main
