; Help commande to lsit available commands

cmd_help::
	ld	hl, #msg_help
	call	puts
	ret

msg_help:
	.asciz	"available commands:\r\n - help: shows all availabe commands\r\n"
