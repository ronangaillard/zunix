; list command: read the superblock of the Fuzix file system and show its size


	.area	_DATA


	.area	_CODE

; cmd_list: check that the CF card holds a V7 file system and show its number of sectors, in
; hexadecimal
;   destroys: A, BC, DE, HL
cmd_list::
	call	mount
	or	a, a
	jp	nz, 1$
	call	mount_error
	ret
1$:
	ld	hl, #msg_mount_success
	call	puts

	; inodes
	call	inode_first

2$:
	call	print_inode
	call	inode_next
	jp	nc, 2$


	ret

mount_error:
	ld	hl, #msg_mount_error
	call	puts
	ret
msg_mount_error:
	.asciz	"Mount error, check if CF is inserted and if CF is formatted with V7 file system\r\n"
msg_mount_success:
	.asciz	"Mount success\r\n"

print_inode:
	ld	hl, #msg_inode_found
	call	puts
	ret
msg_inode_found:
	.asciz	"inode found\r\n"

file_found:
	ld	hl, #msg_file_found
	call	puts
	ret

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
