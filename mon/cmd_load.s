; load command: receive a program (Intel HEX) from the console

	.area	_CODE

; cmd_load: receive Intel HEX lines and write their data to RAM, until the end of file record
; (type 01). Only data records (type 00) are written; the others (02-05: segment and start
; addresses, useless in 64 KB) are read and skipped. The checksum is not checked.
;   destroys: A, BC, D, HL
cmd_load::
	ld	hl, #msg_waiting_for_program
	call	puts

wait_line_start:
	call	getc
	cp	a, #':'
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
	jp	z, read_line_end	; end of file record: no data

	ld	a, b
	or	a, a
	jp	z, read_line_end	; empty record: no data (dec b would loop 256 times)

read_next_byte:
	call	get_hex8
	inc	d
	dec	d			; Z = 1 if type 00 (data), A unchanged
	jp	nz, 1$			; other record type: skip its bytes
	ld	(hl), a
	inc	hl
1$:
	dec	b
	jp	nz, read_next_byte

read_line_end:
	call	get_hex8		; checksum

	ld	a, #'.'
	call	putc

	ld	a, d
	cp	a, #0x01		; type 0x01 is end of file
	jp	nz, wait_line_start

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
get_hex8:
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

msg_waiting_for_program:
	.asciz	"waiting for program\r\n"
