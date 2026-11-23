; Help commande to lsit available commands

cmd_help::
	ld	hl, #msg_help
	call	puts
	ret

msg_help:
	.asciz	"available commands:\r\n - help: shows all availabe commands\r\n - list: list all files at root of CF card\r\n - load: wait for an hex file on the serial port and loads it into RAM\r\n - run: runs program located at address 0x9000\r\n"
