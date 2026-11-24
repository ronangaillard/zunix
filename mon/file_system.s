; Fuzix file system (extended V7) on the CompactFlash card

V7_MAGIC = 0x31C6			; 12742

; Superblock (block 1) offsets
OFFSET_MAGIC = 0			; magic number (2 bytes)
OFFSET_ISIZE = 2			; first sector after the inode table (2 bytes)
OFFSET_FSIZE = 4			; size of the file system in blocks (2 bytes)

; Inode offsets
OFFSET_MODE_TYPE = 1			; high byte of the mode: type of the file, 0 if the inode is free
OFFSET_ADDRESS = 24			; sector numbers of the contents (20 * 2 bytes)

; Sizes in bytes
SECTOR_SIZE = 512
INODE_SIZE = 64
FOLDER_ENTRY_SIZE == 32			; == : also used in cmd_list.s

	.area	_DATA

inode_next_number:
	.ds	2			; number of the next inode to read

inode_table_end:
	.ds	2			; first sector after the inode table

inodebuf::
	.ds	INODE_SIZE		; last inode read

sectorbuf::
	.ds	SECTOR_SIZE		; last sector read

lba:
	.ds	4			; sector number, little-endian

	.area	_CODE

; mount: check that the CF card holds a Fuzix file system and find its inode table
;   out: A = 1 if the magic number is right, 0 if not
;   destroys: BC, DE, HL
mount::
	ld	hl, #1			; sector 1: superblock
	ld	(lba), hl
	ld	hl, #0
	ld	(lba + 2), hl
	ld	de, #lba
	ld	hl, #sectorbuf
	call	read_sector

	ld	hl, (sectorbuf + OFFSET_MAGIC)
	ld	de, #V7_MAGIC
	or	a, a			; clear carry flag
	sbc	hl, de
	jr	z, 1$			; jump when the magic number is right
	ld	a, #0			; no file system
	ret
1$:
	ld	hl, (sectorbuf + OFFSET_ISIZE)
	ld	(inode_table_end), hl	; sectorbuf will be overwritten
	ld	a, #1			; file system detected
	ret

; inode_first: read the first used inode of the table into inodebuf (mount first)
;   out: same as inode_next
;   destroys: A, BC, DE, HL
inode_first::
	ld	hl, #1			; inode 0 is reserved
	ld	(inode_next_number), hl
	call	inode_next
	ret

; inode_next: read the next used inode of the table into inodebuf
;   out: carry = 0: inodebuf = inode, DE = inode number
;        carry = 1: no more inodes
;   destroys: A, BC, HL
inode_next::
	; sector of the inode = number / 8 + 2 (8 inodes per sector)
	ld	de, (inode_next_number)
	srl	d
	rr	e
	srl	d
	rr	e
	srl	d
	rr	e			; divide by 8
	ex	de, hl
	inc	hl
	inc	hl			; the inode table starts at sector 2

	; end of the table ?
	ld	de, (inode_table_end)
	or	a, a			; clear carry flag
	sbc	hl, de
	jr	nc, 1$			; jump when sector >= end of the table
	add	hl, de			; restore the sector number

	ld	(lba), hl
	ld	hl, #0
	ld	(lba + 2), hl
	ld	de, #lba
	ld	hl, #sectorbuf
	call	read_sector

	; address of the inode = sectorbuf + (number modulo 8) * 64
	ld	hl, (inode_next_number)
	ld	a, l
	and	a, #0b0000000000000111	; number of the inode in the sector (0-7)
	ld	l, a
	ld	h, #0
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl			; multiply by 64 (inode size)
	ld	de, #sectorbuf
	add	hl, de

	; copy the inode to inodebuf
	ld	bc, #INODE_SIZE
	ld	de, #inodebuf
	ldir

	; next call: next inode
	ld	hl, (inode_next_number)
	ld	d, h
	ld	e, l			; de = number of this inode
	inc	hl
	ld	(inode_next_number), hl

	ld	a, (inodebuf + OFFSET_MODE_TYPE)
	or	a, a			; also clears carry flag: inode found
	jp	z, inode_next		; free inode: try the next one
	ret
1$:
	scf				; no more inodes
	ret

; dir_first: read the first sector of the directory whose inode is in inodebuf
;   out: sectorbuf = first 16 entries of the directory
;   destroys: A, BC, DE, HL
dir_first::
	ld	hl, (inodebuf + OFFSET_ADDRESS)	; first sector of the contents
	ld	(lba), hl
	ld	hl, #0
	ld	(lba + 2), hl
	ld	de, #lba
	ld	hl, #sectorbuf
	call	read_sector
	ret

; find_kernel_inode: look for the file "kernel.bin" in the root directory (first sector of the
; directory only: 16 entries); call mount then inode_first first, so that inodebuf = root inode
;   out: carry = 0: DE = inode number of the file
;        carry = 1: file not found
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

	or	a, a			; clears carry flag
	ret

kernel_file_name:
	.asciz	"kernel.bin"
