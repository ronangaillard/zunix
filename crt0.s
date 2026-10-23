; crt0 ("C runtime 0"): the assembly that runs before main().
;
; A C program expects two things to be ready when main() starts, and on bare metal nobody else
; does them: a stack, and global variables holding their initial values. This file does both,
; then calls main().
;
; The boot ROM loads kernel.bin at 0x0000 and jumps there with interrupts off, IM 1, RAM bank 0
; everywhere, SIO A at 115200 8N1 (polled), CF in 8-bit mode.
;
; Memory layout produced by the linker (see build/kernel/kernel.map):
;   0x0000  jp init           \
;   0x0038  IM 1 handler       |  _HEADER: fixed addresses imposed by the Z80
;   0x0066  NMI handler        |
;   0x0070  init              /
;   0x0100  _CODE             compiled C code and string constants
;           _INITIALIZER      initial values of the initialised globals (copied by gsinit)
;           _GSINIT/_GSFINAL  gsinit routine
;           _DATA             globals that start at 0       \ variables follow the code
;           _INITIALIZED      globals with an initial value / (--data-loc 0 in the Makefile)
;           ... free ...
;   0xFFFF  stack, grows down

; Name of this module: shown in kernel.map ("Defined In Module") and in error messages. Label only.
	.module crt0

; Options this file is meant to be linked with. The linker compares them with the C files and
; complains on a mismatch.
;   -mz80        target CPU (SDCC also targets Z180, Game Boy, ...)
;   sdcccall(1)  calling convention: which registers carry a C function's arguments and result.
;                Version 1: 8-bit argument in A, 16-bit in HL; 8-bit result in A, 16-bit in DE
;                (main.asm: puts(s) finds s in HL). Matters as soon as assembly and C call each
;                other with arguments; main() takes and returns nothing.
	.optsdcc -mz80 sdcccall(1)

; _main exists, but in another file (main.c; SDCC prefixes C names with _). The assembler leaves
; a hole at "call _main" and the linker fills in the address. The other way round, "name::" (two
; colons, like gsinit:: below) makes a label of this file visible to the others; "name:" stays local.
	.globl	_main

;---------------------------------------------------------------------------------------------
; Areas. An .area is a named bin for code or data: ".area _CODE" means "what follows goes into
; the _CODE bin" until the next .area.
;   - Every file fills its own bins: SDCC puts main.c's code and strings in _CODE, its globals
;     in _DATA / _INITIALIZED.
;   - The linker joins same-named bins from all files end to end (crt0's _CODE + main.c's _CODE
;     = one _CODE).
;   - It places the bins in memory in the order it first sees them. crt0.rel is linked first,
;     so the .area list further down sets the order of the whole memory.
;   - Addresses are chosen by the linker (REL, relocatable, in kernel.map): --code-loc 0x0100
;     in the Makefile puts _CODE at 0x100, --data-loc 0 lets the variable bins follow on.
;   - Except an ABS (absolute) area, like _HEADER here: there ".org 0x38" really means address
;     0x0038. That is why the Z80 vectors live in it.
;---------------------------------------------------------------------------------------------
; Fixed addresses.

	.area	_HEADER (ABS)

	.org	0			; reset, and where the boot ROM jumps
	jp	init

	.org	0x38			; IM 1: every maskable interrupt lands here.
	ei				; Nothing enables interrupts yet, so just return.
	reti

	.org	0x66			; NMI: cannot be masked, just return
	retn

	.org	0x70			; after the vectors, before _CODE at 0x0100 (must not overlap it)
init:
	ld	sp,#0x0000		; stack: the first push writes 0xFFFF-0xFFFE, top of common RAM
	call	gsinit			; set up the globals (below)
	call	_main
	di				; main() returned: nothing left to run, stop the CPU
1$:	halt				; (the loop catches an NMI waking the CPU up)
	jr	1$

;---------------------------------------------------------------------------------------------
; Area order. No code here: the linker places the areas in memory in the order they first
; appear, so this list is the layout above. Code first, variables after.

	.area	_HOME
	.area	_CODE
	.area	_INITIALIZER
	.area	_GSINIT
	.area	_GSFINAL
	.area	_DATA
	.area	_INITIALIZED
	.area	_BSEG
	.area	_BSS
	.area	_HEAP

;---------------------------------------------------------------------------------------------
; gsinit ("global/static init"): give every C global its starting value, once, before main().
; At power-up the RAM holds garbage; C promises that
;
;   int counter;        is 0          -> lives in _DATA, gsinit fills it with zeros
;   int speed = 9600;   is 9600       -> lives in _INITIALIZED; the 9600 itself is kept in
;                                        _INITIALIZER (part of kernel.bin) and gsinit copies it
;
; s__X / l__X are made by the linker: start address / length in bytes of area X. 
;
; Tools used below:
;   ld a,b / or a,c / jr z   the Z80 cannot test a 16-bit register for 0 directly: A = B OR C
;                            is 0 only when B and C are both 0, i.e. BC = 0
;   ldir                     copy BC bytes from (HL) to (DE): one byte, HL+1, DE+1, BC-1, repeat
;                            until BC = 0
;   2$, 3$                   local labels:  they only exist between two normal labels here     
;                            between gsinit:: and the next one), so the same numbers can be 
;                            used again after another normal label without a clash     
;
; gsinit is split in two areas: its body in _GSINIT, its ret alone in _GSFINAL, placed right
; after. If SDCC adds init code of its own to _GSINIT, it lands after ours and before the ret:
;   _GSINIT  : [our code: zeros + copy][SDCC's code, if any]
;   _GSFINAL : [ret]

	.area	_GSINIT
gsinit::
	; Part 1: zero _DATA.
	; The Z80 has no "fill" instruction. Trick: write 0 to the first byte, then LDIR with
	; DE = HL + 1 copies each byte onto the next one, so the 0 spreads over the whole area:
	;   [0][?][?][?]  ->  [0][0][?][?]  ->  [0][0][0][?]  ->  [0][0][0][0]
	ld	bc,#l__DATA		; BC = number of bytes to zero
	ld	a,b			; test BC = 0 ...
	or	a,c			; ... A = B OR C, Z set if both are 0
	jr	z,2$			; no such globals: go to part 2
	ld	hl,#s__DATA		; HL = first byte of _DATA
	ld	(hl),#0			; zero it by hand
	dec	bc			; one byte done, BC = bytes left
	ld	a,b			; test BC = 0 again
	or	a,c
	jr	z,2$			; it was the only byte: done
	ld	e,l			; DE = HL ...
	ld	d,h
	inc	de			; ... + 1: the byte right after
	ldir				; copy (HL) -> (DE) BC times: spreads the 0

	; Part 2: copy the initial values, _INITIALIZER (in kernel.bin) -> _INITIALIZED (variables).
2$:	ld	bc,#l__INITIALIZER	; BC = number of bytes to copy
	ld	a,b			; test BC = 0
	or	a,c
	jr	z,3$			; no initialised globals: done
	ld	de,#s__INITIALIZED	; DE = destination: the variables
	ld	hl,#s__INITIALIZER	; HL = source: the values stored in kernel.bin
	ldir				; plain copy of BC bytes
3$:					; SDCC's own init code, if any, would land here

	.area	_GSFINAL
	ret				; end of gsinit, always last: back to init, which calls main
