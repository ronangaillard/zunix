; Busy-wait delays

	.area	_CODE

; wait: count BC down from 65536 (about 0.16 s at 10 MHz)
;   destroys: A, BC
wait::
	ld	bc, #0
1$:
	dec	bc
	ld	a, c
	or	a, b
	jp	nz, 1$
	ret
