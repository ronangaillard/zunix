; Main loop: greet, read a line, again

	.area	_CODE

main::
	ld	hl, #msg_hello
	call	puts
interpreter_start:
	ld	a, #'>'
	call	putc
	call	readline

	call	find_command
	jp	interpreter_start

; no_command_found: show that the line typed is not a command
;   destroys: A, B, HL
no_command_found:
	ld	hl, #msg_no_command_found
	call	puts
	ld	hl, #commandbuf
	call	puts
	call	newline
	ret

; find_command: look for the line typed (commandbuf) in the command table and run the command
; (jp: the command returns to our caller); show an error when there is no such command
;   destroys: A, B, DE, HL, and everything the command destroys
find_command:
	ld	hl, #commands
1$:
	ld	e, (hl)
	inc	hl
	ld	d, (hl)			; (de) points to command name
	inc	hl
	ld	a, d
	or	a, e
	jp	z, no_command_found	; end of table if e = d = 0
	push	hl
	ld	hl, #commandbuf
	call	compare_strings
	pop	hl
	jr	z, 2$			; command name found, run it
	inc	hl
	inc	hl
	jr	1$
2$:
	ld	a, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, a
	jp	(hl)



; compare_strings: compare two strings
;   in:  HL = address of the first character of the first string
;        DE = address of the first character of the second string
;   out: Z = 0 if different, 1 if same string
;   destroys: A, B, DE, HL
compare_strings::
	ld	b, (hl)
	ld	a, (de)
	cp	b
	jp	nz, 1$			; character is different so string is different
	or	a, a
	jp	z, 2$			; end of strings
	inc	hl
	inc	de
	jp	compare_strings

1$:
	or	#1			; set Z = 0
	ret

2$:
	cp	a, a			; set Z = 1
	ret


msg_hello:
	.asciz	"Z80 bootloader v0.1\r\n by Ronan Gaillard\r\n\r\nrun help for more info\r\n"
msg_no_command_found:
	.asciz	"no command named "
