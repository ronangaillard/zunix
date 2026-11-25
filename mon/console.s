; Console on SIO channel A: output, line input, hexadecimal input

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
	bit	#SIO_RECEIVE_CHAR_AVAILABLE_BIT, a	; did the SIO receive a character?
	jp	z, getc
	in	a, (SIO_AD)
	ret

; readline: read characters until Enter ('\r' or '\n'), echo them, end the line with 0
;   out: commandbuf = the line, ended by 0 (Enter not stored)
;   destroys: A, B, HL
readline::
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
	call	newline
	ret

; hex_digit: convert a hexadecimal character to its value
;   in:  A = character ('0'-'9', 'A'-'F' or 'a'-'f', not checked)
;   out: A = value (0-15)
hex_digit:
	or	a, #0x20		; lowercase: 'A'-'F' -> 'a'-'f', digits unchanged (bit 5 already set)
	cp	a, #'a'
	jp	c, 1$			; jump when A is a digit ('0'-'9')
	sub	a, #'a' - 10		; letter ('a'-'f'): 10-15
	ret
1$:
	sub	#'0'			; digit ('0'-'9')
	ret

; get_hex8: receive 2 hexadecimal characters and return the byte
;   out: A = byte
;   destroys: C
get_hex8::
	call	getc
	call	hex_digit
	add	a, a
	add	a, a
	add	a, a
	add	a, a			; high digit * 16 (rl a would also shift the carry in)
	ld	c, a
	call	getc
	call	hex_digit
	add	a, c
	ret

	.area	_DATA

COMMAND_MAX_LENGTH = 64

commandbuf::
	.ds	COMMAND_MAX_LENGTH + 1
