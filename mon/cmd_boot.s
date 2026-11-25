; boot command: load the kernel ("kernel.bin" in the root directory of the CF card) and start it

	.include	"hw.inc"
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
	jp	c, kernel_load_error
	jp	KERNEL_ADDR		; start the kernel

; no_kernel_found: show that there is no "kernel.bin" in the root directory
;   destroys: A, B, HL
no_kernel_found:
	ld	hl, #msg_no_kernel_found
	call	puts
	ret

; kernel_load_error: show that "kernel.bin" could not be loaded
;   destroys: A, B, HL
kernel_load_error:
	ld	hl, #msg_kernel_load_error
	call	puts
	ret

; find_kernel_inode: look for the file "kernel.bin" in the root directory (first sector of the
; directory only: 16 entries) and read its inode; call mount then inode_first first, so that
; inodebuf = root inode
;   out: carry = 0: inodebuf = inode of the file, DE = its number
;        carry = 1: file not found, or read error
;   destroys: A, BC, HL
find_kernel_inode::
	call	dir_first
	ret	c			; read error
1$:
	call	dir_next
	ret	c			; no more entries: file not found
	push	de			; inode number
	ld	de, #kernel_file_name
	call	compare_strings
	pop	de
	jr	nz, 1$			; not this one

	; load kernel inode
	call	inode_read		; carry: result of inode_read, returned as is
	ret

kernel_file_name:
	.asciz	"kernel.bin"

msg_no_kernel_found:
	.asciz	"no kernel found on CF card\r\n"

msg_kernel_load_error:
	.asciz	"kernel.bin could not be loaded: read error, or bigger than 0x0000-0xDFFF\r\n"
