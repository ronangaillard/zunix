; Line input with echo, into commandbuf

	.area	_CODE

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

	.area	_DATA

COMMAND_MAX_LENGTH = 64

commandbuf::
	.ds	COMMAND_MAX_LENGTH + 1
