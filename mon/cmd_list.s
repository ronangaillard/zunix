; list command: show the names in the root directory of the Fuzix file system

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

	; show each entry: inode number (2 bytes), name (30 bytes)
	ld	hl, #sectorbuf
2$:
	push	hl			; beginning of the entry
	ld	e, (hl)
	inc	hl
	ld	d, (hl)			; DE = inode number
	inc	hl			; HL = name
	ld	a, d
	or	a, e
	jp	nz, 3$
	jp	6$			; free entry (inode number = 0): skip it
3$:
	ld	c, #30			; 30 characters max, no final 0 in this case
4$:
	ld	a, (hl)
	or	a, a
	jp	z, 5$			; jump at the end of the name
	call	putc
	inc	hl
	dec	c
	jp	nz, 4$
5$:
	ld	hl, #msg_line_return	; end of entry
	call	puts
6$:
	pop	hl			; beginning of the entry
	ld	de, #FOLDER_ENTRY_SIZE
	add	hl, de			; jump to next entry

	; end of the sector ?
	ld	de, #sectorbuf + 512
	or	a, a			; clear carry flag
	sbc	hl, de
	add	hl, de			; restore HL, carry does not change
	jr	c, 2$			; jump when HL < end of the sector
	ret

msg_line_return:
	.asciz	"\r\n"
