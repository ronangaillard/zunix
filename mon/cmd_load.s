; load command: receive a program (Intel HEX) from the console

	.area	_CODE

; cmd_load: receive Intel HEX lines and write their data to RAM, until the end of file record
; (type 01). The checksum is not checked.
;   destroys: A, BC, D, HL
cmd_load::
	ld	hl, #msg_waiting_for_program
	call	puts

wait_line_start:
	call	getc
	cp	a, #":"
	jp	nz, wait_line_start

	call	get_hex8
	ld	b, a			; B = line length

	call	get_hex8
	ld	h, a
	call	get_hex8
	ld	l, a			; HL points to RAM where data will be written

	call	get_hex8		; type

	ld	d, a			; D = type
	cp	a, #0x01
	jp	z, read_line_end

read_next_byte:
	call	get_hex8
	ld	(hl), a
	inc	hl
	dec	b
	jp	nz, read_next_byte

read_line_end:
	call	get_hex8		; checksum

	ld	a, #'.'
	call	putc

	ld	a, d
	cp	a, #0x01		; type 0x01 is end of file
	jp	nz, wait_line_start

	ld	a, #'\r'
	call	putc
	ld	a, #'\n'
	call	putc

	ret


; hex_digit: convert a hexadecimal character to its value
;   in:  A = character ('0'-'9' or 'A'-'F', not checked)
;   out: A = value (0-15)
hex_digit:
	cp	#'A'
	jp	c, 1$			; jump when A is a digit ('0'-'9')
	sub	#'A'			; letter ('A'-'F')
	add	#10
	ret
1$:
	sub	#'0'			; digit ('0'-'9')
	ret

; gethex8: receive 2 hexadecimal characters and return the byte
;   out: A = byte
get_hex8:
	call	getc
	call	hex_digit
	rl	a
	rl	a
	rl	a
	rl	a
	ld	c, a
	call	getc
	call	hex_digit
	add	a, c
	ret

msg_waiting_for_program:
	.asciz	"waiting for program\r\n"
