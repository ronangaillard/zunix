# Monitor in assembly

BUILD ?= build

# memory map: _CODE runs in common RAM at CODE_ADDR (stored in the ROM at 0x0100, copied at startup
# by vectors.s), variables at DATA_ADDR, stack below 0xFFFF; 0x0000-0xDFFF is left for the kernel
CODE_ADDR := 0xE000
DATA_ADDR := 0xF000

# vectors first: its absolute area holds 0x0000; the others are placed by the linker
SRC := vectors.s $(filter-out vectors.s,$(wildcard *.s))
OBJ := $(patsubst %.s,$(BUILD)/%.rel,$(SRC))

all: $(BUILD)/monitor.rom

# abspath: errors name the full path, so VS Code (.vscode/tasks.json) finds the file from anywhere
$(BUILD)/%.rel: %.s $(wildcard *.inc)
	mkdir -p $(BUILD)
	sdasz80 -plosgff -o $@ $(abspath $<)

# addresses where the code runs (not where it is stored in the ROM)
$(BUILD)/monitor.ihx: $(OBJ)
	sdldz80 -m -i -b _CODE=$(CODE_ADDR) -b _DATA=$(DATA_ADDR) $@ $(OBJ)

# -s 65536: the code is at 0xE000, beyond the default 32 KB
$(BUILD)/monitor.bin: $(BUILD)/monitor.ihx
	makebin -s 65536 -p $< $@

ROM_CHIP ?= SST39SF040
ROM_SIZE ?= 0x80000

# ROM layout: _HEADER (0x0000-0x00FF), then the code stored at 0x0100, though it runs at CODE_ADDR
$(BUILD)/monitor.img: $(BUILD)/monitor.bin
	python3 -c "import sys; d = open(sys.argv[1], 'rb').read(); \
	code = d[$(CODE_ADDR):]; \
	assert len(code) <= $(DATA_ADDR) - $(CODE_ADDR), '_CODE overlaps _DATA'; \
	open(sys.argv[2], 'wb').write(d[:0x100] + code)" $< $@

# full image of the flash: the layout, then 0xFF (erased flash) up to the size of the chip
$(BUILD)/monitor.rom: $(BUILD)/monitor.img
	python3 -c "import sys; d = open(sys.argv[1], 'rb').read(); \
	open(sys.argv[2], 'wb').write(d + b'\xff' * ($(ROM_SIZE) - len(d)))" $< $@
	@echo "$@: $$(wc -c < $<) bytes, code stored at 0x0100 in the ROM, runs at $(CODE_ADDR)"

# the same layout as Intel HEX, for the serial monitor: loaded at 0x0000 and started there, it runs
# like after a reset (monitor.ihx would not: its code is at 0xE000, and 0x0100 would be empty)
$(BUILD)/monitor-send.ihx: $(BUILD)/monitor.img
	python3 -c "import sys; d = open(sys.argv[1], 'rb').read(); out = open(sys.argv[2], 'w'); \
	recs = [bytes([len(d[a:a + 16]), a >> 8, a & 0xFF, 0]) + d[a:a + 16] for a in range(0, len(d), 16)]; \
	[out.write(':%s%02X\n' % (r.hex().upper(), -sum(r) & 0xFF)) for r in recs]; \
	out.write(':00000001FF\n')" $< $@

flash: $(BUILD)/monitor.rom
	minipro -p "$(ROM_CHIP)" -w $<

# sends the new build to the monitor and then runs it
SEND ?= ../tools/monitor-send.py

send: $(BUILD)/monitor-send.ihx
	python3 $(SEND) $<

# serial console only (resets the board: to keep a program in RAM, stay in send)
serial:
	python3 $(SEND)

clean:
	rm -rf $(BUILD)

.PHONY: all flash send serial clean
