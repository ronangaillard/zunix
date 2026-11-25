; String helpers

	.area	_CODE

; compare_strings: compare two strings
;   in:  HL = address of the first character of the first string
;        DE = address of the first character of the second string
;   out: Z = 0 if different, 1 if same string
;   destroys: A, B, DE, HL
compare_strings::
	ld	b, (hl)
	ld	a, (de)
	cp	b
	jp	nz, 1$			; character is different so string is different
	or	a, a
	jp	z, 2$			; end of strings
	inc	hl
	inc	de
	jp	compare_strings

1$:
	or	#1			; set Z = 0
	ret

2$:
	cp	a, a			; set Z = 1
	ret
