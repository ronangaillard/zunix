; Fuzix file system (extended V7) on the CompactFlash card

V7_MAGIC = 0x31C6			; 12742

; Superblock (block 1) offsets
OFFSET_MAGIC = 0			; magic number (2 bytes)
OFFSET_ISIZE = 2			; first sector after the inode table (2 bytes)
OFFSET_FSIZE = 4			; size of the file system in blocks (2 bytes)

; Inode offsets
OFFSET_MODE_TYPE = 1			; high byte of the mode: type of the file, 0 if the inode is free
OFFSET_ADDRESS = 24			; sector numbers of the contents (20 * 2 bytes)
OFFSET_BLOCK_ADRESSES == 24

; Sizes in bytes
SECTOR_SIZE = 512
INODE_SIZE = 64
FOLDER_ENTRY_SIZE == 32			; == : also used in cmd_list.s
