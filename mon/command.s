; Available monitor commands

commands::
	.dw	name_help
	.dw	cmd_help
	.dw	name_list
	.dw	cmd_list
	.dw	name_load
	.dw	cmd_load
	.dw	name_run
	.dw	cmd_run
	.dw	name_boot
	.dw	cmd_boot
	.dw	0

name_help::
	.asciz	"help"

name_list::
	.asciz	"list"

name_load::
	.asciz	"load"

name_run::
	.asciz	"run"

name_boot::
	.asciz	"boot"
