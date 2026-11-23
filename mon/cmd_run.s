; run command: start the program loaded at 0x9000 by the load command

	.area	_CODE

; cmd_run: start the program at 0x9000; when the program ends with ret, the monitor goes back to
; its prompt
;   destroys: everything the program destroys
cmd_run::
	jp	0x9000
	ret
