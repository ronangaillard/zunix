	.include	"hw.inc"

	.area	_HEADER (ABS)
	.org	0

	di

init:
	ld	sp, #0x0000		; set the stack at the top of the RAM

	call	ledoff

	; Setup CTC

	ld	a, #0x47		; Reset and counter mode
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

	ld	a, #0x18		; Channel A reset

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

start:
	; Write 'coucou'

	ld	hl, #msg_hello
	call	puts

	call	readline



	jp	start

ledon:
	ld	a, #0x81
	out	(0x38), a
	ret

ledoff:
	ld	a, #0x01
	out	(0x38), a
	ret

puts:					; Put string on serial, (HL) is the adresse of the first character
	ld	a, (hl)
	or	a, a
	ret	z
	call	putc
	inc	hl
	jp	puts

putc:
	ld	b, a
1$:
	in	a, (SIO_AC)
	bit	#SIO_TRANSMIT_BUFFER_EMPTY_BIT, a	; Check that the transmit buffer of the SIO is empty
	jp	z, 1$
	ld	a, b
	out	(SIO_AD), a
	ret

getc:
	in	a, (SIO_AC)
	bit	#SIO_RECEIVE_CHAR_AVAILABLE_BIT, a	; Did SIO receveive a character ?
	jp	z, getc
	in	a, (SIO_AD)
	ret

readline:
	ld	hl, #commandbuf
1$:
	call	getc
	cp	#0x0D
	jp	z, 2$
	cp	#0x0A
	jp	z, 2$
	call	putc
	ld	(hl), a
	inc	hl
	jp	1$
2$:
	ld	(hl), #0x00
	ld	a, #0x0D
	call	putc
	ld	a, #0x0A
	call	putc
	ret

wait:
	ld	bc, #0
1$:
	dec	bc
	ld	a, c
	or	a, b
	jp	nz, 1$
	ret

; Strings

msg_hello:
	.asciz	"coucou\r\n"

; Vars in RAM

	.area	_DATA (ABS)
	.org	0x8000
COMMAND_MAX_LENGTH = 64
commandbuf:
	.ds	COMMAND_MAX_LENGTH + 1	;
