; load command: receive a program (Intel HEX) from the console

; Intel HEX record types
HEX_DATA = 0x00
HEX_END_OF_FILE = 0x01

; symbols from the other files (and from the linker: s__, l__)
	.globl	get_hex8, getc, newline, putc, puts

	.area	_CODE

; cmd_load: receive Intel HEX lines and write their data to RAM, until the end of file record
; (type 01). Only data records (type 00) are written; the others (02-05: segment and start
; addresses, useless in 64 KB) are read and skipped. The checksum is not checked.
;   destroys: A, BC, D, HL
cmd_load::
	ld	hl, #msg_waiting_for_program
	call	puts

1$:					; wait for the start of a line
	call	getc
	cp	a, #':'
	jp	nz, 1$

	call	get_hex8
	ld	b, a			; B = line length

	call	get_hex8
	ld	h, a
	call	get_hex8
	ld	l, a			; HL points to RAM where data will be written

	call	get_hex8		; type

	ld	d, a			; D = type
	cp	a, #HEX_END_OF_FILE
	jp	z, 4$			; end of file record: no data

	ld	a, b
	or	a, a
	jp	z, 4$			; empty record: no data (dec b would loop 256 times)

2$:					; data bytes
	call	get_hex8
	inc	d
	dec	d			; Z = 1 if HEX_DATA (0), A unchanged
	jp	nz, 3$			; other record type: skip its bytes
	ld	(hl), a
	inc	hl
3$:
	dec	b
	jp	nz, 2$

4$:					; end of the line
	call	get_hex8		; checksum

	ld	a, #'.'
	call	putc

	ld	a, d
	cp	a, #HEX_END_OF_FILE
	jp	nz, 1$

	call	newline
	ret

msg_waiting_for_program:
	.asciz	"waiting for program\r\n"
