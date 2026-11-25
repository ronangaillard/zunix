# Monitor in assembly

BUILD ?= build

# vectors first: its absolute area holds 0x0000; the others are placed by the linker
SRC := vectors.s $(filter-out vectors.s,$(wildcard *.s))
OBJ := $(patsubst %.s,$(BUILD)/%.rel,$(SRC))

all: $(BUILD)/monitor.rom

# abspath: errors name the full path, so VS Code (.vscode/tasks.json) finds the file from anywhere
$(BUILD)/%.rel: %.s $(wildcard *.inc)
	mkdir -p $(BUILD)
	sdasz80 -plosgff -o $@ $(abspath $<)

# code after the vectors, variables in RAM
$(BUILD)/monitor.ihx: $(OBJ)
	sdldz80 -m -i -b _CODE=0x0E000 -b _DATA=0xF000 $@ $(OBJ)

$(BUILD)/monitor.bin: $(BUILD)/monitor.ihx
	makebin -s 65536 -p $< $@

ROM_CHIP   ?= SST39SF040

CODE_ADDR := 0xE000
DATA_ADDR := 0xF000
ROM_SIZE  ?= 0x80000

# the code runs at CODE_ADDR but is stored in the ROM at 0x0100: vectors.s copies it at startup
$(BUILD)/monitor.rom: $(BUILD)/monitor.bin
	python3 -c "import sys; d = open(sys.argv[1], 'rb').read(); \
	code = d[$(CODE_ADDR):]; \
	assert len(code) <= $(DATA_ADDR) - $(CODE_ADDR), '_CODE overlaps _DATA'; \
	img = d[:0x100] + code; \
	open(sys.argv[2], 'wb').write(img + b'\xff' * ($(ROM_SIZE) - len(img)))" $< $@
	@echo "$@: code stored at 0x0100 in the ROM, runs at $(CODE_ADDR)"
	
flash: $(BUILD)/monitor.rom
	minipro -p "$(ROM_CHIP)" -w $<

# sends the new build to the monitor and then runs it
SEND ?= ../tools/monitor-send.py

send: $(BUILD)/monitor.ihx
	python3 $(SEND) $<

# serial console only (resets the board: to keep a program in RAM, stay in send)
serial:
	python3 $(SEND)

clean:
	rm -rf $(BUILD)

.PHONY: all flash send serial clean
