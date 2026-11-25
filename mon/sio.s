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

; putdec: send HL as 5 decimal digits (unsigned, with leading zeros)
;   in:  HL = number
;   out: HL = 0
;   destroys: A, B, DE
putdec::
	ld	de, #10000
	call	putten
	ld	de, #1000
	call	putten
	ld	de, #100
	call	putten
	ld	de, #10
	call	putten
	ld	de, #1
	call	putten
	ret

; putten: send one decimal digit: how many times DE fits in HL
;   in:  HL = number (less than 10 * DE)
;        DE = power of ten
;   out: HL = remainder
;   destroys: A, B
putten:
	ld	a, #0			; A = digit
	jr	2$
1$:
	inc	a			; DE did fit: count it
2$:
	or	a, a			; clear carry flag
	sbc	hl, de
	jr	nc, 1$			; jump when DE did fit in HL
	add	a, #'0'
	call	putc
	add	hl, de			; undo the last subtraction, which went below 0
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

; newline: send the end of a line ("\r\n")
;   destroys: A, B
newline::
	ld	a, #'\r'
	call	putc
	ld	a, #'\n'
	jp	putc			; putc returns to our caller

; getc: wait for a character and return it
;   out: A = character
getc::
	in	a, (SIO_AC)
	bit	#SIO_RECEIVE_CHAR_AVAILABLE_BIT, a	; Did SIO receveive a character ?
	jp	z, getc
	in	a, (SIO_AD)
	ret
