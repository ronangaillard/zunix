; help command: list the available commands

; symbols from the other files (and from the linker: s__, l__)
	.globl	puts

	.area	_CODE

; cmd_help: show the available commands and what they do
;   destroys: A, B, HL
cmd_help::
	ld	hl, #msg_help
	call	puts
	ret

msg_help:
	.asciz	"available commands:\r\n - help: shows all available commands\r\n - list: lists all files at the root of the CF card\r\n - load: waits for a HEX file on the serial port and loads it into RAM\r\n - run: runs the program loaded at address 0x0000\r\n - boot: loads kernel.bin at address 0x0000 and runs it\r\n"
