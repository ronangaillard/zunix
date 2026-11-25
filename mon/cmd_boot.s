; boot command: load the kernel ("kernel.bin" in the root directory of the CF card) and start it

	.include	"file_system.inc"

	.area	_CODE

; cmd_boot: mount the CF card, find "kernel.bin" in its root directory, read its inode and load
; the whole file into RAM at 0x0000, then start it there
;   destroys: A, BC, DE, HL
cmd_boot::
	call	mount
	jp	c, mount_error		; mount_error returns to our caller

	call	inode_first		; inodebuf = root directory
	jp	c, mount_error		; no used inode: the file system is broken
	call	find_kernel_inode
	jp	c, no_kernel_found

	call	load_file_to_ram
	jp	0x0000			; start the kernel

no_kernel_found:
	ld	hl, #msg_no_kernel_found
	call	puts
	ret

; find_kernel_inode: look for the file "kernel.bin" in the root directory (first sector of the
; directory only: 16 entries) and read its inode; call mount then inode_first first, so that
; inodebuf = root inode
;   out: carry = 0: inodebuf = inode of the file, DE = its number
;        carry = 1: file not found, or its inode could not be read
;   destroys: A, BC, HL
find_kernel_inode::
	call	dir_first
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
	jp	4$			; free entry (inode number = 0): skip it
3$:
	push	de
	ld	de, #kernel_file_name
	call	compare_strings
	jp	z, kernel_inode_found
	pop	de

4$:
	pop	hl			; beginning of the entry
	ld	de, #FOLDER_ENTRY_SIZE
	add	hl, de			; jump to next entry

	; end of the sector ?
	ld	de, #sectorbuf + 512
	or	a, a			; clear carry flag
	sbc	hl, de
	add	hl, de			; restore HL, carry does not change
	jr	c, 2$			; jump when HL < end of the sector
	scf				; set carry flag : kernel not found
	ret

kernel_inode_found:
	pop	de			; DE contains inode number
	pop	hl			; HL was pushed so pop it here

	; load kernel inode
	call	inode_read		; carry: result of inode_read, returned as is
	ret

kernel_file_name:
	.asciz	"kernel.bin"

msg_no_kernel_found:
	.asciz	"no kernel found on CF card\r\n"
