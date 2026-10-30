; LED D_L8, on the latch. Writing the latch also sets the memory map: keep L_ROM_DIS (RAM at
; 0x0000), as the program runs from RAM

	.include	"hw.inc"

	.area	_CODE

; ledon, ledoff
;   destroys: A
ledon::
	ld	a, #L_LED | L_ROM_DIS
	out	(LATCH), a
	ret

ledoff::
	ld	a, #L_ROM_DIS
	out	(LATCH), a
	ret
