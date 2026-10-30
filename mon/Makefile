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
	sdldz80 -m -i -b _CODE=0x0100 -b _DATA=0x8000 $@ $(OBJ)

$(BUILD)/monitor.bin: $(BUILD)/monitor.ihx
	makebin -p $< $@

ROM_CHIP   ?= SST39SF040
ROM_COPIES ?= 4

# on rev A board A17 and A18 are left floating, so we need to
# copy the monitor at 4 different places so that A17 and A18 don't bother
# This is fixed in rev B, so once I receive revB this is not needed anymore
$(BUILD)/monitor.rom: $(BUILD)/monitor.bin
	python3 -c "import sys; d = open(sys.argv[1], 'rb').read(); \
	assert len(d) <= 0x20000, 'monitor > 128 KB'; \
	open(sys.argv[2], 'wb').write((d + b'\xff' * (0x20000 - len(d))) * $(ROM_COPIES))" $< $@
	@echo "$@: $$(wc -c < $<) bytes of code, image for $(ROM_CHIP)"

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
