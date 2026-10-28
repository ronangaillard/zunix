	.include	"hw.inc"
	.include	"hw.inc"
	.area	_HEADER (ABS)
	.area	_CODE (REL,CON)
	.org	0
SIO_AD = 0x20				; data
SIO_AC == 0x21				; control
LONG_CONSTANT_NAME =: 0x01
. = . + 4

start:
	ld	a, #0x01		; comment
	out	(0x38), a
	ld	a, #L_LED | L_ROM_DIS
1$:	halt				; short label keeps its instruction
wait_loop:
	dec	bc
1$:
	jp	nz, 1$
global::
loop:					; comment on a label
	ex	af, af'
	ex	af, af'			;swap
	ld	a, #';
	ld	a, #',
	ld	hl, #"ab
	.ascii	"a, b ; not a comment"	; real comment
	.ascii	/x;y/
	.db	1, 2, 3
	ld	a, (ix+1)
	LD	A, B
	ld	sp, #0x0000		; stack: the first push writes 0xFFFF-0xFFFE, top of common RAM
	call	averyveryverylongroutinename_here	; past column 40
; full line comment, kept
	; indented full line comment
a:
b:	nop
