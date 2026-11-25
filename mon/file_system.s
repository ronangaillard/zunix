	.include	"file_system.inc"

	.area	_DATA

inode_next_number:
	.ds	2			; number of the next inode to read

inode_table_end:
	.ds	2			; first sector after the inode table

inodebuf::
	.ds	INODE_SIZE		; last inode read

sectorbuf::
	.ds	SECTOR_SIZE		; last sector read

sector_pointer:
	.ds	2			; next entry to read in the indirect table (in sectorbuf)

lba:
	.ds	4			; sector number for read_sector, little-endian

	.area	_CODE

; mount: check that the CF card holds a Fuzix file system and find its inode table
;   out: carry = 0: file system found
;        carry = 1: no Fuzix file system (wrong magic number)
;   destroys: A, BC, DE, HL
mount::
	ld	de, #1			; block 1: superblock
	ld	hl, #sectorbuf
	call	read_block

	ld	hl, (sectorbuf + OFFSET_MAGIC)
	ld	de, #V7_MAGIC
	or	a, a			; clear carry flag
	sbc	hl, de
	jr	z, 1$			; jump when the magic number is right
	scf				; no file system
	ret
1$:
	ld	hl, (sectorbuf + OFFSET_ISIZE)
	ld	(inode_table_end), hl	; sectorbuf will be overwritten
	or	a, a			; clear carry flag: file system found
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

	ex	de, hl
	ld	hl, #sectorbuf
	call	read_block

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

; inode_read: read an inode, given its number, into inodebuf (mount first)
; if this inode is free, the next used one is read instead (DE tells which one): give the number of
; a used inode, like the ones found in a directory
;   in:  DE = inode number
;   out: carry = 0: inodebuf = inode, DE = inode number
;        carry = 1: no used inode from this number to the end of the table
;   destroys: A, BC, HL
inode_read::
	ld	(inode_next_number), de
	call	inode_next
	ret

; dir_first: read the first sector of the directory whose inode is in inodebuf
;   out: sectorbuf = first 16 entries of the directory
;   destroys: A, BC, DE, HL
dir_first::
	ld	de, (inodebuf + OFFSET_ADDRESS)	; first sector of the contents
	ld	hl, #sectorbuf
	call	read_block
	ret

; read_block: read one block (one block = one sector) of the file system
;   in:  DE = block number (16 bits, like in the inodes)
;        HL = address of the destination buffer (512 bytes)
;   out: HL = address just after the buffer
;   destroys: A, BC, DE
read_block:
	ld	(lba), de
	ld	de, #0
	ld	(lba + 2), de		; the file system only uses 16-bit block numbers
	ld	de, #lba
	jp	read_sector		; read_sector returns to our caller

; load_file_to_ram: read the file whose inode is in inodebuf into RAM, sector after sector (18 direct
; blocks, then the single indirect block: files up to 137 KB); stops at the first empty block (0)
; for now the destination is always 0x0000; sectorbuf is overwritten (indirect table)
;   out: HL = address after the last byte read
;   destroys: A, BC, DE
load_file_to_ram::
	ld	b, #0			; B = number of direct addresses blocs

	ld	hl, #0
	push	hl			; HL = destination of read bytes in RAM
read_loop:
	ld	hl, #inodebuf + OFFSET_ADDRESS	; first sector of the content
	ld	e, b
	ld	d, #0
	add	hl, de

	ld	e, (hl)
	inc	hl
	ld	d, (hl)			; DE = sector to read

	; is it last sector ?
	ld	a, d
	or	a, e			; Z = 1 if DE = 0
	jp	z, end_of_file

	pop	hl			; HL = destination
	push	bc
	call	read_block
	pop	bc

	push	hl
	inc	b
	inc	b

	ld	a, #36			; 36 = 18 * 2
	cp	a, b
	jp	z, indirect_addressing_table_read

	jp	read_loop

indirect_addressing_table_read:
	; read sector containing indirect adresses
	ld	de, (inodebuf + OFFSET_ADDRESS + 36)	; DE = sector of indirect address table

	; is it last sector ?
	ld	a, d
	or	a, e			; Z = 1 if DE = 0
	jp	z, end_of_file

	ld	hl, #sectorbuf		; sectorbuf will contain indirect address table
	call	read_block
	ld	hl, #sectorbuf
	ld	(sector_pointer), hl	; first entry of the indirect table

	; stack during the loop: destination only (like the direct loop)
indirect_addressing_loop:
	; end of the indirect table ? (256 entries)
	ld	hl, (sector_pointer)
	ld	de, #sectorbuf + SECTOR_SIZE
	or	a, a			; clear carry flag
	sbc	hl, de
	jp	z, end_of_file

	; read the entry, then move the pointer to the next one
	ld	hl, (sector_pointer)
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	inc	hl
	ld	(sector_pointer), hl	; DE = sector to read

	; is it last sector ?
	ld	a, d
	or	a, e			; Z = 1 if DE = 0
	jp	z, end_of_file

	pop	hl			; HL = destination
	call	read_block
	push	hl			; destination of the next sector

	jp	indirect_addressing_loop


end_of_file:
	pop	hl
	ret


; mount_error: show that the CF card could not be mounted
;   destroys: A, B, HL
mount_error::
	ld	hl, #msg_mount_error
	call	puts
	ret

msg_mount_error:
	.asciz	"mount error, check if CF is inserted and if CF is formatted with V7 file system\r\n"
