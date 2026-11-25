; list command: show the names in the root directory of the Fuzix file system

	.include	"file_system.inc"

	.area	_CODE

; cmd_list: mount the CF card and show the names in its root directory (first sector of the
; directory only: 16 entries)
;   destroys: A, BC, DE, HL
cmd_list::
	call	mount
	jp	c, mount_error		; mount_error returns to our caller

	call	inode_first		; inode 1: root directory
	jp	c, mount_error		; no used inode: the file system is broken
	call	dir_first
	jp	c, mount_error		; read error

	; show the name of each entry
1$:
	call	dir_next
	ret	c			; no more entries
	ld	c, #DIR_NAME_LENGTH	; no final 0 when the name has this length
2$:
	ld	a, (hl)
	or	a, a
	jr	z, 3$			; jump at the end of the name
	call	putc
	inc	hl
	dec	c
	jr	nz, 2$
3$:
	call	newline			; end of entry
	jr	1$
