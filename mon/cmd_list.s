; list command: show the names in the root directory of the Fuzix file system

	.area	_CODE

; cmd_list: mount the CF card and show the names in its root directory (first sector of the
; directory only: 16 entries)
;   destroys: A, BC, DE, HL
cmd_list::
	call	mount
	or	a, a
	jp	nz, 1$			; jump when the file system is mounted
	call	mount_error
	ret
1$:
	call	inode_first		; inode 1: root directory
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



msg_mount_success:
	.asciz	"mount success\r\n"

; print_inode: show that an inode was found
;   destroys: A, B, HL
print_inode:
	ld	hl, #msg_inode_found
	call	puts
	ret

msg_inode_found:
	.asciz	"inode found\r\n"

; file_found: show that a file was found
;   destroys: A, B, HL
file_found:
	ld	hl, #msg_file_found
	call	puts
	ret

; folder_found: show that a folder was found
;   destroys: A, B, HL
folder_found:
	ld	hl, #msg_folder_found
	call	puts
	ret

msg_bad_filesystem:
	.asciz	"CF disk is not formatted with V7 file system\r\n"
msg_good_filesystem:
	.asciz	"V7 filesystem detected\r\n"

msg_sector_count_start:
	.asciz	"total sectors : 0x"
msg_sector_count_middle:
	.asciz	" ("
msg_sector_count_end:
	.asciz	" Ko)\r\n"

msg_file_found:
	.asciz	"file found\r\n"
msg_folder_found:
	.asciz	"folder found\r\n"

msg_line_return:
	.asciz	"\r\n"
