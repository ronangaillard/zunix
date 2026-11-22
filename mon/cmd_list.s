; list command: read the superblock of the Fuzix file system and show its size

V7_MAGIC = 0x31C6			; 12742

; Superblock (block 1) offsets
OFFSET_MAGIC = 0			; magic number (2 bytes)
OFFSET_FSIZE = 4			; size of the file system in blocks (2 bytes)

	.area	_DATA

SECTOR_SIZE = 512

sectorbuf:
	.ds	SECTOR_SIZE

lba:
	.ds	4			; sector number, little-endian

	.area	_CODE

; cmd_list: check that the CF card holds a V7 file system and show its number of sectors, in
; hexadecimal
;   destroys: A, BC, DE, HL
cmd_list::
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
	jr	z, 1$
	ld	hl, #msg_bad_filesystem
	call	puts
	ret
1$:					; v7 file system detected
	ld	hl, #msg_good_filesystem
	call	puts

	ld	hl, #msg_sector_count_start
	call	puts
	ld	hl, (sectorbuf + OFFSET_FSIZE)	; blocks are 512 bytes: one block = one sector
	call	puthex
	ld	hl, #msg_sector_count_middle
	call	puts
	ld	hl, (sectorbuf + OFFSET_FSIZE)
	call	putdec
	ld	hl, #msg_sector_count_end
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
	.asciz	")\r\n"
