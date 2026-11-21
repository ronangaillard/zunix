; list command: read the superblock of the Fuzix file system and show its size

; Superblock (block 1) offsets
FSIZE = 4				; size of the file system in blocks (2 bytes)

	.area	_DATA

SECTOR_SIZE = 512

sectorbuf:
	.ds	SECTOR_SIZE

lba:
	.ds	4			; sector number, little-endian

	.area	_CODE

; cmd_list: show the number of sectors of the file system, in hexadecimal
;   destroys: A, BC, DE, HL
cmd_list::
	ld	hl, #1			; sector 1: superblock
	ld	(lba), hl
	ld	hl, #0
	ld	(lba + 2), hl
	ld	de, #lba
	ld	hl, #sectorbuf
	call	read_sector

	ld	hl, #msg_sector_count_start
	call	puts
	ld	hl, (sectorbuf + FSIZE)	; blocks are 512 bytes: one block = one sector
	call	puthex
	ld	hl, #msg_sector_count_end
	call	puts
	ret

msg_sector_count_start:
	.asciz	"total sectors : 0x"
msg_sector_count_end:
	.asciz	"\r\n"
