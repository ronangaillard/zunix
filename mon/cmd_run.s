; run command: start the program loaded at 0x0000 by the load command

	.include	"hw.inc"

	.area	_CODE

; cmd_run: start the program at 0x0000 (like boot does with the kernel); when the program ends
; with ret, the monitor goes back to its prompt
;   destroys: everything the program destroys
cmd_run::
	jp	KERNEL_ADDR
