; Available monitor commands

	.area	_CODE

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

; Helpers shared by the commands

; mount_error: show that the CF card could not be mounted
;   destroys: A, B, HL
mount_error::
	ld	hl, #msg_mount_error
	call	puts
	ret

msg_mount_error:
	.asciz	"mount error, check if CF is inserted and if CF is formatted with V7 file system\r\n"
