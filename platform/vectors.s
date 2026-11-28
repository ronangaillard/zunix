; IM 2 interrupt vectors of the board.
;
; In IM 2, an interrupting chip (SIO, CTC) puts a vector byte on the data bus, and the Z80 reads
; the handler's address at I * 256 + vector. So the table must start on a 256-byte boundary, and
; I holds its high byte (crt0 loads it). Z80 chips only send even vectors: 128 entries of 2
; bytes. Every entry points to unexpected_interrupt, except the ones we actually use.
;
; The table and the handlers live in common memory (0xC000-0xFFFF, see crt0.s): an interrupt can
; come while a process bank is mapped at 0x0000-0xBFFF, and they must still be there.
;   _VECTORS    the table alone, at 0xC000 (-Wl-b in the Makefile): aligned whatever the link
;               order. The Makefile checks that it is not bigger than 256 bytes.
;   _COMMONMEM  the handlers, right after it at 0xC100

	.module	vectors

	.optsdcc	-mz80 sdcccall(1)

	.globl	_panic
	.globl	_timer_interrupt

	.area	_VECTORS

interrupt_table::
; CTC block, at the offset CTC_VECTOR of platform/vectors.h: move both together
	.dw	unexpected_interrupt	; ctc channel 0
	.dw	unexpected_interrupt	; ctc channel 1
	.dw	unexpected_interrupt	; ctc channel 2
	.dw	timer_handler		; ctc channel 3
	.dw	unexpected_interrupt	; unused, keeps the SIO block 16-byte aligned
	.dw	unexpected_interrupt
	.dw	unexpected_interrupt
	.dw	unexpected_interrupt
; SIO block, at the offset SIO_VECTOR of platform/vectors.h: move both together
	.dw	unexpected_interrupt	; sio channel B transmit buffer empty
	.dw	unexpected_interrupt	; sio channel B external/status change
	.dw	unexpected_interrupt	; sio channel B receive character available
	.dw	unexpected_interrupt	; sio channel B special receive condition
	.dw	unexpected_interrupt	; sio channel A transmit buffer empty
	.dw	unexpected_interrupt	; sio channel A external/status change
	.dw	unexpected_interrupt	; sio channel A receive character available
	.dw	unexpected_interrupt	; sio channel A special receive condition
	.rept	112			; 128 entries in all
	.dw	unexpected_interrupt
	.endm

;---------------------------------------------------------------------------------------------
	.area	_COMMONMEM

msg_unexpected_interrupt:
	.asciz	"unexpected interrupt"

; unexpected_interrupt: an interrupt whose vector we never programmed. Calls panic, which does
; not return.

unexpected_interrupt:
	ld	hl, #msg_unexpected_interrupt
	jp	_panic

;---------------------------------------------------------------------------------------------
; timer_handler: the CTC channel that ticks points here

timer_handler:
	push	af
	push	bc
	push	de
	push	hl
	push	ix
	push	iy
	call	_timer_interrupt
	pop	iy
	pop	ix
	pop	hl
	pop	de
	pop	bc
	pop	af
	ei
	reti
