; Console on SIO channel A

	.include	"hw.inc"

	.area	_CODE

; puts: send a string ended by 0
;   in:  HL = address of the first character
;   out: HL = address of the final 0
;   destroys: A, B
puts::
	ld	a, (hl)
	or	a, a
	ret	z
	call	putc
	inc	hl
	jp	puts

; puthex: send HL as 4 hexadecimal digits
;   in:  HL = number
;   destroys: A, B
puthex::
	ld	a, h
	call	puthex8
	ld	a, l
	call	puthex8
	ret

; puthex8: send A as 2 hexadecimal digits
;   in:  A = number
;   destroys: A, B
puthex8::
	push	af
	rrca
	rrca
	rrca
	rrca
	call	1$
	pop	af
	call	1$
	ret
1$:
	and	a, #0x0F
	cp	#10
	jr	c, 2$			; jump when a < 10
	add	a, #'A' - 10
	call	putc
	ret
2$:
	add	a, #'0'
	call	putc
	ret

; putc: send one character (waits until the transmit buffer is empty)
;   in:  A = character
;   out: A = character
;   destroys: B
putc::
	ld	b, a
1$:
	in	a, (SIO_AC)
	bit	#SIO_TRANSMIT_BUFFER_EMPTY_BIT, a	; Check that the transmit buffer of the SIO is empty
	jp	z, 1$
	ld	a, b
	out	(SIO_AD), a
	ret

; getc: wait for a character and return it
;   out: A = character
getc::
	in	a, (SIO_AC)
	bit	#SIO_RECEIVE_CHAR_AVAILABLE_BIT, a	; Did SIO receveive a character ?
	jp	z, getc
	in	a, (SIO_AD)
	ret
