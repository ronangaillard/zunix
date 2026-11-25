; Help commande to list available commands

	.area	_CODE

cmd_help::
	ld	hl, #msg_help
	call	puts
	ret

msg_help:
	.asciz	"available commands:\r\n - help: shows all availabe commands\r\n - list: list all files at root of CF card\r\n - load: wait for an hex file on the serial port and loads it into RAM\r\n - run: runs the program loaded at address 0x0000\r\n - boot: loads kernel.bin at address 0x0000 and runs it\r\n"
