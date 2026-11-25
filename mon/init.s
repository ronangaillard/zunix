; Hardware setup

	.include	"hw.inc"

; symbols from the other files (and from the linker: s__, l__)
	.globl	init_storage, ledoff, main

	.area	_CODE

init::
	di				; disable interrupts
	ld	sp, #0x0000		; set the stack at the top of the RAM

	ld	a, #L_ROM_DIS
	out	(LATCH), a		; disable ROM

	; the vectors of vectors.s left with the ROM: write the same instructions in the RAM now at
	; 0x0000, so that an NMI does not jump into garbage (a kernel loaded at 0x0000 replaces them)
	ld	a, #0xFB		; ei
	ld	(0x0038), a
	ld	hl, #0x4DED		; reti (ED 4D, little-endian)
	ld	(0x0039), hl
	ld	hl, #0x45ED		; retn (ED 45, little-endian)
	ld	(0x0066), hl

	call	ledoff

	; Setup CTC

	ld	a, #0x47		; reset and counter mode
	out	(CTC_A), a
	ld	a, #1			; N = 1
	out	(CTC_A), a

	; Setup SIO

1$:					; wait for previous transmission to be finished
	ld	a, #SIO_RR1		; select RR1
	out	(SIO_AC), a
	in	a, (SIO_AC)
	bit	#SIO_RR1_ALL_SENT_BIT, a	; all sent?
	jr	z, 1$

	; channel A reset, sent twice on purpose: if a register was selected (WR0 pointer) but never
	; written, for example after a reset in the middle of a setup, the first write goes to that
	; register and moves the pointer back to WR0; the second one then reaches WR0
	ld	a, #SIO_WR0_CHRESET
	out	(SIO_AC), a
	out	(SIO_AC), a

	ld	a, #SIO_WR4		; select WR4
	out	(SIO_AC), a
	ld	a, #0x44		; x16 ( -> 115200 bauds) with stop bit
	out	(SIO_AC), a

	ld	a, #SIO_WR5		; select WR5
	out	(SIO_AC), a
	ld	a, #0x68		; send 8 bits by char & enable transmit
	out	(SIO_AC), a

	ld	a, #SIO_WR3		; select WR3
	out	(SIO_AC), a
	ld	a, #0xC1		; receive 8 bits by char & enable reception
	out	(SIO_AC), a

	; Setup CF
	call	init_storage

	jp	main
